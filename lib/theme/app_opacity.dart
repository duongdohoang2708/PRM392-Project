import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

/// Card fill solidity and tint strength from Card appearance settings.
class AppOpacity {
  AppOpacity._();

  // Fixed semantic alphas (never scaled by the card appearance setting).
  static const double surfaceSubtle = 0.08;
  static const double surfaceTint = 0.18;
  static const double surfaceTintMedium = 0.20;
  static const double surfaceTintStrong = 0.28;
  static const double surfaceCompleted = 0.62;
  static const double surfaceCompletedLight = 0.68;
  static const double borderAccent = 0.35;
  static const double borderStrong = 0.5;
  static const double borderStreak = 0.55;
  static const double iconWell = 0.28;
  static const double shadowAccent = 0.22;
  static const double shadowAccentStrong = 0.28;
  static const double textMuted = 0.5;
  static const double chartIdle = 0.32;
  static const double todayRing = 0.75;
  static const double notificationInfo = 0.95;

  /// 0 = card background fully transparent; 1 = card background fully solid.
  static double cardFillSolidityOf(BuildContext context) {
    return context.watch<SettingsProvider>().cardFillSolidity;
  }

  static double cardTintStrengthOf(BuildContext context) {
    return context.watch<SettingsProvider>().cardTintStrength;
  }

  static Color fixed(Color base, double alpha) {
    return base.withValues(alpha: alpha.clamp(0.0, 1.0));
  }

  static Color scaledTint(
    Color accent,
    double baseAlpha,
    BuildContext context,
  ) {
    return fixed(accent, baseAlpha * cardTintStrengthOf(context));
  }

  /// Card fill: accent tint (strength from Settings) over adjustable surface layer.
  static Color cardFill(
    BuildContext context, {
    required Color surface,
    required Color accent,
    required double tintAlpha,
  }) {
    final tint = scaledTint(accent, tintAlpha, context);
    final solidity = cardFillSolidityOf(context);
    return Color.alphaBlend(tint, surface.withValues(alpha: solidity));
  }

  /// Solid surface only (no accent tint), opacity controlled by Settings.
  static Color solidSurfaceFill(BuildContext context, Color surface) {
    final solidity = cardFillSolidityOf(context);
    return surface.withValues(alpha: solidity);
  }
}
