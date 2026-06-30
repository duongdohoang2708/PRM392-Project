import 'package:flutter/material.dart';

import '../../models/activity_mode.dart';
import '../../theme/activity_mode_palette.dart';
import '../../theme/app_colors.dart';

class ThemeModeHeroCard extends StatelessWidget {
  final ActivityModeId modeId;
  final IconData icon;
  final String name;
  final String? statusLabel;
  final bool isModeRunning;
  final bool showTurnOnOff;
  final VoidCallback? onTurnOn;
  final VoidCallback? onTurnOff;

  const ThemeModeHeroCard({
    super.key,
    required this.modeId,
    required this.icon,
    required this.name,
    this.statusLabel,
    required this.isModeRunning,
    this.showTurnOnOff = true,
    this.onTurnOn,
    this.onTurnOff,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = ActivityModePalette.forMode(modeId, brightness: brightness);
    final accent = AppColors.primaryDarkOf(context);
    final onAccent = Colors.white;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 36),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceFillOf(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (statusLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    statusLabel!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (showTurnOnOff) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isModeRunning ? onTurnOff : onTurnOn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: onAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        isModeRunning ? 'Turn off' : 'Turn on',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardSurfaceFillOf(context),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: palette.primaryDark,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
