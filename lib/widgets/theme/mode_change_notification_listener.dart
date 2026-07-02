import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_mode.dart';
import '../../navigation/app_navigator.dart';
import '../../providers/activity_mode_provider.dart';
import '../custom_snackbar.dart';
import 'mode_change_notification_suppression.dart';
/// Shows an in-app top banner when [ActivityModeProvider.activeModeId] changes.
class ModeChangeNotificationListener extends StatefulWidget {
  final Widget child;

  const ModeChangeNotificationListener({super.key, required this.child});

  @override
  State<ModeChangeNotificationListener> createState() =>
      _ModeChangeNotificationListenerState();
}

class _ModeChangeNotificationListenerState
    extends State<ModeChangeNotificationListener> {
  ActivityModeProvider? _provider;
  ActivityModeId? _lastMode;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ActivityModeProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_onProviderChanged);
      _provider = provider;
      provider.addListener(_onProviderChanged);
      _hasInitialized = false;
      _lastMode = null;
      _onProviderChanged();
    }
  }

  void _onProviderChanged() {
    final provider = _provider;
    if (provider == null || !provider.isLoaded) return;

    final mode = provider.activeModeId;
    if (!_hasInitialized) {
      _hasInitialized = true;
      _lastMode = mode;
      return;
    }

    if (_lastMode == mode) return;
    _lastMode = mode;

    if (!mounted || ModeChangeNotificationSuppression.isSuppressed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModeChangeNotificationSuppression.isSuppressed) return;
      final navContext = navigatorKey.currentContext;
      if (navContext == null) return;

      final definition = ActivityModes.definitionFor(mode);
      final message = mode == ActivityModeId.defaultMode
          ? 'Back to Default'
          : 'Switched to ${definition.name}';
      AppNotification.showModeSwitch(
        navContext,
        modeId: mode,
        message: message,
        statusLabel: _provider?.heroStatusLabelFor(mode),
      );
    });
  }
  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
