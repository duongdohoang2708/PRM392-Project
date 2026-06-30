import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/task/task_filter_chips.dart';
import '../../widgets/task/task_sort_dropdowns.dart';
import '../../widgets/task/task_list_item.dart';
import '../../providers/task_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../models/task_model.dart';
import '../../widgets/task/task_group_list.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/staggered_list_entry.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../utils/keyboard/keyboard_insets.dart';
import '../../widgets/common/app_scaffold.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _showCompleted = true;
  Set<String> _knownActiveIds = {};
  Set<String> _knownCompletedIds = {};
  bool _isFirstBuild = true;
  String _lastFilterState = '';

  List<MapEntry<String, List<Task>>> _groupScheduledTasks(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    for (var task in tasks) {
      if (task.dueDate == null) {
        grouped.putIfAbsent('No Date', () => []).add(task);
        continue;
      }

      final tDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      String groupName;
      if (tDate.isBefore(today)) {
        groupName = 'Overdue';
      } else if (tDate.isAtSameMomentAs(today)) {
        groupName = 'Today';
      } else if (tDate.isAtSameMomentAs(tomorrow)) {
        groupName = 'Tomorrow';
      } else if (tDate.isAfter(tomorrow) && tDate.isBefore(nextWeek)) {
        groupName = 'This Week';
      } else if (tDate.year == today.year && tDate.month == today.month) {
        groupName = 'This Month';
      } else if ((tDate.year == today.year && tDate.month == today.month + 1) ||
          (tDate.year == today.year + 1 &&
              today.month == 12 &&
              tDate.month == 1)) {
        groupName = 'Next Month';
      } else {
        groupName = 'Tháng ${tDate.month}';
        if (tDate.year != today.year) {
          groupName += ' ${tDate.year}';
        }
      }

      grouped.putIfAbsent(groupName, () => []).add(task);
    }

    final order = [
      'Overdue',
      'Today',
      'Tomorrow',
      'This Week',
      'This Month',
      'Next Month',
    ];

    final sortedEntries = grouped.entries.toList();
    sortedEntries.sort((a, b) {
      int indexA = order.indexOf(a.key);
      int indexB = order.indexOf(b.key);

      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      } else if (indexA != -1) {
        return -1;
      } else if (indexB != -1) {
        return 1;
      } else if (a.key == 'No Date') {
        return 1;
      } else if (b.key == 'No Date') {
        return -1;
      } else {
        // Sort by the first task's due date in each group
        if (a.value.isEmpty || b.value.isEmpty) return 0;
        final aDate = a.value.first.dueDate!;
        final bDate = b.value.first.dueDate!;
        return aDate.compareTo(bDate);
      }
    });

    return sortedEntries;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final currentFilterState = '${taskProvider.activeFilter}_${taskProvider.filterStatus}_${taskProvider.searchQuery}_${taskProvider.sortBy}_${taskProvider.filterProject}_${taskProvider.filterPriority}';
    final bool filterChanged = currentFilterState != _lastFilterState;
    _lastFilterState = currentFilterState;

    final isStatusFilterCompleted = taskProvider.filterStatus == 'Completed';
    final uncompletedTasks = isStatusFilterCompleted
        ? taskProvider.filteredTasks
        : taskProvider.filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = isStatusFilterCompleted
        ? <Task>[]
        : taskProvider.filteredTasks.where((t) => t.isCompleted).toList();

    // Xác định task nào vừa mới xuất hiện trong section
    final currentActiveIds = uncompletedTasks.map((t) => t.id).toSet();
    final currentCompletedIds = completedTasks.map((t) => t.id).toSet();
    
    final Set<String> newActiveIds;
    final Set<String> newCompletedIds;
    if (_isFirstBuild || filterChanged) {
      newActiveIds = {};
      newCompletedIds = {};
      _isFirstBuild = false;
    } else {
      newActiveIds = currentActiveIds.difference(_knownActiveIds);
      newCompletedIds = currentCompletedIds.difference(_knownCompletedIds);
    }

    // Cập nhật set đã biết
    _knownActiveIds = currentActiveIds;
    _knownCompletedIds = currentCompletedIds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = MediaQuery.of(context).size.width >= 768;

        Widget mainContent = Stack(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task List',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              CustomSearchBar(
                                hintText: 'Search tasks...',
                                onChanged: (value) => taskProvider.setSearchQuery(value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          height: 60.0,
                          backgroundColor: AppColors.backgroundOf(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 8.0,
                            ),
                            child: TaskFilterChips(),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const TaskSortDropdowns(),
                              const SizedBox(height: 32),

                              Column(
                                key: ValueKey('task_list_$currentFilterState'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (taskProvider.activeFilter == 'Scheduled')
                                      ..._groupScheduledTasks(uncompletedTasks).map((
                                  group,
                                ) {
                                  final List<Widget> taskWidgets = [];
                                  for (int i = 0; i < group.value.length; i++) {
                                    final task = group.value[i];
                                    final isNew = newActiveIds.contains(task.id);
                                    final item = TaskListItem(
                                      hideActions: false,
                                      task: task,
                                    );
                                    taskWidgets.add(StaggeredListEntry(
                                      key: ValueKey('task_wrapper_${currentFilterState}_${task.id}'),
                                      index: i,
                                      isNewAddition: isNew,
                                      child: item,
                                    ));
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24.0,
                                    ),
                                    child: TaskGroupList(
                                      title: group.key,
                                      count: group.value.length,
                                      tasks: taskWidgets,
                                    ),
                                  );
                                })
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: uncompletedTasks.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final task = entry.value;
                                    final isNew = newActiveIds.contains(task.id);
                                    final item = TaskListItem(
                                      hideActions: false,
                                      task: task,
                                    );
                                    return StaggeredListEntry(
                                      key: ValueKey('task_wrapper_${currentFilterState}_${task.id}'),
                                      index: index,
                                      isNewAddition: isNew,
                                      child: item,
                                    );
                                  }).toList(),
                                ),

                              if (uncompletedTasks.isEmpty &&
                                  completedTasks.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(child: Text("No tasks found.")),
                                ),

                              if (completedTasks.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                InkWell(
                                  onTap: () => setState(() => _showCompleted = !_showCompleted),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Completed Tasks (${completedTasks.length})',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondaryOf(context),
                                        ),
                                      ),
                                      Icon(
                                        _showCompleted
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: AppColors.textSecondaryOf(context),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_showCompleted) ...[
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: completedTasks.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final task = entry.value;
                                      final isNew = newCompletedIds.contains(task.id);
                                      final item = TaskListItem(
                                        hideActions: false,
                                        task: task,
                                      );
                                      return StaggeredListEntry(
                                        key: ValueKey('task_wrapper_completed_${currentFilterState}_${task.id}'),
                                        index: index,
                                        isNewAddition: isNew,
                                        child: item,
                                      );
                                    }).toList(),
                                  ),
                                ],
                                ],
                              ],
                            ),
                            const SizedBox(height: 100), // Padding for FAB
                          ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: KeyboardBottomSpacer()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        Widget fab = FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/create-task');
          },
          child: Icon(Icons.add),
        );

        if (isDesktop) {
          return AppScaffold(
            backgroundColor: AppColors.backgroundOf(context),
            appBar: _buildAppBar(context, showMenuIcon: false),
            body: mainContent,
            floatingActionButton: fab,
          );
        }

        return AppScaffold(
          backgroundColor: AppColors.backgroundOf(context),
          drawer: const AppDrawer(
            isPermanent: false,
            activeRoute: '/task-list',
          ),
          appBar: _buildAppBar(context, showMenuIcon: true),
          body: Builder(
            builder: (context) => GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                  Scaffold.of(context).openDrawer();
                }
              },
              child: mainContent,
            ),
          ),
          floatingActionButton: fab,
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
              // Mobile: Open overlay drawer
              Scaffold.of(context).openDrawer();
            } else {
              // Desktop: Toggle collapsed state
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
