import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/focus_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/focus_sound_options.dart';
import '../settings/settings_widgets.dart';
import 'focus_sound_picker_sheet.dart';

class FocusOtherSettingsForm extends StatelessWidget {
  const FocusOtherSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();

    final tiles = <Widget>[
      SettingsSwitchTile(
        icon: Icons.play_circle_outline,
        title: 'Auto start focus',
        subtitle: 'Begin the next focus session automatically',
        value: focus.autoStartFocus,
        onChanged: focus.setAutoStartFocus,
      ),
      SettingsSwitchTile(
        icon: Icons.coffee_outlined,
        title: 'Auto start break',
        subtitle: 'Begin breaks automatically after focus',
        value: focus.autoStartBreak,
        onChanged: focus.setAutoStartBreak,
      ),
      SettingsSwitchTile(
        icon: Icons.stay_current_portrait_outlined,
        title: 'Keep screen on',
        subtitle: 'Prevent the display from sleeping while the timer runs',
        value: focus.keepScreenOn,
        onChanged: focus.setKeepScreenOn,
      ),
      SettingsSwitchTile(
        icon: Icons.volume_up_outlined,
        title: 'Focus completion sound',
        subtitle: 'Play a sound when a focus session ends',
        value: focus.focusCompletionSoundEnabled,
        onChanged: focus.setFocusCompletionSoundEnabled,
      ),
      SettingsNavTile(
        icon: Icons.music_note_outlined,
        title: FocusSoundOption.labelFor(focus.focusSoundId),
        subtitle: 'Focus sound',
        onTap: focus.focusCompletionSoundEnabled
            ? () => FocusSoundPickerSheet.show(
                  context,
                  title: 'Focus sound',
                  selectedSoundId: focus.focusSoundId,
                  onSelected: focus.setFocusSoundId,
                )
            : null,
        titleColor: focus.focusCompletionSoundEnabled
            ? null
            : Theme.of(context).disabledColor,
      ),
      SettingsSwitchTile(
        icon: Icons.notifications_active_outlined,
        title: 'Break completion sound',
        subtitle: 'Play a sound when a break ends',
        value: focus.breakCompletionSoundEnabled,
        onChanged: focus.setBreakCompletionSoundEnabled,
      ),
      SettingsNavTile(
        icon: Icons.music_note_outlined,
        title: FocusSoundOption.labelFor(focus.breakSoundId),
        subtitle: 'Break sound',
        onTap: focus.breakCompletionSoundEnabled
            ? () => FocusSoundPickerSheet.show(
                  context,
                  title: 'Break sound',
                  selectedSoundId: focus.breakSoundId,
                  onSelected: focus.setBreakSoundId,
                )
            : null,
        titleColor: focus.breakCompletionSoundEnabled
            ? null
            : Theme.of(context).disabledColor,
      ),
      SettingsSwitchTile(
        icon: Icons.vibration,
        title: 'Vibrate when focus ends',
        subtitle: 'Haptic feedback after each focus session',
        value: focus.vibrateOnFocusEnd,
        onChanged: focus.setVibrateOnFocusEnd,
      ),
      SettingsSwitchTile(
        icon: Icons.vibration,
        title: 'Vibrate when break ends',
        subtitle: 'Haptic feedback after each break',
        value: focus.vibrateOnBreakEnd,
        onChanged: focus.setVibrateOnBreakEnd,
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(
                height: 1,
                color: AppColors.borderOf(context),
              ),
            ),
          tiles[i],
        ],
      ],
    );
  }
}
