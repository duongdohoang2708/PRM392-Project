import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity_mode.dart';
import '../providers/activity_mode_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../screens/auth/login_screen.dart';
import '../theme/activity_mode_palette.dart';
import '../theme/app_theme.dart';

/// Signs out, resets activity mode + appearance while navigating to login so
/// the user never sees the palette change on the account screen.
Future<void> signOutAndNavigateToLogin(BuildContext context) async {
  final activityModes = context.read<ActivityModeProvider>();
  final settings = context.read<SettingsProvider>();

  await context.read<UserProvider>().signOut();
  if (!context.mounted) return;

  final themeMode = settings.themeMode;

  await Future.wait([
    activityModes.prepareDefaultThemeForSignOut(),
    settings.prepareDefaultAppearanceForSignOut(),
  ]);
  if (!context.mounted) return;

  final brightness = switch (themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => MediaQuery.platformBrightnessOf(context),
  };
  final palette = ActivityModePalette.forMode(
    ActivityModeId.defaultMode,
    brightness: brightness,
  );

  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (context) {
        return Theme(
          data: AppTheme.build(brightness: brightness, palette: palette),
          child: const LoginScreen(),
        );
      },
    ),
    (route) => false,
  );

  activityModes.commitDefaultThemeForSignOut();
  settings.commitDefaultAppearanceForSignOut();
}
