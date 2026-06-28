import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../background_pattern.dart';

/// Popup/sheet/dialog shell: [BackgroundPattern] under a fill layer controlled
/// by the Card appearance setting — never shows the screen behind the modal.
class PopupSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color? fillColor;

  const PopupSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final overlayFill = fillColor ?? AppColors.popupOverlayFillOf(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned.fill(child: BackgroundPattern()),
            Positioned.fill(child: ColoredBox(color: overlayFill)),
            if (border != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(border: border),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
