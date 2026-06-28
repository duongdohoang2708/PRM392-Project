import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_mode.dart';
import '../../providers/activity_mode_provider.dart';
import '../../theme/activity_mode_palette.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/common/app_time_picker.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class ActivityModeDetailScreen extends StatelessWidget {
  final ActivityModeId modeId;

  const ActivityModeDetailScreen({super.key, required this.modeId});

  @override
  Widget build(BuildContext context) {
    final activityModes = context.watch<ActivityModeProvider>();
    final definition = ActivityModes.definitionFor(modeId);
    final schedule = activityModes.scheduleFor(modeId);
    final brightness = Theme.of(context).brightness;
    final palette = ActivityModePalette.forMode(modeId, brightness: brightness);
    final isActive = activityModes.activeModeId == modeId;
    final isManualActive =
        activityModes.manualOverrideActive && activityModes.manualModeId == modeId;

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: definition.name,
      showBack: true,
      child: Column(
        children: [
          StatPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.description,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Color preview',
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ColorSwatch(label: 'Primary', color: palette.primary),
                    _ColorSwatch(label: 'Accent', color: palette.primaryDark),
                    _ColorSwatch(label: 'Background', color: palette.background),
                    _ColorSwatch(label: 'Surface', color: palette.surface),
                    _ColorSwatch(label: 'Text', color: palette.textPrimary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (modeId != ActivityModeId.defaultMode)
            StatPanel(
              title: 'Schedule',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When enabled, this mode activates automatically during the set hours.',
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SettingsSwitchTile(
                    icon: Icons.alarm_outlined,
                    title: 'Enable schedule',
                    subtitle: schedule.enabled
                        ? activityModes.scheduleLabelFor(modeId)
                        : 'This mode will not auto-activate',
                    value: schedule.enabled,
                    onChanged: (enabled) async {
                      await activityModes.updateModeSchedule(
                        modeId,
                        schedule.copyWith(enabled: enabled),
                      );
                      if (context.mounted) {
                        AppNotification.showSuccess(
                          context,
                          enabled ? 'Schedule enabled.' : 'Schedule disabled.',
                        );
                      }
                    },
                  ),
                  if (schedule.enabled) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Divider(
                        height: 1,
                        color: AppColors.borderOf(context),
                      ),
                    ),
                    _ScheduleTimeRow(
                      label: 'From',
                      time: schedule.start,
                      onTap: () => _pickTime(context, activityModes, isStart: true),
                    ),
                    _ScheduleTimeRow(
                      label: 'Until',
                      time: schedule.end,
                      onTap: () => _pickTime(context, activityModes, isStart: false),
                    ),
                  ],
                ],
              ),
            ),
          if (modeId != ActivityModeId.defaultMode) const SizedBox(height: 16),
          StatPanel(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await activityModes.activateModeManually(modeId);
                      if (context.mounted) {
                        AppNotification.showSuccess(
                          context,
                          '${definition.name} activated.',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOf(context),
                      foregroundColor: AppColors.textPrimaryOf(context),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Text(
                      isActive && isManualActive
                          ? 'Currently active'
                          : 'Activate now',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (isManualActive) ...[
                  const SizedBox(height: 10),
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
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    ActivityModeProvider activityModes, {
    required bool isStart,
  }) async {
    final schedule = activityModes.scheduleFor(modeId);
    final initial = isStart ? schedule.start : schedule.end;
    final picked = await showAppTimePicker(context, initialTime: initial);
    if (picked == null) return;

    await activityModes.updateModeSchedule(
      modeId,
      schedule.copyWith(
        start: isStart ? picked : schedule.start,
        end: isStart ? schedule.end : picked,
      ),
    );

    if (context.mounted) {
      AppNotification.showSuccess(context, 'Schedule updated.');
    }
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorSwatch({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondaryOf(context),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ScheduleTimeRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _ScheduleTimeRow({
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
