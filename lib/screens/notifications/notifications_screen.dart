import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_record.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../../screens/task/task_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/notifications/notification_list_item.dart';
import '../../widgets/statistics/statistics_widgets.dart';
import '../../widgets/common/app_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const List<String> _filters = [
    'All',
    'Tasks',
    'Focus',
    'Goals',
    'Achievements',
  ];

  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final notificationProvider = context.watch<NotificationProvider>();
        final tasks = context.watch<TaskProvider>().tasks;
        final history = notificationProvider.filteredRecords(
          filter: _activeFilter,
          tasks: tasks,
        );
        final groupedHistory = _groupRecords(history);

        final content = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildFilterChips(),
                        const SizedBox(height: 20),
                        if (history.isEmpty)
                          StatPanel(
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No notifications in this view yet.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        else
                          ...groupedHistory.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: StatPanel(
                                title: entry.key,
                                child: Column(
                                  children:
                                      List.generate(entry.value.length, (index) {
                                    final record = entry.value[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index == entry.value.length - 1
                                            ? 0
                                            : 10,
                                      ),
                                      child: NotificationListItem(
                                        record: record,
                                        onTap: () => _openRecord(
                                          context,
                                          record,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          }),
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
          backgroundColor: AppColors.background,
          drawer: isDesktop
              ? null
              : const AppDrawer(
                  isPermanent: false,
                  activeRoute: '/notifications',
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _activeFilter = filter),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDark
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isDesktop,
  }) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            if (isDesktop) {
              context.read<DrawerProvider>().toggleDesktopCollapse();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
      ),
    );
  }

  Map<String, List<NotificationRecord>> _groupRecords(
    List<NotificationRecord> records,
  ) {
    final groups = <String, List<NotificationRecord>>{};
    final orderedKeys = <String>[];

    for (final record in records) {
      final key = _dayLabel(record.timestamp);
      if (!groups.containsKey(key)) {
        groups[key] = [];
        orderedKeys.add(key);
      }
      groups[key]!.add(record);
    }

    return {for (final key in orderedKeys) key: groups[key]!};
  }

  String _dayLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);
    if (date.isAtSameMomentAs(today)) return 'Today';
    if (date.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return AppDateTimeFormat.weekdayMonthDay(value);
  }

  void _openRecord(BuildContext context, NotificationRecord record) {
    if (record.category == NotificationCategory.focus) {
      Navigator.pushNamed(context, '/focus');
      return;
    }
    if (record.category == NotificationCategory.goals) {
      Navigator.pushNamed(context, '/goals');
      return;
    }
    if (record.category == NotificationCategory.achievement) {
      Navigator.pushNamed(context, '/achievements');
      return;
    }
    if (record.category == NotificationCategory.statistics &&
        !_isTaskDigestRecord(record)) {
      Navigator.pushNamed(context, '/statistics');
      return;
    }
    if (record.category == NotificationCategory.taskReminder ||
        record.category == NotificationCategory.taskDue) {
      if (record.taskId != null) {
        _openTask(context, record.taskId!);
      }
      return;
    }
    if (record.category == NotificationCategory.statistics) {
      Navigator.pushNamed(context, '/task-list');
      return;
    }
  }

  bool _isTaskDigestRecord(NotificationRecord record) {
    final title = record.title.toLowerCase();
    return title.contains('today') ||
        title.contains('overdue') ||
        title.contains('important');
  }

  void _openTask(BuildContext context, String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: taskId),
      ),
    );
  }
}
