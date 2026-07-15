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
import '../../widgets/common/screen_chrome.dart';

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
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = ScreenChrome.isDesktopShellLayout(context);
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
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 24,
                            bottom: 16,
                          ),
                          child: Text(
                            'Notifications',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          height: 60,
                          backgroundColor: AppColors.backgroundOf(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: _buildFilterChips(),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                        sliver: SliverToBoxAdapter(
                          child: history.isEmpty
                              ? StatPanel(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      'No notifications in this view yet.',
                                      style: TextStyle(
                                        color: AppColors.textSecondaryOf(
                                          context,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: groupedHistory.entries.map(
                                    (entry) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: StatPanel(
                                          title: entry.key,
                                          child: Column(
                                            children: List.generate(
                                              entry.value.length,
                                              (index) {
                                                final record =
                                                    entry.value[index];
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: index ==
                                                            entry.value.length -
                                                                1
                                                        ? 0
                                                        : 10,
                                                  ),
                                                  child: NotificationListItem(
                                                    record: record,
                                                    isSelectionMode: _isSelectionMode,
                                                    isSelected: _selectedIds.contains(record.id),
                                                    onLongPress: () {
                                                      if (!_isSelectionMode) {
                                                        setState(() {
                                                          _isSelectionMode = true;
                                                          _selectedIds.add(record.id);
                                                        });
                                                      }
                                                    },
                                                    onTap: () {
                                                      if (_isSelectionMode) {
                                                        setState(() {
                                                          if (_selectedIds.contains(record.id)) {
                                                            _selectedIds.remove(record.id);
                                                            if (_selectedIds.isEmpty) {
                                                              _isSelectionMode = false;
                                                            }
                                                          } else {
                                                            _selectedIds.add(record.id);
                                                          }
                                                        });
                                                      } else {
                                                        _openRecord(context, record);
                                                      }
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList(),
                                ),
                        ),
                      ),
                    ],
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
                      ? AppColors.primaryDarkOf(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.borderOf(context),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
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
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${_selectedIds.length} Selected',
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimaryOf(context)),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedIds.clear();
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            tooltip: 'Delete selected',
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
                    context.read<NotificationProvider>().deleteNotifications(_selectedIds.toList());
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    });
                  },
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: AppColors.backgroundOf(context),
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryOf(context)),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all),
          tooltip: 'Mark all as read',
          onPressed: () {
            context.read<NotificationProvider>().markAllRead();
          },
        ),
      ],
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color backgroundColor;

  _StickyHeaderDelegate({
    required this.child,
    required this.height,
    required this.backgroundColor,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
