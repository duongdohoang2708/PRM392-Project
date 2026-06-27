import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Compact pill action for section headers (View All, View history, …).
class SectionActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const SectionActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.primaryDark;
    final bg = backgroundColor ??
        (AppColors.isDark(context)
            ? AppColors.primary.withValues(alpha: 0.16)
            : Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.14),
                AppColors.surfaceOf(context),
              ));

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: AppColors.isDark(context)
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.primary.withValues(alpha: 0.22),
          ),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
