import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/activity_mode_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';

class GreetingSection extends StatelessWidget {
  final String? subtitle;

  const GreetingSection({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final activityModes = context.watch<ActivityModeProvider>();
    final definition = activityModes.activeDefinition;
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good morning,';
    } else if (hour < 18) {
      greeting = 'Good afternoon,';
    } else {
      greeting = 'Good evening,';
    }

    final resolvedSubtitle = subtitle ??
        switch (hour) {
          < 12 => "Let's make today productive!",
          < 18 => 'Keep up the great work!',
          _ => 'Time to wind down and reflect!',
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLightTintOf(context, alpha: 0.35),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.projectBorderOf(context, AppColors.primaryOf(context)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                definition.icon,
                size: 16,
                color: AppColors.primaryDarkOf(context),
              ),
              const SizedBox(width: 6),
              Text(
                definition.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkOf(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          greeting,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.fullName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryOf(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          resolvedSubtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.projectAccentOf(context, AppColors.primaryDarkOf(context)),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
