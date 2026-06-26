import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_record.dart';
import '../models/task_model.dart';
import '../providers/focus_provider.dart';
import '../screens/task/task_detail_screen.dart';
import '../utils/reminder/insight_notification_ids.dart';
import '../utils/reminder/reminder_scheduler.dart';
import '../navigation/app_navigator.dart';

typedef NotificationDeliveredCallback = void Function({
  required String title,
  required String body,
  required String type,
  String? taskId,
});

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _pomodoroChannel =
      MethodChannel('task_flow/pomodoro_notification');

  static FocusProvider? _focusProvider;
  static NotificationDeliveredCallback? onNotificationDelivered;
  static NotificationResponse? _pendingLaunchResponse;

  static const int _notificationId = 1001;

  static const String _alertChannelId = 'pomodoro_alerts';
  static const String _alertChannelName = 'Pomodoro Alerts';
  static const String _alertChannelDescription =
      'Alerts when focus or break sessions finish';
  static const int _alertNotificationId = 1002;
  static const int _focusPhaseCompleteNotificationId = 1003;

  static const String _taskChannelId = 'task_reminders';
  static const String _taskChannelName = 'Task Reminders';
  static const String _taskChannelDescription =
      'Reminders and due-date alerts for your tasks';

  static const String _insightChannelId = 'taskflow_insights';
  static const String _insightChannelName = 'Goals & Insights';
  static const String _insightChannelDescription =
      'Streak, achievements, digests, and productivity summaries';

  static const String _actionPauseResume = 'pause_resume';
  static const String _actionStop = 'stop';

  static const String portName = 'pomodoro_notification_port';
  static ReceivePort? _receivePort;

  static bool _timezoneReady = false;

  static Future<void> init() async {
    await _ensureTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse != null) {
      _pendingLaunchResponse = launchResponse;
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(portName);
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, portName);

    _receivePort!.listen((message) {
      if (message is String) {
        if (message == _actionPauseResume) {
          _handlePauseResume();
        } else if (message == _actionStop) {
          _handleStop();
        }
      }
    });

    _pomodoroChannel.setMethodCallHandler((call) async {
      if (call.method == 'openPomodoro') {
        _navigateToPomodoro();
      }
    });
  }

  static Future<void> _ensureTimezone() async {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _timezoneReady = true;
  }

  static void setFocusProvider(FocusProvider provider) {
    _focusProvider = provider;
  }

  static void setOnNotificationDelivered(NotificationDeliveredCallback? callback) {
    onNotificationDelivered = callback;
    final pending = _pendingLaunchResponse;
    if (pending == null) return;
    _pendingLaunchResponse = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onNotificationResponse(pending);
    });
  }

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == _actionPauseResume) {
      _handlePauseResume();
      return;
    }
    if (response.actionId == _actionStop) {
      _handleStop();
      return;
    }

    final payload = response.payload;
    if (payload == null) return;

    if (payload == 'pomodoro') {
      _navigateToPomodoro();
      return;
    }

    final data = _decodePayload(payload);
    if (data == null) return;

    final type = data['type'] as String?;
    if (type == 'task_reminder' || type == 'task_due') {
      final taskId = data['taskId'] as String?;
      final title = data['title'] as String? ?? 'Task reminder';
      final body = data['body'] as String? ?? '';
      onNotificationDelivered?.call(
        title: title,
        body: body,
        type: type!,
        taskId: taskId,
      );
      if (taskId != null) {
        _navigateToTaskDetail(taskId);
      }
      return;
    }

    final insightTitle = data['title'] as String?;
    final insightBody = data['body'] as String?;
    if (type != null && insightTitle != null && insightBody != null) {
      onNotificationDelivered?.call(
        title: insightTitle,
        body: insightBody,
        type: type,
        taskId: data['taskId'] as String?,
      );
      final route = data['route'] as String? ?? routeForNotificationType(type);
      if (route != null) {
        _navigateToRoute(route);
      }
      return;
    }

    if (type == 'focus') {
      onNotificationDelivered?.call(
        title: data['title'] as String? ?? 'Focus session',
        body: data['body'] as String? ?? '',
        type: 'focus',
      );
      _navigateToPomodoro();
    }
  }

  static void _navigateToRoute(String route) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main',
      (routeName) => false,
      arguments: {'initialRoute': route},
    );
  }

  static Map<String, dynamic>? _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }
    return null;
  }

  static String _encodePayload(Map<String, dynamic> data) => jsonEncode(data);

  static void _handlePauseResume() {
    if (_focusProvider == null) return;
    if (_focusProvider!.timerState == TimerState.running) {
      _focusProvider!.pauseTimer();
    } else {
      _focusProvider!.startTimer();
    }
  }

  static void _handleStop() {
    if (_focusProvider == null) return;
    _focusProvider!.resetEntireCycle();
    cancelTimerNotification();
  }

  static void _navigateToPomodoro() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main',
      (route) => false,
      arguments: {'initialRoute': '/focus'},
    );
  }

  static void _navigateToTaskDetail(String taskId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: taskId),
      ),
    );
  }

  static Future<void> showTimerNotification({
    required String phaseLabel,
    required String timeString,
    required bool isRunning,
    required int remainingSeconds,
    int? deadlineEpochMs,
    String? taskName,
  }) async {
    if (Platform.isAndroid) {
      await _pomodoroChannel.invokeMethod<void>('showTimerNotification', {
        'phaseLabel': phaseLabel,
        'timeString': timeString,
        'isRunning': isRunning,
        'remainingSeconds': remainingSeconds,
        'deadlineEpochMs': deadlineEpochMs ?? 0,
        'taskName': taskName,
        'notificationId': _notificationId,
      });
      return;
    }

    String title = phaseLabel;
    if (taskName != null && taskName.isNotEmpty) {
      title = '$phaseLabel • $taskName';
    }

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(iOS: darwinDetails);

    await _plugin.show(
      id: _notificationId,
      title: title,
      body: isRunning ? timeString : '$timeString (Paused)',
      notificationDetails: details,
      payload: 'pomodoro',
    );
  }

  static Future<void> cancelTimerNotification() async {
    if (Platform.isAndroid) {
      await _pomodoroChannel.invokeMethod<void>(
        'cancelTimerNotification',
        _notificationId,
      );
      return;
    }

    await _plugin.cancel(id: _notificationId);
  }

  static Future<void> schedulePhaseAlarm(Map<String, dynamic> payload) async {
    if (!Platform.isAndroid) return;
    await ensureExactAlarmPermission();
    await _pomodoroChannel.invokeMethod<void>('schedulePhaseAlarm', payload);
  }

  static Future<void> ensureExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<void> cancelPhaseAlarm() async {
    if (!Platform.isAndroid) return;
    await _pomodoroChannel.invokeMethod<void>('cancelPhaseAlarm');
  }

  static Future<Map<String, dynamic>?> getPomodoroRuntimeState() async {
    if (!Platform.isAndroid) return null;
    final result = await _pomodoroChannel.invokeMethod<Object?>(
      'getPomodoroRuntimeState',
    );
    if (result is! Map) return null;
    return Map<String, dynamic>.from(result);
  }

  static Future<void> scheduleFocusPhaseComplete({
    required DateTime scheduledAt,
    required String title,
    required String body,
    required bool playSound,
    required bool enableVibration,
    String? soundId,
  }) async {
    await _ensureTimezone();

    AndroidNotificationSound? androidSound;
    if (playSound && soundId != null && soundId.isNotEmpty) {
      androidSound = RawResourceAndroidNotificationSound(soundId);
    }

    // Channel id encodes sound + vibration; bump the version suffix whenever
    // these settings change, since Android locks a channel after first creation.
    final soundPart = (playSound && soundId != null && soundId.isNotEmpty)
        ? soundId
        : 'silent';
    final vibPart = enableVibration ? 'vib' : 'novib';
    final channelId = '${_alertChannelId}_v3_${soundPart}_$vibPart';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _alertChannelName,
      channelDescription: _alertChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: playSound,
      sound: androidSound,
      enableVibration: enableVibration,
      vibrationPattern: enableVibration
          ? Int64List.fromList([0, 350, 150, 350])
          : null,
      category: AndroidNotificationCategory.alarm,
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final tzScheduled = tz.TZDateTime.from(scheduledAt, tz.local);
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      id: _focusPhaseCompleteNotificationId,
      title: title,
      body: body,
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: scheduleMode,
      payload: _encodePayload({'type': 'focus'}),
    );
  }

  static Future<void> cancelFocusPhaseComplete() async {
    await _plugin.cancel(id: _focusPhaseCompleteNotificationId);
    await cancelPhaseAlarm();
  }

  static Future<void> showSessionCompleteNotification({
    required String title,
    required String body,
    bool playSound = true,
    bool enableVibration = true,
    String? soundId,
  }) async {
    AndroidNotificationSound? androidSound;
    if (playSound && soundId != null && soundId.isNotEmpty) {
      androidSound = RawResourceAndroidNotificationSound(soundId);
    }

    // Channel id encodes sound + vibration; bump the version suffix whenever
    // these settings change, since Android locks a channel after first creation.
    final soundPart = (playSound && soundId != null && soundId.isNotEmpty)
        ? soundId
        : 'silent';
    final vibPart = enableVibration ? 'vib' : 'novib';
    final channelId = '${_alertChannelId}_v3_${soundPart}_$vibPart';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _alertChannelName,
      channelDescription: _alertChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: playSound,
      sound: androidSound,
      enableVibration: enableVibration,
      vibrationPattern: enableVibration
          ? Int64List.fromList([0, 350, 150, 350])
          : null,
      category: AndroidNotificationCategory.alarm,
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final payload = _encodePayload({
      'type': 'focus',
      'title': title,
      'body': body,
    });

    await _plugin.show(
      id: _alertNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );

    onNotificationDelivered?.call(
      title: title,
      body: body,
      type: 'focus',
    );
  }

  static Future<void> scheduleTaskReminder({
    required Task task,
    required DateTime scheduledAt,
  }) async {
    await _scheduleTaskNotification(
      notificationId: ReminderScheduler.notificationIdForTask(task.id),
      task: task,
      scheduledAt: scheduledAt,
      type: 'task_reminder',
      body: ReminderScheduler.buildNotificationBody(task, scheduledAt),
    );
  }

  static Future<void> scheduleTaskDueNotification({
    required Task task,
    required DateTime scheduledAt,
  }) async {
    await _scheduleTaskNotification(
      notificationId: ReminderScheduler.notificationIdForTaskDue(task.id),
      task: task,
      scheduledAt: scheduledAt,
      type: 'task_due',
      body: ReminderScheduler.buildDueNotificationBody(task),
    );
  }

  static Future<void> _scheduleTaskNotification({
    required int notificationId,
    required Task task,
    required DateTime scheduledAt,
    required String type,
    required String body,
  }) async {
    await _ensureTimezone();

    final payload = _encodePayload({
      'type': type,
      'taskId': task.id,
      'title': task.title,
      'body': body,
    });

    const androidDetails = AndroidNotificationDetails(
      _taskChannelId,
      _taskChannelName,
      channelDescription: _taskChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final tzScheduled = tz.TZDateTime.from(scheduledAt, tz.local);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      id: notificationId,
      title: task.title,
      body: body,
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: scheduleMode,
      payload: payload,
    );
  }

  /// Immediate delivery — used by the in-app watchdog when fire time passes.
  static Future<void> showTaskReminderNow({
    required Task task,
    required DateTime fireAt,
  }) async {
    await _showTaskNotificationNow(
      notificationId: ReminderScheduler.notificationIdForTask(task.id),
      task: task,
      type: 'task_reminder',
      body: ReminderScheduler.buildNotificationBody(task, fireAt),
    );
  }

  static Future<void> showTaskDueNow({
    required Task task,
    required DateTime dueAt,
  }) async {
    await _showTaskNotificationNow(
      notificationId: ReminderScheduler.notificationIdForTaskDue(task.id),
      task: task,
      type: 'task_due',
      body: ReminderScheduler.buildDueNotificationBody(task),
    );
  }

  static Future<void> _showTaskNotificationNow({
    required int notificationId,
    required Task task,
    required String type,
    required String body,
  }) async {
    final payload = _encodePayload({
      'type': type,
      'taskId': task.id,
      'title': task.title,
      'body': body,
    });

    const androidDetails = AndroidNotificationDetails(
      _taskChannelId,
      _taskChannelName,
      channelDescription: _taskChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: notificationId,
      title: task.title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );

    onNotificationDelivered?.call(
      title: task.title,
      body: body,
      type: type,
      taskId: task.id,
    );
  }

  static Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(id: ReminderScheduler.notificationIdForTask(taskId));
  }

  static Future<void> cancelTaskDueNotification(String taskId) async {
    await _plugin.cancel(id: ReminderScheduler.notificationIdForTaskDue(taskId));
  }

  static Future<void> cancelAllTaskNotifications(String taskId) async {
    await cancelTaskReminder(taskId);
    await cancelTaskDueNotification(taskId);
  }

  static Future<void> rescheduleAllTaskReminders(List<Task> tasks) async {
    for (final task in tasks) {
      await cancelAllTaskNotifications(task.id);

      final reminderAt = ReminderScheduler.computeFireTimeForTask(task);
      if (reminderAt != null) {
        await scheduleTaskReminder(task: task, scheduledAt: reminderAt);
      }

      final dueAt = ReminderScheduler.computeDueFireTimeForTask(task);
      if (dueAt != null) {
        await scheduleTaskDueNotification(task: task, scheduledAt: dueAt);
      }
    }
  }

  static Future<void> scheduleInsightNotification({
    required int notificationId,
    required String type,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? route,
  }) async {
    await _scheduleInsightNotification(
      notificationId: notificationId,
      type: type,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      route: route ?? routeForNotificationType(type),
    );
  }

  static Future<void> showInsightNotification({
    required int notificationId,
    required String type,
    required String title,
    required String body,
    String? route,
  }) async {
    await _showInsightNotificationNow(
      notificationId: notificationId,
      type: type,
      title: title,
      body: body,
      route: route ?? routeForNotificationType(type),
    );
  }

  static Future<void> cancelAllInsightNotifications() async {
    for (final id in InsightNotificationIds.allScheduled) {
      await _plugin.cancel(id: id);
    }
  }

  static Future<void> _scheduleInsightNotification({
    required int notificationId,
    required String type,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? route,
  }) async {
    await _ensureTimezone();

    final payload = _encodePayload({
      'type': type,
      'title': title,
      'body': body,
      if (route != null) 'route': route,
    });

    const androidDetails = AndroidNotificationDetails(
      _insightChannelId,
      _insightChannelName,
      channelDescription: _insightChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final tzScheduled = tz.TZDateTime.from(scheduledAt, tz.local);
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: scheduleMode,
      payload: payload,
    );
  }

  static Future<void> _showInsightNotificationNow({
    required int notificationId,
    required String type,
    required String title,
    required String body,
    String? route,
  }) async {
    final payload = _encodePayload({
      'type': type,
      'title': title,
      'body': body,
      if (route != null) 'route': route,
    });

    const androidDetails = AndroidNotificationDetails(
      _insightChannelId,
      _insightChannelName,
      channelDescription: _insightChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );

    onNotificationDelivered?.call(
      title: title,
      body: body,
      type: type,
    );
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final actionId = notificationResponse.actionId;
  if (actionId == null) return;

  final sendPort =
      IsolateNameServer.lookupPortByName('pomodoro_notification_port');
  sendPort?.send(actionId);
}
