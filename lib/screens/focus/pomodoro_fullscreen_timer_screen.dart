import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../providers/focus_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/focus/pomodoro_session_progress_card.dart';
import '../../widgets/focus/pomodoro_timer_carousel.dart';

class PomodoroFullscreenTimerScreen extends StatefulWidget {
  const PomodoroFullscreenTimerScreen({super.key});

  @override
  State<PomodoroFullscreenTimerScreen> createState() =>
      _PomodoroFullscreenTimerScreenState();
}

class _PomodoroFullscreenTimerScreenState
    extends State<PomodoroFullscreenTimerScreen>
    with SingleTickerProviderStateMixin {
  static const _cardScale = 1.3;
  static const _timerScale = 1.5015; // 1.43 × 1.05
  static const _baseContentWidth = 420.0;

  Ticker? _liveTicker;

  @override
  void initState() {
    super.initState();
    _liveTicker = createTicker((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveTicker?.dispose();
    super.dispose();
  }

  void _syncLiveTicker(FocusProvider focusProvider) {
    final shouldRun = focusProvider.timerState == TimerState.running &&
        focusProvider.expectedEndTime != null;
    if (shouldRun) {
      if (_liveTicker != null && !_liveTicker!.isActive) {
        _liveTicker!.start();
      }
    } else if (_liveTicker != null && _liveTicker!.isActive) {
      _liveTicker!.stop();
    }
  }

  int _getPhaseDurationInSeconds(PhaseType phase, FocusProvider provider) {
    return switch (phase) {
      PhaseType.focus => provider.focusMinutes * 60,
      PhaseType.shortBreak => provider.shortBreakMinutes * 60,
      PhaseType.longBreak => provider.longBreakMinutes * 60,
    };
  }

  Widget _buildSessionProgressCard(FocusProvider focusProvider) {
    final sequence = focusProvider.sequence;
    if (sequence.isEmpty) return const SizedBox.shrink();

    final phaseIndex = focusProvider.currentPhaseIndex;
    var phaseProgress = 0.0;
    if (phaseIndex < sequence.length) {
      final phaseSeconds = _getPhaseDurationInSeconds(
        sequence[phaseIndex],
        focusProvider,
      );
      if (phaseSeconds > 0) {
        phaseProgress = focusProvider.phaseElapsedFraction(phaseSeconds);
      }
    }

    return PomodoroSessionProgressCard(
      sequence: sequence,
      currentPhaseIndex: phaseIndex,
      rounds: focusProvider.rounds,
      focusMinutes: focusProvider.focusMinutes,
      shortBreakMinutes: focusProvider.shortBreakMinutes,
      longBreakMinutes: focusProvider.longBreakMinutes,
      phaseProgress: phaseProgress,
      scale: _cardScale,
    );
  }

  Widget _fullscreenScaled({
    required Widget child,
    double baseWidth = _baseContentWidth,
  }) {
    final scaledWidth = baseWidth * _cardScale;
    return SizedBox(
      width: scaledWidth,
      child: child,
    );
  }

  Widget _buildControls(FocusProvider focusProvider) {
    final isRunning = focusProvider.timerState == TimerState.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: focusProvider.resetEntireCycle,
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () {
            if (isRunning) {
              focusProvider.pauseTimer();
            } else {
              focusProvider.startTimer();
            }
          },
          child: Container(
            width: 132,
            height: 56,
            decoration: BoxDecoration(
              color: isRunning ? AppColors.accentYellow : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (isRunning ? AppColors.accentYellow : AppColors.primary)
                      .withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              isRunning ? 'Pause' : 'Start',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isRunning ? AppColors.textPrimary : AppColors.primaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.skip_next, color: AppColors.textSecondary),
            onPressed: focusProvider.skipPhase,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSection({
    required String label,
    required Color phaseColor,
    required double progress,
    required String timeString,
    required int minutes,
    required int seconds,
    required int totalSeconds,
    required FocusProvider focusProvider,
  }) {
    return Center(
      child: _fullscreenScaled(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: phaseColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: phaseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PomodoroTimerCarousel(
                progress: progress,
                timeString: timeString,
                minutes: minutes,
                seconds: seconds,
                phaseColor: phaseColor,
                totalSeconds: totalSeconds,
                deadline: focusProvider.expectedEndTime,
                isRunning: focusProvider.timerState == TimerState.running,
                timerSize: kPomodoroTimerSize * _timerScale,
                bottomPadding: 24 * _timerScale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideSection(FocusProvider focusProvider) {
    return Center(
      child: _fullscreenScaled(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSessionProgressCard(focusProvider),
              const SizedBox(height: 28),
              _buildControls(focusProvider),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    _syncLiveTicker(focusProvider);

    final sequence = focusProvider.sequence;
    if (sequence.isEmpty || focusProvider.currentPhaseIndex >= sequence.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final currentPhase = sequence[focusProvider.currentPhaseIndex];
    final phaseMeta = switch (currentPhase) {
      PhaseType.focus => (
          label: 'Focus Session',
          color: AppColors.primary,
          total: focusProvider.focusMinutes * 60,
        ),
      PhaseType.shortBreak => (
          label: 'Short Break',
          color: AppColors.accentPeach,
          total: focusProvider.shortBreakMinutes * 60,
        ),
      PhaseType.longBreak => (
          label: 'Long Break',
          color: AppColors.accentYellow,
          total: focusProvider.longBreakMinutes * 60,
        ),
    };

    final totalSeconds = phaseMeta.total;
    final progress = totalSeconds == 0
        ? 0.0
        : focusProvider.phaseElapsedFraction(totalSeconds);
    final remaining = focusProvider.displayRemainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const BackgroundPattern(),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.close_fullscreen,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: 'Exit fullscreen',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: isLandscape
                      ? Row(
                          children: [
                            Expanded(
                              child: _buildTimerSection(
                                label: phaseMeta.label,
                                phaseColor: phaseMeta.color,
                                progress: progress,
                                timeString: timeString,
                                minutes: minutes,
                                seconds: seconds,
                                totalSeconds: totalSeconds,
                                focusProvider: focusProvider,
                              ),
                            ),
                            Expanded(
                              child: _buildSideSection(focusProvider),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTimerSection(
                                label: phaseMeta.label,
                                phaseColor: phaseMeta.color,
                                progress: progress,
                                timeString: timeString,
                                minutes: minutes,
                                seconds: seconds,
                                totalSeconds: totalSeconds,
                                focusProvider: focusProvider,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                child: _buildSideSection(focusProvider),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void openPomodoroFullscreenTimer(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const PomodoroFullscreenTimerScreen();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
