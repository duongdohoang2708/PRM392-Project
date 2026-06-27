import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../background_pattern.dart';
import '../custom_snackbar.dart';

class AvatarCropScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const AvatarCropScreen({
    super.key,
    required this.imageBytes,
  });

  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List imageBytes,
  }) {
    return Navigator.of(context, rootNavigator: true).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AvatarCropScreen(
          key: ValueKey(imageBytes.lengthInBytes ^ imageBytes.hashCode),
          imageBytes: Uint8List.fromList(imageBytes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AvatarCropShell(imageBytes: imageBytes);
  }
}

class _AvatarCropShell extends StatefulWidget {
  final Uint8List imageBytes;

  const _AvatarCropShell({required this.imageBytes});

  @override
  State<_AvatarCropShell> createState() => _AvatarCropShellState();
}

class _AvatarCropShellState extends State<_AvatarCropShell> {
  final _cropController = CropController();

  void _onCropped(CropResult result) {
    if (!mounted) return;

    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.pop(context, Uint8List.fromList(croppedImage));
      case CropFailure(:final cause):
        AppNotification.showError(
          context,
          'Could not crop the image. Please try again.',
        );
        if (kDebugMode) {
          debugPrint('Avatar crop failed: $cause');
        }
    }
  }

  void _applyCrop() {
    _cropController.cropCircle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          const BackgroundPattern(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Crop Photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 72),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    'Pinch to zoom and drag the photo until it fits the circle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _AvatarCropEditor(
                      imageBytes: widget.imageBytes,
                      controller: _cropController,
                      onCropped: _onCropped,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Use Photo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCropEditor extends StatelessWidget {
  final Uint8List imageBytes;
  final CropController controller;
  final ValueChanged<CropResult> onCropped;

  const _AvatarCropEditor({
    required this.imageBytes,
    required this.controller,
    required this.onCropped,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: AppColors.surfaceOf(context),
        child: Crop(
          key: ValueKey(imageBytes.lengthInBytes ^ imageBytes.hashCode),
          controller: controller,
          image: imageBytes,
          withCircleUi: true,
          interactive: true,
          baseColor: AppColors.surfaceOf(context),
          maskColor: Colors.black.withValues(alpha: 0.62),
          progressIndicator: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryDark,
            ),
          ),
          onCropped: onCropped,
        ),
      ),
    );
  }
}
