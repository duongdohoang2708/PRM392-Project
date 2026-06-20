import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../task/task_list_item.dart';

class UpNextTasksSection extends StatelessWidget {
  const UpNextTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    // Get up to 4 upcoming tasks from Today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingTasks = taskProvider.tasks.where((t) {
      if (t.dueDate == null) return false;
      final tDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return tDate.isAtSameMomentAs(today);
    }).toList();

    upcomingTasks.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    final displayTasks = upcomingTasks.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Up Next',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/task-list');
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (displayTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No upcoming tasks. Enjoy your day!",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ...displayTasks.map((task) {
          return TaskListItem(
            key: ValueKey(task.id),
            task: task,
            disableCompleteAnimation: true,
            hideActions: true,
          );
        }),
      ],
    );
  }
}
