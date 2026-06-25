import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../goals/weekly_streak_panel.dart';
import '../statistics/statistics_widgets.dart';

class StreakOverviewSection extends StatelessWidget {
  const StreakOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final goalsProvider = context.watch<GoalsProvider>();
    final currentStreak = goalsProvider.currentStreak;
    final weekDays = goalsProvider.currentWeekGoalDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Streak Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/goals'),
              child: const Text(
                'View goals',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/goals'),
          borderRadius: BorderRadius.circular(20),
          child: StatPanel(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 640;

                final streakBlock = _StreakSummary(
                  currentStreak: currentStreak,
                  isCompact: !isWide,
                );

                final weekCalendar = Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: WeeklyStreakRow(days: weekDays),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: streakBlock,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: weekCalendar),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    streakBlock,
                    const SizedBox(height: 16),
                    weekCalendar,
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StreakSummary extends StatelessWidget {
  final int currentStreak;
  final bool isCompact;

  const _StreakSummary({
    required this.currentStreak,
    required this.isCompact,
  });

  String get _headline {
    if (currentStreak == 0) return 'Light the flame today!';
    if (currentStreak < 3) return 'The fire is catching!';
    if (currentStreak < 7) return '$currentStreak days on fire!';
    if (currentStreak < 14) return '$currentStreak days strong!';
    return '$currentStreak days — unstoppable!';
  }

  String get _tagline {
    if (currentStreak == 0) {
      return 'One bold day is all it takes to spark something great.';
    }
    if (currentStreak < 3) {
      return 'Momentum is building — ride the wave while it\'s hot.';
    }
    if (currentStreak < 7) {
      return 'You\'re heating up. Stay locked in and keep the streak alive.';
    }
    if (currentStreak < 14) {
      return 'Discipline is paying off. Don\'t cool down now.';
    }
    return 'This is elite consistency. Keep burning bright.';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isCompact ? 56 : 64,
          height: isCompact ? 56 : 64,
          decoration: BoxDecoration(
            color: AppColors.accentPeach.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentPeach.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.local_fire_department,
            color: AppColors.accentPeach,
            size: isCompact ? 30 : 34,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _headline,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tagline,
                maxLines: isCompact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
