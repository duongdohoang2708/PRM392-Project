import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
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
  final GlobalKey<NavigatorState> navigatorKey;

  // Settings
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _rounds = 4;
  int _longBreakInterval = 4;

  // State
  TimerState _timerState = TimerState.idle;
  final List<PhaseType> _sequence = [];
  int _currentPhaseIndex = 0;
  int _remainingSeconds = 0;
  Task? _selectedTask;
  Timer? _timer;
  DateTime? _expectedEndTime;
  final List<FocusSessionLog> _focusHistory = [];

  FocusProvider(this.navigatorKey) {
    _focusHistory.addAll(_buildMockHistory());
    _generateSequence();
    _resetTimerState();
    NotificationService.setFocusProvider(this);
    WidgetsBinding.instance.addObserver(this);
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
      if (_timerState == TimerState.running && _expectedEndTime != null) {
        _onTimerTick();
        if (_timerState == TimerState.running) {
          _updateNotification();
        }
      }
    }
  }

  // Getters
  int get focusMinutes => _focusMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get rounds => _rounds;
  int get longBreakInterval => _longBreakInterval;
  
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
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _updateNotification() {
    NotificationService.showTimerNotification(
      phaseLabel: _getCurrentPhaseLabel(),
      timeString: _getTimeString(),
      isRunning: _timerState == TimerState.running,
      remainingSeconds: _remainingSeconds,
      taskName: _selectedTask?.title,
    );
  }

  void _onTimerTick() {
    if (_expectedEndTime == null) return;

    final diffMs = _expectedEndTime!.difference(DateTime.now()).inMilliseconds;
    if (diffMs > 0) {
      final nextRemaining = diffMs ~/ 1000;
      if (nextRemaining != _remainingSeconds) {
        _remainingSeconds = nextRemaining;
        if (_timerState == TimerState.running) {
          _updateNotification();
        }
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
    _timerState = TimerState.running;
    _expectedEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

    _timer?.cancel();
    _onTimerTick();
    _updateNotification();
    notifyListeners();

    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _onTimerTick();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    if (_expectedEndTime != null) {
      final diffMs = _expectedEndTime!.difference(DateTime.now()).inMilliseconds;
      if (diffMs > 0) {
        _remainingSeconds = diffMs ~/ 1000;
      }
    }
    _expectedEndTime = null;
    _timerState = TimerState.paused;
    _updateNotification();
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

  void _handlePhaseComplete({bool isSkipped = false}) {
    _timer?.cancel();
    _expectedEndTime = null;

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
    } else {
      // Completed all phases
      _timerState = TimerState.completed;
      NotificationService.cancelTimerNotification();
      _showNotification('Session complete! Great job!');
    }

    // Trigger system notification if it finished naturally (not skipped)
    if (!isSkipped && completedPhase != null) {
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

      NotificationService.showSessionCompleteNotification(
        title: title,
        body: body,
      );
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
        durationMinutes: 10,
      ),
      FocusSessionLog(
        title: 'Polish dashboard cards',
        taskId: '2',
        time: now.subtract(const Duration(days: 3, hours: 7)),
        durationMinutes: 20,
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
