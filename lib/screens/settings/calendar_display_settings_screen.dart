import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class CalendarDisplaySettingsScreen extends StatelessWidget {
  const CalendarDisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: 'Calendar & Time',
      showBack: true,
      child: Column(
        children: [
          StatPanel(
            title: 'Week starts on',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Controls the calendar grid and weekly streak row.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SettingsOptionCard(
                  title: 'Monday',
                  subtitle: 'Mon – Sun columns',
                  icon: Icons.view_week_outlined,
                  selected: settings.weekStartsOnMonday,
                  onTap: () async {
                    await settings.setWeekStartsOnMonday(true);
                    if (context.mounted) {
                      AppNotification.showSuccess(
                        context,
                        'Week now starts on Monday.',
                      );
                    }
                  },
                ),
                SettingsOptionCard(
                  title: 'Sunday',
                  subtitle: 'Sun – Sat columns',
                  icon: Icons.view_week_outlined,
                  selected: !settings.weekStartsOnMonday,
                  onTap: () async {
                    await settings.setWeekStartsOnMonday(false);
                    if (context.mounted) {
                      AppNotification.showSuccess(
                        context,
                        'Week now starts on Sunday.',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StatPanel(
            title: 'Time format',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applies to task due times, reminders, and focus history.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SettingsOptionCard(
                  title: '12-hour',
                  subtitle: 'Example: 2:30 PM',
                  icon: Icons.schedule_outlined,
                  selected: settings.use12HourClock,
                  onTap: () async {
                    await settings.setUse12HourClock(true);
                    if (context.mounted) {
                      AppNotification.showSuccess(
                        context,
                        'Time format set to 12-hour.',
                      );
                    }
                  },
                ),
                SettingsOptionCard(
                  title: '24-hour',
                  subtitle: 'Example: 14:30',
                  icon: Icons.schedule_outlined,
                  selected: !settings.use12HourClock,
                  onTap: () async {
                    await settings.setUse12HourClock(false);
                    if (context.mounted) {
                      AppNotification.showSuccess(
                        context,
                        'Time format set to 24-hour.',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
