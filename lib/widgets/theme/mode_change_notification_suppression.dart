import 'package:flutter/material.dart';

/// Ref-counted guard so activity-mode switch toasts are not shown on auth flows.
class ModeChangeNotificationSuppression {
  ModeChangeNotificationSuppression._();

  static int _count = 0;

  static bool get isSuppressed => _count > 0;

  static void acquire() => _count++;

  static void release() {
    if (_count > 0) _count--;
  }
}

/// Call from auth [State] objects to suppress mode-switch notifications.
mixin SuppressesModeChangeNotification<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ModeChangeNotificationSuppression.acquire();
  }

  @override
  void dispose() {
    ModeChangeNotificationSuppression.release();
    super.dispose();
  }
}
