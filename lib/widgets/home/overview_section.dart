import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../common/tinted_accent_card.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today Overview',
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
            final aspectRatio = constraints.maxWidth >= 600 ? 3.0 : 2.5;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: [
                TintedAccentCard(
                  accentColor: const Color(0xFF0277BD),
                  icon: Icons.task_alt,
                  label: 'Tasks Today',
                  value: '${taskProvider.tasksTodayCount}',
                ),
                TintedAccentCard(
                  accentColor: AppColors.primaryDarkOf(context),
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  value: '${taskProvider.completedTodayCount}',
                  lightBgAlpha: 0.52,
                  darkBgAlpha: 0.26,
                ),
                TintedAccentCard(
                  accentColor: AppColors.accentYellow,
                  icon: Icons.pending_actions_outlined,
                  label: 'Remaining',
                  value: '${taskProvider.remainingTodayCount}',
                ),
                TintedAccentCard(
                  accentColor: const Color(0xFFD32F2F),
                  icon: Icons.event_busy_outlined,
                  label: 'Overdue',
                  value: '${taskProvider.overdueCount}',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
