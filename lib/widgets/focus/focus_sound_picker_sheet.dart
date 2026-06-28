import 'package:flutter/material.dart';

import '../../services/focus_feedback_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/focus_sound_options.dart';
import '../custom_snackbar.dart';
import '../common/app_bottom_sheet.dart';
import '../common/popup_surface.dart';
import '../settings/settings_widgets.dart';

class FocusSoundPickerSheet extends StatelessWidget {
  final String title;
  final String selectedSoundId;
  final ValueChanged<String> onSelected;

  const FocusSoundPickerSheet({
    super.key,
    required this.title,
    required this.selectedSoundId,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String selectedSoundId,
    required ValueChanged<String> onSelected,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => FocusSoundPickerSheet(
        title: title,
        selectedSoundId: selectedSoundId,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: PopupSurface(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
        fillColor: AppColors.popupPanelOverlayFillOf(context),
        child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.borderOf(context)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    for (final option in FocusSoundOption.all)
                      SettingsOptionCard(
                        title: option.label,
                        subtitle: option.description,
                        icon: Icons.music_note_outlined,
                        selected: option.id == selectedSoundId,
                        onTap: () {
                          FocusFeedbackService.preview(option.id);
                          onSelected(option.id);
                          Navigator.pop(context);
                          AppNotification.showSuccess(
                            context,
                            'Sound set to ${option.label}.',
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
