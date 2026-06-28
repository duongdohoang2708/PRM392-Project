import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/calendar_week_config.dart';
import '../utils/formatters/app_date_time_format.dart';
import '../utils/reminder/task_reminder.dart';

class SettingsProvider with ChangeNotifier {
  static const String _themeModeKey = 'settings_theme_mode';
  static const String _notificationsEnabledKey = 'settings_notifications_enabled';
  static const String _taskRemindersKey = 'settings_task_reminders_enabled';
  static const String _goalsInsightsKey = 'settings_goals_insights_enabled';
  static const String _achievementsKey = 'settings_achievements_enabled';
  static const String _quietHoursEnabledKey = 'settings_quiet_hours_enabled';
  static const String _quietHoursStartKey = 'settings_quiet_hours_start';
  static const String _quietHoursEndKey = 'settings_quiet_hours_end';
  static const String _defaultTimedReminderKey = 'settings_default_timed_reminder';
  static const String _defaultAllDayReminderKey =
      'settings_default_allday_reminder';
  static const String _use12HourClockKey = 'settings_use_12_hour_clock';
  static const String _weekStartsMondayKey = 'settings_week_starts_monday';
  static const String _transparencyMultiplierKey =
      'settings_transparency_multiplier';
  static const String _cardFillSolidityKey = 'settings_card_fill_solidity';
  static const String _cardTintStrengthKey = 'settings_card_tint_strength';

  static const double minCardFillSolidity = 0.0;
  static const double maxCardFillSolidity = 1.0;
  static const double defaultCardFillSolidity = 0.0;

  static const double minCardTintStrength = 0.0;
  static const double maxCardTintStrength = 2.0;
  static const double defaultCardTintStrength = 1.0;

  /// Legacy multiplier range — migrated to [cardFillSolidity].
  static const double minTransparencyMultiplier = 0.5;
  static const double maxTransparencyMultiplier = 1.5;
  static const double defaultTransparencyMultiplier = 1.0;

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _taskRemindersEnabled = true;
  bool _goalsInsightsEnabled = true;
  bool _achievementsEnabled = true;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  String _defaultTimedReminder = '30 mins before';
  String _defaultAllDayReminder = '1 day before';
  bool _use12HourClock = true;
  bool _weekStartsOnMonday = true;
  double _cardFillSolidity = defaultCardFillSolidity;
  double _cardTintStrength = defaultCardTintStrength;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  bool get goalsInsightsEnabled => _goalsInsightsEnabled;
  bool get achievementsEnabled => _achievementsEnabled;
  bool get quietHoursEnabled => _quietHoursEnabled;
  TimeOfDay get quietHoursStart => _quietHoursStart;
  TimeOfDay get quietHoursEnd => _quietHoursEnd;
  String get defaultTimedReminder => _defaultTimedReminder;
  String get defaultAllDayReminder => _defaultAllDayReminder;
  bool get use12HourClock => _use12HourClock;
  bool get weekStartsOnMonday => _weekStartsOnMonday;
  double get cardFillSolidity => _cardFillSolidity;
  double get cardTintStrength => _cardTintStrength;
  bool get isLoaded => _loaded;

  /// 0 = transparent card background, 100 = fully solid.
  int get cardFillSolidityPercent => (_cardFillSolidity * 100).round();

  /// 100 = default tint; 0 = no accent tint; 200 = double strength.
  int get cardTintStrengthPercent => (_cardTintStrength * 100).round();

  @Deprecated('Use cardFillSolidity')
  double get transparencyMultiplier => _cardFillSolidity;

  @Deprecated('Use cardFillSolidityPercent')
  int get transparencyPercent => cardFillSolidityPercent;

  bool get canDeliverTaskReminders =>
      _notificationsEnabled && _taskRemindersEnabled;

  bool get canDeliverGoalsInsights =>
      _notificationsEnabled && _goalsInsightsEnabled;

  bool get canDeliverAchievements =>
      _notificationsEnabled && _achievementsEnabled;

  List<String> get timedReminderOptions => TaskReminder.timedPresets
      .where((option) => option != TaskReminder.custom)
      .toList();

  List<String> get allDayReminderOptions => TaskReminder.allDayPresets
      .where((option) => option != TaskReminder.custom)
      .toList();

  bool isInQuietHours([DateTime? at]) {
    if (!_quietHoursEnabled) return false;

    final now = at ?? DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _quietHoursStart.hour * 60 + _quietHoursStart.minute;
    final endMinutes = _quietHoursEnd.hour * 60 + _quietHoursEnd.minute;

    if (startMinutes == endMinutes) return false;

    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  bool canDeliverInsightType(String type) {
    if (!_notificationsEnabled) return false;
    if (type == 'achievement_unlock' || type == 'achievement_near') {
      return _achievementsEnabled;
    }
    if (_isTaskDigestInsightType(type)) {
      return _taskRemindersEnabled;
    }
    return _goalsInsightsEnabled;
  }

  static bool _isTaskDigestInsightType(String type) {
    return type == 'morning_digest' ||
        type == 'overdue_digest' ||
        type == 'important_eod';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    _taskRemindersEnabled = prefs.getBool(_taskRemindersKey) ??
        _notificationsEnabled;
    _goalsInsightsEnabled =
        prefs.getBool(_goalsInsightsKey) ?? _notificationsEnabled;
    _achievementsEnabled =
        prefs.getBool(_achievementsKey) ?? _notificationsEnabled;
    _quietHoursEnabled = prefs.getBool(_quietHoursEnabledKey) ?? false;
    _quietHoursStart = _readTimeOfDay(
      prefs.getString(_quietHoursStartKey),
      const TimeOfDay(hour: 22, minute: 0),
    );
    _quietHoursEnd = _readTimeOfDay(
      prefs.getString(_quietHoursEndKey),
      const TimeOfDay(hour: 7, minute: 0),
    );
    _defaultTimedReminder =
        prefs.getString(_defaultTimedReminderKey) ?? '30 mins before';
    _defaultAllDayReminder =
        prefs.getString(_defaultAllDayReminderKey) ?? '1 day before';
    _use12HourClock = prefs.getBool(_use12HourClockKey) ?? true;
    _weekStartsOnMonday = prefs.getBool(_weekStartsMondayKey) ?? true;
    _cardFillSolidity = _readCardFillSolidity(prefs);
    _cardTintStrength = _readCardTintStrength(prefs);

    _applyDisplayPreferences();
    _loaded = true;
    notifyListeners();
  }

  void _applyDisplayPreferences() {
    AppDateTimeFormat.use12HourClock = _use12HourClock;
    CalendarWeekConfig.weekStartsOnMonday = _weekStartsOnMonday;
  }

  TimeOfDay _readTimeOfDay(String? raw, TimeOfDay fallback) {
    if (raw == null || !raw.contains(':')) return fallback;
    final parts = raw.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return fallback;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _encodeTimeOfDay(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  double _readCardFillSolidity(SharedPreferences prefs) {
    final stored = prefs.getDouble(_cardFillSolidityKey);
    if (stored != null) {
      return stored.clamp(minCardFillSolidity, maxCardFillSolidity);
    }

    final legacy = prefs.getDouble(_transparencyMultiplierKey);
    if (legacy == null) return defaultCardFillSolidity;

    // Migrate old 0.5–1.5 multiplier to 0.0–1.0 solidity.
    if (legacy > maxCardFillSolidity) {
      return ((legacy - minTransparencyMultiplier) /
              (maxTransparencyMultiplier - minTransparencyMultiplier))
          .clamp(minCardFillSolidity, maxCardFillSolidity);
    }

    return legacy.clamp(minCardFillSolidity, maxCardFillSolidity);
  }

  double _readCardTintStrength(SharedPreferences prefs) {
    final stored = prefs.getDouble(_cardTintStrengthKey);
    if (stored == null) return defaultCardTintStrength;
    return stored.clamp(minCardTintStrength, maxCardTintStrength);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    if (_taskRemindersEnabled == enabled) return;
    _taskRemindersEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_taskRemindersKey, enabled);
  }

  Future<void> setGoalsInsightsEnabled(bool enabled) async {
    if (_goalsInsightsEnabled == enabled) return;
    _goalsInsightsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_goalsInsightsKey, enabled);
  }

  Future<void> setAchievementsEnabled(bool enabled) async {
    if (_achievementsEnabled == enabled) return;
    _achievementsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_achievementsKey, enabled);
  }

  Future<void> setQuietHoursEnabled(bool enabled) async {
    if (_quietHoursEnabled == enabled) return;
    _quietHoursEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quietHoursEnabledKey, enabled);
  }

  Future<void> setQuietHoursStart(TimeOfDay value) async {
    _quietHoursStart = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quietHoursStartKey, _encodeTimeOfDay(value));
  }

  Future<void> setQuietHoursEnd(TimeOfDay value) async {
    _quietHoursEnd = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quietHoursEndKey, _encodeTimeOfDay(value));
  }

  Future<void> setDefaultTimedReminder(String reminder) async {
    if (_defaultTimedReminder == reminder) return;
    _defaultTimedReminder = reminder;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultTimedReminderKey, reminder);
  }

  Future<void> setDefaultAllDayReminder(String reminder) async {
    if (_defaultAllDayReminder == reminder) return;
    _defaultAllDayReminder = reminder;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultAllDayReminderKey, reminder);
  }

  Future<void> setUse12HourClock(bool value) async {
    if (_use12HourClock == value) return;
    _use12HourClock = value;
    _applyDisplayPreferences();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_use12HourClockKey, value);
  }

  Future<void> setWeekStartsOnMonday(bool value) async {
    if (_weekStartsOnMonday == value) return;
    _weekStartsOnMonday = value;
    _applyDisplayPreferences();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weekStartsMondayKey, value);
  }

  Future<void> setCardFillSolidity(double value) async {
    final clamped = value.clamp(minCardFillSolidity, maxCardFillSolidity);
    if (_cardFillSolidity == clamped) return;
    _cardFillSolidity = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cardFillSolidityKey, clamped);
  }

  Future<void> setCardTintStrength(double value) async {
    final clamped = value.clamp(minCardTintStrength, maxCardTintStrength);
    if (_cardTintStrength == clamped) return;
    _cardTintStrength = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cardTintStrengthKey, clamped);
  }

  Future<void> resetCardAppearance() async {
    await setCardFillSolidity(defaultCardFillSolidity);
    await setCardTintStrength(defaultCardTintStrength);
  }

  bool get isDefaultCardAppearance =>
      _cardFillSolidity == defaultCardFillSolidity &&
      _cardTintStrength == defaultCardTintStrength;

  String get cardAppearanceSubtitle {
    final parts = <String>[];
    if (_cardFillSolidity == 0) {
      parts.add('Transparent cards');
    } else if (_cardFillSolidity == 1) {
      parts.add('Solid cards');
    } else {
      parts.add('${((1 - _cardFillSolidity) * 100).round()}% transparent');
    }
    if (_cardTintStrength == 0) {
      parts.add('no tint');
    } else if (_cardTintStrength != defaultCardTintStrength) {
      if (_cardTintStrength < defaultCardTintStrength) {
        parts.add('subtle tint');
      } else {
        parts.add('strong tint');
      }
    }
    return parts.join(' · ');
  }

  @Deprecated('Use setCardFillSolidity')
  Future<void> setTransparencyMultiplier(double value) =>
      setCardFillSolidity(value);
}
