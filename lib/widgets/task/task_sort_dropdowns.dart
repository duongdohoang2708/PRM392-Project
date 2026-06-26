import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../common/app_dropdown.dart';

class TaskSortDropdowns extends StatelessWidget {
  const TaskSortDropdowns({super.key});

  static const double _wideBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    final projectFilter = _buildDropdownButton(
      context: context,
      icon: Icons.folder_open_outlined,
      label: 'Project',
      value: provider.filterProject,
      items: provider.availableProjects,
      onChanged: (val) {
        if (val != null) provider.setFilterProject(val);
      },
    );
    final priorityFilter = _buildDropdownButton(
      context: context,
      icon: Icons.flag_outlined,
      label: 'Priority',
      value: provider.filterPriority,
      items: provider.availablePriorities,
      onChanged: (val) {
        if (val != null) provider.setFilterPriority(val);
      },
    );
    final statusFilter = _buildDropdownButton(
      context: context,
      icon: Icons.schedule,
      label: 'Status',
      value: provider.filterStatus,
      items: provider.availableStatuses,
      onChanged: (val) {
        if (val != null) provider.setFilterStatus(val);
      },
    );
    final sortControl = _buildSortControl(context, provider);

    if (isWide) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            projectFilter,
            const SizedBox(width: 8),
            priorityFilter,
            const SizedBox(width: 8),
            statusFilter,
            const SizedBox(width: 16),
            sortControl,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              projectFilter,
              const SizedBox(width: 8),
              priorityFilter,
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            statusFilter,
            const SizedBox(width: 16),
            sortControl,
          ],
        ),
      ],
    );
  }

  Widget _buildSortControl(BuildContext context, TaskProvider provider) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sort by: ',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        AppDropdown<String>(
          value: provider.sortBy,
          isDense: true,
          icon: Icon(
            Icons.expand_more,
            size: 16,
            color: AppColors.textSecondaryOf(context),
          ),
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
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
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppDropdown<String>(
        value: value,
        isDense: true,
        icon: Icon(
          Icons.expand_more,
          size: 16,
          color: AppColors.textSecondaryOf(context),
        ),
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimaryOf(context),
        ),
        onChanged: onChanged,
        items: items.map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (val == value) ...[
                  Icon(icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                ],
                Text(val.startsWith('All') ? label : val),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
