import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';

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
      return tDate.isAtSameMomentAs(today) && !t.isCompleted;
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildTaskItem(context, task),
          );
        }),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    Color priorityColor;
    switch (task.priority) {
      case 'High':
        priorityColor = AppColors.accentPink;
        break;
      case 'Medium':
        priorityColor = AppColors.accentYellow;
        break;
      case 'Low':
        priorityColor = AppColors.primaryLight;
        break;
      default:
        priorityColor = AppColors.textSecondary;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue =
        task.dueDate != null &&
        DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        ).isBefore(today) &&
        !task.isCompleted;

    String timeStr;
    if (task.dueDate == null) {
      timeStr = 'No due date';
    } else {
      final tDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      if (isOverdue) {
        timeStr = 'Overdue, ${DateFormat('MMM d').format(task.dueDate!)}';
      } else if (tDate.isAtSameMomentAs(today)) {
        timeStr = 'Today, ${DateFormat('HH:mm').format(task.dueDate!)}';
      } else {
        timeStr = DateFormat('MMM d, HH:mm').format(task.dueDate!);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withAlpha((255 * 0.02).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.read<TaskProvider>().toggleTaskCompletion(task.id);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.primary
                      : AppColors.textSecondary.withAlpha(100),
                  width: 2,
                ),
                color: task.isCompleted
                    ? AppColors.primary
                    : Colors.transparent,
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      task.dueDate == null
                          ? Icons.calendar_today_outlined
                          : Icons.schedule,
                      size: 14,
                      color: isOverdue
                          ? Colors.redAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: isOverdue
                            ? Colors.redAccent
                            : AppColors.textSecondary,
                        fontWeight: isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: priorityColor,
            ),
          ),
        ],
      ),
    );
  }
}
