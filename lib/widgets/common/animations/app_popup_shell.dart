import 'package:flutter/material.dart';

/// Positions popup content without blocking taps outside the panel.
///
/// Used as the root widget for screens shown via [showAppPopup]. Only the
/// panel bounds participate in hit testing so taps outside can dismiss.
class AppPopupShell extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  final EdgeInsets? insetPadding;
  final double? width;
  final BoxConstraints? constraints;

  const AppPopupShell({
    super.key,
    required this.child,
    this.alignment = Alignment.centerRight,
    this.insetPadding,
    this.width,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final padding = insetPadding ??
        (isMobile
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 24));
    final panelWidth = width ?? (isMobile ? null : 400.0);
    final maxHeight =
        constraints?.maxHeight ?? MediaQuery.sizeOf(context).height * 0.85;

    final panel = Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: child,
      ),
    );

    if (alignment == Alignment.center) {
      return Positioned(
        top: padding.top,
        left: padding.left,
        right: padding.right,
        child: panel,
      );
    }

    return Positioned(
      top: padding.top,
      bottom: padding.bottom,
      right: padding.right,
      left: isMobile ? padding.left : null,
      width: isMobile ? null : panelWidth,
      child: Align(
        alignment: alignment,
        child: panel,
      ),
    );
  }
}
