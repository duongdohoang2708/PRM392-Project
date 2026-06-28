import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../project/create_project_popup.dart';
import '../common/app_popup_transition.dart';
import '../common/tinted_accent_card.dart';
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
                _actionCard(
                  context,
                  icon: Icons.add_task,
                  title: 'Create Task',
                  color: AppColors.primaryDark,
                  lightBgAlpha: 0.39,
                ),
                _actionCard(
                  context,
                  icon: Icons.timer,
                  title: 'Start Focus',
                  color: AppColors.accentYellow,
                  lightBgAlpha: 0.20,
                ),
                _actionCard(
                  context,
                  icon: Icons.create_new_folder_outlined,
                  title: 'New Project',
                  color: AppColors.accentPeach,
                  lightBgAlpha: 0.20,
                ),
                _actionCard(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Calendar',
                  color: AppColors.primary,
                  lightBgAlpha: 0.20,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required double lightBgAlpha,
  }) {
    return Builder(
      builder: (buttonContext) => TintedAccentCard(
        variant: TintedAccentCardVariant.action,
        accentColor: color,
        icon: icon,
        label: title,
        lightBgAlpha: lightBgAlpha,
        darkBgAlpha: lightBgAlpha * 0.5,
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
      ),
    );
  }
}
