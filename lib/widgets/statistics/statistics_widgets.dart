import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../providers/statistics_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_opacity.dart';
import '../common/accent_icon_well.dart';

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
  final double? height;
  final AlignmentGeometry? alignment;

  const StatPanel({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final headerChildren = <Widget>[];
    if (title != null) {
      headerChildren.add(
        Expanded(
          child: Text(
            title!,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
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
      height: height,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: AppColors.panelFillOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOf(context).withValues(
              alpha: AppColors.isDark(context) ? 0.04 : 0.08,
            ),
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

class StatBarChart extends StatefulWidget {
  final List<StatisticsBarPoint> points;
  final Color activeColor;
  final Color idleColor;
  final String unitSuffix;
  final String? periodKey;

  const StatBarChart({
    super.key,
    required this.points,
    required this.activeColor,
    required this.idleColor,
    this.unitSuffix = '',
    this.periodKey,
  });

  @override
  State<StatBarChart> createState() => _StatBarChartState();
}

class _StatBarChartState extends State<StatBarChart> {
  static const double _scrollBarWidth = 16;
  static const double _scrollCellGap = 2;
  static const double _scrollCellWidth = 42;
  static const double _scrollCellStride = _scrollCellWidth + _scrollCellGap;

  final ScrollController _scrollController = ScrollController();
  String? _lastScrolledPeriodKey;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scheduleScrollToHighlight();
  }

  @override
  void didUpdateWidget(covariant StatBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periodKey != widget.periodKey ||
        oldWidget.points.length != widget.points.length) {
      _lastScrolledPeriodKey = null;
      _scheduleScrollToHighlight();
    }
  }

  void _scheduleScrollToHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollToHighlight();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToHighlight();
      });
    });
  }

  void _scrollToHighlight() {
    if (!mounted || !_scrollController.hasClients) return;

    final periodKey = widget.periodKey;
    if (periodKey != null && periodKey == _lastScrolledPeriodKey) return;

    final highlightIndex =
        widget.points.indexWhere((point) => point.isHighlighted);
    if (highlightIndex < 0) return;

    final viewport = _scrollController.position.viewportDimension;
    final target =
        (highlightIndex * _scrollCellStride) - (viewport / 2) + (_scrollCellStride / 2);
    final maxExtent = _scrollController.position.maxScrollExtent;

    _scrollController.jumpTo(target.clamp(0.0, maxExtent));
    _lastScrolledPeriodKey = periodKey;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No data in this range.',
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final maxValue = math.max(
      1,
      widget.points
          .map((point) => point.value)
          .fold<int>(0, (a, b) => math.max(a, b)),
    );

    const double maxBarHeight = 160;
    const double valueLabelHeight = 18;
    const double axisLabelBlockHeight = 30;
    const double chartVerticalGaps = 14;
    const double chartBottomInset = 6;
    final double chartHeight = valueLabelHeight +
        chartVerticalGaps +
        (14 + maxBarHeight) +
        axisLabelBlockHeight +
        chartBottomInset;
    final bool scrollable = widget.points.length > 8;

    Widget buildCell(
      StatisticsBarPoint point, {
      required double barWidth,
      double labelWidth = 0,
    }) {
      final ratio = point.value / maxValue;
      final barHeight = point.value == 0 ? 6.0 : 14 + (ratio * maxBarHeight);
      final barColor = point.isHighlighted ? widget.activeColor : widget.idleColor;
      final labelColor = point.isHighlighted
          ? AppColors.chartBarHighlightLabelOf(context)
          : AppColors.textSecondaryOf(context);
      final effectiveLabelWidth = labelWidth > 0
          ? labelWidth
          : math.max(barWidth + 14, 28).toDouble();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${point.value}${widget.unitSuffix}',
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
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
            width: effectiveLabelWidth,
            child: point.subLabel == null
                ? Text(
                    point.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: point.isHighlighted
                          ? AppColors.chartBarHighlightLabelOf(context)
                          : AppColors.textSecondaryOf(context),
                      fontSize: 11,
                      fontWeight: point.isHighlighted
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        point.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: point.isHighlighted
                              ? AppColors.chartBarHighlightLabelOf(context)
                              : AppColors.textSecondaryOf(context),
                          fontSize: 11,
                          fontWeight: point.isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      Text(
                        point.subLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: point.isHighlighted
                              ? AppColors.chartBarHighlightLabelOf(context)
                              : AppColors.textSecondaryOf(context),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    }

    if (scrollable) {
      return SizedBox(
        height: chartHeight,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          itemCount: widget.points.length,
          itemBuilder: (context, index) {
            final point = widget.points[index];
            return Padding(
              padding: EdgeInsets.only(
                right: index == widget.points.length - 1 ? 0 : _scrollCellGap,
              ),
              child: SizedBox(
                height: chartHeight,
                width: _scrollCellWidth,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: buildCell(point, barWidth: _scrollBarWidth),
                ),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const spacing = 5.0;
        final totalSpacing = spacing * math.max(0, widget.points.length - 1);
        final cellWidth =
            ((availableWidth - totalSpacing) / math.max(widget.points.length, 1))
                .toDouble();
        final barWidth =
            math.min(48.0, math.max(22.0, cellWidth * 0.55)).toDouble();

        return SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < widget.points.length; index++) ...[
                if (index > 0) const SizedBox(width: spacing),
                SizedBox(
                  height: chartHeight,
                  width: cellWidth,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: buildCell(
                      widget.points[index],
                      barWidth: barWidth,
                      labelWidth: cellWidth,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
              AccentIconWell(
                accentColor: accent,
                icon: icon,
                size: 40,
                iconSize: 22,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      captionText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
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
              backgroundColor: AppOpacity.fixed(
                AppColors.borderOf(context),
                0.6,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusGoalProgressPanel extends StatelessWidget {
  final FocusGoalPeriodData data;

  const FocusGoalProgressPanel({super.key, required this.data});

  String get _valueText {
    if (data.isSingleDay) {
      if (data.isRestDay) {
        return 'Freeze day';
      }
      return '${data.periodMinutes}/${data.focusGoalMinutes} min';
    }
    return '${data.daysMet}/${data.eligibleDays} days';
  }

  String get _captionText {
    if (data.isSingleDay) {
      if (data.isRestDay) {
        return 'Focus goal waived on freeze days.';
      }
      if (data.focusGoalMinutes == 0) {
        return 'No focus goal configured.';
      }
      if (data.periodMinutes >= data.focusGoalMinutes) {
        return 'Focus goal met for this day.';
      }
      final remaining = data.focusGoalMinutes - data.periodMinutes;
      return '$remaining min remaining to reach goal.';
    }

    if (data.eligibleDays == 0) {
      return 'No tracked days in this period yet.';
    }

    final buffer = StringBuffer(
      '${data.daysMet} of ${data.eligibleDays} days met the focus goal',
    );
    if (data.restDays > 0) {
      buffer.write(
        ' (${data.restDays} freeze day${data.restDays == 1 ? '' : 's'} waived)',
      );
    }
    buffer.write('.');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return DailyGoalCard(
      titleText: 'Focus Goal Progress',
      valueText: _valueText,
      captionText: _captionText,
      progress: data.isSingleDay && data.isRestDay ? 1 : data.progress,
      accent: const Color(0xFF5E8F5D),
      icon: Icons.flag_rounded,
    );
  }
}

class TaskDueInsightPanel extends StatelessWidget {
  final TaskDueSummaryData data;

  const TaskDueInsightPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final dueProgress = data.dueCount == 0
        ? 0.0
        : (data.completedCount / data.dueCount).clamp(0, 1).toDouble();

    return StatPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Due vs Completed',
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DueMetricTile(
                  label: 'Due',
                  value: '${data.dueCount}',
                  color: AppColors.accentYellow,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DueMetricTile(
                  label: 'Completed',
                  value: '${data.completedCount}',
                  color: AppColors.primaryOf(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DueMetricTile(
                  label: 'Pending',
                  value: '${data.pendingCount}',
                  color: AppColors.accentPeach,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: dueProgress,
              minHeight: 10,
              backgroundColor: AppOpacity.fixed(
                AppColors.borderOf(context),
                0.6,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryDarkOf(context),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.dueCount == 0
                ? 'No tasks were due in this period.'
                : '${data.dueCompletionRate}% of due tasks completed',
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'On-time Summary',
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DueMetricTile(
                  label: 'On-time rate',
                  value: '${data.onTimeRate}%',
                  color: AppColors.primaryDarkOf(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DueMetricTile(
                  label: 'On-time',
                  value: '${data.onTimeCount}',
                  color: AppColors.primaryOf(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DueMetricTile(
                  label: 'Late',
                  value: '${data.lateCount}',
                  color: AppColors.accentPeach,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DueMetricTile(
                  label: 'Missed',
                  value: '${data.missedCount}',
                  color: AppColors.accentPink,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.completedCount == 0
                ? 'Complete due tasks to build on-time stats.'
                : 'On-time counts tasks finished by their due date.',
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DueMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statCardBgOf(context, color, lightAlpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statCardBorderOf(context, color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
        color: AppColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.completedCheckBgOf(context),
              shape: BoxShape.circle,
              border: AppColors.isDark(context)
                  ? Border.all(
                      color: AppColors.statCardBorderOf(
                        context,
                        AppColors.primaryOf(context),
                      ),
                    )
                  : null,
            ),
            child: Icon(
              Icons.check,
              color: AppColors.completedCheckFgOf(context),
              size: 20,
            ),
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
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
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
              color: AppColors.cardSurfaceFillOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Text(
              durationLabel,
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
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
      ('Low', data['Low'] ?? 0, AppColors.primaryOf(context)),
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
                  color: value == 0
                      ? AppOpacity.fixed(
                          AppColors.borderOf(context),
                          0.7,
                        )
                      : color,
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
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '$value ($percent%)',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
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
