import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/activity_mode_provider.dart';
import '../../providers/settings_provider.dart';

/// Forces subtree rebuild when app theme (light/dark) or activity palette changes.
///
/// Uses [KeyedSubtree] because returning the same `const` child would otherwise
/// skip rebuilds on routes still mounted below the current navigator page.
class ThemeRebuildScope extends StatelessWidget {
  final Widget child;

  const ThemeRebuildScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final activityModes = context.watch<ActivityModeProvider>();

    return KeyedSubtree(
      key: ValueKey(
        '${settings.themeMode.index}_${activityModes.activeModeId}',
      ),
      child: child,
    );
  }
}
