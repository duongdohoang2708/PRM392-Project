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
  /// When set on tablet/desktop, centers the panel at this global point.
  final Offset? centerAt;
  /// When set on tablet/desktop, places the panel beside the tap point instead
  /// of the default right rail or screen center.
  final Offset? nearAnchor;

  const AppPopupShell({
    super.key,
    required this.child,
    this.alignment = Alignment.centerRight,
    this.insetPadding,
    this.width,
    this.constraints,
    this.centerAt,
    this.nearAnchor,
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

    if (centerAt != null && !isMobile) {
      final size = MediaQuery.sizeOf(context);
      final resolvedWidth = panelWidth ?? 400.0;
      final alignX =
          ((centerAt!.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
      final alignY =
          ((centerAt!.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
      return Positioned.fill(
        child: Padding(
          padding: padding,
          child: Align(
            alignment: Alignment(alignX, alignY),
            child: SizedBox(width: resolvedWidth, child: panel),
          ),
        ),
      );
    }

    if (nearAnchor != null && !isMobile) {
      final resolvedWidth = panelWidth ?? 400.0;
      final size = MediaQuery.sizeOf(context);
      // Panel grows from the time label: top-right of panel sits near the anchor.
      final panelLeft = (nearAnchor!.dx - resolvedWidth + 32).clamp(
        padding.left,
        size.width - resolvedWidth - padding.right,
      );
      final panelTop = (nearAnchor!.dy - 20).clamp(
        padding.top,
        size.height - maxHeight - padding.bottom,
      );
      return Positioned(
        top: panelTop,
        left: panelLeft,
        width: resolvedWidth,
        child: panel,
      );
    }

    if (alignment == Alignment.center) {
      final resolvedWidth = panelWidth ?? (isMobile ? null : 400.0);
      return Positioned.fill(
        child: Padding(
          padding: padding,
          child: Align(
            alignment: Alignment.center,
            child: resolvedWidth == null
                ? panel
                : SizedBox(width: resolvedWidth, child: panel),
          ),
        ),
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
