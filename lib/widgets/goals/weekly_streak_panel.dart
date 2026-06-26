import 'package:flutter/material.dart';

import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../statistics/statistics_widgets.dart';

class WeeklyStreakPanel extends StatelessWidget {
  final List<GoalDayData> days;
  final bool wrappedInPanel;
  final EdgeInsetsGeometry? panelPadding;
  final bool fillHeight;

  const WeeklyStreakPanel({
    super.key,
    required this.days,
    this.wrappedInPanel = true,
    this.panelPadding,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = WeeklyStreakRow(days: days);
    if (!wrappedInPanel) return content;
    return StatPanel(
      padding: panelPadding ?? const EdgeInsets.all(16),
      height: fillHeight ? double.infinity : null,
      alignment: fillHeight ? Alignment.center : null,
      child: content,
    );
  }
}

class WeeklyStreakRow extends StatelessWidget {
  final List<GoalDayData> days;

  const WeeklyStreakRow({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: days
          .map((day) => Expanded(child: WeekDayTile(day: day)))
          .toList(),
    );
  }
}

class WeekDayTile extends StatelessWidget {
  final GoalDayData day;

  const WeekDayTile({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final label = labels[day.date.weekday - 1];
    final missed = day.isMissed;
    final isRestDay = day.isRestDay;

    final borderColor = day.isToday
        ? AppColors.streakTodayAccentOf(context)
        : missed
        ? AppColors.borderOf(context)
        : day.isComplete
        ? AppColors.streakCompleteBorderOf(context)
        : isRestDay
        ? AppColors.streakFreezeBorderOf(context)
        : day.isPartial
        ? AppColors.accentYellow.withValues(alpha: 0.55)
        : AppColors.borderOf(context);

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: day.isComplete
                ? AppColors.streakCompleteFillOf(context)
                : isRestDay
                ? AppColors.streakFreezeFillOf(context)
                : AppColors.insetSurfaceOf(context),
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: day.isToday ? 1.8 : 1,
            ),
          ),
          child: Center(
            child: Text(
              '${day.date.day}',
              style: TextStyle(
                color: day.isToday
                    ? AppColors.streakTodayAccentOf(context)
                    : AppColors.textSecondaryOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: day.isToday
                ? AppColors.streakTodayAccentOf(context)
                : AppColors.textSecondaryOf(context),
            fontSize: 11,
            fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (missed)
          Text(
            'x',
            style: TextStyle(
              color: AppColors.streakMissedMarkOf(context),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          )
        else if (day.isComplete)
          Icon(
            Icons.local_fire_department,
            color: AppColors.streakFlameOf(context),
            size: 22,
          )
        else if (isRestDay)
          Icon(
            AppIcons.freezeDay,
            color: AppColors.streakFreezeIconOf(context),
            size: 22,
          )
        else
          const SizedBox(height: 22),
      ],
    );
  }
}
