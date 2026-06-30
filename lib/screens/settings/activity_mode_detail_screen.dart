import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_mode.dart';
import '../../providers/activity_mode_provider.dart';
import '../../theme/activity_mode_palette.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/common/animations/app_popup_transition.dart';
import '../../widgets/common/app_time_picker.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/settings/theme_mode_hero_card.dart';
import '../../widgets/settings/turn_on_mode_duration_popup.dart';
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
    final isDefault = modeId == ActivityModeId.defaultMode;
    final isModeRunning = activityModes.isModeRunningFor(modeId);
    final heroStatus = activityModes.heroStatusLabelFor(modeId);

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: definition.name,
      showBack: true,
      showPageTitle: false,
      child: Column(
        children: [
          ThemeModeHeroCard(
            modeId: modeId,
            icon: definition.icon,
            name: definition.name,
            statusLabel: heroStatus,
            isModeRunning: isModeRunning,
            showTurnOnOff: !isDefault,
            onTurnOn: isDefault
                ? null
                : () => _handleTurnOn(context, activityModes, definition),
            onTurnOff: isDefault
                ? null
                : () => _handleTurnOff(context, activityModes),
          ),
          const SizedBox(height: 16),
          if (modeId != ActivityModeId.defaultMode)
            StatPanel(
              title: 'Schedule',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When enabled, this mode activates automatically during the set hours. Two modes cannot share the exact same start and end (e.g. both 1 PM–4 PM).',
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
                      final error = await activityModes.updateModeSchedule(
                        modeId,
                        schedule.copyWith(enabled: enabled),
                      );
                      if (!context.mounted) return;
                      if (error != null) {
                        AppNotification.showError(context, error);
                        return;
                      }
                      AppNotification.showSuccess(
                        context,
                        enabled ? 'Schedule enabled.' : 'Schedule disabled.',
                      );
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
                      onTap: (anchor) => _pickTime(
                        context,
                        activityModes,
                        isStart: true,
                        anchor: anchor,
                      ),
                    ),
                    _ScheduleTimeRow(
                      label: 'Until',
                      time: schedule.end,
                      onTap: (anchor) => _pickTime(
                        context,
                        activityModes,
                        isStart: false,
                        anchor: anchor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (modeId != ActivityModeId.defaultMode) const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Future<void> _handleTurnOn(
    BuildContext context,
    ActivityModeProvider activityModes,
    ActivityModeDefinition definition,
  ) async {
    final isWide = isTabletOrDesktopPopupLayout(context);
    final popupCenter = popupContentAreaCenter(context);
    final selection = await showTurnOnModeDurationPopup(
      context,
      modeId: modeId,
      modeName: definition.name,
      anchor: isWide ? popupCenter : null,
      shellCenterAt: isWide ? popupCenter : null,
    );
    if (selection == null) return;

    await activityModes.activateModeManually(
      modeId,
      duration: selection.untilStopped ? null : selection.duration,
    );
  }

  Future<void> _handleTurnOff(
    BuildContext context,
    ActivityModeProvider activityModes,
  ) async {
    await activityModes.turnOffMode(modeId);
  }

  Future<void> _pickTime(
    BuildContext context,
    ActivityModeProvider activityModes, {
    required bool isStart,
    required Offset anchor,
  }) async {
    final schedule = activityModes.scheduleFor(modeId);
    final initial = isStart ? schedule.start : schedule.end;
    final isWide = isTabletOrDesktopPopupLayout(context);

    final picked = await showAppTimePicker(
      context,
      initialTime: initial,
      title: isStart ? 'Start time' : 'End time',
      anchor: isWide ? anchor : null,
      shellNearAnchor: isWide ? anchor : null,
    );
    if (picked == null) return;

    final updated = schedule.copyWith(
      start: isStart ? picked : schedule.start,
      end: isStart ? schedule.end : picked,
    );

    final error = await activityModes.updateModeSchedule(modeId, updated);
    if (!context.mounted) return;
    if (error != null) {
      AppNotification.showError(context, error);
      return;
    }
    AppNotification.showSuccess(context, 'Schedule updated.');
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

class _ScheduleTimeRow extends StatefulWidget {
  final String label;
  final TimeOfDay time;
  final void Function(Offset anchor) onTap;

  const _ScheduleTimeRow({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  State<_ScheduleTimeRow> createState() => _ScheduleTimeRowState();
}

class _ScheduleTimeRowState extends State<_ScheduleTimeRow> {
  final GlobalKey _timeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          final timeContext = _timeKey.currentContext;
          final anchor = timeContext != null
              ? popupAnchorFromContext(timeContext)
              : popupAnchorFromContext(context);
          widget.onTap(anchor);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                key: _timeKey,
                AppDateTimeFormat.timeOfDay(widget.time),
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
