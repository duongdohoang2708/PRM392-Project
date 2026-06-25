import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
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
          progress = 1 - (focusProvider.remainingSeconds / totalSeconds);
        }
        final int minutes = focusProvider.remainingSeconds ~/ 60;
        final int seconds = focusProvider.remainingSeconds % 60;
        timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    } else {
      timeString = '${focusProvider.focusMinutes.toString().padLeft(2, '0')}:00';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Focus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
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
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(100),
                  blurRadius: 10,
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
                        backgroundColor: Colors.white.withAlpha(50),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.timer, color: Colors.white, size: 24),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha(200),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (isRunning) {
                      context.read<FocusProvider>().pauseTimer();
                    } else {
                      context.read<FocusProvider>().startTimer();
                    }
                  },
                  icon: Icon(
                    isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
