import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Shared dropdown styling for TaskFlow — rounded menu, surface background, border.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final AlignmentGeometry alignment;
  final TextStyle? style;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final Widget? icon;
  final bool isDense;
  final double? itemHeight;
  final Widget? hint;
  final Color accentColor;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
    this.alignment = AlignmentDirectional.centerStart,
    this.style,
    this.selectedItemBuilder,
    this.icon,
    this.isDense = false,
    this.itemHeight,
    this.hint,
    this.accentColor = AppColors.primaryDark,
  });

  static const int menuElevation = 6;
  static final BorderRadius menuBorderRadius = BorderRadius.circular(16);

  static TextStyle textStyle({
    required Color color,
    FontWeight? fontWeight,
    double fontSize = 14,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w500,
    );
  }

  static TextStyle textStyleFor(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double fontSize = 14,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color ?? AppColors.textPrimaryOf(context),
      fontWeight: fontWeight ?? FontWeight.w500,
    );
  }

  static Widget menuChild(
    Widget child, {
    Alignment alignment = Alignment.centerRight,
    Color? textColor,
  }) {
    Widget content = child;
    if (child is Text && textColor != null) {
      final baseStyle = child.style ?? const TextStyle();
      content = Text(
        child.data ?? '',
        style: baseStyle.copyWith(color: textColor),
        overflow: child.overflow,
        maxLines: child.maxLines,
        softWrap: child.softWrap,
        textAlign: child.textAlign,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Align(alignment: alignment, child: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: accentColor.withValues(alpha: 0.08),
        focusColor: accentColor.withValues(alpha: 0.12),
        highlightColor: accentColor.withValues(alpha: 0.10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: isExpanded,
          alignment: alignment,
          hint: hint,
          isDense: isDense,
          itemHeight: itemHeight ?? 48,
          borderRadius: menuBorderRadius,
          elevation: menuElevation,
          dropdownColor: AppColors.surfaceOf(context),
          icon: icon ??
              Icon(
                Icons.expand_more,
                size: 20,
                color: AppColors.textSecondaryOf(context),
              ),
          style: style ?? textStyleFor(context, fontWeight: FontWeight.w500),
          selectedItemBuilder: selectedItemBuilder,
        ),
      ),
    );
  }
}
