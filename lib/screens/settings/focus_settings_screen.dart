import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/focus_provider.dart';
import '../../widgets/focus/focus_other_settings_form.dart';
import '../../widgets/focus/pomodoro_settings_form.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class FocusSettingsScreen extends StatelessWidget {
  const FocusSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: 'Focus Settings',
      showBack: true,
      independentBodyScroll: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;

          final timerPanel = StatPanel(
            title: 'Timer Settings',
            child: PomodoroSettingsForm(
              showHeader: false,
              showSaveButton: false,
              autoSaveOnDispose: true,
              initialFocusMinutes: focusProvider.focusMinutes,
              initialShortBreakMinutes: focusProvider.shortBreakMinutes,
              initialLongBreakMinutes: focusProvider.longBreakMinutes,
              initialRounds: focusProvider.rounds,
              initialLongBreakInterval: focusProvider.longBreakInterval,
              onSave: (focus, shortBreak, longBreak, rounds, interval) {
                focusProvider.updateSettings(
                  focus: focus,
                  shortBreak: shortBreak,
                  longBreak: longBreak,
                  rounds: rounds,
                  interval: interval,
                );
              },
            ),
          );

          final otherPanel = const StatPanel(
            title: 'Other configurations',
            child: FocusOtherSettingsForm(),
          );

          if (!isWide) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  timerPanel,
                  const SizedBox(height: 16),
                  otherPanel,
                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: timerPanel,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: otherPanel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
