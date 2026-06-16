import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';

class SmartListsSection extends StatelessWidget {
  const SmartListsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Lists',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth >= 900) {
              crossAxisCount = 6;
            } else if (constraints.maxWidth >= 600) {
              crossAxisCount = 3;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildListFilter(
                  context,
                  Icons.wb_sunny_outlined,
                  'Today',
                  taskProvider.getCountForFilter('Today').toString(),
                  AppColors.accentPink,
                ),
                _buildListFilter(
                  context,
                  Icons.event_outlined,
                  'Tomorrow',
                  taskProvider.getCountForFilter('Tomorrow').toString(),
                  AppColors.primary,
                ),
                _buildListFilter(
                  context,
                  Icons.date_range,
                  'This Week',
                  taskProvider.getCountForFilter('This Week').toString(),
                  AppColors.accentYellow,
                ),
                _buildListFilter(
                  context,
                  Icons.schedule,
                  'Scheduled',
                  taskProvider.getCountForFilter('Scheduled').toString(),
                  AppColors.primaryDark,
                ),
                _buildListFilter(
                  context,
                  Icons.event_busy_outlined,
                  'Unscheduled',
                  taskProvider.getCountForFilter('Unscheduled').toString(),
                  AppColors.border,
                ),
                _buildListFilter(
                  context,
                  Icons.star_outline,
                  'Important',
                  taskProvider.getCountForFilter('Important').toString(),
                  AppColors.accentPeach,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildListFilter(
    BuildContext context,
    IconData icon,
    String title,
    String count,
    Color iconColor,
  ) {
    return InkWell(
      onTap: () {
        context.read<TaskProvider>().setActiveFilter(title);
        Navigator.pushNamed(context, '/task-list');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
