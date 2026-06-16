import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/task/task_search_bar.dart';
import '../../widgets/task/task_filter_chips.dart';
import '../../widgets/task/task_sort_dropdowns.dart';
import '../../widgets/task/task_list_item.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';
import 'package:intl/intl.dart';
import '../../widgets/task/task_group_list.dart';
import '../../widgets/background_pattern.dart';
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _showCompleted = false;

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

      final tDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      
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
                 (tDate.year == today.year + 1 && today.month == 12 && tDate.month == 1)) {
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
      'Next Month'
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
    final isStatusFilterCompleted = taskProvider.filterStatus == 'Completed';
    final uncompletedTasks = isStatusFilterCompleted
        ? taskProvider.filteredTasks
        : taskProvider.filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = isStatusFilterCompleted
        ? <Task>[]
        : taskProvider.filteredTasks.where((t) => t.isCompleted).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 768;

        Widget mainContent = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task List',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const TaskSearchBar(),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                    delegate: _StickyHeaderDelegate(
                      height: 60.0,
                      backgroundColor: AppColors.background,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                          
                          if (taskProvider.activeFilter == 'Scheduled')
                            ..._groupScheduledTasks(uncompletedTasks).map((group) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: TaskGroupList(
                                  title: group.key,
                                  count: group.value.length,
                                  tasks: group.value.map((task) => TaskListItem(
                                    key: ValueKey(task.id),
                                    task: task,
                                  )).toList(),
                                ),
                              );
                            })
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: uncompletedTasks.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final task = uncompletedTasks[index];
                                return TaskListItem(
                                  key: ValueKey(task.id),
                                  task: task,
                                );
                              },
                            ),
                          
                          if (uncompletedTasks.isEmpty && completedTasks.isEmpty)
                             const Padding(
                               padding: EdgeInsets.symmetric(vertical: 40),
                               child: Center(child: Text("No tasks found.")),
                             ),
                             
                          if (completedTasks.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showCompleted = !_showCompleted;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showCompleted ? 'Hide Completed' : 'Show Completed',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _showCompleted ? Icons.expand_less : Icons.expand_more,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_showCompleted) ...[
                              const SizedBox(height: 16),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: completedTasks.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final task = completedTasks[index];
                                  return TaskListItem(
                                    key: ValueKey(task.id),
                                    task: task,
                                  );
                                },
                              ),
                            ],
                          ],

                          const SizedBox(height: 100), // Padding for FAB
                        ],
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

        Widget fab = FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create task coming soon!')),
            );
          },
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32),
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                const AppDrawer(isPermanent: true, activeRoute: '/task-list'),
                Expanded(
                  child: Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: _buildAppBar(context, showMenuIcon: false),
                    body: mainContent,
                    floatingActionButton: fab,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: const AppDrawer(isPermanent: false, activeRoute: '/task-list'),
          appBar: _buildAppBar(context, showMenuIcon: true),
          body: mainContent,
          floatingActionButton: fab,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, {required bool showMenuIcon}) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      automaticallyImplyLeading: showMenuIcon,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        const SizedBox(width: 8),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
