import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    String subtitle;

    if (hour < 12) {
      greeting = 'Good morning,';
      subtitle = "Let's make today productive!";
    } else if (hour < 18) {
      greeting = 'Good afternoon,';
      subtitle = "Keep up the great work!";
    } else {
      greeting = 'Good evening,';
      subtitle = "Time to wind down and reflect!";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Dương',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
