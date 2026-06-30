import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/common/app_dropdown.dart';
import '../../widgets/common/app_time_picker.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final masterEnabled = settings.notificationsEnabled;

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: 'Notification Settings',
      showBack: true,
      child: Column(
        children: [
          SettingsSection(
            title: 'General',
            children: [
              SettingsSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                subtitle: 'Master switch for all alerts',
                value: masterEnabled,
                onChanged: (enabled) async {
                  await settings.setNotificationsEnabled(enabled);
                  if (context.mounted) {
                    AppNotification.showInfo(
                      context,
                      enabled
                          ? 'Notifications enabled.'
                          : 'All notifications paused.',
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Categories',
            children: [
              SettingsSwitchTile(
                icon: Icons.alarm_outlined,
                title: 'Task reminders',
                subtitle: 'Due dates, reminders, and task digests',
                value: settings.taskRemindersEnabled,
                onChanged: masterEnabled ? (enabled) async {
                        await settings.setTaskRemindersEnabled(enabled);
                        if (context.mounted) {
                          AppNotification.showInfo(
                            context,
                            enabled
                                ? 'Task reminders enabled.'
                                : 'Task reminders paused.',
                          );
                        }
                      }
                    : null,
              ),
              SettingsSwitchTile(
                icon: Icons.insights_outlined,
                title: 'Goals & insights',
                subtitle: 'Streaks, freeze credits, stats milestones',
                value: settings.goalsInsightsEnabled,
                onChanged: masterEnabled ? (enabled) async {
                        await settings.setGoalsInsightsEnabled(enabled);
                        if (context.mounted) {
                          AppNotification.showInfo(
                            context,
                            enabled
                                ? 'Goals & insights enabled.'
                                : 'Goals & insights paused.',
                          );
                        }
                      }
                    : null,
              ),
              SettingsSwitchTile(
                icon: Icons.emoji_events_outlined,
                title: 'Achievements',
                subtitle: 'Unlocks and near-unlock nudges',
                value: settings.achievementsEnabled,
                onChanged: masterEnabled ? (enabled) async {
                        await settings.setAchievementsEnabled(enabled);
                        if (context.mounted) {
                          AppNotification.showInfo(
                            context,
                            enabled
                                ? 'Achievement alerts enabled.'
                                : 'Achievement alerts paused.',
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          StatPanel(
            title: 'Quiet hours',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task reminders will not fire during quiet hours. Goals and achievements are not affected.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SettingsSwitchTile(
                  icon: Icons.bedtime_outlined,
                  title: 'Enable quiet hours',
                  subtitle: masterEnabled && settings.quietHoursEnabled
                      ? '${AppDateTimeFormat.timeOfDay(settings.quietHoursStart)} – ${AppDateTimeFormat.timeOfDay(settings.quietHoursEnd)}'
                      : 'Pause task reminders overnight',
                  value: settings.quietHoursEnabled,
                  onChanged: masterEnabled
                      ? (enabled) async {
                          await settings.setQuietHoursEnabled(enabled);
                          if (context.mounted) {
                            AppNotification.showInfo(
                              context,
                              enabled
                                  ? 'Quiet hours enabled.'
                                  : 'Quiet hours disabled.',
                            );
                          }
                        }
                      : null,
                ),
                if (masterEnabled && settings.quietHoursEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      color: AppColors.borderOf(context),
                    ),
                  ),
                  _QuietHoursTimeRow(
                    label: 'From',
                    time: settings.quietHoursStart,
                    onTap: () => _pickQuietHour(
                      context,
                      settings,
                      isStart: true,
                    ),
                  ),
                  _QuietHoursTimeRow(
                    label: 'Until',
                    time: settings.quietHoursEnd,
                    onTap: () => _pickQuietHour(
                      context,
                      settings,
                      isStart: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          StatPanel(
            title: 'Default Reminders',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Used for new tasks that have a due date but no reminder set yet. Existing task reminders are not changed.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _DefaultReminderRow(
                  label: 'Timed tasks',
                  value: settings.defaultTimedReminder,
                  options: settings.timedReminderOptions,
                  onChanged: (value) async {
                    await settings.setDefaultTimedReminder(value);
                    if (context.mounted) {
                      AppNotification.showSuccess(
                        context,
                        'Default timed reminder updated.',
                      );
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Divider(
                    height: 1,
                    color: AppColors.borderOf(context),
                  ),
                ),
                _DefaultReminderRow(
                  label: 'All-day tasks',
                  value: settings.defaultAllDayReminder,
                  options: settings.allDayReminderOptions,
                  onChanged: (value) async {
                    await settings.setDefaultAllDayReminder(value);
                    if (context.mounted) {
                      AppNotification.showSuccess(
                        context,
                        'Default all-day reminder updated.',
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

  Future<void> _pickQuietHour(
    BuildContext context,
    SettingsProvider settings, {
    required bool isStart,
  }) async {
    final initial = isStart ? settings.quietHoursStart : settings.quietHoursEnd;
    final picked = await showAppTimePicker(
      context,
      initialTime: initial,
    );
    if (picked == null) return;

    if (isStart) {
      await settings.setQuietHoursStart(picked);
    } else {
      await settings.setQuietHoursEnd(picked);
    }

    if (context.mounted) {
      AppNotification.showSuccess(context, 'Quiet hours updated.');
    }
  }
}

class _QuietHoursTimeRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _QuietHoursTimeRow({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                AppDateTimeFormat.timeOfDay(time),
                style: TextStyle(
                  color: AppColors.primaryDarkOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondaryOf(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultReminderRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DefaultReminderRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: AppDropdown<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              alignment: AlignmentDirectional.centerEnd,
              selectedItemBuilder: (context) {
                return options
                    .map(
                      (option) => AppDropdown.menuChild(
                        Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    )
                    .toList();
              },
              items: options
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: AppDropdown.menuChild(Text(option)),
                    ),
                  )
                  .toList(),
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ],
      ),
    );
  }
}
