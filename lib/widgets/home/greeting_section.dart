import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';

class GreetingSection extends StatelessWidget {
  final String? subtitle;

  const GreetingSection({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
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
