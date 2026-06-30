import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/drawer_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/tinted_accent_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_opacity.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/common/animations/app_horizontal_slide_transition.dart';
import '../../widgets/common/animations/app_popup_transition.dart';
import '../../widgets/common/app_date_picker.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/statistics/statistics_widgets.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/screen_chrome.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = ScreenChrome.isDesktopShellLayout(context);
        final statsProvider = context.watch<StatisticsProvider>();
        context.watch<SettingsProvider>();

        final content = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        _StatisticsSegmentedControl(
                          activeTab: statsProvider.activeTab,
                          onChanged: statsProvider.setActiveTab,
                        ),
                        const SizedBox(height: 20),
                        _StatisticsTabSwitcher(
                          activeTab: statsProvider.activeTab,
                          statsProvider: statsProvider,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        return AppScaffold(
          backgroundColor: AppColors.backgroundOf(context),
          drawer: isDesktop
              ? null
              : const AppDrawer(
                  isPermanent: false,
                  activeRoute: '/statistics',
                ),
          appBar: _buildAppBar(context, showMenuIcon: !isDesktop),
          body: isDesktop
              ? content
              : Builder(
                  builder: (context) => GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 300) {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                    child: content,
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool showMenuIcon,
  }) {
    return AppBar(
      backgroundColor: AppColors.backgroundOf(context),
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryOf(context)),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            if (showMenuIcon) {
              Scaffold.of(context).openDrawer();
            } else {
              context.read<DrawerProvider>().toggleDesktopCollapse();
            }
          },
        ),
      ),
      actions: const [
        NotificationBellButton(),
        SizedBox(width: 8),
      ],
    );
  }
}

class _StatisticsSegmentedControl extends StatelessWidget {
  final StatisticsTab activeTab;
  final ValueChanged<StatisticsTab> onChanged;

  const _StatisticsSegmentedControl({
    required this.activeTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.panelFillOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Focus',
              selected: activeTab == StatisticsTab.focus,
              onTap: () => onChanged(StatisticsTab.focus),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SegmentButton(
              label: 'Task',
              selected: activeTab == StatisticsTab.task,
              onTap: () => onChanged(StatisticsTab.task),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsTabSwitcher extends StatefulWidget {
  final StatisticsTab activeTab;
  final StatisticsProvider statsProvider;

  const _StatisticsTabSwitcher({
    required this.activeTab,
    required this.statsProvider,
  });

  @override
  State<_StatisticsTabSwitcher> createState() => _StatisticsTabSwitcherState();
}

class _StatisticsTabSwitcherState extends State<_StatisticsTabSwitcher>
    with TickerProviderStateMixin {
  int _direction = 1;

  @override
  void didUpdateWidget(covariant _StatisticsTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTab != widget.activeTab) {
      _direction = widget.activeTab == StatisticsTab.focus ? -1 : 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.activeTab == StatisticsTab.focus
        ? _FocusStatisticsContent(
            key: const ValueKey('focus-stats'),
            statsProvider: widget.statsProvider,
          )
        : _TaskStatisticsContent(
            key: const ValueKey('task-stats'),
            statsProvider: widget.statsProvider,
          );

    return appHorizontalSlideSwitcher(
      slideDirection: _direction,
      isIncomingChild: (child) =>
          (widget.activeTab == StatisticsTab.focus &&
              child.key == const ValueKey('focus-stats')) ||
          (widget.activeTab == StatisticsTab.task &&
              child.key == const ValueKey('task-stats')),
      child: child,
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.segmentSelectedFillOf(context)
              : AppColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primaryDarkOf(context)
                : AppColors.borderOf(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.segmentSelectedLabelOf(context)
                : AppColors.textSecondaryOf(context),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final StatisticsRange activeRange;
  final ValueChanged<StatisticsRange> onChanged;

  const _RangeSelector({
    required this.activeRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _RangeChip(
            label: 'Today',
            selected: activeRange == StatisticsRange.today,
            onTap: () => onChanged(StatisticsRange.today),
          ),
          const SizedBox(width: 10),
          _RangeChip(
            label: 'Week',
            selected: activeRange == StatisticsRange.week,
            onTap: () => onChanged(StatisticsRange.week),
          ),
          const SizedBox(width: 10),
          _RangeChip(
            label: 'Month',
            selected: activeRange == StatisticsRange.month,
            onTap: () => onChanged(StatisticsRange.month),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDarkOf(context) : AppColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryDarkOf(context) : AppColors.borderOf(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Cluster wrapping the range filter + overview cards + chart(s).
class _OverviewCluster extends StatelessWidget {
  final StatisticsProvider statsProvider;
  final List<Widget> children;

  const _OverviewCluster({
    required this.statsProvider,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return StatPanel(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 44),
                child: _RangeSelector(
                  activeRange: statsProvider.activeRange,
                  onChanged: statsProvider.setActiveRange,
                ),
              ),
              const SizedBox(height: 12),
              _PeriodNavigator(
                label: statsProvider.periodLabel,
                canGoForward: statsProvider.canShiftForward,
                onPrevious: () => statsProvider.shiftPeriod(-1),
                onNext: () => statsProvider.shiftPeriod(1),
                onPick: () => _pickStatisticsPeriod(context, statsProvider),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _PeriodNavButton(
              icon: Icons.today_outlined,
              tooltip: 'Jump to current period',
              onPressed: statsProvider.resetToCurrentPeriod,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  final String label;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  const _PeriodNavigator({
    required this.label,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PeriodNavButton(
          icon: Icons.chevron_left,
          onPressed: onPrevious,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.primaryDarkOf(context),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _PeriodNavButton(
          icon: Icons.chevron_right,
          onPressed: canGoForward ? onNext : null,
        ),
      ],
    );
  }
}

class _PeriodNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _PeriodNavButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.primaryDarkOf(context)
              : AppOpacity.fixed(
                  AppColors.textSecondaryOf(context),
                  0.4,
                ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

Future<void> _pickStatisticsPeriod(
  BuildContext context,
  StatisticsProvider provider,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final initialDate =
      provider.anchorDate.isAfter(today) ? today : provider.anchorDate;

  final title = switch (provider.activeRange) {
    StatisticsRange.today => 'Select a day',
    StatisticsRange.week => 'Select a day in the week',
    StatisticsRange.month => 'Select a day in the month',
  };

  final picked = await showAppDatePicker(
    context,
    anchor: popupAnchorFromContext(context),
    initialDate: initialDate,
    firstDate: DateTime(2020, 1, 1),
    lastDate: today,
    title: title,
  );

  if (picked != null && context.mounted) {
    provider.setAnchorDate(picked);
  }
}

class _FocusStatisticsContent extends StatelessWidget {
  final StatisticsProvider statsProvider;

  const _FocusStatisticsContent({super.key, required this.statsProvider});

  @override
  Widget build(BuildContext context) {
    final data = statsProvider.focusStats;
    final recent = statsProvider.recentSessionsInRange(limit: 5);
    final granularity = statsProvider.chartGranularityLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverviewCluster(
          statsProvider: statsProvider,
          children: [
            _StatsCardGrid(
              cards: [
                _StatCardModel(
                  title: 'Focus Time',
                  value: formatFocusMinutes(data.totalMinutes),
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF0277BD),
                ),
                _StatCardModel(
                  title: 'Sessions',
                  value: '${data.sessions}',
                  icon: Icons.repeat,
                  color: AppColors.primaryDarkOf(context),
                  lightBgAlpha: 0.52,
                  darkBgAlpha: 0.26,
                ),
                _StatCardModel(
                  title: 'Average',
                  value: '${data.averageMinutes}m',
                  icon: Icons.auto_graph,
                  color: AppColors.accentYellow,
                ),
                _StatCardModel(
                  title: 'Longest',
                  value: '${data.longestMinutes}m',
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFFD32F2F),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ClusterChartHeader(title: 'Focus Minutes by $granularity'),
            const SizedBox(height: 12),
            StatBarChart(
              key: ValueKey('focus-chart-${statsProvider.chartPeriodKey}'),
              points: data.minutesBars,
              activeColor: AppColors.chartBarActiveOf(context),
              idleColor: AppColors.chartBarIdleOf(context),
              unitSuffix: 'm',
              periodKey: statsProvider.chartPeriodKey,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SessionsSection(
          totalSessions: statsProvider.totalSessionsInRange,
          averageMinutes: statsProvider.averageSessionMinutesInRange,
          recentSessions: recent,
          onViewAll: () => Navigator.pushNamed(context, '/focus-history'),
        ),
      ],
    );
  }
}

class _TaskStatisticsContent extends StatelessWidget {
  final StatisticsProvider statsProvider;

  const _TaskStatisticsContent({super.key, required this.statsProvider});

  @override
  Widget build(BuildContext context) {
    final data = statsProvider.taskStats;
    final granularity = statsProvider.chartGranularityLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverviewCluster(
          statsProvider: statsProvider,
          children: [
            _StatsCardGrid(
              cards: [
                _StatCardModel(
                  title: 'Total Tasks',
                  value: '${data.total}',
                  icon: Icons.task_alt,
                  color: const Color(0xFF0277BD),
                ),
                _StatCardModel(
                  title: 'Completed',
                  value: '${data.completed}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.primaryDarkOf(context),
                  lightBgAlpha: 0.52,
                  darkBgAlpha: 0.26,
                ),
                _StatCardModel(
                  title: 'Pending',
                  value: '${data.pending}',
                  icon: Icons.hourglass_top_outlined,
                  color: AppColors.accentYellow,
                ),
                _StatCardModel(
                  title: 'Overdue',
                  value: '${data.overdue}',
                  icon: Icons.error_outline,
                  color: const Color(0xFFD32F2F),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ClusterChartHeader(
              title: 'Task Completion by $granularity',
              trailing: Text(
                '${data.completionRate}%',
                style: TextStyle(
                  color: AppColors.primaryDarkOf(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            StatBarChart(
              key: ValueKey('task-chart-${statsProvider.chartPeriodKey}'),
              points: data.completionBars,
              activeColor: AppColors.chartBarActiveOf(context),
              idleColor: AppColors.chartBarIdleOf(context),
              periodKey: statsProvider.chartPeriodKey,
            ),
            const SizedBox(height: 20),
            const _ClusterChartHeader(title: 'Priority Breakdown'),
            const SizedBox(height: 12),
            PriorityBreakdownChart(data: data.priorityBreakdown),
          ],
        ),
        const SizedBox(height: 16),
        TaskDueInsightPanel(data: data.dueSummary),
      ],
    );
  }
}

class _ClusterChartHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _ClusterChartHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SessionsSection extends StatelessWidget {
  final int totalSessions;
  final int averageMinutes;
  final List<FocusSessionLog> recentSessions;
  final VoidCallback onViewAll;

  const _SessionsSection({
    required this.totalSessions,
    required this.averageMinutes,
    required this.recentSessions,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return StatPanel(
      title: 'Sessions',
      trailing: TextButton(
        onPressed: onViewAll,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('View all'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SessionMetric(
                  icon: Icons.done_all,
                  label: 'Completed',
                  value: '$totalSessions total',
                  color: AppColors.primaryDarkOf(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SessionMetric(
                  icon: Icons.timer_outlined,
                  label: 'Average focus',
                  value: '${averageMinutes}m',
                  color: AppColors.accentPeach,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Recent completed sessions',
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (recentSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No focus sessions in this range.',
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...List.generate(recentSessions.length, (index) {
              final log = recentSessions[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == recentSessions.length - 1 ? 0 : 10,
                ),
                child: SessionTile(
                  title: log.title,
                  subtitle: _formatSessionTime(log.time),
                  durationLabel: '${log.durationMinutes}m',
                  onTap: onViewAll,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SessionMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SessionMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCardGrid extends StatelessWidget {
  final List<_StatCardModel> cards;

  const _StatsCardGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: constraints.maxWidth >= 900 ? 3.2 : 2.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _StatCard(card: card);
          },
        );
      },
    );
  }
}

class _StatCardModel {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double lightBgAlpha;
  final double? darkBgAlpha;

  const _StatCardModel({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.lightBgAlpha = 0.28,
    this.darkBgAlpha,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardModel card;

  const _StatCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return TintedAccentCard(
      variant: TintedAccentCardVariant.statistics,
      accentColor: card.color,
      icon: card.icon,
      label: card.title,
      value: card.value,
      lightBgAlpha: card.lightBgAlpha,
      darkBgAlpha: card.darkBgAlpha ?? card.lightBgAlpha,
    );
  }
}

String _formatSessionTime(DateTime time) =>
    AppDateTimeFormat.sessionTimestamp(time);
