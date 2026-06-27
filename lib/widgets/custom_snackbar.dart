import 'package:flutter/material.dart';

import 'common/animations/app_bottom_slide_fade.dart';
import 'dart:async';
import '../theme/app_colors.dart';

class AppNotification {
  static OverlayEntry? _currentEntry;

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.notificationSuccessBgOf(context),
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.notificationErrorBgOf(context),
      icon: Icons.error_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.accentYellow.withValues(
        alpha: AppColors.isDark(context) ? 0.85 : 0.92,
      ),
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.notificationInfoBgOf(context),
      icon: Icons.info_outline,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    // If there is an active overlay, remove it first
    if (_currentEntry != null) {
      try {
        _currentEntry!.remove();
      } catch (_) {}
      _currentEntry = null;
    }

    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) {
      // Fallback for navigator keys
      final navigator = Navigator.maybeOf(context);
      if (navigator?.overlay != null) {
        _insertOverlay(navigator!.overlay!, message, backgroundColor, icon);
      }
      return;
    }
    
    _insertOverlay(overlayState, message, backgroundColor, icon);
  }

  static void _insertOverlay(OverlayState overlayState, String message, Color backgroundColor, IconData icon) {
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _NotificationToast(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: () {
          if (_currentEntry == entry) {
            try {
              entry.remove();
            } catch (_) {}
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }
}

class _NotificationToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _NotificationToast({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<_NotificationToast> {
  bool _isVisible = false;
  Timer? _dismissTimer;
  Timer? _removeTimer;

  @override
  void initState() {
    super.initState();
    // Trigger slide-in animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });

    _dismissTimer = Timer(const Duration(seconds: 3), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
    _removeTimer = Timer(const Duration(milliseconds: 250), () {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;
    final foreground =
        AppColors.notificationFgOn(context, widget.backgroundColor);

    return Positioned(
      bottom: bottomPadding,
      left: 16,
      right: 16,
      child: SafeArea(
        child: AppBottomSlideFade(
          visible: _isVisible,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, color: foreground, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
