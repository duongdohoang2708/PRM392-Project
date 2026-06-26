import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/task_model.dart';
import '../services/focus_feedback_service.dart';
import '../services/notification_service.dart';
import '../utils/focus_sound_options.dart';
import '../widgets/custom_snackbar.dart';

enum TimerState { idle, running, paused, completed }
enum PhaseType { focus, shortBreak, longBreak }

class FocusSessionLog {
  final String title;
  final String? taskId;
  final DateTime time;
  final int durationMinutes;

  FocusSessionLog({
    required this.title,
    this.taskId,
    required this.time,
    required this.durationMinutes,
  });
}

class FocusProvider with ChangeNotifier, WidgetsBindingObserver {
  static const String _focusMinutesKey = 'focus_focus_minutes';
  static const String _shortBreakKey = 'focus_short_break_minutes';
  static const String _longBreakKey = 'focus_long_break_minutes';
  static const String _roundsKey = 'focus_rounds';
  static const String _longBreakIntervalKey = 'focus_long_break_interval';
  static const String _autoStartFocusKey = 'focus_auto_start_focus';
  static const String _autoStartBreakKey = 'focus_auto_start_break';
  static const String _keepScreenOnKey = 'focus_keep_screen_on';
  static const String _focusSoundEnabledKey = 'focus_completion_sound_enabled';
  static const String _breakSoundEnabledKey = 'focus_break_sound_enabled';
  static const String _focusSoundIdKey = 'focus_sound_id';
  static const String _breakSoundIdKey = 'focus_break_sound_id';
  static const String _vibrateFocusEndKey = 'focus_vibrate_on_focus_end';
  static const String _vibrateBreakEndKey = 'focus_vibrate_on_break_end';

  final GlobalKey<NavigatorState> navigatorKey;

  // Settings
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _rounds = 4;
  int _longBreakInterval = 4;
  bool _autoStartFocus = false;
  bool _autoStartBreak = false;
  bool _keepScreenOn = false;
  bool _focusCompletionSoundEnabled = true;
  bool _breakCompletionSoundEnabled = true;
  String _focusSoundId = FocusSoundOption.defaultFocusSoundId;
  String _breakSoundId = FocusSoundOption.defaultBreakSoundId;
  bool _vibrateOnFocusEnd = true;
  bool _vibrateOnBreakEnd = true;

  // State
  TimerState _timerState = TimerState.idle;
  final List<PhaseType> _sequence = [];
  int _currentPhaseIndex = 0;
  int _remainingSeconds = 0;
  Task? _selectedTask;
  Timer? _timer;
  DateTime? _expectedEndTime;
  final List<FocusSessionLog> _focusHistory = [];
  bool _isAppInForeground = true;

  FocusProvider(this.navigatorKey) {
    _focusHistory.addAll(_buildMockHistory());
    _generateSequence();
    _resetTimerState();
    NotificationService.setFocusProvider(this);
    WidgetsBinding.instance.addObserver(this);
    unawaited(loadSettings());
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final focus = prefs.getInt(_focusMinutesKey);
    final shortBreak = prefs.getInt(_shortBreakKey);
    final longBreak = prefs.getInt(_longBreakKey);
    final rounds = prefs.getInt(_roundsKey);
    final interval = prefs.getInt(_longBreakIntervalKey);

    if (focus != null) _focusMinutes = focus;
    if (shortBreak != null) _shortBreakMinutes = shortBreak;
    if (longBreak != null) _longBreakMinutes = longBreak;
    if (rounds != null) _rounds = rounds;
    if (interval != null) _longBreakInterval = interval;

    _autoStartFocus = prefs.getBool(_autoStartFocusKey) ?? _autoStartFocus;
    _autoStartBreak = prefs.getBool(_autoStartBreakKey) ?? _autoStartBreak;
    _keepScreenOn = prefs.getBool(_keepScreenOnKey) ?? _keepScreenOn;
    _focusCompletionSoundEnabled =
        prefs.getBool(_focusSoundEnabledKey) ?? _focusCompletionSoundEnabled;
    _breakCompletionSoundEnabled =
        prefs.getBool(_breakSoundEnabledKey) ?? _breakCompletionSoundEnabled;
    _focusSoundId =
        prefs.getString(_focusSoundIdKey) ?? _focusSoundId;
    _breakSoundId =
        prefs.getString(_breakSoundIdKey) ?? _breakSoundId;
    _vibrateOnFocusEnd =
        prefs.getBool(_vibrateFocusEndKey) ?? _vibrateOnFocusEnd;
    _vibrateOnBreakEnd =
        prefs.getBool(_vibrateBreakEndKey) ?? _vibrateOnBreakEnd;

    _generateSequence();
    _resetTimerState();
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_focusMinutesKey, _focusMinutes);
    await prefs.setInt(_shortBreakKey, _shortBreakMinutes);
    await prefs.setInt(_longBreakKey, _longBreakMinutes);
    await prefs.setInt(_roundsKey, _rounds);
    await prefs.setInt(_longBreakIntervalKey, _longBreakInterval);
    await prefs.setBool(_autoStartFocusKey, _autoStartFocus);
    await prefs.setBool(_autoStartBreakKey, _autoStartBreak);
    await prefs.setBool(_keepScreenOnKey, _keepScreenOn);
    await prefs.setBool(_focusSoundEnabledKey, _focusCompletionSoundEnabled);
    await prefs.setBool(_breakSoundEnabledKey, _breakCompletionSoundEnabled);
    await prefs.setString(_focusSoundIdKey, _focusSoundId);
    await prefs.setString(_breakSoundIdKey, _breakSoundId);
    await prefs.setBool(_vibrateFocusEndKey, _vibrateOnFocusEnd);
    await prefs.setBool(_vibrateBreakEndKey, _vibrateOnBreakEnd);
  }

  Future<void> _persistBehaviorSettings() async {
    await _persistSettings();
  }

  Future<void> _syncWakelock() async {
    if (!_keepScreenOn || _timerState != TimerState.running) {
      await WakelockPlus.disable();
      return;
    }
    await WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      unawaited(_onAppResumed());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isAppInForeground = false;
      unawaited(_onAppPaused());
    } else {
      _isAppInForeground = false;
    }
  }

  /// App is going to the background: hand control to a background alarm /
  /// scheduled notification so the phase can complete (and chain) while the
  /// Dart timer is suspended.
  Future<void> _onAppPaused() async {
    if (_timerState == TimerState.running && _expectedEndTime != null) {
      await _schedulePhaseEndAlarm();
    }
  }

  Future<void> _onAppResumed() async {
    // Foreground takes over: read where the background mechanism left off, then
    // cancel it so the in-app timer is the single source of feedback (prevents
    // double sound/vibration when re-entering the app).
    await _reconcileNativeRuntime();
    if (_timerState == TimerState.running &&
        _expectedEndTime != null &&
        !DateTime.now().isBefore(_expectedEndTime!)) {
      _syncMissedPhases();
    }
    await _cancelPhaseEndAlarm();
    if (_timerState == TimerState.running && _expectedEndTime != null) {
      _armAlignedTimer();
      _updateNotification();
    }
    notifyListeners();
  }

  Future<void> _reconcileNativeRuntime() async {
    if (!Platform.isAndroid) return;

    final previousIndex = _currentPhaseIndex;
    final state = await NotificationService.getPomodoroRuntimeState();
    if (state == null) return;

    final phaseIndex = state['phase_index'];
    final deadlineMs = state['deadline_ms'];
    final timerRunning = state['timer_running'];
    final remainingSeconds = state['remaining_seconds'];

    if (phaseIndex is int) {
      if (phaseIndex > previousIndex) {
        for (var i = previousIndex; i < phaseIndex; i++) {
          if (i < _sequence.length && _sequence[i] == PhaseType.focus) {
            _focusHistory.insert(
              0,
              FocusSessionLog(
                title: _selectedTask?.title ?? 'Focus Session',
                taskId: _selectedTask?.id,
                time: DateTime.now(),
                durationMinutes: _focusMinutes,
              ),
            );
          }
        }
      }
      _currentPhaseIndex = phaseIndex.clamp(0, _sequence.length - 1);
    }
    if (remainingSeconds is int) {
      _remainingSeconds = remainingSeconds;
    }

    if (timerRunning == true && deadlineMs is int && deadlineMs > 0) {
      _timer?.cancel();
      _timerState = TimerState.running;
      _expectedEndTime =
          DateTime.fromMillisecondsSinceEpoch(deadlineMs);
      return;
    }

    _timer?.cancel();
    _expectedEndTime = null;
    if (timerRunning == false) {
      _timerState = _currentPhaseIndex >= _sequence.length - 1 &&
              (remainingSeconds is int && remainingSeconds == 0)
          ? TimerState.completed
          : TimerState.idle;
    }
  }

  void _syncMissedPhases() {
    var safety = 0;
    while (_timerState == TimerState.running &&
        _expectedEndTime != null &&
        !DateTime.now().isBefore(_expectedEndTime!) &&
        safety < _sequence.length + 2) {
      safety++;
      _remainingSeconds = 0;
      _handlePhaseComplete(suppressFeedback: true);
      if (_timerState == TimerState.idle) {
        final nextPhase = _sequence[_currentPhaseIndex];
        final shouldAutoStart = nextPhase == PhaseType.focus
            ? _autoStartFocus
            : _autoStartBreak;
        if (shouldAutoStart) {
          startTimer();
        } else {
          break;
        }
      } else {
        break;
      }
    }
  }

  // Getters
  int get focusMinutes => _focusMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get rounds => _rounds;
  int get longBreakInterval => _longBreakInterval;
  bool get autoStartFocus => _autoStartFocus;
  bool get autoStartBreak => _autoStartBreak;
  bool get keepScreenOn => _keepScreenOn;
  bool get focusCompletionSoundEnabled => _focusCompletionSoundEnabled;
  bool get breakCompletionSoundEnabled => _breakCompletionSoundEnabled;
  String get focusSoundId => _focusSoundId;
  String get breakSoundId => _breakSoundId;
  bool get vibrateOnFocusEnd => _vibrateOnFocusEnd;
  bool get vibrateOnBreakEnd => _vibrateOnBreakEnd;
  
  TimerState get timerState => _timerState;
  List<PhaseType> get sequence => _sequence;
  int get currentPhaseIndex => _currentPhaseIndex;
  int get remainingSeconds => _remainingSeconds;
  Task? get selectedTask => _selectedTask;
  DateTime? get expectedEndTime => _expectedEndTime;
  List<FocusSessionLog> get focusHistory => _focusHistory;
  int get totalFocusMinutes =>
      _focusHistory.fold(0, (sum, log) => sum + log.durationMinutes);
  int get completedSessionsCount => _focusHistory.length;
  int get averageSessionMinutes => _focusHistory.isEmpty
      ? 0
      : (totalFocusMinutes / _focusHistory.length).round();

  void setSelectedTask(Task? task) {
    _selectedTask = task;
    notifyListeners();
  }

  void updateSettings({
    required int focus,
    required int shortBreak,
    required int longBreak,
    required int rounds,
    required int interval,
  }) {
    _focusMinutes = focus;
    _shortBreakMinutes = shortBreak;
    _longBreakMinutes = longBreak;
    _rounds = rounds;
    _longBreakInterval = interval;
    
    _generateSequence();
    _resetTimerState();
    notifyListeners();
    unawaited(_persistSettings());
  }

  Future<void> setAutoStartFocus(bool value) async {
    _autoStartFocus = value;
    notifyListeners();
    await _persistBehaviorSettings();
  }

  Future<void> setAutoStartBreak(bool value) async {
    _autoStartBreak = value;
    notifyListeners();
    await _persistBehaviorSettings();
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    notifyListeners();
    await _persistBehaviorSettings();
    await _syncWakelock();
  }

  Future<void> setFocusCompletionSoundEnabled(bool value) async {
    _focusCompletionSoundEnabled = value;
    notifyListeners();
    await _persistBehaviorSettings();
  }

  Future<void> setBreakCompletionSoundEnabled(bool value) async {
    _breakCompletionSoundEnabled = value;
    notifyListeners();
    await _persistBehaviorSettings();
  }

  Future<void> setFocusSoundId(String value) async {
    _focusSoundId = value;
    notifyListeners();
    await _persistBehaviorSettings();
  }

  Future<void> setBreakSoundId(String value) async {
    _breakSoundId = value;
    notifyListeners();
    await _persistBehaviorSettings();
  }

  Future<void> setVibrateOnFocusEnd(bool value) async {
    _vibrateOnFocusEnd = value;
    notifyListeners();
    await _persistBehaviorSettings();
  }

  Future<void> setVibrateOnBreakEnd(bool value) async {
    _vibrateOnBreakEnd = value;
    notifyListeners();
    await _persistBehaviorSettings();
  }

  void _playPhaseFeedback(PhaseType completedPhase) {
    final isFocus = completedPhase == PhaseType.focus;
    final playSound = isFocus
        ? _focusCompletionSoundEnabled
        : _breakCompletionSoundEnabled;
    final vibrate =
        isFocus ? _vibrateOnFocusEnd : _vibrateOnBreakEnd;
    final soundId = isFocus ? _focusSoundId : _breakSoundId;

    if (playSound) {
      unawaited(FocusFeedbackService.playSound(soundId));
    }
    if (vibrate) {
      unawaited(FocusFeedbackService.vibrate());
    }
  }

  _PhaseFeedbackConfig _feedbackConfigFor(PhaseType completedPhase) {
    final isFocus = completedPhase == PhaseType.focus;
    return _PhaseFeedbackConfig(
      playSound: isFocus
          ? _focusCompletionSoundEnabled
          : _breakCompletionSoundEnabled,
      enableVibration:
          isFocus ? _vibrateOnFocusEnd : _vibrateOnBreakEnd,
      soundId: FocusSoundOption.androidRawName(
        isFocus ? _focusSoundId : _breakSoundId,
      ),
    );
  }

  Map<String, dynamic> _buildPhaseAlarmPayload() {
    if (_expectedEndTime == null ||
        _sequence.isEmpty ||
        _currentPhaseIndex >= _sequence.length) {
      return {};
    }

    final completedPhase = _sequence[_currentPhaseIndex];
    final feedback = _feedbackConfigFor(completedPhase);
    final isLastPhase = _currentPhaseIndex >= _sequence.length - 1;
    final nextPhase =
        isLastPhase ? null : _sequence[_currentPhaseIndex + 1];

    return {
      'deadlineEpochMs': _expectedEndTime!.millisecondsSinceEpoch,
      'phaseIndex': _currentPhaseIndex,
      'sequence': _sequence.map((phase) => phase.name).toList(),
      'focusMinutes': _focusMinutes,
      'shortBreakMinutes': _shortBreakMinutes,
      'longBreakMinutes': _longBreakMinutes,
      'autoStartFocus': _autoStartFocus,
      'autoStartBreak': _autoStartBreak,
      'focusSoundEnabled': _focusCompletionSoundEnabled,
      'breakSoundEnabled': _breakCompletionSoundEnabled,
      'focusSoundId': _focusSoundId,
      'breakSoundId': _breakSoundId,
      'vibrateOnFocusEnd': _vibrateOnFocusEnd,
      'vibrateOnBreakEnd': _vibrateOnBreakEnd,
      'taskName': _selectedTask?.title ?? '',
      'timerNotificationId': 1001,
      'remainingSeconds': _remainingSeconds,
      'playSound': feedback.playSound,
      'enableVibration': feedback.enableVibration,
      'soundId': feedback.soundId,
      'completeTitle': _completionTitle(completedPhase, isLastPhase),
      'completeBody': _completionBody(completedPhase, isLastPhase, nextPhase),
    };
  }

  String _completionTitle(PhaseType completedPhase, bool isLastPhase) {
    if (isLastPhase) return 'All Sessions Complete!';
    if (completedPhase == PhaseType.focus) return 'Focus Session Finished';
    return 'Break Finished';
  }

  String _completionBody(
    PhaseType completedPhase,
    bool isLastPhase,
    PhaseType? nextPhase,
  ) {
    if (isLastPhase) {
      return 'Excellent job! You finished the entire Pomodoro cycle.';
    }
    if (completedPhase == PhaseType.focus) {
      return nextPhase == PhaseType.longBreak
          ? 'Great job! Take a long break.'
          : 'Great job! Take a short break.';
    }
    return 'Ready to focus? Start your next session.';
  }

  Future<void> _schedulePhaseEndAlarm() async {
    if (_expectedEndTime == null || _timerState != TimerState.running) {
      return;
    }

    final payload = _buildPhaseAlarmPayload();
    if (payload.isEmpty) return;

    final completedPhase = _sequence[_currentPhaseIndex];
    final feedback = _feedbackConfigFor(completedPhase);

    final isLastPhase = _currentPhaseIndex >= _sequence.length - 1;
    final nextPhase = isLastPhase ? null : _sequence[_currentPhaseIndex + 1];
    final nextWillAutoStart = nextPhase == null
        ? false
        : (nextPhase == PhaseType.focus ? _autoStartFocus : _autoStartBreak);

    // Use exactly one background mechanism to avoid duplicate alerts/sounds:
    //  - Auto-start ON  -> native exact alarm (alerts + chains the next phase).
    //  - Auto-start OFF -> scheduled local notification (same proven mechanism
    //                      as task reminders; the timer simply stops).
    if (Platform.isAndroid && nextWillAutoStart) {
      try {
        await NotificationService.cancelFocusPhaseComplete();
        await NotificationService.schedulePhaseAlarm(payload);
      } catch (e) {
        debugPrint('schedulePhaseAlarm failed: $e');
      }
      return;
    }

    try {
      await NotificationService.cancelPhaseAlarm();
      await NotificationService.scheduleFocusPhaseComplete(
        scheduledAt: _expectedEndTime!,
        title: payload['completeTitle'] as String,
        body: payload['completeBody'] as String,
        playSound: feedback.playSound,
        enableVibration: feedback.enableVibration,
        soundId: feedback.soundId,
      );
    } catch (e) {
      debugPrint('scheduleFocusPhaseComplete failed: $e');
    }
  }

  Future<void> _cancelPhaseEndAlarm() async {
    await NotificationService.cancelFocusPhaseComplete();
  }

  void _generateSequence() {
    _sequence.clear();
    for (int i = 1; i <= _rounds; i++) {
      _sequence.add(PhaseType.focus);
      if (i % _longBreakInterval == 0) {
        _sequence.add(PhaseType.longBreak);
      } else if (i < _rounds) {
        _sequence.add(PhaseType.shortBreak);
      }
    }
  }

  void _resetTimerState() {
    _timer?.cancel();
    _expectedEndTime = null;
    _currentPhaseIndex = 0;
    _timerState = TimerState.idle;
    if (_sequence.isNotEmpty) {
      _setPhaseDuration();
    }
    NotificationService.cancelTimerNotification();
    unawaited(_cancelPhaseEndAlarm());
    unawaited(_syncWakelock());
    notifyListeners();
  }

  void _setPhaseDuration() {
    if (_currentPhaseIndex >= _sequence.length) return;
    switch (_sequence[_currentPhaseIndex]) {
      case PhaseType.focus:
        _remainingSeconds = _focusMinutes * 60;
        break;
      case PhaseType.shortBreak:
        _remainingSeconds = _shortBreakMinutes * 60;
        break;
      case PhaseType.longBreak:
        _remainingSeconds = _longBreakMinutes * 60;
        break;
    }
  }

  String _getCurrentPhaseLabel() {
    if (_sequence.isEmpty || _currentPhaseIndex >= _sequence.length) {
      return 'Focus Session';
    }
    switch (_sequence[_currentPhaseIndex]) {
      case PhaseType.focus:
        return 'Focus Session';
      case PhaseType.shortBreak:
        return 'Short Break';
      case PhaseType.longBreak:
        return 'Long Break';
    }
  }

  String _getTimeString() {
    final remaining = displayRemainingSeconds;
    final int minutes = remaining ~/ 60;
    final int seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _updateNotification() {
    final remaining = displayRemainingSeconds;
    NotificationService.showTimerNotification(
      phaseLabel: _getCurrentPhaseLabel(),
      timeString: _getTimeString(),
      isRunning: _timerState == TimerState.running,
      remainingSeconds: remaining,
      deadlineEpochMs: _expectedEndTime?.millisecondsSinceEpoch,
      taskName: _selectedTask?.title,
    );
  }

  /// Deadline aligned to wall-clock second boundaries so display,
  /// notification, and aligned ticks all decrement together.
  DateTime _deadlineFromRemainingSeconds(int remainingSeconds) {
    final now = DateTime.now();
    if (remainingSeconds <= 0) return now;

    final msPart = now.millisecond;
    final msUntilNextBoundary = msPart == 0 ? 1000 : (1000 - msPart);
    final totalMs = (remainingSeconds - 1) * 1000 + msUntilNextBoundary;

    return DateTime.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch + totalMs,
    );
  }

  int _remainingFromDeadline(DateTime endTime) {
    final diffMs = endTime.difference(DateTime.now()).inMilliseconds;
    if (diffMs <= 0) return 0;
    return (diffMs + 999) ~/ 1000;
  }

  /// Whole seconds left for display — uses wall-clock deadline while running.
  int get displayRemainingSeconds {
    if (_timerState == TimerState.running && _expectedEndTime != null) {
      return _remainingFromDeadline(_expectedEndTime!);
    }
    return _remainingSeconds;
  }

  /// Elapsed fraction of the current phase (0.0–1.0), smooth while running.
  double phaseElapsedFraction(int totalPhaseSeconds) {
    if (totalPhaseSeconds <= 0) return 0;
    if (_timerState == TimerState.running && _expectedEndTime != null) {
      final totalMs = totalPhaseSeconds * 1000;
      final remainMs =
          _expectedEndTime!.difference(DateTime.now()).inMilliseconds;
      if (remainMs <= 0) return 1.0;
      return ((totalMs - remainMs) / totalMs).clamp(0.0, 1.0);
    }
    return ((totalPhaseSeconds - _remainingSeconds) / totalPhaseSeconds)
        .clamp(0.0, 1.0);
  }

  void _armAlignedTimer() {
    _timer?.cancel();

    void scheduleNext() {
      if (_timerState != TimerState.running || _expectedEndTime == null) {
        return;
      }

      final now = DateTime.now();
      final msUntilNextSecond = 1000 - (now.millisecond % 1000);
      final delayMs = msUntilNextSecond == 0 ? 1000 : msUntilNextSecond;

      _timer = Timer(Duration(milliseconds: delayMs), () {
        _onTimerTick();
        scheduleNext();
      });
    }

    _onTimerTick();
    scheduleNext();
  }

  void _onTimerTick() {
    if (_expectedEndTime == null) return;

    final nextRemaining = _remainingFromDeadline(_expectedEndTime!);
    if (nextRemaining > 0) {
      final changed = nextRemaining != _remainingSeconds;
      _remainingSeconds = nextRemaining;
      if (changed) {
        notifyListeners();
      }
      return;
    }

    _remainingSeconds = 0;
    _handlePhaseComplete();
  }

  void startTimer() {
    if (_currentPhaseIndex >= _sequence.length) {
      _resetTimerState();
    }

    _timer?.cancel();
    _timerState = TimerState.running;

    _expectedEndTime = _deadlineFromRemainingSeconds(_remainingSeconds);
    _onTimerTick();
    _updateNotification();
    notifyListeners();

    _armAlignedTimer();
    unawaited(_syncWakelock());
    // Background alarm/notification is scheduled when the app actually goes to
    // the background (see _onAppPaused), not here — this avoids a duplicate
    // alert racing with the in-app timer while the app is in the foreground.
    if (!_isAppInForeground) {
      unawaited(_schedulePhaseEndAlarm());
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    if (_expectedEndTime != null) {
      final nextRemaining = _remainingFromDeadline(_expectedEndTime!);
      if (nextRemaining > 0) {
        _remainingSeconds = nextRemaining;
      }
    }
    _expectedEndTime = null;
    _timerState = TimerState.paused;
    _updateNotification();
    unawaited(_cancelPhaseEndAlarm());
    unawaited(_syncWakelock());
    notifyListeners();
  }

  void skipPhase() {
    pauseTimer();
    _handlePhaseComplete(isSkipped: true);
  }

  void resetEntireCycle() {
    pauseTimer();
    _resetTimerState();
  }

  void _handlePhaseComplete({
    bool isSkipped = false,
    bool suppressFeedback = false,
  }) {
    _timer?.cancel();
    _expectedEndTime = null;
    unawaited(_cancelPhaseEndAlarm());

    final completedPhase = _sequence.isNotEmpty && _currentPhaseIndex < _sequence.length
        ? _sequence[_currentPhaseIndex]
        : null;

    if (!isSkipped && _sequence.isNotEmpty && _sequence[_currentPhaseIndex] == PhaseType.focus) {
      _focusHistory.insert(0, FocusSessionLog(
        title: _selectedTask?.title ?? 'Focus Session',
        taskId: _selectedTask?.id,
        time: DateTime.now(),
        durationMinutes: _focusMinutes,
      ));
    }

    final bool isLastPhase = _currentPhaseIndex >= _sequence.length - 1;

    if (!isSkipped && !suppressFeedback && completedPhase != null) {
      if (_isAppInForeground) {
        _playPhaseFeedback(completedPhase);
      }
    }

    // Auto-advance
    if (!isLastPhase) {
      _currentPhaseIndex++;
      _setPhaseDuration();
      _timerState = TimerState.idle;

      final nextPhase = _sequence[_currentPhaseIndex];
      _showNotification(nextPhase == PhaseType.focus
          ? 'Break is over. Ready to focus?'
          : 'Focus complete! Take a break.');
      _updateNotification();

      final shouldAutoStart = nextPhase == PhaseType.focus
          ? _autoStartFocus
          : _autoStartBreak;
      if (shouldAutoStart) {
        startTimer();
      } else {
        unawaited(_syncWakelock());
      }
    } else {
      // Completed all phases
      _timerState = TimerState.completed;
      NotificationService.cancelTimerNotification();
      _showNotification('Session complete! Great job!');
      unawaited(_syncWakelock());
    }

    // Trigger system notification if it finished naturally (not skipped, and
    // not while catching up phases that already alerted in the background)
    if (!isSkipped && !suppressFeedback && completedPhase != null) {
      final feedback = _feedbackConfigFor(completedPhase);
      String title = '';
      String body = '';

      if (isLastPhase) {
        title = 'All Sessions Complete!';
        body = 'Excellent job! You finished the entire Pomodoro cycle.';
      } else if (completedPhase == PhaseType.focus) {
        title = 'Focus Session Finished';
        final nextPhase = _sequence[_currentPhaseIndex];
        body = nextPhase == PhaseType.longBreak
            ? 'Great job! Take a long break.'
            : 'Great job! Take a short break.';
      } else {
        title = 'Break Finished';
        body = 'Ready to focus? Start your next session.';
      }

      if (!Platform.isAndroid) {
        NotificationService.showSessionCompleteNotification(
          title: title,
          body: body,
          playSound: feedback.playSound,
          enableVibration: feedback.enableVibration,
          soundId: feedback.soundId,
        );
      }
    }

    notifyListeners();
  }

  List<FocusSessionLog> _buildMockHistory() {
    final now = DateTime.now();

    return [
      FocusSessionLog(
        title: 'Finish Flutter Assignment',
        taskId: '1',
        time: now.subtract(const Duration(hours: 2, minutes: 15)),
        durationMinutes: 25,
      ),
      FocusSessionLog(
        title: 'Debug layout overflow',
        taskId: '10',
        time: now.subtract(const Duration(hours: 4, minutes: 20)),
        durationMinutes: 30,
      ),
      FocusSessionLog(
        title: 'Review PRs',
        taskId: '10',
        time: now.subtract(const Duration(hours: 5, minutes: 10)),
        durationMinutes: 15,
      ),
      FocusSessionLog(
        title: 'Setup Firebase Authentication',
        taskId: '7',
        time: now.subtract(const Duration(days: 1, hours: 3)),
        durationMinutes: 30,
      ),
      FocusSessionLog(
        title: 'Task grooming',
        taskId: '11',
        time: now.subtract(const Duration(days: 1, hours: 6)),
        durationMinutes: 35,
      ),
      FocusSessionLog(
        title: 'Plan next week sprint',
        taskId: '11',
        time: now.subtract(const Duration(days: 2, hours: 1)),
        durationMinutes: 45,
      ),
      FocusSessionLog(
        title: 'State management deep dive',
        taskId: '4',
        time: now.subtract(const Duration(days: 2, hours: 7)),
        durationMinutes: 20,
      ),
      FocusSessionLog(
        title: 'Prepare slides for presentation',
        taskId: '20',
        time: now.subtract(const Duration(days: 3, hours: 4)),
        durationMinutes: 35,
      ),
      FocusSessionLog(
        title: 'Polish dashboard cards',
        taskId: '2',
        time: now.subtract(const Duration(days: 3, hours: 7)),
        durationMinutes: 30,
      ),
      FocusSessionLog(
        title: 'Write test scenarios',
        taskId: '6',
        time: now.subtract(const Duration(days: 4, hours: 2)),
        durationMinutes: 60,
      ),
      FocusSessionLog(
        title: 'Read Atomic Habits Ch. 1',
        taskId: '16',
        time: now.subtract(const Duration(days: 5, hours: 2)),
        durationMinutes: 20,
      ),
      FocusSessionLog(
        title: 'Refactor project cards',
        taskId: '15',
        time: now.subtract(const Duration(days: 5, hours: 6)),
        durationMinutes: 45,
      ),
      FocusSessionLog(
        title: 'Write project report',
        taskId: '6',
        time: now.subtract(const Duration(days: 8, hours: 5)),
        durationMinutes: 35,
      ),
      FocusSessionLog(
        title: 'UI Design Home Screen',
        taskId: '2',
        time: now.subtract(const Duration(days: 12, hours: 2)),
        durationMinutes: 40,
      ),
      FocusSessionLog(
        title: 'Watch Flutter Animation Tutorial',
        taskId: '18',
        time: now.subtract(const Duration(days: 18, hours: 3)),
        durationMinutes: 25,
      ),
      FocusSessionLog(
        title: 'Submit Q3 Expense Report',
        taskId: '17',
        time: now.subtract(const Duration(days: 24, hours: 6)),
        durationMinutes: 50,
      ),
    ];
  }

  void _showNotification(String message) {
    if (navigatorKey.currentContext != null) {
      if (message.contains('complete') || message.contains('Take a break')) {
        AppNotification.showSuccess(navigatorKey.currentContext!, message);
      } else {
        AppNotification.showInfo(navigatorKey.currentContext!, message);
      }
    }
  }
}

class _PhaseFeedbackConfig {
  final bool playSound;
  final bool enableVibration;
  final String soundId;

  const _PhaseFeedbackConfig({
    required this.playSound,
    required this.enableVibration,
    required this.soundId,
  });
}
