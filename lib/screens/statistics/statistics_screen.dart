import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/drawer_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/custom_snackbar.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final statsProvider = context.watch<StatisticsProvider>();

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
                                color: AppColors.textPrimary,
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

        return Scaffold(
          backgroundColor: AppColors.background,
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
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            AppNotification.showInfo(context, 'Notifications coming soon!');
          },
        ),
        const SizedBox(width: 8),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
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

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final isIncoming =
              (widget.activeTab == StatisticsTab.focus && child.key == const ValueKey('focus-stats')) ||
              (widget.activeTab == StatisticsTab.task && child.key == const ValueKey('task-stats'));
          final offsetDirection = isIncoming ? _direction : -_direction;

          final inCurve = isIncoming
              ? CurveTween(curve: Curves.easeOutCubic)
              : CurveTween(curve: Curves.easeInCubic);

          final slideAnimation = animation.drive(
            Tween<Offset>(
              begin: Offset(0.28 * offsetDirection, 0),
              end: Offset.zero,
            ).chain(inCurve),
          );
          final fadeAnimation = animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: isIncoming ? Curves.easeOutCubic : Curves.easeInCubic),
            ),
          );

          return ClipRect(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            ),
          );
        },
        child: child,
      ),
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
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
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
          color: selected ? AppColors.primaryDark : AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RangeSelector(
            activeRange: statsProvider.activeRange,
            onChanged: statsProvider.setActiveRange,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FocusStatisticsContent extends StatelessWidget {
  final StatisticsProvider statsProvider;

  const _FocusStatisticsContent({super.key, required this.statsProvider});

  @override
  Widget build(BuildContext context) {
    final data = statsProvider.focusStats;
    final recent = statsProvider.recentSessions(limit: 5);

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
                  color: AppColors.primaryDark,
                  bgColor: AppColors.primaryLight.withValues(alpha: 0.4),
                ),
                _StatCardModel(
                  title: 'Sessions',
                  value: '${data.sessions}',
                  icon: Icons.repeat,
                  color: AppColors.accentYellow,
                  bgColor: AppColors.accentYellow.withValues(alpha: 0.2),
                ),
                _StatCardModel(
                  title: 'Average',
                  value: '${data.averageMinutes}m',
                  icon: Icons.auto_graph,
                  color: AppColors.accentPeach,
                  bgColor: AppColors.accentPeach.withValues(alpha: 0.18),
                ),
                _StatCardModel(
                  title: 'Longest',
                  value: '${statsProvider.longestSessionMinutes}m',
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.accentPink,
                  bgColor: AppColors.accentPink.withValues(alpha: 0.15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _ClusterChartHeader(title: 'Focus Minutes by Day'),
            const SizedBox(height: 12),
            StatBarChart(
              points: data.minutesBars,
              activeColor: AppColors.primaryDark,
              idleColor: AppColors.primaryLight,
              unitSuffix: 'm',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SessionsSection(
          totalSessions: statsProvider.totalSessions,
          averageMinutes: statsProvider.averageSessionMinutes,
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
                  color: AppColors.primaryDark,
                  bgColor: AppColors.primaryLight.withValues(alpha: 0.4),
                ),
                _StatCardModel(
                  title: 'Completed',
                  value: '${data.completed}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.primary,
                  bgColor: AppColors.primary.withValues(alpha: 0.2),
                ),
                _StatCardModel(
                  title: 'Pending',
                  value: '${data.pending}',
                  icon: Icons.hourglass_top_outlined,
                  color: AppColors.accentYellow,
                  bgColor: AppColors.accentYellow.withValues(alpha: 0.2),
                ),
                _StatCardModel(
                  title: 'Overdue',
                  value: '${data.overdue}',
                  icon: Icons.error_outline,
                  color: AppColors.accentPeach,
                  bgColor: AppColors.accentPeach.withValues(alpha: 0.18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ClusterChartHeader(
              title: 'Task Completion by Day',
              trailing: Text(
                '${data.completionRate}%',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            StatBarChart(
              points: data.completionBars,
              activeColor: AppColors.primaryDark,
              idleColor: AppColors.primaryLight,
            ),
            const SizedBox(height: 20),
            const _ClusterChartHeader(title: 'Priority Breakdown'),
            const SizedBox(height: 12),
            PriorityBreakdownChart(data: data.priorityBreakdown),
          ],
        ),
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
            style: const TextStyle(
              color: AppColors.textPrimary,
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
                  color: AppColors.primaryDark,
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
          const Text(
            'Recent completed sessions',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (recentSessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No focus sessions yet.',
                style: TextStyle(
                  color: AppColors.textSecondary,
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
            style: const TextStyle(
              color: AppColors.textPrimary,
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
            childAspectRatio: constraints.maxWidth >= 900 ? 2.2 : 1.8,
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
  final Color bgColor;

  const _StatCardModel({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardModel card;

  const _StatCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card.bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: card.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(card.icon, color: card.color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatSessionTime(DateTime time) =>
    AppDateTimeFormat.sessionTimestamp(time);
