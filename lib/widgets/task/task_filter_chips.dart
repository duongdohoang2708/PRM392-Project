import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';

class TaskFilterChips extends StatelessWidget {
  const TaskFilterChips({super.key});

  final List<Map<String, dynamic>> _filters = const [
    {'label': 'Today', 'activeColor': AppColors.accentPink, 'activeTextColor': AppColors.textPrimary, 'inactiveBg': Colors.transparent},
    {'label': 'Tomorrow', 'activeColor': AppColors.border, 'activeTextColor': AppColors.textPrimary, 'inactiveBg': Colors.transparent},
    {'label': 'This Week', 'activeColor': AppColors.accentYellow, 'activeTextColor': AppColors.textPrimary, 'inactiveBg': Colors.transparent},
    {'label': 'Scheduled', 'activeColor': AppColors.primaryLight, 'activeTextColor': AppColors.textPrimary, 'inactiveBg': Colors.transparent},
    {'label': 'Unscheduled', 'activeColor': AppColors.border, 'activeTextColor': AppColors.textPrimary, 'inactiveBg': Colors.transparent},
    {'label': 'Important', 'activeColor': AppColors.accentPeach, 'activeTextColor': AppColors.textPrimary, 'inactiveBg': Colors.transparent},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilter = context.watch<TaskProvider>().activeFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final filter = _filters[index];
          final isSelected = activeFilter == filter['label'];
          
          Color bgColor = isSelected ? filter['activeColor'] : Colors.transparent;
          Color borderColor = isSelected ? Colors.transparent : AppColors.border;
          Color textColor = isSelected ? filter['activeTextColor'] : AppColors.textSecondary;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                final provider = context.read<TaskProvider>();
                if (provider.activeFilter == filter['label']) {
                  provider.setActiveFilter(''); // Deselect
                } else {
                  provider.setActiveFilter(filter['label']);
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 0 : 1, // Remove border width visually if selected
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: filter['activeColor'].withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Text(
                  filter['label'],
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
