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
          'Overview',
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
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  title: 'Tasks Today',
                  value: '${taskProvider.tasksTodayCount}',
                  icon: Icons.task_alt,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight.withAlpha(100),
                ),
                _buildStatCard(
                  title: 'Completed',
                  value: '${taskProvider.completedCount}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.accentPeach,
                  bgColor: AppColors.accentPeach.withAlpha(50),
                ),
                _buildStatCard(
                  title: 'Focus Time',
                  value: '2h 15m', // Static mock for now
                  icon: Icons.timer_outlined,
                  color: AppColors.accentYellow,
                  bgColor: AppColors.accentYellow.withAlpha(50),
                ),
                _buildStatCard(
                  title: 'Productivity',
                  value: '${taskProvider.productivityScore}%',
                  icon: Icons.trending_up,
                  color: AppColors.primaryDark,
                  bgColor: AppColors.primaryLight.withAlpha(150),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
