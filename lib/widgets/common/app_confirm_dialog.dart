import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'popup_surface.dart';

enum AppConfirmButtonStyle {
  destructive,
  elevated,
  accentText,
}

/// Confirmation dialog with [PopupSurface] background (pattern + transparency).
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelLabel;
  final String confirmLabel;
  final Color? confirmBackgroundColor;
  final Color? confirmForegroundColor;
  final AppConfirmButtonStyle confirmButtonStyle;
  final Color? fillColor;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Confirm',
    this.confirmBackgroundColor,
    this.confirmForegroundColor,
    this.confirmButtonStyle = AppConfirmButtonStyle.elevated,
    this.fillColor,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    Color? confirmBackgroundColor,
    Color? confirmForegroundColor,
    AppConfirmButtonStyle confirmButtonStyle =
        AppConfirmButtonStyle.elevated,
    Color? fillColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmDialog(
        title: title,
        content: content,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        confirmBackgroundColor: confirmBackgroundColor,
        confirmForegroundColor: confirmForegroundColor,
        confirmButtonStyle: confirmButtonStyle,
        fillColor: fillColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmBg =
        confirmBackgroundColor ?? AppColors.primaryDarkOf(context);
    final confirmFg = confirmForegroundColor ?? Colors.white;

    Widget confirmButton;
    switch (confirmButtonStyle) {
      case AppConfirmButtonStyle.destructive:
        confirmButton = TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case AppConfirmButtonStyle.accentText:
        confirmButton = TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: confirmFg,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case AppConfirmButtonStyle.elevated:
        confirmButton = ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmBg,
            foregroundColor: confirmFg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: Text(confirmLabel),
        );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: PopupSurface(
        borderRadius: BorderRadius.circular(20),
        fillColor: fillColor ?? AppColors.popupOverlayFillOf(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      cancelLabel,
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  confirmButton,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
