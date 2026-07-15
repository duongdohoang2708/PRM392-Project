import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/main_shell.dart';
import '../providers/user_provider.dart';
import 'common/animations/app_bottom_slide_fade.dart';
import 'common/animations/app_top_slide_fade.dart';
import 'common/animations/app_popup_transition.dart';
import 'dart:async';
import '../models/activity_mode.dart';
import '../navigation/app_navigator.dart';
import '../providers/drawer_provider.dart';
import '../theme/activity_mode_palette.dart';
import '../theme/app_colors.dart';

class AppNotification {
  static OverlayEntry? _currentEntry;
  static OverlayEntry? _currentTopEntry;

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

  static void showModeSwitch(
    BuildContext context, {
    required ActivityModeId modeId,
    required String message,
    String? statusLabel,
  }) {
    if (_currentTopEntry != null) {
      try {
        _currentTopEntry!.remove();
      } catch (_) {}
      _currentTopEntry = null;
    }

    final overlayState = _resolveOverlay(context);
    if (overlayState == null) return;

    final overlayContext = navigatorKey.currentContext ?? context;
    final brightness = Theme.of(overlayContext).brightness;
    final palette =
        ActivityModePalette.forMode(modeId, brightness: brightness);
    final definition = ActivityModes.definitionFor(modeId);
    final backgroundColor = AppColors.notificationInfoBgOf(overlayContext);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ModeSwitchToast(
        message: message,
        statusLabel: statusLabel,
        backgroundColor: backgroundColor,
        icon: definition.icon,
        iconBackgroundColor: palette.primaryLight,
        iconColor: palette.primaryDark,
        onDismiss: () {
          if (_currentTopEntry == entry) {
            try {
              entry.remove();
            } catch (_) {}
            _currentTopEntry = null;
          }
        },
      ),
    );

    _currentTopEntry = entry;
    overlayState.insert(entry);
  }

  static OverlayState? _resolveOverlay(BuildContext context) {
    return Overlay.maybeOf(context, rootOverlay: true) ??
        Navigator.maybeOf(context)?.overlay ??
        navigatorKey.currentState?.overlay;
  }

  static bool _checkHasDrawer(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<MainShell>() != null) {
      return true;
    }
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isAuthenticated) {
        return true;
      }
    } catch (_) {}
    return false;
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

    final hasDrawer = _checkHasDrawer(context);

    // Compute drawer offset here, where DrawerProvider is available.
    double drawerOffset = 0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth >= kDesktopLayoutBreakpoint && hasDrawer) {
      try {
        final collapsed = context.read<DrawerProvider>().isDesktopCollapsed;
        drawerOffset = collapsed ? kDesktopDrawerWidthCollapsed : kDesktopDrawerWidthExpanded;
      } catch (_) {
        drawerOffset = kDesktopDrawerWidthExpanded;
      }
    }

    // Always use root overlay so the snackbar spans the full screen.
    final overlayState =
        Overlay.maybeOf(context, rootOverlay: true) ??
        navigatorKey.currentState?.overlay ??
        Overlay.maybeOf(context);

    if (overlayState == null) return;

    _insertOverlay(overlayState, message, backgroundColor, icon, drawerOffset);
  }

  static void _insertOverlay(
    OverlayState overlayState,
    String message,
    Color backgroundColor,
    IconData icon,
    double drawerOffset,
  ) {
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _NotificationToast(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        drawerOffset: drawerOffset,
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

class _ModeSwitchToast extends StatefulWidget {
  final String message;
  final String? statusLabel;
  final Color backgroundColor;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onDismiss;

  const _ModeSwitchToast({
    required this.message,
    this.statusLabel,
    required this.backgroundColor,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onDismiss,
  });

  @override
  State<_ModeSwitchToast> createState() => _ModeSwitchToastState();
}

class _ModeSwitchToastState extends State<_ModeSwitchToast> {
  bool _isVisible = false;
  Timer? _dismissTimer;
  Timer? _removeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isVisible = true);
    });
    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (mounted) setState(() => _isVisible = false);
    _removeTimer = Timer(const Duration(milliseconds: 250), widget.onDismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= kDesktopLayoutBreakpoint) {
      context.watch<DrawerProvider>();
    }
    final insets = notificationOverlayInsets(context);
    final foreground =
        AppColors.notificationFgOn(context, widget.backgroundColor);

    return Positioned(
      top: insets.top,
      left: insets.left,
      right: insets.right,
      child: AppTopSlideFade(
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.statusLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.statusLabel!,
                          style: TextStyle(
                            color: foreground.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;
  final double drawerOffset;

  const _NotificationToast({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
    required this.drawerOffset,
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
    const double horizontal = 16;
    const double bottomExtra = 16;
    final bottom = MediaQuery.paddingOf(context).bottom + bottomExtra;
    final left = widget.drawerOffset + horizontal;
    const right = horizontal;

    final foreground =
        AppColors.notificationFgOn(context, widget.backgroundColor);

    return Positioned(
      bottom: bottom,
      left: left,
      right: right,
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
    );
  }
}
