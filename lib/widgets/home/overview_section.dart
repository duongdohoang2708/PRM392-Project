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
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 900 ? 4 : 2;
            // Wider 2-column rails (tablet portrait) get a higher ratio → shorter cards.
            final aspectRatio = width >= 900
                ? 3.0
                : width >= 560
                    ? 4.2
                    : 2.8;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: [
                TintedAccentCard(
                  accentColor: AppColors.statBlue,
                  icon: Icons.task_alt,
                  label: 'Tasks Today',
                  value: '${taskProvider.tasksTodayCount}',
                ),
                TintedAccentCard(
                  accentColor: AppColors.statGreen,
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  value: '${taskProvider.completedTodayCount}',
                ),
                TintedAccentCard(
                  accentColor: AppColors.statYellow,
                  icon: Icons.pending_actions_outlined,
                  label: 'Remaining',
                  value: '${taskProvider.remainingTodayCount}',
                ),
                TintedAccentCard(
                  accentColor: AppColors.statRed,
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
