import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Projects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('View all projects coming soon'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildProjectCard(
                title: 'PRM392 Mobile App',
                taskCount:
                    '${taskProvider.getProjectTaskCount('PRM392 Mobile App')} tasks',
                progress: taskProvider.getProjectProgress('PRM392 Mobile App'),
                color: AppColors.primaryDark,
                bgColor: AppColors.primaryLight.withAlpha(50),
              ),
              const SizedBox(width: 16),
              _buildProjectCard(
                title: 'Learn Flutter',
                taskCount:
                    '${taskProvider.getProjectTaskCount('Learn Flutter')} tasks',
                progress: taskProvider.getProjectProgress('Learn Flutter'),
                color: AppColors.accentPeach,
                bgColor: AppColors.accentPeach.withAlpha(50),
              ),
              const SizedBox(width: 16),
              _buildProjectCard(
                title: 'Personal Goals',
                taskCount:
                    '${taskProvider.getProjectTaskCount('Personal Goals')} tasks',
                progress: taskProvider.getProjectProgress('Personal Goals'),
                color: AppColors.accentYellow,
                bgColor: AppColors.accentYellow.withAlpha(50),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard({
    required String title,
    required String taskCount,
    required double progress,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withAlpha((255 * 0.03).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.folder_outlined, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    taskCount,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% completed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
