import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../main.dart' show navigatorKey;
import '../../providers/focus_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/focus/pomodoro_session_progress_card.dart';
import '../../widgets/focus/pomodoro_timer_carousel.dart';

const double kPomodoroFullscreenWideBreakpoint = 768;

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

  static const double _wideBreakpoint = kPomodoroFullscreenWideBreakpoint;

  bool _isWideScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= _wideBreakpoint;
  }

  bool _useHorizontalSplit(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  Widget _buildCloseButton(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
    );
  }

  Widget _buildTimerContent({
    required String label,
    required Color phaseColor,
    required double progress,
    required String timeString,
    required int minutes,
    required int seconds,
    required int totalSeconds,
    required FocusProvider focusProvider,
    required bool isWideScreen,
    required double timerSize,
    required double bottomPadding,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        isWideScreen ? 24 : 12,
        24,
        isWideScreen ? 32 : 16,
      ),
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
          SizedBox(height: isWideScreen ? 32 : 20),
          PomodoroTimerCarousel(
            progress: progress,
            timeString: timeString,
            minutes: minutes,
            seconds: seconds,
            phaseColor: phaseColor,
            totalSeconds: totalSeconds,
            deadline: focusProvider.expectedEndTime,
            isRunning: focusProvider.timerState == TimerState.running,
            timerSize: timerSize,
            bottomPadding: bottomPadding,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection({
    required BuildContext context,
    required String label,
    required Color phaseColor,
    required double progress,
    required String timeString,
    required int minutes,
    required int seconds,
    required int totalSeconds,
    required FocusProvider focusProvider,
    required bool isWideScreen,
    required bool useHorizontalSplit,
  }) {
    if (isWideScreen) {
      final timerSize = _timerSizeForPanel(
        context,
        useHorizontalSplit: useHorizontalSplit,
      );
      final content = _buildTimerContent(
        label: label,
        phaseColor: phaseColor,
        progress: progress,
        timeString: timeString,
        minutes: minutes,
        seconds: seconds,
        totalSeconds: totalSeconds,
        focusProvider: focusProvider,
        isWideScreen: isWideScreen,
        timerSize: timerSize,
        bottomPadding: 24 * (timerSize / kPomodoroTimerSize),
      );
      return SizedBox.expand(
        child: Center(child: content),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final timerSize = _timerSizeForMobileConstraints(constraints);
        final bottomPadding = 12 * (timerSize / kPomodoroTimerSize);
        final content = _buildTimerContent(
          label: label,
          phaseColor: phaseColor,
          progress: progress,
          timeString: timeString,
          minutes: minutes,
          seconds: seconds,
          totalSeconds: totalSeconds,
          focusProvider: focusProvider,
          isWideScreen: isWideScreen,
          timerSize: timerSize,
          bottomPadding: bottomPadding,
        );
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: content,
          ),
        );
      },
    );
  }

  double _timerSizeForMobileConstraints(BoxConstraints constraints) {
    const overhead = 84.0;
    final maxW = constraints.maxWidth - 48;
    final maxH = constraints.maxHeight - overhead;
    if (!maxW.isFinite || !maxH.isFinite) {
      return kPomodoroTimerSize;
    }
    return math.min(maxW, maxH).clamp(200.0, kPomodoroTimerSize * _timerScale);
  }

  double _timerSizeForPanel(
    BuildContext context, {
    required bool useHorizontalSplit,
  }) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final panelWidth =
        useHorizontalSplit ? size.width / 2 : size.width;
    final panelHeight = useHorizontalSplit
        ? size.height - padding.vertical
        : (size.height - padding.vertical) * 0.58;

    final maxByWidth = panelWidth * 0.78;
    final maxByHeight = panelHeight * 0.62;
    final target = maxByWidth < maxByHeight ? maxByWidth : maxByHeight;

    return target.clamp(kPomodoroTimerSize * _timerScale, 520);
  }

  Widget _buildSideSection(
    FocusProvider focusProvider, {
    required bool isWideScreen,
  }) {
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isWideScreen ? 24 : 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSessionProgressCard(focusProvider),
          SizedBox(height: isWideScreen ? 32 : 28),
          _buildControls(focusProvider),
        ],
      ),
    );

    if (isWideScreen) {
      return SizedBox.expand(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _baseContentWidth * _cardScale * 1.15,
            ),
            child: content,
          ),
        ),
      );
    }

    return Center(child: _fullscreenScaled(child: content));
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
      return const AppScaffold(body: SizedBox.shrink());
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

    final isWideScreen = _isWideScreen(context);
    final useHorizontalSplit = _useHorizontalSplit(context);

    final timerSection = _buildTimerSection(
      context: context,
      label: phaseMeta.label,
      phaseColor: phaseMeta.color,
      progress: progress,
      timeString: timeString,
      minutes: minutes,
      seconds: seconds,
      totalSeconds: totalSeconds,
      focusProvider: focusProvider,
      isWideScreen: isWideScreen,
      useHorizontalSplit: useHorizontalSplit,
    );

    final sideSection = _buildSideSection(
      focusProvider,
      isWideScreen: isWideScreen,
    );

    return AppScaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackgroundPattern(),
          SafeArea(
            bottom: !isWideScreen,
            child: useHorizontalSplit
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: timerSection),
                      Expanded(child: sideSection),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: timerSection),
                      Expanded(
                        flex: 2,
                        child: isWideScreen
                            ? sideSection
                            : SingleChildScrollView(child: sideSection),
                      ),
                    ],
                  ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: _buildCloseButton(context),
          ),
        ],
      ),
    );
  }
}

void openPomodoroFullscreenTimer(BuildContext context) {
  final isWide = MediaQuery.sizeOf(context).width >= kPomodoroFullscreenWideBreakpoint;
  final navigator = isWide
      ? navigatorKey.currentState
      : Navigator.of(context);

  navigator?.push(
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
