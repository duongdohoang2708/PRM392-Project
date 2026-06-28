import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../goals/weekly_streak_panel.dart';
import '../statistics/statistics_widgets.dart';
import '../common/section_action_button.dart';

class StreakOverviewSection extends StatelessWidget {
  const StreakOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final goalsProvider = context.watch<GoalsProvider>();
    final weekDays = goalsProvider.currentWeekGoalDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Streak Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            SectionActionButton(
              label: 'View goals',
              onPressed: () => Navigator.pushNamed(context, '/goals'),
              foregroundColor: AppColors.primaryDark,
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
                  goalsProvider: goalsProvider,
                  isCompact: !isWide,
                );

                final weekCalendar = Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderOf(context)),
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
  final GoalsProvider goalsProvider;
  final bool isCompact;

  const _StreakSummary({
    required this.goalsProvider,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final isRestDay = goalsProvider.isTodayRestDay;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isCompact ? 56 : 64,
          height: isCompact ? 56 : 64,
          decoration: BoxDecoration(
            color: isRestDay
                ? AppColors.cardFillOf(
                    context,
                    accentColor: AppColors.freezeBlue,
                    lightTintAlpha: 0.14,
                    darkTintAlpha: 0.14,
                  )
                : AppColors.cardFillOf(
                    context,
                    accentColor: AppColors.accentPeach,
                    lightTintAlpha: 0.18,
                    darkTintAlpha: 0.18,
                  ),
            shape: BoxShape.circle,
            border: Border.all(
              color: isRestDay
                  ? AppColors.statCardBorderOf(context, AppColors.freezeBlue)
                  : AppColors.statCardBorderOf(context, AppColors.accentPeach),
              width: 1.5,
            ),
          ),
          child: Icon(
            isRestDay
                ? AppIcons.freezeDay
                : Icons.local_fire_department,
            color: isRestDay ? AppIcons.freezeDayColor : AppColors.accentPeach,
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
                goalsProvider.streakHeroTitle,
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                goalsProvider.streakHeroSubtitle,
                maxLines: isCompact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
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
