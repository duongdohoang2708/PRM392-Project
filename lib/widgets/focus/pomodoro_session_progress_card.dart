import 'package:flutter/material.dart';

import '../../providers/focus_provider.dart';
import '../../theme/app_colors.dart';

class PomodoroSessionProgressCard extends StatelessWidget {
  final List<PhaseType> sequence;
  final int currentPhaseIndex;
  final int rounds;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final double phaseProgress;
  final bool allCompleted;
  final double scale;

  const PomodoroSessionProgressCard({
    super.key,
    required this.sequence,
    required this.currentPhaseIndex,
    required this.rounds,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.phaseProgress,
    this.allCompleted = false,
    this.scale = 1,
  });

  Color _phaseColor(PhaseType phase) {
    return switch (phase) {
      PhaseType.focus => AppColors.primary,
      PhaseType.shortBreak => AppColors.accentPeach,
      PhaseType.longBreak => AppColors.accentYellow,
    };
  }

  int _phaseDurationMinutes(PhaseType phase) {
    return switch (phase) {
      PhaseType.focus => focusMinutes,
      PhaseType.shortBreak => shortBreakMinutes,
      PhaseType.longBreak => longBreakMinutes,
    };
  }

  String _phaseTitle(PhaseType phase) {
    return switch (phase) {
      PhaseType.focus => 'Focus session',
      PhaseType.shortBreak => 'Short break',
      PhaseType.longBreak => 'Long break',
    };
  }

  int _focusSessionNumber(int phaseIndex) {
    var count = 0;
    for (var i = 0; i <= phaseIndex && i < sequence.length; i++) {
      if (sequence[i] == PhaseType.focus) count++;
    }
    return count;
  }

  String _currentLabel() {
    if (sequence.isEmpty) return 'No session';

    if (allCompleted || currentPhaseIndex >= sequence.length) {
      return 'All sessions complete';
    }

    final phase = sequence[currentPhaseIndex];
    if (phase == PhaseType.focus) {
      return 'Focus session ${_focusSessionNumber(currentPhaseIndex)} of $rounds';
    }
    return _phaseTitle(phase);
  }

  String? _nextLabel() {
    if (allCompleted || sequence.isEmpty) return null;

    final nextIndex = currentPhaseIndex + 1;
    if (nextIndex >= sequence.length) return null;

    final nextPhase = sequence[nextIndex];
    final minutes = _phaseDurationMinutes(nextPhase);
    final title = nextPhase == PhaseType.focus
        ? 'Focus session ${_focusSessionNumber(nextIndex)}'
        : _phaseTitle(nextPhase);

    return '$title · $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    if (sequence.isEmpty) return const SizedBox.shrink();

    final PhaseType? currentPhase = allCompleted || currentPhaseIndex >= sequence.length
        ? null
        : sequence[currentPhaseIndex];
    final phaseColor = currentPhase != null
        ? _phaseColor(currentPhase)
        : AppColors.primary;
    final progress = allCompleted ? 1.0 : phaseProgress.clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();
    final nextLabel = _nextLabel();
    final s = scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: AppColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(
            color: AppColors.borderOf(context).withValues(alpha: 0.59)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT',
            style: TextStyle(
              fontSize: 11 * s,
              fontWeight: FontWeight.w800,
              color: phaseColor,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 4 * s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _currentLabel(),
                  style: TextStyle(
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                '$progressPercent%',
                style: TextStyle(
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w800,
                  color: phaseColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * s),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6 * s,
              backgroundColor: phaseColor.withAlpha(35),
              valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
            ),
          ),
          if (nextLabel != null) ...[
            SizedBox(height: 10 * s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: 11 * s,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondaryOf(context).withAlpha(200),
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(width: 8 * s),
                Expanded(
                  child: Text(
                    nextLabel,
                    style: TextStyle(
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryOf(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
