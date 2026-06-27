import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../project/create_project_popup.dart';
import '../common/app_popup_transition.dart';
import '../custom_snackbar.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryOf(context),
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
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.add_task,
                  title: 'Create Task',
                  color: AppColors.primaryDark,
                  bgColor: AppColors.primaryLightTintOf(context, alpha: 0.39),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.timer,
                  title: 'Start Focus',
                  color: AppColors.accentYellow,
                  bgColor: AppColors.accentYellow.withAlpha(50),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.create_new_folder_outlined,
                  title: 'New Project',
                  color: AppColors.accentPeach,
                  bgColor: AppColors.accentPeach.withAlpha(50),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Calendar',
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLightTintOf(context, alpha: 0.2),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required Color bgColor,
  }) {
    return Builder(
      builder: (buttonContext) => InkWell(
        onTap: () {
          if (title == 'Create Task') {
            Navigator.pushNamed(context, '/create-task');
          } else if (title == 'Calendar') {
            Navigator.pushNamed(context, '/calendar');
          } else if (title == 'New Project') {
            showCreateProjectPopup(
              context,
              anchor: popupAnchorFromContext(buttonContext),
            );
          } else if (title == 'Start Focus') {
            Navigator.pushNamed(context, '/focus');
          } else {
            AppNotification.showInfo(context, '$title coming soon!');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(buttonContext),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
