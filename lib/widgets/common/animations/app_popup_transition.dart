import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/drawer_provider.dart';

export 'app_popup_shell.dart';

const Duration kAppPopupTransitionDuration = Duration(milliseconds: 420);

typedef AppPopupRouteTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);

/// Global center of the widget tied to [context], e.g. the pressed button.
Offset popupAnchorFromContext(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
    return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
  }
  final size = MediaQuery.sizeOf(context);
  return Offset(size.width / 2, size.height / 2);
}

const double kDesktopLayoutBreakpoint = 768;
const double kDesktopDrawerWidthExpanded = 280;
const double kDesktopDrawerWidthCollapsed = 88;

/// Width of the permanent desktop sidebar when present.
double desktopDrawerWidth(BuildContext context) {
  try {
    final collapsed = context.read<DrawerProvider>().isDesktopCollapsed;
    return collapsed ? kDesktopDrawerWidthCollapsed : kDesktopDrawerWidthExpanded;
  } catch (_) {
    return kDesktopDrawerWidthExpanded;
  }
}

/// Screen center on mobile/tablet; center of the main content column on desktop
/// (excludes the permanent [AppDrawer] rail).
Offset popupContentAreaCenter(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.width < kDesktopLayoutBreakpoint) {
    return Offset(size.width / 2, size.height / 2);
  }
  final drawerWidth = desktopDrawerWidth(context);
  final contentWidth = size.width - drawerWidth;
  return Offset(drawerWidth + contentWidth / 2, size.height / 2);
}

/// Insets for in-app notification banners: on desktop, excludes the sidebar.
EdgeInsets notificationOverlayInsets(
  BuildContext context, {
  double horizontal = 16,
  double topExtra = 12,
  double bottomExtra = 16,
}) {
  final padding = MediaQuery.paddingOf(context);
  final top = padding.top + topExtra;
  final bottom = padding.bottom + bottomExtra;
  final size = MediaQuery.sizeOf(context);

  if (size.width < kDesktopLayoutBreakpoint) {
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  final drawerWidth = desktopDrawerWidth(context);
  return EdgeInsets.fromLTRB(drawerWidth + horizontal, top, horizontal, bottom);
}

Offset popupScreenCenter(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return Offset(size.width / 2, size.height / 2);
}

bool isTabletOrDesktopPopupLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 600;

AppPopupRouteTransitionBuilder buildAppPopupTransition({Offset? anchor}) {
  return (context, animation, secondaryAnimation, child) {
    final resolvedAnchor = anchor ?? popupAnchorFromContext(context);

    final scaleAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.05, 0.9, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, fadeAnimation]),
      builder: (context, child) {
        final scale = scaleAnimation.value;
        final matrix = Matrix4.identity()
          ..translateByDouble(resolvedAnchor.dx, resolvedAnchor.dy, 0, 1)
          ..scaleByDouble(scale, scale, scale, 1)
          ..translateByDouble(-resolvedAnchor.dx, -resolvedAnchor.dy, 0, 1);

        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform(
            transform: matrix,
            alignment: Alignment.topLeft,
            filterQuality: FilterQuality.medium,
            child: child,
          ),
        );
      },
      child: child,
    );
  };
}

Future<T?> showAppPopup<T>({
  required BuildContext context,
  required Widget child,
  Offset? anchor,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  final resolvedAnchor = anchor ?? popupAnchorFromContext(context);

  // Dismiss keyboard before opening so a still-focused field does not reopen it
  // after the popup closes and the parent rebuilds.
  FocusManager.instance.primaryFocus?.unfocus();

  final result = await showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: kAppPopupTransitionDuration,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (barrierDismissible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            child,
          ],
        ),
      );
    },
    transitionBuilder: buildAppPopupTransition(anchor: resolvedAnchor),
  );

  FocusManager.instance.primaryFocus?.unfocus();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FocusManager.instance.primaryFocus?.unfocus();
  });
  return result;
}
