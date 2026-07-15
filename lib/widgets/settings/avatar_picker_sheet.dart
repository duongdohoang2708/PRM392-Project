import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_navigator.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/avatar_storage.dart';
import '../common/user_avatar.dart';
import '../common/app_bottom_sheet.dart';
import '../common/popup_surface.dart';
import '../custom_snackbar.dart';
import 'avatar_crop_screen.dart';

class AvatarPickerSheet extends StatefulWidget {
  final BuildContext anchorContext;

  const AvatarPickerSheet({
    super.key,
    required this.anchorContext,
  });

  static const _presetAvatars = [
    (
      label: 'Mint',
      url: 'assets/images/avatars/mint.png',
      color: Color(0xFFb6e3f4),
    ),
    (
      label: 'Coral',
      url: 'assets/images/avatars/coral.png',
      color: Color(0xFFffd5dc),
    ),
    (
      label: 'Sage',
      url: 'assets/images/avatars/sage.png',
      color: Color(0xFFc0f0d8),
    ),
    (
      label: 'Lilac',
      url: 'assets/images/avatars/lilac.png',
      color: Color(0xFFd1d4f9),
    ),
    (
      label: 'Amber',
      url: 'assets/images/avatars/amber.png',
      color: Color(0xFFffdfbf),
    ),
    (
      label: 'Ocean',
      url: 'assets/images/avatars/ocean.png',
      color: Color(0xFFc0e8ff),
    ),
  ];

  static Future<void> show(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (_) => AvatarPickerSheet(anchorContext: context),
    );
  }

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  bool _isPicking = false;

  Future<void> _select(BuildContext context, String? avatarUrl) async {
    await context.read<UserProvider>().updateAvatar(avatarUrl);
    if (!context.mounted) return;
    Navigator.pop(context);
    AppNotification.showSuccess(widget.anchorContext, 'Avatar updated.');
  }

  Future<void> _pickFromDevice() async {
    if (_isPicking) return;

    setState(() => _isPicking = true);

    final userProvider = context.read<UserProvider>();
    final anchor = widget.anchorContext;

    try {
      final imageBytes = await AvatarStorage.pickImageBytesFromGallery();
      if (!mounted) return;
      if (imageBytes == null) {
        setState(() => _isPicking = false);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (!anchor.mounted) return;

      final croppedBytes = await AvatarCropScreen.show(
        anchor,
        imageBytes: imageBytes,
      );
      if (croppedBytes == null) return;

      final uploadError = await userProvider.uploadAvatarBytes(
        bytes: croppedBytes,
        contentType: 'image/jpeg',
      );
      
      if (uploadError != null) {
        _showMessage(success: false, message: uploadError);
        return;
      }

      _showMessage(
        success: true,
        message: 'Avatar updated.',
      );
    } on AvatarPickException catch (error) {
      if (mounted) {
        setState(() => _isPicking = false);
      }
      _showMessage(success: false, message: error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _isPicking = false);
      }
      _showMessage(
        success: false,
        message: kDebugMode
            ? 'Could not load image: $error'
            : 'Could not load the selected image. Please try again.',
      );
    }
  }

  void _showMessage({required bool success, required String message}) {
    final ctx =
        navigatorKey.currentContext ?? widget.anchorContext;
    if (!ctx.mounted) return;

    if (success) {
      AppNotification.showSuccess(ctx, message);
    } else {
      AppNotification.showError(ctx, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasDeviceAvatar = AvatarStorage.isDeviceAvatar(user.avatarUrl);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: PopupSurface(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
        child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Choose Avatar',
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a photo from your device, crop it, or choose a preset avatar.',
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isPicking ? null : _pickFromDevice,
                icon: _isPicking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.primaryDarkOf(context),
                      ),
                label: Text(
                  _isPicking ? 'Opening gallery...' : 'Choose from device',
                  style: TextStyle(
                    color: AppColors.primaryDarkOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(
                    color: hasDeviceAvatar
                        ? AppColors.primaryDarkOf(context)
                        : AppColors.borderOf(context),
                    width: hasDeviceAvatar ? 2 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final List<Widget> avatarOptions = [];
                
                // 1. Initials
                avatarOptions.add(
                  _AvatarOption(
                    label: 'Initials',
                    selected: user.avatarUrl == null,
                    onTap: () => _select(context, null),
                    child: UserAvatar(
                      avatarUrl: null,
                      initials: user.initials,
                      radius: 28,
                    ),
                  ),
                );

                // 2. Google Avatar
                final googleUrl = user.googleAvatarUrl;
                if (googleUrl != null) {
                  avatarOptions.add(
                    _AvatarOption(
                      label: 'Google',
                      selected: user.avatarUrl == googleUrl,
                      onTap: () => _select(context, googleUrl),
                      child: UserAvatar(
                        avatarUrl: googleUrl,
                        initials: 'G',
                        radius: 28,
                      ),
                    ),
                  );
                }

                // 3. Presets
                for (final preset in AvatarPickerSheet._presetAvatars) {
                  avatarOptions.add(
                    _AvatarOption(
                      label: preset.label,
                      selected: user.avatarUrl == preset.url,
                      onTap: () => _select(context, preset.url),
                      child: UserAvatar(
                        avatarUrl: preset.url,
                        initials: preset.label[0],
                        backgroundColor: preset.color,
                        radius: 28,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: avatarOptions.length,
                  itemBuilder: (context, index) => avatarOptions[index],
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _AvatarOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryDarkOf(context).withValues(
                    alpha: AppColors.isDark(context) ? 0.22 : 0.1,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primaryDarkOf(context)
                  : AppColors.borderOf(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
