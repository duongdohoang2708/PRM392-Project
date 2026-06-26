import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: 'Theme',
      showBack: true,
      child: StatPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how TaskFlow looks on this device.',
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SettingsOptionCard(
              title: 'Light',
              subtitle: 'Matcha pastel theme',
              icon: Icons.light_mode_outlined,
              selected: settings.themeMode == ThemeMode.light,
              onTap: () async {
                await settings.setThemeMode(ThemeMode.light);
                if (context.mounted) {
                  AppNotification.showSuccess(context, 'Theme set to Light.');
                }
              },
            ),
            SettingsOptionCard(
              title: 'Dark',
              subtitle: 'Dimmed surfaces with matcha accents',
              icon: Icons.dark_mode_outlined,
              selected: settings.themeMode == ThemeMode.dark,
              onTap: () async {
                await settings.setThemeMode(ThemeMode.dark);
                if (context.mounted) {
                  AppNotification.showSuccess(context, 'Theme set to Dark.');
                }
              },
            ),
            SettingsOptionCard(
              title: 'System',
              subtitle: 'Follow device appearance',
              icon: Icons.brightness_auto_outlined,
              selected: settings.themeMode == ThemeMode.system,
              onTap: () async {
                await settings.setThemeMode(ThemeMode.system);
                if (context.mounted) {
                  AppNotification.showSuccess(context, 'Theme set to System.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
