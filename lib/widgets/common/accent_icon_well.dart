import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Achievement-style icon container: light well fill + border matching icon color.
class AccentIconWell extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final double? size;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double borderWidth;
  final bool muted;
  final BoxShape shape;
  final Color? iconColor;

  const AccentIconWell({
    super.key,
    required this.accentColor,
    required this.icon,
    this.size,
    this.iconSize = 20,
    this.padding,
    this.borderRadius = 10,
    this.borderWidth = 1,
    this.muted = false,
    this.shape = BoxShape.rectangle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = iconColor ??
        AppColors.accentIconWellForegroundOf(
          context,
          accentColor,
          muted: muted,
        );

    final decoration = BoxDecoration(
      color: AppColors.accentIconWellFillOf(
        context,
        accentColor,
        muted: muted,
      ),
      shape: shape,
      borderRadius:
          shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      border: Border.all(color: foreground, width: borderWidth),
    );

    final iconWidget = Icon(icon, color: foreground, size: iconSize);

    if (size != null) {
      return Container(
        width: size,
        height: size,
        decoration: decoration,
        alignment: Alignment.center,
        child: iconWidget,
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(6),
      decoration: decoration,
      child: iconWidget,
    );
  }
}
