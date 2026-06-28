import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_mode.dart';
import '../theme/activity_mode_palette.dart';

class ActivityModeProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String _autoScheduleKey = 'activity_auto_schedule_enabled';
  static const String _manualOverrideKey = 'activity_manual_override_active';
  static const String _manualModeKey = 'activity_manual_mode_id';

  bool _autoScheduleEnabled = true;
  bool _manualOverrideActive = false;
  ActivityModeId _manualModeId = ActivityModeId.defaultMode;
  late Map<ActivityModeId, ActivityModeSchedule> _schedules;
  ActivityModeId _activeModeId = ActivityModeId.defaultMode;
  Timer? _minuteTimer;
  bool _loaded = false;

  ActivityModeProvider() {
    _schedules = {
      for (final preset in ActivityModes.presets) preset.id: preset.defaultSchedule,
    };
    WidgetsBinding.instance.addObserver(this);
    _startMinuteTimer();
  }

  bool get autoScheduleEnabled => _autoScheduleEnabled;
  bool get manualOverrideActive => _manualOverrideActive;
  ActivityModeId get manualModeId => _manualModeId;
  ActivityModeId get activeModeId => _activeModeId;
  bool get isLoaded => _loaded;

  ActivityModeDefinition get activeDefinition =>
      ActivityModes.definitionFor(_activeModeId);

  String get activeSourceLabel =>
      _manualOverrideActive ? 'Manual' : (_autoScheduleEnabled ? 'Automatic' : 'Default');

  ActivityModeSchedule scheduleFor(ActivityModeId id) =>
      _schedules[id] ?? ActivityModes.definitionFor(id).defaultSchedule;

  ActivityModePalette paletteFor(Brightness brightness) =>
      ActivityModePalette.forMode(_activeModeId, brightness: brightness);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _autoScheduleEnabled = prefs.getBool(_autoScheduleKey) ?? true;
    _manualOverrideActive = prefs.getBool(_manualOverrideKey) ?? false;
    _manualModeId = ActivityModes.idFromStorage(
      prefs.getString(_manualModeKey) ?? 'default',
    );

    for (final preset in ActivityModes.presets) {
      final key = ActivityModes.storageKeyFor(preset.id);
      final enabled = prefs.getBool('activity_${key}_schedule_enabled');
      final startH = prefs.getInt('activity_${key}_start_h');
      final startM = prefs.getInt('activity_${key}_start_m');
      final endH = prefs.getInt('activity_${key}_end_h');
      final endM = prefs.getInt('activity_${key}_end_m');

      if (enabled != null ||
          startH != null ||
          startM != null ||
          endH != null ||
          endM != null) {
        _schedules[preset.id] = ActivityModeSchedule(
          enabled: enabled ?? preset.defaultSchedule.enabled,
          start: TimeOfDay(
            hour: startH ?? preset.defaultSchedule.start.hour,
            minute: startM ?? preset.defaultSchedule.start.minute,
          ),
          end: TimeOfDay(
            hour: endH ?? preset.defaultSchedule.end.hour,
            minute: endM ?? preset.defaultSchedule.end.minute,
          ),
        );
      }
    }

    _recomputeActiveMode();
    _loaded = true;
    notifyListeners();
  }

  ActivityModeId resolveActiveMode([DateTime? now]) {
    if (_manualOverrideActive) {
      return _manualModeId;
    }
    if (!_autoScheduleEnabled) {
      return ActivityModeId.defaultMode;
    }

    final at = now ?? DateTime.now();
    for (final id in ActivityModes.schedulePriority) {
      final schedule = _schedules[id];
      if (schedule != null && schedule.containsTime(at)) {
        return id;
      }
    }
    return ActivityModeId.defaultMode;
  }

  Future<void> setAutoScheduleEnabled(bool enabled) async {
    _autoScheduleEnabled = enabled;
    _recomputeActiveMode();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoScheduleKey, enabled);
  }

  Future<void> activateModeManually(ActivityModeId id) async {
    _manualOverrideActive = true;
    _manualModeId = id;
    _recomputeActiveMode();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualOverrideKey, true);
    await prefs.setString(
      _manualModeKey,
      ActivityModes.storageKeyFor(id),
    );
  }

  Future<void> clearManualOverride() async {
    _manualOverrideActive = false;
    _recomputeActiveMode();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualOverrideKey, false);
  }

  Future<void> updateModeSchedule(
    ActivityModeId id,
    ActivityModeSchedule schedule,
  ) async {
    _schedules[id] = schedule;
    _recomputeActiveMode();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final key = ActivityModes.storageKeyFor(id);
    await prefs.setBool('activity_${key}_schedule_enabled', schedule.enabled);
    await prefs.setInt('activity_${key}_start_h', schedule.start.hour);
    await prefs.setInt('activity_${key}_start_m', schedule.start.minute);
    await prefs.setInt('activity_${key}_end_h', schedule.end.hour);
    await prefs.setInt('activity_${key}_end_m', schedule.end.minute);
  }

  String scheduleLabelFor(ActivityModeId id) {
    if (id == ActivityModeId.defaultMode) return 'Fallback when no schedule matches';
    final schedule = scheduleFor(id);
    if (!schedule.enabled) return 'Schedule off';
    return '${_formatTime(schedule.start)} – ${_formatTime(schedule.end)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _recomputeActiveMode() {
    _activeModeId = resolveActiveMode();
  }

  void _startMinuteTimer() {
    _minuteTimer?.cancel();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final previous = _activeModeId;
      _recomputeActiveMode();
      if (previous != _activeModeId) {
        notifyListeners();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final previous = _activeModeId;
      _recomputeActiveMode();
      if (previous != _activeModeId) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
