import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 600 ? 4 : 2;
            final aspectRatio = constraints.maxWidth >= 600 ? 3.0 : 2.5;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: [
                _buildStatCard(
                  title: 'Tasks Today',
                  value: '${taskProvider.tasksTodayCount}',
                  icon: Icons.task_alt,
                  color: const Color(0xFF0277BD),
                  bgColor: const Color(0xFF0277BD).withAlpha(50),
                ),
                _buildStatCard(
                  title: 'Completed',
                  value: '${taskProvider.completedTodayCount}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.primaryDark,
                  bgColor: AppColors.primaryLight.withAlpha(100),
                ),
                _buildStatCard(
                  title: 'Remaining',
                  value: '${taskProvider.remainingTodayCount}',
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.accentYellow,
                  bgColor: AppColors.accentYellow.withAlpha(50),
                ),
                _buildStatCard(
                  title: 'Overdue',
                  value: '${taskProvider.overdueCount}',
                  icon: Icons.event_busy_outlined,
                  color: const Color(0xFFD32F2F),
                  bgColor: const Color(0xFFD32F2F).withAlpha(50),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
