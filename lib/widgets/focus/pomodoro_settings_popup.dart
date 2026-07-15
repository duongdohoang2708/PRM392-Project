import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../common/app_popup_transition.dart';
import '../common/popup_surface.dart';
import 'pomodoro_settings_form.dart';

class PomodoroSettingsPopup extends StatelessWidget {
  final int initialFocusMinutes;
  final int initialShortBreakMinutes;
  final int initialLongBreakMinutes;
  final int initialRounds;
  final int initialLongBreakInterval;
  final void Function(
    int focus,
    int shortBreak,
    int longBreak,
    int rounds,
    int interval,
  ) onSave;

  const PomodoroSettingsPopup({
    super.key,
    required this.initialFocusMinutes,
    required this.initialShortBreakMinutes,
    required this.initialLongBreakMinutes,
    required this.initialRounds,
    required this.initialLongBreakInterval,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return AppPopupShell(
      alignment: isMobile ? Alignment.center : Alignment.centerRight,
      child: PopupSurface(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 16,
                  top: 16,
                  bottom: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Timer Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textSecondaryOf(context),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.borderOf(context), height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: PomodoroSettingsForm(
                    initialFocusMinutes: initialFocusMinutes,
                    initialShortBreakMinutes: initialShortBreakMinutes,
                    initialLongBreakMinutes: initialLongBreakMinutes,
                    initialRounds: initialRounds,
                    initialLongBreakInterval: initialLongBreakInterval,
                    showSaveButton: false,
                    autoSaveOnDispose: true,
                    onSave: (focus, shortBreak, longBreak, rounds, interval) {
                      onSave(
                        focus,
                        shortBreak,
                        longBreak,
                        rounds,
                        interval,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
