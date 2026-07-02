import 'package:flutter/material.dart';

import '../models/activity_mode.dart';
import 'activity_mode_palette.dart';
import 'app_opacity.dart';

class AppColors {
  // Primary & Accents
  static const Color primary = Color(0xFF96C490); // Pastel matcha green
  static const Color primaryDark = Color(0xFF5E8F5D); // Deep matcha accent
  static const Color primaryLight = Color(0xFFCFE4CA); // Soft sage green

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFAF8EF); // Cream background
  static const Color surface = Color(0xFFFFFDF7); // Warm ivory surface

  // Accents
  static const Color accentYellow = Color(0xFFE3B82B); // Darker mustard yellow
  static const Color accentPeach = Color(0xFFDF7E52); // Darker orange/peach
  static const Color accentPink = Color(0xFFD65D7F); // Darker pink

  /// Ice blue for freeze-day streak UI (icons, borders, highlights).
  static const Color freezeBlue = Color(0xFF4BA3D6);

  /// Streak flame icon (dark orange).
  static const Color streakFlame = Color(0xFFE65100);

  /// Statistics overview cards — blue, green, yellow, red.
  static const Color statBlue = Color(0xFF4BA3D6);
  static const Color statGreen = Color(0xFF5E8F5D);
  static const Color statYellow = Color(0xFFE3B82B);
  static const Color statRed = Color(0xFFE53935);

  /// Rainbow palette for quick actions (red → violet).
  static const List<Color> rainbowPalette = [
    Color(0xFFE53935), // red
    Color(0xFFF4511E), // orange
    Color(0xFFF9A825), // yellow
    Color(0xFF43A047), // green
    Color(0xFF1E88E5), // blue
    Color(0xFF8E24AA), // violet
  ];

  /// Rainbow accent readable in light and dark mode.
  static Color rainbowOf(BuildContext context, int index) {
    final palette = rainbowPalette;
    return projectAccentOf(context, palette[index % palette.length]);
  }

  /// Streak flame cells in calendar views.
  static const Color streakRed = Color(0xFFC62828);

  // Typography
  static const Color textPrimary = Color(0xFF333C31); // Muted text
  static const Color textSecondary = Color(0xFF6A7565); // Secondary text

  // Borders & Dividers
  static const Color border = Color(0xFFD7DFCA); // Light border

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF1A1F1C);
  static const Color darkSurface = Color(0xFF242B27);
  static const Color darkBorder = Color(0xFF3A4540);
  static const Color darkTextPrimary = Color(0xFFE8EDE9);
  static const Color darkTextSecondary = Color(0xFF9AA8A0);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static ActivityModePalette paletteOf(BuildContext context) {
    return Theme.of(context).extension<ActivityModePalette>() ??
        ActivityModePalette.forMode(
          ActivityModeId.defaultMode,
          brightness: Theme.of(context).brightness,
        );
  }

  static Color primaryOf(BuildContext context) => paletteOf(context).primary;

  static Color primaryDarkOf(BuildContext context) =>
      paletteOf(context).primaryDark;

  /// Filled corner actions (FAB +/gear, Create Task/Project) — deeper in dark
  /// mode so white icon/label stays readable. Not used on project detail FAB.
  static Color prominentActionFillOf(BuildContext context) {
    if (!isDark(context)) return primaryOf(context);
    return Color.lerp(primaryDarkOf(context), Colors.black, 0.15)!;
  }

  static Color prominentActionFillFromPalette(
    ActivityModePalette palette, {
    required Brightness brightness,
  }) {
    if (brightness == Brightness.light) return palette.primary;
    return Color.lerp(palette.primaryDark, Colors.black, 0.15)!;
  }

  static Color prominentActionForegroundOf(BuildContext context) {
    if (isDark(context)) return Colors.white;
    return Theme.of(context).colorScheme.onPrimary;
  }

  static Color primaryLightOf(BuildContext context) =>
      paletteOf(context).primaryLight;

  static Color backgroundOf(BuildContext context) =>
      paletteOf(context).background;

  static Color surfaceOf(BuildContext context) => paletteOf(context).surface;

  static Color borderOf(BuildContext context) => paletteOf(context).border;

  static Color textPrimaryOf(BuildContext context) =>
      paletteOf(context).textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      paletteOf(context).textSecondary;

  /// Auth branding title — brighter in default dark mode on decor backgrounds.
  static Color authBrandingTitleOf(BuildContext context) {
    final palette = paletteOf(context);
    if (isDark(context) && palette.modeId == ActivityModeId.defaultMode) {
      return palette.primary;
    }
    return palette.primaryDark;
  }

  /// Auth branding tagline — slightly lifted in default dark mode.
  static Color authBrandingSubtitleOf(BuildContext context) {
    final palette = paletteOf(context);
    if (isDark(context) && palette.modeId == ActivityModeId.defaultMode) {
      return Color.lerp(palette.textSecondary, palette.textPrimary, 0.45)!;
    }
    return palette.textSecondary;
  }

  /// Drawer header strip behind profile greeting.
  static Color drawerHeaderOf(BuildContext context) =>
      paletteOf(context).drawerHeader;

  /// Cards/lists on top of scaffold background.
  static Color cardOf(BuildContext context) => paletteOf(context).card;

  /// Neutral panel (StatPanel) — no accent tint, solidity from Settings.
  static Color panelFillOf(BuildContext context) =>
      AppOpacity.solidSurfaceFill(context, surfaceOf(context));

  /// Dropdown menu list — always fully opaque, never follows Card appearance.
  static Color dropdownMenuFillOf(BuildContext context) => surfaceOf(context);

  /// Dropdown field shell on forms — transparent; parent card shows through.
  static Color dropdownShellFillOf(BuildContext context) => Colors.transparent;

  /// Dropdown filter pill shell (task filters, etc.) — always solid.
  static Color dropdownFilterShellFillOf(BuildContext context) => cardOf(context);

  /// Neutral card shell — no accent tint, solidity from Settings.
  static Color cardSurfaceFillOf(BuildContext context) =>
      AppOpacity.solidSurfaceFill(context, cardOf(context));

  /// Overlay fill on [BackgroundPattern] inside popups/sheets/dialogs.
  static Color popupOverlayFillOf(BuildContext context) =>
      cardSurfaceFillOf(context);

  /// Panel overlay fill for large popup shells (e.g. sound picker).
  static Color popupPanelOverlayFillOf(BuildContext context) =>
      panelFillOf(context);

  /// Card background: fixed accent tint + adjustable opaque surface layer.
  /// Solidity 0 = transparent (see page background); 1 = solid card fill.
  static Color cardFillOf(
    BuildContext context, {
    required Color accentColor,
    double lightTintAlpha = 0.08,
    double darkTintAlpha = 0.12,
    Color? surface,
  }) {
    final accent = projectAccentOf(context, accentColor);
    final tintAlpha = isDark(context) ? darkTintAlpha : lightTintAlpha;
    return AppOpacity.cardFill(
      context,
      surface: surface ?? cardOf(context),
      accent: accent,
      tintAlpha: tintAlpha,
    );
  }

  /// Neutral grayscale base for active task cards — keeps project tint readable.
  static Color taskCardNeutralSurfaceOf(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF2A2A2C)
        : const Color(0xFFF3F3F4);
  }

  /// Task list/detail card tinted by project accent.
  static Color taskCardOf(
    BuildContext context,
    Color accentColor, {
    bool completed = false,
  }) {
    if (completed) {
      return cardSurfaceFillOf(context);
    }
    return cardFillOf(
      context,
      accentColor: accentColor,
      surface: taskCardNeutralSurfaceOf(context),
      lightTintAlpha: AppOpacity.surfaceTint,
      darkTintAlpha: AppOpacity.surfaceTint,
    );
  }

  /// Neutral task card (no project) — active matches project list panels.
  static Color neutralTaskCardFillOf(
    BuildContext context, {
    required bool completed,
  }) {
    if (!completed) {
      return panelFillOf(context);
    }
    final solidity =
        AppOpacity.cardFillSolidityOf(context) * AppOpacity.surfaceCompleted;
    return cardOf(context).withValues(alpha: solidity.clamp(0.0, 1.0));
  }

  /// Border for neutral task cards — softer when completed.
  static Color neutralTaskCardBorderOf(
    BuildContext context, {
    required bool completed,
  }) {
    if (!completed) {
      return borderOf(context);
    }
    return AppOpacity.fixed(borderOf(context), AppOpacity.surfaceCompleted);
  }

  /// Shared shell for task list/detail/create cards — project tint + border.
  static BoxDecoration taskCardDecorationOf(
    BuildContext context,
    Color accentColor, {
    bool completed = false,
    bool includeShadow = false,
    bool tinted = true,
  }) {
    final Color fill;
    if (tinted) {
      fill = taskCardOf(context, accentColor, completed: completed);
    } else {
      fill = neutralTaskCardFillOf(context, completed: completed);
    }

    final Color borderColor;
    final double borderWidth;
    if (!tinted) {
      borderColor = neutralTaskCardBorderOf(context, completed: completed);
      borderWidth = 1;
    } else {
      borderColor = projectBorderOf(context, accentColor);
      borderWidth = 1.5;
    }

    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: includeShadow && !completed
          ? tinted
              ? [
                  BoxShadow(
                    color: projectGlowOf(context, accentColor),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
          : null,
    );
  }

  /// Project/task accent — slightly lifted in dark mode for readable, vivid chips.
  static Color projectAccentOf(BuildContext context, Color color) {
    if (!isDark(context)) return color;
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation + 0.06).clamp(0.0, 0.72);
    final lightness = (hsl.lightness + 0.05).clamp(0.50, 0.60);
    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }

  /// Border color for project/task cards — fixed alpha, not affected by setting.
  static Color projectBorderOf(BuildContext context, Color accentColor) {
    final accent = projectAccentOf(context, accentColor);
    return AppOpacity.fixed(accent, AppOpacity.borderStrong);
  }

  /// Soft tint fill behind project icons and chips.
  static Color projectTintOf(
    BuildContext context,
    Color accentColor, {
    double lightAlpha = 0.15,
    double darkAlpha = 0.20,
  }) {
    return cardFillOf(
      context,
      accentColor: accentColor,
      lightTintAlpha: lightAlpha,
      darkTintAlpha: darkAlpha,
    );
  }

  /// Subtle glow/shadow from project accent — fixed, not affected by setting.
  static Color projectGlowOf(BuildContext context, Color accentColor) {
    final accent = projectAccentOf(context, accentColor);
    if (isDark(context)) {
      return accent.withValues(alpha: 0.0);
    }
    return AppOpacity.fixed(accent, AppOpacity.surfaceSubtle);
  }

  /// Muted accent for checkbox rings and secondary accents.
  static Color projectMutedAccentOf(BuildContext context, Color accentColor) {
    final accent = projectAccentOf(context, accentColor);
    return AppOpacity.fixed(accent, AppOpacity.textMuted);
  }

  /// Inset surface for nested cells (streak day, list rows).
  static Color insetSurfaceOf(BuildContext context) =>
      paletteOf(context).insetSurface;

  static Color primaryLightTintOf(BuildContext context, {double alpha = 0.3}) {
    if (isDark(context)) {
      return cardFillOf(
        context,
        accentColor: primaryOf(context),
        lightTintAlpha: alpha * 0.5,
        darkTintAlpha: alpha * 0.5,
      );
    }
    return cardFillOf(
      context,
      accentColor: primaryLightOf(context),
      lightTintAlpha: alpha,
      darkTintAlpha: alpha,
    );
  }

  /// Tinted stat/overview card background.
  static Color statCardBgOf(
    BuildContext context,
    Color accentColor, {
    double lightAlpha = 0.28,
    double darkAlpha = 0.28,
  }) {
    return cardFillOf(
      context,
      accentColor: accentColor,
      lightTintAlpha: lightAlpha,
      darkTintAlpha: darkAlpha,
    );
  }

  /// Tinted stat/overview card border — fixed alpha.
  static Color statCardBorderOf(BuildContext context, Color accentColor) {
    final accent = projectAccentOf(context, accentColor);
    final baseAlpha = isDark(context) ? AppOpacity.borderAccent : 0.2;
    return AppOpacity.fixed(accent, baseAlpha);
  }

  /// Icon well behind stat/overview card icons — fixed alpha.
  static Color statCardIconWellOf(BuildContext context, Color accentColor) {
    final accent = projectAccentOf(context, accentColor);
    return AppOpacity.fixed(accent, AppOpacity.iconWell);
  }

  /// Achievement-style icon well background (neutral — no accent tint).
  static Color accentIconWellFillOf(
    BuildContext context,
    Color accentColor, {
    bool muted = false,
  }) {
    if (muted) return insetSurfaceOf(context);
    if (isDark(context)) {
      return backgroundOf(context);
    }
    return Colors.white.withValues(alpha: 0.8);
  }

  /// Achievement-style icon foreground (and matching border color).
  static Color accentIconWellForegroundOf(
    BuildContext context,
    Color accentColor, {
    bool muted = false,
  }) {
    if (muted) return textSecondaryOf(context);
    return projectAccentOf(context, accentColor);
  }

  /// Pomodoro phase color tints — fixed alpha.
  static Color phaseTintOf(
    BuildContext context,
    Color phaseColor, {
    required double baseAlpha,
  }) {
    return AppOpacity.fixed(phaseColor, baseAlpha);
  }

  /// Completed-session check circle (focus history, session tiles).
  static Color completedCheckBgOf(BuildContext context) {
    if (isDark(context)) {
      return AppOpacity.fixed(primaryOf(context), 0.22);
    }
    return primaryLightOf(context);
  }

  static Color completedCheckFgOf(BuildContext context) =>
      isDark(context) ? primaryOf(context) : primaryDarkOf(context);

  /// In-app toast backgrounds — muted in dark mode to avoid glare.
  static Color notificationSuccessBgOf(BuildContext context) => isDark(context)
      ? const Color(0xFF2A3D2C)
      : primaryDarkOf(context);

  static Color notificationInfoBgOf(BuildContext context) => isDark(context)
      ? cardOf(context)
      : AppOpacity.fixed(textPrimaryOf(context), AppOpacity.notificationInfo);

  static Color notificationErrorBgOf(BuildContext context) => isDark(context)
      ? const Color(0xFF3D2A2A)
      : const Color(0xFFE57373);

  static Color notificationFgOn(BuildContext context, Color background) {
    return background.computeLuminance() > 0.55
        ? textPrimaryOf(context)
        : (isDark(context) ? darkTextPrimary : Colors.white);
  }

  /// Streak calendar tiles — stronger red/green/blue on dark backgrounds.
  static Color streakCompleteBorderOf(BuildContext context) {
    if (isDark(context)) {
      return const Color(0xFFFF5252);
    }
    return AppOpacity.fixed(streakRed, AppOpacity.borderStreak);
  }

  static Color streakCompleteFillOf(BuildContext context) {
    if (isDark(context)) {
      return AppOpacity.fixed(
        const Color(0xFFFF5252),
        AppOpacity.surfaceTintMedium,
      );
    }
    return AppOpacity.fixed(streakRed, AppOpacity.surfaceTint);
  }

  static Color streakMissedMarkOf(BuildContext context) => isDark(context)
      ? const Color(0xFFFF5252)
      : const Color(0xFFE53935);

  static Color streakFlameOf(BuildContext context) => isDark(context)
      ? const Color(0xFFFF9100)
      : streakFlame;

  static Color streakTodayAccentOf(BuildContext context) =>
      isDark(context) ? primaryOf(context) : primaryDarkOf(context);

  static Color streakFreezeBorderOf(BuildContext context) {
    if (isDark(context)) {
      return const Color(0xFF64C8F5);
    }
    return AppOpacity.fixed(freezeBlue, 0.4);
  }

  static Color streakFreezeFillOf(BuildContext context) {
    if (isDark(context)) {
      return AppOpacity.fixed(
        const Color(0xFF64C8F5),
        AppOpacity.surfaceTint,
      );
    }
    return AppOpacity.fixed(freezeBlue, 0.1);
  }

  static Color streakFreezeIconOf(BuildContext context) => isDark(context)
      ? const Color(0xFF64C8F5)
      : freezeBlue;

  /// Pomodoro Start/Pause pill — fixed translucency.
  static BoxDecoration pomodoroPlayButtonDecoration(
    BuildContext context, {
    required bool isRunning,
    required double borderRadius,
  }) {
    final dark = isDark(context);
    final accent = isRunning ? accentYellow : primaryOf(context);

    return BoxDecoration(
      color: AppOpacity.fixed(
        accent,
        dark ? 0.22 : AppOpacity.surfaceTintMedium,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppOpacity.fixed(accent, dark ? 0.45 : 0.38),
      ),
      boxShadow: [
        BoxShadow(
          color: AppOpacity.fixed(
            accent,
            dark ? AppOpacity.shadowAccentStrong : AppOpacity.shadowAccent,
          ),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static Color pomodoroPlayButtonLabelOf(
    BuildContext context, {
    required bool isRunning,
  }) {
    if (isRunning) return accentYellow;
    return isDark(context) ? primaryOf(context) : primaryDarkOf(context);
  }

  /// Segmented pill (Focus/Task, Week/Month) — selected fill; matches range chips.
  static Color segmentSelectedFillOf(BuildContext context) =>
      primaryDarkOf(context);

  /// Segmented pill — selected label.
  static Color segmentSelectedLabelOf(BuildContext context) => Colors.white;

  /// Calendar — selected day circle fill.
  static Color calendarSelectedDayFillOf(BuildContext context) =>
      isDark(context) ? primaryDarkOf(context) : primaryOf(context);

  /// Calendar — today ring when the day is not selected.
  static Color calendarTodayRingOf(BuildContext context) {
    if (isDark(context)) {
      return AppOpacity.fixed(primaryDarkOf(context), AppOpacity.todayRing);
    }
    return primaryDarkOf(context);
  }

  /// Calendar — selected day number.
  static Color calendarSelectedDayTextOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  /// Statistics bar chart — highlighted column.
  static Color chartBarActiveOf(BuildContext context) =>
      isDark(context) ? primaryOf(context) : primaryDarkOf(context);

  /// Statistics bar chart — default columns.
  static Color chartBarIdleOf(BuildContext context) {
    if (isDark(context)) {
      return AppOpacity.fixed(primaryOf(context), AppOpacity.chartIdle);
    }
    return primaryLightOf(context);
  }

  /// Statistics bar chart — label for highlighted column.
  static Color chartBarHighlightLabelOf(BuildContext context) =>
      isDark(context) ? primaryOf(context) : primaryDarkOf(context);
}
