import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_mode.dart';
import '../../providers/activity_mode_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class ActivityModesScreen extends StatelessWidget {
  const ActivityModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activityModes = context.watch<ActivityModeProvider>();
    final active = activityModes.activeDefinition;

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: 'Activity Modes',
      showBack: true,
      child: Column(
        children: [
          StatPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active now',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightTintOf(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        active.icon,
                        color: AppColors.primaryDarkOf(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active.name,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            activityModes.activeSourceLabel,
                            style: TextStyle(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (activityModes.manualOverrideActive) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await activityModes.clearManualOverride();
                        if (context.mounted) {
                          AppNotification.showInfo(
                            context,
                            'Returned to automatic scheduling.',
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDarkOf(context),
                        side: BorderSide(color: AppColors.borderOf(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Return to automatic',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Scheduling',
            children: [
              SettingsSwitchTile(
                icon: Icons.schedule_outlined,
                title: 'Automatic schedule',
                subtitle: activityModes.autoScheduleEnabled
                    ? 'Modes switch by time'
                    : 'Stay on Default unless manual',
                value: activityModes.autoScheduleEnabled,
                onChanged: (enabled) async {
                  await activityModes.setAutoScheduleEnabled(enabled);
                  if (context.mounted) {
                    AppNotification.showInfo(
                      context,
                      enabled
                          ? 'Automatic scheduling enabled.'
                          : 'Automatic scheduling disabled.',
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Modes',
            children: [
              for (final preset in ActivityModes.presets)
                SettingsNavTile(
                  icon: preset.icon,
                  title: preset.name,
                  subtitle: activityModes.scheduleLabelFor(preset.id),
                  trailing: activityModes.activeModeId == preset.id
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.primaryDarkOf(context),
                          size: 22,
                        )
                      : null,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/settings/activity-modes/detail',
                    arguments: {'modeId': preset.id.name},
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
