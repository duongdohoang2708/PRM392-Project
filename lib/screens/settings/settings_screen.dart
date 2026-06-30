import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/activity_mode_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_icons.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/common/app_bottom_sheet.dart';
import '../../widgets/goals/rest_days_settings_sheet.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/settings/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _weekdayShort = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  String _formatFreezeDays(Set<int> weekdays) {
    if (weekdays.isEmpty) return 'None';
    final sorted = weekdays.toList()..sort();
    return sorted.map((day) => _weekdayShort[day] ?? '?').join(', ');
  }

  void _showFreezeDaysSheet(BuildContext context) {
    final goalsProvider = context.read<GoalsProvider>();
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => RestDaysSettingsSheet(
        initialRestWeekdays: goalsProvider.restWeekdays,
        onSave: (weekdays) {
          goalsProvider.setRestWeekdays(weekdays);
          AppNotification.showSuccess(
            context,
            'Freeze days updated.',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsProvider = context.watch<GoalsProvider>();
    final settings = context.watch<SettingsProvider>();
    final activityModes = context.watch<ActivityModeProvider>();
    final weekStartLabel = settings.weekStartsOnMonday ? 'Monday' : 'Sunday';
    final timeFormatLabel = settings.use12HourClock ? '12-hour' : '24-hour';

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: 'Settings',
      child: Column(
        children: [
          const SettingsAccountCard(),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingsNavTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: settings.themeModeLabel,
                onTap: () => Navigator.pushNamed(context, '/settings/theme'),
              ),
              SettingsNavTile(
                icon: Icons.tune_outlined,
                title: 'Theme Modes',
                subtitle: activityModes.activeDefinition.name,
                onTap: () =>
                    Navigator.pushNamed(context, '/settings/activity-modes'),
              ),
              SettingsNavTile(
                icon: Icons.style_outlined,
                title: 'Card appearance',
                subtitle: settings.cardAppearanceSubtitle,
                onTap: () =>
                    Navigator.pushNamed(context, '/settings/card-appearance'),
              ),
              SettingsSwitchTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Background icons',
                subtitle: settings.backgroundDecorIconsEnabled
                    ? 'Decorative icons shown'
                    : 'Plain background only',
                value: settings.backgroundDecorIconsEnabled,
                onChanged: settings.setBackgroundDecorIconsEnabled,
              ),
              SettingsNavTile(
                icon: Icons.calendar_month_outlined,
                title: 'Calendar & Time Format',
                subtitle: 'Week starts $weekStartLabel • $timeFormatLabel',
                onTap: () => Navigator.pushNamed(context, '/settings/calendar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Productivity',
            children: [
              SettingsNavTile(
                icon: Icons.timer_outlined,
                title: 'Focus Settings',
                subtitle: 'Timer durations and focus behavior',
                onTap: () => Navigator.pushNamed(context, '/settings/focus'),
              ),
              const SettingsFocusGoalTile(),
              SettingsNavTile(
                icon: AppIcons.freezeDay,
                title: 'Freeze Days',
                subtitle: _formatFreezeDays(goalsProvider.restWeekdays),
                onTap: () => _showFreezeDaysSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Notifications',
            children: [
              SettingsNavTile(
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
                subtitle: 'Alerts and default reminders',
                onTap: () =>
                    Navigator.pushNamed(context, '/settings/notifications'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
