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

class FocusHistoryScreen extends StatelessWidget {
  const FocusHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final statsProvider = context.watch<StatisticsProvider>();
        final sessions = statsProvider.allSessions;

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
                          'Focus History',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        _HistorySummary(
                          totalSessions: statsProvider.totalSessions,
                          totalMinutes: statsProvider.totalFocusMinutesAllTime,
                          averageMinutes: statsProvider.averageSessionMinutes,
                        ),
                        const SizedBox(height: 16),
                        if (sessions.isEmpty)
                          StatPanel(
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No focus sessions recorded yet. Start a Pomodoro to build your history.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._buildGroupedSessions(sessions),
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
          appBar: _buildAppBar(context, isDesktop: isDesktop),
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

  List<Widget> _buildGroupedSessions(List<FocusSessionLog> sessions) {
    final groups = <String, List<FocusSessionLog>>{};
    final orderedKeys = <String>[];

    for (final session in sessions) {
      final key = _dayLabel(session.time);
      if (!groups.containsKey(key)) {
        groups[key] = [];
        orderedKeys.add(key);
      }
      groups[key]!.add(session);
    }

    final widgets = <Widget>[];
    for (final key in orderedKeys) {
      final groupSessions = groups[key]!;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StatPanel(
            title: key,
            child: Column(
              children: List.generate(groupSessions.length, (index) {
                final log = groupSessions[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == groupSessions.length - 1 ? 0 : 10,
                  ),
                  child: SessionTile(
                    title: log.title,
                    subtitle: _timeLabel(log.time),
                    durationLabel: '${log.durationMinutes}m',
                  ),
                );
              }),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isDesktop,
  }) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () {
                if (isDesktop) {
                  context.read<DrawerProvider>().toggleDesktopCollapse();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              size: 28,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            AppNotification.showInfo(context, 'Notifications coming soon!');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _HistorySummary extends StatelessWidget {
  final int totalSessions;
  final int totalMinutes;
  final int averageMinutes;

  const _HistorySummary({
    required this.totalSessions,
    required this.totalMinutes,
    required this.averageMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return StatPanel(
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Sessions',
              value: '$totalSessions',
              color: AppColors.primaryDark,
            ),
          ),
          _divider(),
          Expanded(
            child: _SummaryItem(
              label: 'Total focus',
              value: formatFocusMinutes(totalMinutes),
              color: AppColors.accentPeach,
            ),
          ),
          _divider(),
          Expanded(
            child: _SummaryItem(
              label: 'Average',
              value: '${averageMinutes}m',
              color: AppColors.accentYellow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dayLabel(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_months[time.month - 1]} ${time.day}, ${time.year}';
}

String _timeLabel(DateTime time) => AppDateTimeFormat.time(time);
