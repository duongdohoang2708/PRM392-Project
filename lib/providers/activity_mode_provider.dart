import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_mode.dart';
import '../theme/activity_mode_palette.dart';
import '../utils/activity_mode_schedule_validator.dart';
import '../utils/formatters/app_date_time_format.dart';

class ActivityModeProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String _manualOverrideKey = 'activity_manual_override_active';
  static const String _manualModeKey = 'activity_manual_mode_id';
  static const String _manualExpiresAtKey = 'activity_manual_expires_at_ms';
  static const String _suppressedScheduleKey = 'activity_suppressed_schedule_id';
  static const String _suppressedWindowsKey = 'activity_suppressed_window_starts';

  bool _manualOverrideActive = false;
  ActivityModeId _manualModeId = ActivityModeId.defaultMode;
  DateTime? _manualExpiresAt;
  final Map<ActivityModeId, DateTime> _suppressedWindowStarts = {};
  late Map<ActivityModeId, ActivityModeSchedule> _schedules;
  ActivityModeId _activeModeId = ActivityModeId.defaultMode;
  Timer? _minuteTimer;
  Timer? _expiryTimer;
  bool _loaded = false;
  ActivityModeId? _trackedScheduledMode;
  bool _scheduleTrackerInitialized = false;

  ActivityModeProvider() {
    _schedules = {
      for (final preset in ActivityModes.presets) preset.id: preset.defaultSchedule,
    };
    WidgetsBinding.instance.addObserver(this);
    _startMinuteTimer();
  }

  bool get manualOverrideActive => _manualOverrideActive;
  ActivityModeId get manualModeId => _manualModeId;
  ActivityModeId get activeModeId => _activeModeId;
  bool get isLoaded => _loaded;
  DateTime? get manualExpiresAt => _manualExpiresAt;
  bool get isManualIndefinite =>
      _manualOverrideActive && _manualExpiresAt == null;

  bool isManualActiveFor(ActivityModeId id) =>
      _manualOverrideActive && _manualModeId == id;

  bool isModeRunningFor(ActivityModeId id) => _activeModeId == id;

  bool isScheduledActiveFor(ActivityModeId id) {
    if (id == ActivityModeId.defaultMode) return false;
    return isModeRunningFor(id) &&
        !isManualActiveFor(id) &&
        _effectiveScheduledModeId(DateTime.now()) == id;
  }

  String? heroStatusLabelFor(ActivityModeId id) {
    if (id == ActivityModeId.defaultMode) {
      return 'Runs automatically when no other mode is active';
    }
    if (isManualActiveFor(id)) {
      return manualStatusLabelFor(id);
    }
    if (isScheduledActiveFor(id)) {
      final schedule = scheduleFor(id);
      return 'Scheduled until ${AppDateTimeFormat.timeOfDay(schedule.end)}';
    }
    return null;
  }

  ActivityModeDefinition get activeDefinition =>
      ActivityModes.definitionFor(_activeModeId);

  String get activeSourceLabel {
    if (_manualOverrideActive) return 'Manual';
    final at = DateTime.now();
    if (_activeModeId != ActivityModeId.defaultMode &&
        _effectiveScheduledModeId(at) == _activeModeId) {
      return 'Scheduled';
    }
    return 'Default';
  }

  ActivityModeSchedule scheduleFor(ActivityModeId id) =>
      _schedules[id] ?? ActivityModes.definitionFor(id).defaultSchedule;

  ActivityModePalette paletteFor(Brightness brightness) =>
      ActivityModePalette.forMode(_activeModeId, brightness: brightness);

  String? manualStatusLabelFor(ActivityModeId id) {
    if (!isManualActiveFor(id)) return null;
    if (_manualExpiresAt == null) return 'Until I turn it off';
    return 'Until ${AppDateTimeFormat.timeOfDay(TimeOfDay.fromDateTime(_manualExpiresAt!))}';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _manualOverrideActive = prefs.getBool(_manualOverrideKey) ?? false;
    _manualModeId = ActivityModes.idFromStorage(
      prefs.getString(_manualModeKey) ?? 'default',
    );
    if (_manualOverrideActive && _manualModeId == ActivityModeId.defaultMode) {
      _manualOverrideActive = false;
      await prefs.setBool(_manualOverrideKey, false);
    }
    final expiresMs = prefs.getInt(_manualExpiresAtKey);
    if (expiresMs != null && expiresMs > 0) {
      _manualExpiresAt = DateTime.fromMillisecondsSinceEpoch(expiresMs);
      if (_manualOverrideActive &&
          _manualExpiresAt!.isBefore(DateTime.now())) {
        _manualOverrideActive = false;
        _manualExpiresAt = null;
        await prefs.setBool(_manualOverrideKey, false);
        await prefs.remove(_manualExpiresAtKey);
      }
    }

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

    await _loadSuppressedWindows(prefs);

    _syncSuppressionWithSchedule();
    _scheduleExpiryTimer();
    _recomputeActiveModeFromClock(isColdStart: true);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _loadSuppressedWindows(SharedPreferences prefs) async {
    _suppressedWindowStarts.clear();

    final encoded = prefs.getStringList(_suppressedWindowsKey);
    if (encoded != null) {
      for (final entry in encoded) {
        final parts = entry.split(':');
        if (parts.length != 2) continue;
        final id = ActivityModes.idFromStorage(parts[0]);
        final ms = int.tryParse(parts[1]);
        if (ms == null || id == ActivityModeId.defaultMode) continue;
        _suppressedWindowStarts[id] =
            DateTime.fromMillisecondsSinceEpoch(ms);
      }
      return;
    }

    // Migrate legacy single-mode suppression key.
    final legacy = prefs.getString(_suppressedScheduleKey);
    if (legacy == null) return;

    final id = ActivityModes.idFromStorage(legacy);
    if (id == ActivityModeId.defaultMode) return;

    final schedule = _schedules[id];
    final now = DateTime.now();
    if (schedule != null &&
        schedule.enabled &&
        schedule.containsTime(now)) {
      final windowStart = schedule.currentWindowStart(now);
      if (windowStart != null) {
        _suppressedWindowStarts[id] = windowStart;
      }
    }
  }

  ActivityModeId resolveActiveMode([DateTime? now]) {
    if (_manualOverrideActive) return _manualModeId;
    final at = now ?? DateTime.now();
    final scheduled = _effectiveScheduledModeId(at);
    if (scheduled == null) return ActivityModeId.defaultMode;

    final schedule = scheduleFor(scheduled);
    if (!schedule.containsTime(at)) return ActivityModeId.defaultMode;

    if (schedule.isStartMinute(at) || _activeModeId == scheduled) {
      return scheduled;
    }
    return _activeModeId;
  }

  /// Raw schedule winner at [at], ignoring user suppression.
  ActivityModeId? _resolveScheduledModeId(DateTime at) {
    ActivityModeId? winner;
    DateTime? winnerStart;

    for (final id in ActivityModeId.values) {
      if (id == ActivityModeId.defaultMode) continue;

      final schedule = _schedules[id];
      if (schedule == null || !schedule.enabled) continue;

      final windowStart = schedule.currentWindowStart(at);
      if (windowStart == null) continue;

      if (winnerStart == null || windowStart.isAfter(winnerStart)) {
        winner = id;
        winnerStart = windowStart;
      } else if (windowStart == winnerStart && id.index > winner!.index) {
        winner = id;
      }
    }

    return winner;
  }

  bool _isSuppressedForWindow(ActivityModeId id, DateTime at) {
    final suppressedStart = _suppressedWindowStarts[id];
    if (suppressedStart == null) return false;

    final schedule = scheduleFor(id);
    if (!schedule.enabled || !schedule.containsTime(at)) return false;

    final windowStart = schedule.currentWindowStart(at);
    return windowStart != null && windowStart == suppressedStart;
  }

  ActivityModeId? _effectiveScheduledModeId(DateTime at) {
    final scheduled = _resolveScheduledModeId(at);
    if (scheduled == null) return null;
    if (_isSuppressedForWindow(scheduled, at)) return null;
    return scheduled;
  }

  void _syncSuppressionWithSchedule() {
    if (_suppressedWindowStarts.isEmpty) return;

    final at = DateTime.now();
    final toRemove = <ActivityModeId>[];

    for (final entry in _suppressedWindowStarts.entries) {
      final id = entry.key;
      final schedule = scheduleFor(id);
      if (!schedule.enabled || !schedule.containsTime(at)) {
        toRemove.add(id);
        continue;
      }
      final windowStart = schedule.currentWindowStart(at);
      if (windowStart == null || windowStart != entry.value) {
        toRemove.add(id);
      }
    }

    if (toRemove.isEmpty) return;

    for (final id in toRemove) {
      _suppressedWindowStarts.remove(id);
    }
    unawaited(_persistSuppressedWindows());
  }

  Future<void> _persistSuppressedWindows() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_suppressedScheduleKey);

    if (_suppressedWindowStarts.isEmpty) {
      await prefs.remove(_suppressedWindowsKey);
      return;
    }

    final encoded = _suppressedWindowStarts.entries
        .map(
          (e) =>
              '${ActivityModes.storageKeyFor(e.key)}:${e.value.millisecondsSinceEpoch}',
        )
        .toList();
    await prefs.setStringList(_suppressedWindowsKey, encoded);
  }

  /// Turn off [id] — immediately returns to Default and suppresses every mode
  /// whose schedule currently contains the present time.
  Future<void> turnOffMode(ActivityModeId id) async {
    if (id == ActivityModeId.defaultMode) return;

    if (_manualOverrideActive && _manualModeId == id) {
      _manualOverrideActive = false;
      _manualExpiresAt = null;
      _expiryTimer?.cancel();
      _expiryTimer = null;
    }

    final now = DateTime.now();
    for (final preset in ActivityModes.presets) {
      if (preset.id == ActivityModeId.defaultMode) continue;

      final schedule = scheduleFor(preset.id);
      if (!schedule.enabled || !schedule.containsTime(now)) continue;

      final windowStart = schedule.currentWindowStart(now);
      if (windowStart != null) {
        _suppressedWindowStarts[preset.id] = windowStart;
      }
    }

    _activeModeId = ActivityModeId.defaultMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualOverrideKey, _manualOverrideActive);
    if (!_manualOverrideActive) {
      await prefs.remove(_manualExpiresAtKey);
    }
    await _persistSuppressedWindows();
  }

  /// [duration] null = until user turns off; non-null = timed manual session.
  Future<void> activateModeManually(
    ActivityModeId id, {
    Duration? duration,
  }) async {
    if (id == ActivityModeId.defaultMode) return;

    _manualOverrideActive = true;
    _manualModeId = id;
    _manualExpiresAt =
        duration != null ? DateTime.now().add(duration) : null;
    _scheduleExpiryTimer();
    _activeModeId = id;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualOverrideKey, true);
    await prefs.setString(
      _manualModeKey,
      ActivityModes.storageKeyFor(id),
    );
    if (_manualExpiresAt != null) {
      await prefs.setInt(
        _manualExpiresAtKey,
        _manualExpiresAt!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_manualExpiresAtKey);
    }
  }

  Future<void> clearManualOverride() async {
    await _clearManualOverride();
  }

  Future<void> _clearManualOverride({bool persist = true}) async {
    if (!_manualOverrideActive && _manualExpiresAt == null) return;
    _manualOverrideActive = false;
    _manualExpiresAt = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _recomputeActiveModeFromClock();
    if (persist) {
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_manualOverrideKey, false);
      await prefs.remove(_manualExpiresAtKey);
    }
  }

  /// Persists the schedule when valid. Returns an error message on failure.
  Future<String?> updateModeSchedule(
    ActivityModeId id,
    ActivityModeSchedule schedule,
  ) async {
    final error = ActivityModeScheduleValidator.validate(
      modeId: id,
      schedule: schedule,
      schedules: _schedules,
    );
    if (error != null) return error;

    _schedules[id] = schedule;
    _resyncScheduleTracker();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final key = ActivityModes.storageKeyFor(id);
    await prefs.setBool('activity_${key}_schedule_enabled', schedule.enabled);
    await prefs.setInt('activity_${key}_start_h', schedule.start.hour);
    await prefs.setInt('activity_${key}_start_m', schedule.start.minute);
    await prefs.setInt('activity_${key}_end_h', schedule.end.hour);
    await prefs.setInt('activity_${key}_end_m', schedule.end.minute);
    return null;
  }

  String? scheduleLabelFor(ActivityModeId id) {
    if (id == ActivityModeId.defaultMode) return null;
    final schedule = scheduleFor(id);
    if (!schedule.enabled) return 'Schedule off';
    return '${AppDateTimeFormat.timeOfDay(schedule.start)} – ${AppDateTimeFormat.timeOfDay(schedule.end)}';
  }

  void _resyncScheduleTracker() {
    _trackedScheduledMode = _resolveScheduledModeId(DateTime.now());
    _scheduleTrackerInitialized = true;
  }

  void _handleScheduleTransition(ActivityModeId? rawScheduled) {
    if (!_scheduleTrackerInitialized) {
      _trackedScheduledMode = rawScheduled;
      _scheduleTrackerInitialized = true;
      return;
    }

    if (_trackedScheduledMode == rawScheduled) return;

    _trackedScheduledMode = rawScheduled;
    if (rawScheduled != null && _manualOverrideActive) {
      _manualOverrideActive = false;
      _manualExpiresAt = null;
      _expiryTimer?.cancel();
      _expiryTimer = null;
      unawaited(_persistManualOverrideCleared());
    }
  }

  /// Applies theme from clock rules only (timer, resume, cold start).
  void _recomputeActiveModeFromClock({bool isColdStart = false}) {
    final at = DateTime.now();
    _syncSuppressionWithSchedule();

    final rawScheduled = _resolveScheduledModeId(at);
    _handleScheduleTransition(rawScheduled);

    if (_manualOverrideActive &&
        _manualExpiresAt != null &&
        !at.isBefore(_manualExpiresAt!)) {
      _manualOverrideActive = false;
      _manualExpiresAt = null;
      _expiryTimer?.cancel();
      _expiryTimer = null;
      unawaited(_persistManualOverrideCleared());
    }

    if (_manualOverrideActive) {
      _activeModeId = _manualModeId;
      return;
    }

    final scheduled = _effectiveScheduledModeId(at);

    if (scheduled != null) {
      final schedule = scheduleFor(scheduled);
      if (schedule.containsTime(at)) {
        final shouldEnter = isColdStart ||
            schedule.isStartMinute(at) ||
            _activeModeId == scheduled;
        if (shouldEnter) {
          _activeModeId = scheduled;
          return;
        }
      }
    }

    if (_activeModeId != ActivityModeId.defaultMode) {
      final activeSchedule = scheduleFor(_activeModeId);
      if (!activeSchedule.enabled || !activeSchedule.containsTime(at)) {
        _activeModeId = ActivityModeId.defaultMode;
        return;
      }

      if (_effectiveScheduledModeId(at) == _activeModeId) {
        return;
      }
    }

    if (scheduled == null) {
      _activeModeId = ActivityModeId.defaultMode;
    }
  }

  Future<void> _persistManualOverrideCleared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualOverrideKey, false);
    await prefs.remove(_manualExpiresAtKey);
  }

  void _checkManualExpiry() {
    if (_manualOverrideActive &&
        _manualExpiresAt != null &&
        !DateTime.now().isBefore(_manualExpiresAt!)) {
      unawaited(_clearManualOverride());
    }
  }

  void _scheduleExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    if (!_manualOverrideActive || _manualExpiresAt == null) return;

    final remaining = _manualExpiresAt!.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      unawaited(_clearManualOverride());
      return;
    }

    _expiryTimer = Timer(remaining, () {
      unawaited(_clearManualOverride());
    });
  }

  void _onScheduleTick() {
    _checkManualExpiry();
    final previousMode = _activeModeId;
    final previousManual = _manualOverrideActive;
    _recomputeActiveModeFromClock();
    if (previousMode != _activeModeId ||
        previousManual != _manualOverrideActive) {
      notifyListeners();
    }
  }

  void _startMinuteTimer() {
    _minuteTimer?.cancel();

    final now = DateTime.now();
    final delay = Duration(
      seconds: 60 - now.second,
      milliseconds: 1000 - now.millisecond,
    );

    _minuteTimer = Timer(delay, () {
      _onScheduleTick();
      _minuteTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _onScheduleTick(),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onScheduleTick();
    }
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _expiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
