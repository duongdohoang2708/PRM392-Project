import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_record.dart';
import '../models/task_model.dart';
import '../providers/focus_provider.dart';
import '../providers/goals_provider.dart';
import '../services/notification_service.dart';
import '../utils/reminder/insight_notification_builder.dart';
import '../utils/reminder/insight_notification_ids.dart';
import '../utils/reminder/reminder_scheduler.dart';
import 'task_provider.dart';
import 'settings_provider.dart';

class NotificationProvider with ChangeNotifier {
  static const String _firedKeysPref = 'notification_fired_keys';
  static const String _historyPref = 'notification_history';
  static const String _unlockedAchievementsPref = 'notification_unlocked_achievements';
  static const String _dailyFlagsPref = 'notification_daily_flags';
  static const String _dailyDayPref = 'notification_daily_day';
  static const String _statsMilestonePref = 'notification_stats_milestone';
  static const int _maxHistoryRecords = 100;

  final List<NotificationRecord> _records = [];
  final Set<String> _firedReminderKeys = {};
  final Set<String> _unlockedAchievementKeys = {};
  final Set<String> _dailyFlags = {};
  int _lastCompletedTasksAllTime = 0;

  List<Task> _tasks = [];
  String? _tasksSignature;
  String? _insightSignature;
  SettingsProvider? _settingsProvider;
  GoalsProvider? _goalsProvider;
  FocusProvider? _focusProvider;
  String? _settingsSignature;
  Timer? _watchdog;
  bool _initialized = false;
  bool _firedKeysLoaded = false;
  bool _achievementStateLoaded = false;

  NotificationProvider() {
    unawaited(_bootstrapHistory());
    _loadFiredKeys();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  List<NotificationRecord> get records => List.unmodifiable(
        _records..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      );

  int get unreadCount => _records.where((record) => !record.isRead).length;

  void bindSources({
    required TaskProvider taskProvider,
    required FocusProvider focusProvider,
    required GoalsProvider goalsProvider,
    SettingsProvider? settingsProvider,
  }) {
    _goalsProvider = goalsProvider;
    _focusProvider = focusProvider;

    if (settingsProvider != null) {
      final newSettingsSignature = _buildSettingsSignature(settingsProvider);
      final settingsChanged = newSettingsSignature != _settingsSignature;
      _settingsProvider = settingsProvider;
      _settingsSignature = newSettingsSignature;
      if (settingsChanged && _initialized) {
        unawaited(_applyNotificationPreferenceChanges());
      }
    }
    final firstBind = !_initialized;
    final newTasks = List<Task>.from(taskProvider.tasks);
    final removedTaskIds = _tasks.map((t) => t.id).toSet()
      ..removeAll(newTasks.map((t) => t.id));
    for (final taskId in removedTaskIds) {
      unawaited(NotificationService.cancelAllTaskNotifications(taskId));
    }

    _tasks = newTasks;

    final taskSignature = _buildTasksSignature(_tasks);
    if (taskSignature != _tasksSignature) {
      _tasksSignature = taskSignature;
      if (_settingsProvider?.canDeliverTaskReminders ?? true) {
        unawaited(NotificationService.rescheduleAllTaskReminders(_tasks));
      } else {
        for (final task in _tasks) {
          unawaited(NotificationService.cancelAllTaskNotifications(task.id));
        }
      }
    }

    final insightSignature = _buildInsightSignature(
      tasks: _tasks,
      goalsProvider: goalsProvider,
      focusProvider: focusProvider,
    );
    if (insightSignature != _insightSignature) {
      _insightSignature = insightSignature;
      unawaited(
        _syncInsightNotifications(
          tasks: _tasks,
          goalsProvider: goalsProvider,
          focusProvider: focusProvider,
        ),
      );
    }

    if (firstBind) {
      NotificationService.setOnNotificationDelivered(_handleDeliveredNotification);
      _initialized = true;
      unawaited(_bootstrapDeliveredSync(goalsProvider));
      _startWatchdog();
    }
  }

  Future<void> _bootstrapHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_historyPref);
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          _records.addAll(
            decoded
                .whereType<Map<String, dynamic>>()
                .map(NotificationRecord.fromJson),
          );
          notifyListeners();
          return;
        }
      } catch (_) {
        // Fall through to seed mock history if storage is corrupted.
      }
    }

    _seedMockHistory();
    await _persistHistory();
    notifyListeners();
  }

  Future<void> _bootstrapDeliveredSync(GoalsProvider goalsProvider) async {
    await _loadFiredKeys();
    await _loadAchievementState();
    await _seedAchievementsIfNeeded(goalsProvider);
    await _loadDailyFlags();
    _lastCompletedTasksAllTime = goalsProvider.completedTasksAllTime;
    await syncDeliveredReminders(_tasks);
  }

  Future<void> _seedAchievementsIfNeeded(GoalsProvider goalsProvider) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_unlockedAchievementsPref)) return;
    for (final achievement in goalsProvider.achievements) {
      if (achievement.isUnlocked) {
        _unlockedAchievementKeys.add(
          InsightNotificationBuilder.achievementKey(achievement),
        );
      }
    }
    _lastCompletedTasksAllTime = goalsProvider.completedTasksAllTime;
    await _persistAchievementState();
  }

  String _buildSettingsSignature(SettingsProvider settings) {
    return [
      settings.notificationsEnabled,
      settings.taskRemindersEnabled,
      settings.goalsInsightsEnabled,
      settings.achievementsEnabled,
      settings.quietHoursEnabled,
      settings.quietHoursStart.hour,
      settings.quietHoursStart.minute,
      settings.quietHoursEnd.hour,
      settings.quietHoursEnd.minute,
    ].join('|');
  }

  Future<void> _applyNotificationPreferenceChanges() async {
    if (_settingsProvider == null) return;

    if (_settingsProvider!.canDeliverTaskReminders) {
      await NotificationService.rescheduleAllTaskReminders(_tasks);
    } else {
      for (final task in _tasks) {
        await NotificationService.cancelAllTaskNotifications(task.id);
      }
    }

    final goalsProvider = _goalsProvider;
    final focusProvider = _focusProvider;
    if (goalsProvider != null && focusProvider != null) {
      await _syncInsightNotifications(
        tasks: _tasks,
        goalsProvider: goalsProvider,
        focusProvider: focusProvider,
      );
    }
  }

  bool _canDeliverTaskReminderNow() {
    final settings = _settingsProvider;
    if (settings == null) return true;
    if (!settings.canDeliverTaskReminders) return false;
    if (settings.isInQuietHours()) return false;
    return true;
  }

  String _buildTasksSignature(List<Task> tasks) {
    return tasks
        .map(
          (task) =>
              '${task.id}|${task.title}|${task.reminder}|${task.dueDate?.millisecondsSinceEpoch}|${task.isCompleted}|${task.isAllDay}',
        )
        .join(';;');
  }

  String _buildInsightSignature({
    required List<Task> tasks,
    required GoalsProvider goalsProvider,
    required FocusProvider focusProvider,
  }) {
    return [
      InsightNotificationBuilder.tasksDueTodayCount(tasks),
      InsightNotificationBuilder.overdueCount(tasks),
      InsightNotificationBuilder.importantIncompleteDueToday(tasks),
      goalsProvider.focusMinutesToday,
      goalsProvider.taskGoalMetToday,
      goalsProvider.focusGoalMetToday,
      goalsProvider.isTodayRestDay,
      goalsProvider.isTodayComplete,
      goalsProvider.currentStreak,
      goalsProvider.completedTasksAllTime,
      focusProvider.completedSessionsCount,
    ].join('|');
  }

  Future<void> _loadFiredKeys() async {
    if (_firedKeysLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_firedKeysPref) ?? [];
    final cutoff = DateTime.now()
        .subtract(const Duration(minutes: 30))
        .millisecondsSinceEpoch;

    _firedReminderKeys.addAll(
      stored.where((key) {
        final timestamp = _firedKeyTimestamp(key);
        return timestamp != null && timestamp >= cutoff;
      }),
    );
    _firedKeysLoaded = true;
  }

  Future<void> _loadAchievementState() async {
    if (_achievementStateLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _unlockedAchievementKeys.addAll(
      prefs.getStringList(_unlockedAchievementsPref) ?? [],
    );
    _lastCompletedTasksAllTime = prefs.getInt(_statsMilestonePref) ?? 0;
    _achievementStateLoaded = true;
  }

  Future<void> _persistAchievementState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _unlockedAchievementsPref,
      _unlockedAchievementKeys.toList(),
    );
    await prefs.setInt(_statsMilestonePref, _lastCompletedTasksAllTime);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _loadDailyFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDay = prefs.getString(_dailyDayPref);
    final today = _todayKey();
    if (storedDay != today) {
      _dailyFlags.clear();
      await prefs.setString(_dailyDayPref, today);
      await prefs.setStringList(_dailyFlagsPref, []);
      return;
    }
    _dailyFlags.addAll(prefs.getStringList(_dailyFlagsPref) ?? []);
  }

  Future<void> _setDailyFlag(String flag) async {
    await _loadDailyFlags();
    if (_dailyFlags.contains(flag)) return;
    _dailyFlags.add(flag);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyDayPref, _todayKey());
    await prefs.setStringList(_dailyFlagsPref, _dailyFlags.toList());
  }

  bool _hasDailyFlag(String flag) {
    return _dailyFlags.contains(flag);
  }

  int? _firedKeyTimestamp(String key) {
    final separator = key.lastIndexOf('_');
    if (separator == -1) return null;
    return int.tryParse(key.substring(separator + 1));
  }

  Future<void> _markNotificationFired(String key) async {
    if (_firedReminderKeys.contains(key)) return;
    _firedReminderKeys.add(key);
    await _persistFiredKeys();
  }

  Future<void> _persistFiredKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now()
        .subtract(const Duration(minutes: 30))
        .millisecondsSinceEpoch;
    final pruned = _firedReminderKeys
        .where((key) {
          final timestamp = _firedKeyTimestamp(key);
          return timestamp != null && timestamp >= cutoff;
        })
        .toList();
    _firedReminderKeys
      ..clear()
      ..addAll(pruned);
    await prefs.setStringList(_firedKeysPref, pruned);
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = List<NotificationRecord>.from(_records)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final capped = sorted.take(_maxHistoryRecords).toList();
    await prefs.setString(
      _historyPref,
      jsonEncode(capped.map((record) => record.toJson()).toList()),
    );
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkDueReminders();
    });
  }

  Future<void> _checkDueReminders() async {
    if (!_canDeliverTaskReminderNow()) return;

    for (final task in _tasks) {
      final reminderAt = ReminderScheduler.computeRawFireTime(
        dueDate: task.dueDate,
        isAllDay: task.isAllDay,
        reminder: task.reminder,
      );
      if (reminderAt != null &&
          ReminderScheduler.shouldDeliverReminderNow(task, reminderAt)) {
        final key = 'reminder_${task.id}_${reminderAt.millisecondsSinceEpoch}';
        if (!_firedReminderKeys.contains(key)) {
          await _markNotificationFired(key);
          await NotificationService.showTaskReminderNow(
            task: task,
            fireAt: reminderAt,
          );
        }
      }

      final dueAt = ReminderScheduler.computeRawDueFireTime(task);
      if (dueAt != null && ReminderScheduler.shouldDeliverDueNow(task, dueAt)) {
        final key = 'due_${task.id}_${dueAt.millisecondsSinceEpoch}';
        if (!_firedReminderKeys.contains(key)) {
          await _markNotificationFired(key);
          await NotificationService.showTaskDueNow(task: task, dueAt: dueAt);
        }
      }
    }
  }

  Future<void> _syncInsightNotifications({
    required List<Task> tasks,
    required GoalsProvider goalsProvider,
    required FocusProvider focusProvider,
  }) async {
    if (_settingsProvider != null && !_settingsProvider!.notificationsEnabled) {
      await NotificationService.cancelAllInsightNotifications();
      return;
    }
    await _loadAchievementState();
    await _loadDailyFlags();

    await _checkEventDrivenInsights(
      tasks: tasks,
      goalsProvider: goalsProvider,
      focusProvider: focusProvider,
    );
    await _rescheduleInsightNotifications(
      tasks: tasks,
      goalsProvider: goalsProvider,
      focusProvider: focusProvider,
    );
  }

  Future<void> _checkEventDrivenInsights({
    required List<Task> tasks,
    required GoalsProvider goalsProvider,
    required FocusProvider focusProvider,
  }) async {
    if (goalsProvider.taskGoalMetToday &&
        goalsProvider.focusGoalMetToday &&
        !goalsProvider.isTodayRestDay &&
        !_hasDailyFlag('streak_secured')) {
      final copy = InsightNotificationBuilder.streakSecured(goalsProvider);
      await _deliverInsightNow(
        notificationId: 121001,
        type: 'streak_secured',
        title: copy.title,
        body: copy.body,
      );
      await _setDailyFlag('streak_secured');
    }

    if (goalsProvider.focusGoalMetToday && !_hasDailyFlag('focus_goal_met')) {
      final copy = InsightNotificationBuilder.focusGoalMet(goalsProvider);
      await _deliverInsightNow(
        notificationId: 121002,
        type: 'focus_goal_met',
        title: copy.title,
        body: copy.body,
      );
      await _setDailyFlag('focus_goal_met');
    }

    final focusRemaining = goalsProvider.focusDailyGoal.remaining;
    if (!goalsProvider.isTodayRestDay &&
        !goalsProvider.focusGoalMetToday &&
        focusRemaining > 0 &&
        focusRemaining <= InsightNotificationBuilder.focusNearMinutes &&
        !_hasDailyFlag('focus_goal_near')) {
      final copy = InsightNotificationBuilder.focusGoalNear(goalsProvider);
      await _deliverInsightNow(
        notificationId: 121003,
        type: 'focus_goal_near',
        title: copy.title,
        body: copy.body,
      );
      await _setDailyFlag('focus_goal_near');
    }

    for (final achievement in goalsProvider.achievements) {
      final key = InsightNotificationBuilder.achievementKey(achievement);
      if (achievement.isUnlocked) {
        if (!_unlockedAchievementKeys.contains(key)) {
          _unlockedAchievementKeys.add(key);
          final copy = InsightNotificationBuilder.achievementUnlocked(achievement);
          await _deliverInsightNow(
            notificationId: _insightEventId(key),
            type: 'achievement_unlock',
            title: copy.title,
            body: copy.body,
          );
        }
      } else {
        final near = InsightNotificationBuilder.achievementNearUnlock(achievement);
        final nearFlag = 'near_$key';
        if (near != null && !_hasDailyFlag(nearFlag)) {
          await _deliverInsightNow(
            notificationId: _insightEventId('near_$key'),
            type: 'achievement_near',
            title: near.title,
            body: near.body,
          );
          await _setDailyFlag(nearFlag);
        }
      }
    }
    await _persistAchievementState();

    final completedAllTime = goalsProvider.completedTasksAllTime;
    if (completedAllTime > _lastCompletedTasksAllTime) {
      final milestone = InsightNotificationBuilder.statisticsMilestone(
        completedTasksAllTime: completedAllTime,
      );
      if (milestone != null) {
        await _deliverInsightNow(
          notificationId: _insightEventId('stats_$completedAllTime'),
          type: 'stats_milestone',
          title: milestone.title,
          body: milestone.body,
        );
      }
      _lastCompletedTasksAllTime = completedAllTime;
      await _persistAchievementState();
    }

    if (!goalsProvider.isTodayRestDay &&
        !goalsProvider.isTodayComplete &&
        goalsProvider.manualRestCreditsRemaining == 1 &&
        !_hasDailyFlag('freeze_credit')) {
      await _deliverInsightNow(
        notificationId: _insightEventId('freeze_credit'),
        type: 'freeze_credit',
        title: 'One freeze credit left',
        body:
            'You have 1 manual freeze day left this month if today gets away from you.',
      );
      await _setDailyFlag('freeze_credit');
    }
  }

  int _insightEventId(String seed) =>
      121000 + (seed.hashCode & 0x7fffffff) % 8000;

  bool _canScheduleInsightType(String type) {
    final settings = _settingsProvider;
    if (settings == null) return true;
    return settings.canDeliverInsightType(type);
  }

  Future<void> _rescheduleInsightNotifications({
    required List<Task> tasks,
    required GoalsProvider goalsProvider,
    required FocusProvider focusProvider,
  }) async {
    await NotificationService.cancelAllInsightNotifications();

    final morning = InsightNotificationBuilder.morningDigest(tasks);
    final morningAt = InsightNotificationBuilder.nextDailyTime(
      hour: InsightNotificationBuilder.morningHour,
      minute: InsightNotificationBuilder.morningMinute,
    );
    if (morningAt != null && _canScheduleInsightType('morning_digest')) {
      await NotificationService.scheduleInsightNotification(
        notificationId: InsightNotificationIds.morningDigest,
        type: 'morning_digest',
        title: morning.title,
        body: morning.body,
        scheduledAt: morningAt,
      );
    }

    final overdue = InsightNotificationBuilder.overdueDigest(tasks);
    final overdueAt = InsightNotificationBuilder.nextDailyTime(
      hour: InsightNotificationBuilder.morningHour,
      minute: InsightNotificationBuilder.overdueDigestMinute,
    );
    if (overdue != null && overdueAt != null && _canScheduleInsightType('overdue_digest')) {
      await NotificationService.scheduleInsightNotification(
        notificationId: InsightNotificationIds.overdueDigest,
        type: 'overdue_digest',
        title: overdue.title,
        body: overdue.body,
        scheduledAt: overdueAt,
      );
    }

    final important = InsightNotificationBuilder.importantEod(tasks);
    final importantAt = InsightNotificationBuilder.nextDailyTime(
      hour: InsightNotificationBuilder.importantEodHour,
      minute: InsightNotificationBuilder.importantEodMinute,
    );
    if (important != null && importantAt != null && _canScheduleInsightType('important_eod')) {
      await NotificationService.scheduleInsightNotification(
        notificationId: InsightNotificationIds.importantEod,
        type: 'important_eod',
        title: important.title,
        body: important.body,
        scheduledAt: importantAt,
      );
    }

    final goalsEod = InsightNotificationBuilder.goalsEndOfDay(goalsProvider);
    final goalsAt = InsightNotificationBuilder.nextDailyTime(
      hour: InsightNotificationBuilder.goalsEodHour,
      minute: InsightNotificationBuilder.goalsEodMinute,
    );
    if (goalsEod != null && goalsAt != null && _canScheduleInsightType('streak_reminder')) {
      await NotificationService.scheduleInsightNotification(
        notificationId: InsightNotificationIds.goalsEod,
        type: 'streak_reminder',
        title: goalsEod.title,
        body: goalsEod.body,
        scheduledAt: goalsAt,
      );
    }

    if (goalsProvider.isTodayRestDay) {
      final freezeCopy = InsightNotificationBuilder.freezeDayMorning(goalsProvider);
      final freezeAt = InsightNotificationBuilder.nextDailyTime(
        hour: InsightNotificationBuilder.freezeDayHour,
        minute: 0,
      );
      if (freezeAt != null && _canScheduleInsightType('freeze_day')) {
        await NotificationService.scheduleInsightNotification(
          notificationId: InsightNotificationIds.freezeDayMorning,
          type: 'freeze_day',
          title: freezeCopy.title,
          body: freezeCopy.body,
          scheduledAt: freezeAt,
        );
      }
    }

    final weeklyAt = InsightNotificationBuilder.nextWeeklySundayTime(
      hour: InsightNotificationBuilder.weeklySummaryHour,
      minute: InsightNotificationBuilder.weeklySummaryMinute,
    );
    if (weeklyAt != null && _canScheduleInsightType('weekly_summary')) {
      final weekly = InsightNotificationBuilder.weeklySummary(
        tasks: tasks,
        goals: goalsProvider,
        focusMinutesThisWeek:
            InsightNotificationBuilder.focusMinutesInLastDays(focusProvider, 7),
      );
      await NotificationService.scheduleInsightNotification(
        notificationId: InsightNotificationIds.weeklySummary,
        type: 'weekly_summary',
        title: weekly.title,
        body: weekly.body,
        scheduledAt: weeklyAt,
      );
    }
  }

  Future<void> _deliverInsightNow({
    required int notificationId,
    required String type,
    required String title,
    required String body,
  }) async {
    if (_settingsProvider != null && !_settingsProvider!.canDeliverInsightType(type)) {
      return;
    }
    await NotificationService.showInsightNotification(
      notificationId: notificationId,
      type: type,
      title: title,
      body: body,
    );
  }

  List<NotificationRecord> filteredRecords({
    required String filter,
    required List<Task> tasks,
  }) {
    final history = records;
    switch (filter) {
      case 'Tasks':
        return history
            .where(
              (record) =>
                  record.category == NotificationCategory.taskReminder ||
                  record.category == NotificationCategory.taskDue ||
                  (record.category == NotificationCategory.statistics &&
                      _isTaskDigestRecord(record)),
            )
            .toList();
      case 'Focus':
        return history
            .where((record) => record.category == NotificationCategory.focus)
            .toList();
      case 'Goals':
        return history
            .where((record) => record.category == NotificationCategory.goals)
            .toList();
      case 'Achievements':
        return history
            .where(
              (record) => record.category == NotificationCategory.achievement,
            )
            .toList();
      default:
        return history;
    }
  }

  bool _isTaskDigestRecord(NotificationRecord record) {
    final title = record.title.toLowerCase();
    return title.contains('today') ||
        title.contains('overdue') ||
        title.contains('important');
  }

  void addRecord(NotificationRecord record) {
    final duplicate = _records.any(
      (existing) =>
          existing.id == record.id ||
          (existing.taskId != null &&
              existing.taskId == record.taskId &&
              existing.category == record.category &&
              existing.timestamp.difference(record.timestamp).inMinutes.abs() <
                  2),
    );
    if (duplicate) return;
    _records.insert(0, record);
    notifyListeners();
    unawaited(_persistHistory());
  }

  void markAsRead(String id) {
    final index = _records.indexWhere((record) => record.id == id);
    if (index == -1 || _records[index].isRead) return;
    _records[index] = _records[index].copyWith(isRead: true);
    notifyListeners();
    unawaited(_persistHistory());
  }

  void markAllRead() {
    var changed = false;
    for (var i = 0; i < _records.length; i++) {
      if (!_records[i].isRead) {
        _records[i] = _records[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      unawaited(_persistHistory());
    }
  }

  void clearAll() {
    if (_records.isEmpty) return;
    _records.clear();
    notifyListeners();
    unawaited(_persistHistory());
  }

  Future<void> syncDeliveredReminders(List<Task> tasks) async {
    await _loadFiredKeys();
    final now = DateTime.now();
    for (final task in tasks) {
      if (ReminderScheduler.shouldRemindForTask(task)) {
        final pastFireAt = ReminderScheduler.computeRawFireTime(
          dueDate: task.dueDate,
          isAllDay: task.isAllDay,
          reminder: task.reminder,
        );
        if (pastFireAt != null &&
            pastFireAt.isBefore(now) &&
            ReminderScheduler.shouldBackfillReminderHistory(task, pastFireAt)) {
          final key =
              'reminder_${task.id}_${pastFireAt.millisecondsSinceEpoch}';
          await _markNotificationFired(key);
          addRecord(
            NotificationRecord(
              id: 'delivered_${task.id}_${pastFireAt.millisecondsSinceEpoch}',
              category: NotificationCategory.taskReminder,
              title: task.title,
              body: ReminderScheduler.buildNotificationBody(task, pastFireAt),
              timestamp: pastFireAt,
              taskId: task.id,
              isRead: now.difference(pastFireAt).inHours > 6,
            ),
          );
        }
      }

      if (ReminderScheduler.shouldNotifyAtDue(task)) {
        final pastDueAt = ReminderScheduler.computeRawDueFireTime(task);
        if (pastDueAt != null &&
            pastDueAt.isBefore(now) &&
            ReminderScheduler.shouldBackfillDueHistory(task, pastDueAt)) {
          final key = 'due_${task.id}_${pastDueAt.millisecondsSinceEpoch}';
          await _markNotificationFired(key);
          addRecord(
            NotificationRecord(
              id: 'delivered_due_${task.id}_${pastDueAt.millisecondsSinceEpoch}',
              category: NotificationCategory.taskDue,
              title: task.title,
              body: ReminderScheduler.buildDueNotificationBody(task),
              timestamp: pastDueAt,
              taskId: task.id,
              isRead: now.difference(pastDueAt).inHours > 6,
            ),
          );
        }
      }
    }
  }

  void _handleDeliveredNotification({
    required String title,
    required String body,
    required String type,
    String? taskId,
  }) {
    addRecord(
      NotificationRecord(
        id: 'live_${DateTime.now().millisecondsSinceEpoch}',
        category: categoryFromType(type),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        taskId: taskId,
      ),
    );
  }

  void _seedMockHistory() {
    final now = DateTime.now();
    _records.addAll([
      NotificationRecord(
        id: 'mock_1',
        category: NotificationCategory.taskReminder,
        title: 'Finish Flutter Assignment',
        body: 'Due at 10:00 AM',
        timestamp: now.subtract(const Duration(hours: 2)),
        taskId: '1',
        isRead: true,
      ),
      NotificationRecord(
        id: 'mock_2',
        category: NotificationCategory.statistics,
        title: 'Today in TaskFlow',
        body: '3 tasks due today • 1 overdue',
        timestamp: now.subtract(const Duration(hours: 6)),
        isRead: false,
      ),
      NotificationRecord(
        id: 'mock_3',
        category: NotificationCategory.focus,
        title: 'Focus Session Finished',
        body: 'Great job! Take a short break.',
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      NotificationRecord(
        id: 'mock_4',
        category: NotificationCategory.goals,
        title: 'Streak secured!',
        body: '4-day streak — today\'s tasks and focus goals are complete.',
        timestamp: now.subtract(const Duration(hours: 8)),
        isRead: false,
      ),
      NotificationRecord(
        id: 'mock_5',
        category: NotificationCategory.achievement,
        title: 'Achievement unlocked',
        body: '5-day streak',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationRecord(
        id: 'mock_6',
        category: NotificationCategory.statistics,
        title: 'Your week in TaskFlow',
        body: '6 tasks completed • 180 min focused • 4-day streak',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationRecord(
        id: 'mock_7',
        category: NotificationCategory.system,
        title: 'Welcome to TaskFlow notifications',
        body: 'Task reminders, focus alerts, streaks, and achievements appear here.',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]);
  }
}
