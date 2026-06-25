import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../providers/statistics_provider.dart';
import '../../theme/app_colors.dart';

String formatFocusMinutes(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) {
    return '${minutes}m';
  }
  if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${minutes}m';
}

class StatPanel extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const StatPanel({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final headerChildren = <Widget>[];
    if (title != null) {
      headerChildren.add(
        Expanded(
          child: Text(
            title!,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      if (trailing != null) {
        headerChildren.add(trailing!);
      }
    }

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerChildren.isNotEmpty) ...[
            Row(children: headerChildren),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class StatBarChart extends StatelessWidget {
  final List<StatisticsBarPoint> points;
  final Color activeColor;
  final Color idleColor;
  final String unitSuffix;

  const StatBarChart({
    super.key,
    required this.points,
    required this.activeColor,
    required this.idleColor,
    this.unitSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No data in this range.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final maxValue = math.max(
      1,
      points.map((point) => point.value).fold<int>(0, (a, b) => math.max(a, b)),
    );

    const double maxBarHeight = 104;
    const double chartHeight = 168;
    final bool scrollable = points.length > 8;
    final double barWidth = scrollable ? 16 : 22;
    final bool showValueLabels = !scrollable;

    Widget buildCell(StatisticsBarPoint point) {
      final ratio = point.value / maxValue;
      final barHeight = point.value == 0 ? 6.0 : 14 + (ratio * maxBarHeight);
      final barColor = point.isHighlighted ? activeColor : idleColor;
      final labelColor =
          point.isHighlighted ? AppColors.primaryDark : AppColors.textSecondary;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showValueLabels) ...[
            Text(
              '${point.value}$unitSuffix',
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: barWidth + 14,
            child: Text(
              point.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: point.isHighlighted
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
                fontSize: 11,
                fontWeight:
                    point.isHighlighted ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (scrollable) {
      return SizedBox(
        height: chartHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points
                .map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: buildCell(point),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return SizedBox(
      height: chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points
            .map((point) => Expanded(child: buildCell(point)))
            .toList(),
      ),
    );
  }
}

class DailyGoalCard extends StatelessWidget {
  final String titleText;
  final String valueText;
  final String captionText;
  final double progress;
  final Color accent;
  final IconData icon;

  const DailyGoalCard({
    super.key,
    required this.titleText,
    required this.valueText,
    required this.captionText,
    required this.progress,
    required this.accent,
    this.icon = Icons.flag_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return StatPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      captionText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueText,
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.border.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class SessionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String durationLabel;
  final VoidCallback? onTap;

  const SessionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              durationLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: card,
    );
  }
}

class PriorityBreakdownChart extends StatelessWidget {
  final Map<String, int> data;

  const PriorityBreakdownChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (sum, value) => sum + value);
    final safeTotal = math.max(total, 1);

    final segments = [
      ('High', data['High'] ?? 0, AppColors.accentPeach),
      ('Medium', data['Medium'] ?? 0, AppColors.accentYellow),
      ('Low', data['Low'] ?? 0, AppColors.primary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: segments.map((segment) {
              final value = segment.$2;
              final color = segment.$3;
              final percent = value / safeTotal;
              final flex = math.max(1, (percent * 100).round());

              return Expanded(
                flex: flex,
                child: Container(
                  height: 18,
                  color: value == 0 ? AppColors.border.withValues(alpha: 0.7) : color,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        ...segments.map((segment) {
          final label = segment.$1;
          final value = segment.$2;
          final color = segment.$3;
          final percent = ((value / safeTotal) * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '$value ($percent%)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
