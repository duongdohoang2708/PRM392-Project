import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';

class TaskFilterChips extends StatelessWidget {
  const TaskFilterChips({super.key});

  final List<String> _filters = const [
    'Today',
    'Tomorrow',
    'This Week',
    'Scheduled',
    'Unscheduled',
    'Important',
  ];

  static const List<Color> _rainbowColors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFFFF9F43), // Orange
    Color(0xFFFFD166), // Yellow
    Color(0xFF06D6A0), // Green
    Color(0xFF4D96FF), // Blue
    Color(0xFF5D5FEF), // Indigo
    Color(0xFFB556EB), // Violet
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilter = context.watch<TaskProvider>().activeFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final filterLabel = _filters[index];
          final isSelected = activeFilter == filterLabel;
          final activeColor = _rainbowColors[index % _rainbowColors.length];

          Color bgColor = isSelected
              ? activeColor
              : Colors.transparent;
          Color borderColor = isSelected
              ? Colors.transparent
              : AppColors.border;
          Color textColor = isSelected
              ? Colors.white
              : AppColors.textSecondaryOf(context);

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                final provider = context.read<TaskProvider>();
                if (provider.activeFilter == filterLabel) {
                  provider.setActiveFilter(''); // Deselect
                } else {
                  provider.setActiveFilter(filterLabel);
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected
                        ? 0
                        : 1, // Remove border width visually if selected
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filterLabel,
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
