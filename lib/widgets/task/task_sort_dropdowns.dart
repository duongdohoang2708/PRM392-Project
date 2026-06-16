import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';

class TaskSortDropdowns extends StatelessWidget {
  const TaskSortDropdowns({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TaskProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
            _buildDropdownButton(
              context: context, 
              icon: Icons.folder_open_outlined, 
              label: 'Project',
              value: provider.filterProject,
              items: provider.availableProjects,
              onChanged: (val) {
                if (val != null) provider.setFilterProject(val);
              },
            ),
            const SizedBox(width: 8),
            _buildDropdownButton(
              context: context, 
              icon: Icons.flag_outlined, 
              label: 'Priority',
              value: provider.filterPriority,
              items: provider.availablePriorities,
              onChanged: (val) {
                if (val != null) provider.setFilterPriority(val);
              },
            ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildDropdownButton(
              context: context, 
              icon: Icons.schedule, 
              label: 'Status',
              value: provider.filterStatus,
              items: provider.availableStatuses,
              onChanged: (val) {
                if (val != null) provider.setFilterStatus(val);
              },
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(
              'Sort by: ',
              style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.sortBy,
                icon: const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
                style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                isDense: true,
                onChanged: (val) {
                  if (val != null) {
                    provider.setSortBy(val);
                  }
                },
                items: ['Due Date', 'Priority', 'Name'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownButton({
    required BuildContext context, 
    required IconData icon, 
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
          style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
          isDense: true,
          onChanged: onChanged,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (val == value) Icon(icon, size: 14, color: AppColors.primary),
                  if (val == value) const SizedBox(width: 4),
                  Text(val.startsWith('All') ? label : val),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
