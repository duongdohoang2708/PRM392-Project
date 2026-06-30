import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_opacity.dart';
import '../../providers/focus_provider.dart';

class ActiveFocusSection extends StatelessWidget {
  const ActiveFocusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final isRunning = focusProvider.timerState == TimerState.running;
    final isIdle = focusProvider.timerState == TimerState.idle;

    double progress = 0.0;
    String timeString = "25:00";
    String title = focusProvider.selectedTask?.title ?? "Ready to focus";

    if (focusProvider.sequence.isNotEmpty) {
      final currentPhase = focusProvider.sequence[focusProvider.currentPhaseIndex];
      int totalSeconds = 0;
      switch (currentPhase) {
        case PhaseType.focus:
          totalSeconds = focusProvider.focusMinutes * 60;
          title = focusProvider.selectedTask?.title ?? "Focus Session";
          break;
        case PhaseType.shortBreak:
          totalSeconds = focusProvider.shortBreakMinutes * 60;
          title = "Short Break";
          break;
        case PhaseType.longBreak:
          totalSeconds = focusProvider.longBreakMinutes * 60;
          title = "Long Break";
          break;
      }
      
      if (isIdle && focusProvider.currentPhaseIndex == 0) {
         // If idle and hasn't started, show full time and 0 progress
         progress = 0.0;
         final int minutes = totalSeconds ~/ 60;
         final int seconds = totalSeconds % 60;
         timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        if (totalSeconds > 0) {
          progress = focusProvider.phaseElapsedFraction(totalSeconds);
        }
        final int remaining = focusProvider.displayRemainingSeconds;
        final int minutes = remaining ~/ 60;
        final int seconds = remaining % 60;
        timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    } else {
      timeString = '${focusProvider.focusMinutes.toString().padLeft(2, '0')}:00';
    }

    final isDark = AppColors.isDark(context);
    final accent = isDark ? AppColors.primaryOf(context) : AppColors.primaryDarkOf(context);
    final titleColor = AppColors.textPrimaryOf(context);
    final subtitleColor = AppColors.textSecondaryOf(context);
    final progressTrack = AppColors.primaryLightTintOf(
      context,
      alpha: isDark ? 0.3 : 0.55,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Focus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/focus');
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceFillOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppOpacity.fixed(AppColors.primaryOf(context), 0.3)
                    : AppColors.borderOf(context),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: progressTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                    Icon(Icons.timer, color: accent, size: 24),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FocusControlButton(
                      icon: Icons.refresh,
                      onPressed: () {
                        context.read<FocusProvider>().resetEntireCycle();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FocusControlButton(
                      icon: isRunning
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 40,
                      iconSize: 40,
                      onPressed: () {
                        if (isRunning) {
                          context.read<FocusProvider>().pauseTimer();
                        } else {
                          context.read<FocusProvider>().startTimer();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _FocusControlButton(
                      icon: Icons.skip_next,
                      onPressed: () {
                        context.read<FocusProvider>().skipPhase();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FocusControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  const _FocusControlButton({
    required this.icon,
    required this.onPressed,
    this.size = 38,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = isDark ? AppColors.primaryOf(context) : AppColors.primaryDarkOf(context);

    return Material(
      color: isDark
          ? AppColors.insetSurfaceOf(context)
          : AppColors.primaryLightTintOf(context, alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: accent,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
