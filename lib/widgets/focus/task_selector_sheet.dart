import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../providers/focus_provider.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../theme/app_colors.dart';
import '../common/app_dropdown.dart';

class TaskSelectorSheet extends StatefulWidget {
  const TaskSelectorSheet({super.key});

  @override
  State<TaskSelectorSheet> createState() => _TaskSelectorSheetState();
}

class _TaskSelectorSheetState extends State<TaskSelectorSheet> {
  String _selectedSmartList = 'All';
  String _selectedProject = 'All';
  String _selectedPriority = 'All';

  final List<String> _smartListOptions = [
    'All',
    'Today',
    'Tomorrow',
    'This Week',
    'Scheduled',
    'Unscheduled',
    'Important'
  ];
  final List<String> _priorityOptions = ['All', 'High', 'Medium', 'Low'];

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final focusProvider = context.read<FocusProvider>();

    // Get available projects
    final List<String> projectOptions = ['All', ...taskProvider.availableProjects.where((p) => p != 'All Projects')];

    // Filter tasks
    var filteredTasks = taskProvider.tasks.where((t) => !t.isCompleted).toList();

    if (_selectedSmartList != 'All') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final endOfWeek = today.add(Duration(days: 7 - today.weekday));

      filteredTasks = filteredTasks.where((t) {
        if (_selectedSmartList == 'Important') return t.isImportant;
        if (_selectedSmartList == 'Unscheduled') return t.dueDate == null;
        if (_selectedSmartList == 'Scheduled') return t.dueDate != null;

        if (t.dueDate == null) return false;
        final dueDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);

        switch (_selectedSmartList) {
          case 'Today':
            return dueDate.isAtSameMomentAs(today);
          case 'Tomorrow':
            return dueDate.isAtSameMomentAs(tomorrow);
          case 'This Week':
            return dueDate.isAtSameMomentAs(today) ||
                (dueDate.isAfter(today) &&
                    dueDate.isBefore(endOfWeek.add(const Duration(days: 1))));
          default:
            return true;
        }
      }).toList();
    }

    if (_selectedProject != 'All') {
      filteredTasks = filteredTasks.where((t) => t.project == _selectedProject).toList();
    }

    if (_selectedPriority != 'All') {
      filteredTasks = filteredTasks.where((t) => t.priority == _selectedPriority).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 0),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Task',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown(
                  value: _selectedSmartList,
                  items: _smartListOptions,
                  onChanged: (val) => setState(() => _selectedSmartList = val!),
                  icon: Icons.calendar_today,
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  value: _selectedProject,
                  items: projectOptions,
                  onChanged: (val) => setState(() => _selectedProject = val!),
                  icon: Icons.folder_outlined,
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  value: _selectedPriority,
                  items: _priorityOptions,
                  onChanged: (val) => setState(() => _selectedPriority = val!),
                  icon: Icons.flag_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks match your filters.',
                      style: TextStyle(color: AppColors.textSecondaryOf(context)),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return ListTile(
                        leading: Icon(
                          Icons.task_alt,
                          color: task.priority == 'High'
                              ? AppColors.accentPeach
                              : task.priority == 'Medium'
                                  ? AppColors.accentYellow
                                  : AppColors.primary,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            color: AppColors.textPrimaryOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.project,
                              style: TextStyle(
                                color: AppColors.textSecondaryOf(context),
                                fontSize: 12,
                              ),
                            ),
                            if (task.dueDate != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 10, color: AppColors.textSecondaryOf(context).withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppDateTimeFormat.slashDate(task.dueDate!),
                                    style: TextStyle(
                                      color: AppColors.textSecondaryOf(context).withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: task.isImportant
                            ? const Icon(Icons.star, color: AppColors.accentYellow, size: 20)
                            : null,
                        onTap: () {
                          focusProvider.setSelectedTask(task);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    // Ensure value is in items, otherwise fallback to the first item.
    final safeValue = items.contains(value) ? value : items.first;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: AppDropdown<String>(
        value: safeValue,
        isDense: true,
        icon: Icon(Icons.expand_more, color: AppColors.textSecondaryOf(context), size: 20),
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textPrimaryOf(context),
          fontWeight: FontWeight.w500,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item == safeValue) ...[
                  Icon(icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                ],
                Text(item),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
