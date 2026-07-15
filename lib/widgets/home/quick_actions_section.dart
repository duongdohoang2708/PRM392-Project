import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/tinted_accent_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  static const _actions = <_QuickAction>[
    _QuickAction(
      icon: Icons.add_task,
      title: 'Create Task',
      rainbowIndex: 0,
      route: '/create-task',
    ),
    _QuickAction(
      icon: Icons.timer,
      title: 'Start Focus',
      rainbowIndex: 1,
      route: '/focus',
    ),
    _QuickAction(
      icon: Icons.create_new_folder_outlined,
      title: 'New Project',
      rainbowIndex: 2,
      route: '/create-project',
    ),
    _QuickAction(
      icon: Icons.calendar_month_outlined,
      title: 'Calendar',
      rainbowIndex: 3,
      route: '/calendar',
    ),
    _QuickAction(
      icon: Icons.format_list_bulleted,
      title: 'Task List',
      rainbowIndex: 4,
      route: '/task-list',
    ),
    _QuickAction(
      icon: Icons.flag_outlined,
      title: 'Goals',
      rainbowIndex: 5,
      route: '/goals',
    ),
  ];

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
            final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: _actions
                  .map((action) => _actionCard(context, action))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context, _QuickAction action) {
    final baseColor =
        AppColors.rainbowPalette[action.rainbowIndex % AppColors.rainbowPalette.length];

    return Builder(
      builder: (buttonContext) => TintedAccentCard(
        variant: TintedAccentCardVariant.action,
        accentColor: baseColor,
        icon: action.icon,
        label: action.title,
        lightBgAlpha: 0.28,
        darkBgAlpha: 0.28,
        onTap: () {
          if (action.route != null) {
            Navigator.pushNamed(context, action.route!);
          }
        },
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final int rainbowIndex;
  final String? route;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.rainbowIndex,
    this.route,
  });
}
