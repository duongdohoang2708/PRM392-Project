import 'package:flutter/material.dart';

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

Alignment alignmentFromGlobalOffset(BuildContext context, Offset globalOffset) {
  final size = MediaQuery.sizeOf(context);
  return Alignment(
    ((globalOffset.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
    ((globalOffset.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
  );
}

AppPopupRouteTransitionBuilder buildAppPopupTransition({Offset? anchor}) {
  return (context, animation, secondaryAnimation, child) {
    final resolvedAnchor = anchor ?? popupAnchorFromContext(context);
    final alignment = alignmentFromGlobalOffset(context, resolvedAnchor);

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

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(scaleAnimation),
        alignment: alignment,
        child: child,
      ),
    );
  };
}

Future<T?> showAppPopup<T>({
  required BuildContext context,
  required Widget child,
  Offset? anchor,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final resolvedAnchor = anchor ?? popupAnchorFromContext(context);

  return showGeneralDialog<T>(
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
}
