import 'package:flutter/material.dart';

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

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  /// Drawer header strip behind profile greeting.
  static Color drawerHeaderOf(BuildContext context) => isDark(context)
      ? const Color(0xFF2A332E)
      : primaryLight;

  /// Cards/lists on top of scaffold background.
  static Color cardOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF2D3530) : surface;

  /// Task list/detail card tinted by project accent.
  static Color taskCardOf(
    BuildContext context,
    Color accentColor, {
    bool completed = false,
  }) {
    if (completed) {
      // Neutral completed tone — translucent only, not project-tinted.
      if (isDark(context)) {
        return const Color(0xFF232A26).withValues(alpha: 0.62);
      }
      return background.withValues(alpha: 0.68);
    }
    final accent = projectAccentOf(context, accentColor);
    // Translucent tint — same approach as Home overview/quick-action cards.
    return accent.withValues(alpha: 0.18);
  }

  /// Project/task accent — slightly lifted in dark mode for readable, vivid chips.
  static Color projectAccentOf(BuildContext context, Color color) {
    if (!isDark(context)) return color;
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation + 0.06).clamp(0.0, 0.72);
    final lightness = (hsl.lightness + 0.05).clamp(0.50, 0.60);
    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }

  /// Border color for project/task cards.
  static Color projectBorderOf(BuildContext context, Color accentColor) {
    final accent = projectAccentOf(context, accentColor);
    return accent.withValues(alpha: 0.5);
  }

  /// Soft tint fill behind project icons and chips.
  static Color projectTintOf(
    BuildContext context,
    Color accentColor, {
    double lightAlpha = 0.15,
    double darkAlpha = 0.20,
  }) {
    final accent = projectAccentOf(context, accentColor);
    return accent.withValues(alpha: isDark(context) ? darkAlpha : lightAlpha);
  }

  /// Subtle glow/shadow from project accent.
  static Color projectGlowOf(BuildContext context, Color accentColor) {
    final accent = projectAccentOf(context, accentColor);
    return accent.withValues(alpha: isDark(context) ? 0.0 : 0.04);
  }

  /// Muted accent for checkbox rings and secondary accents.
  static Color projectMutedAccentOf(BuildContext context, Color accentColor) {
    final accent = projectAccentOf(context, accentColor);
    return accent.withValues(alpha: isDark(context) ? 0.50 : 0.5);
  }

  /// Inset surface for nested cells (streak day, list rows).
  static Color insetSurfaceOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF232A26) : background;

  static Color primaryLightTintOf(BuildContext context, {double alpha = 0.3}) =>
      isDark(context)
          ? primary.withValues(alpha: alpha * 0.5)
          : primaryLight.withValues(alpha: alpha);

  /// Completed-session check circle (focus history, session tiles).
  static Color completedCheckBgOf(BuildContext context) =>
      isDark(context)
          ? primary.withValues(alpha: 0.22)
          : primaryLight;

  static Color completedCheckFgOf(BuildContext context) =>
      isDark(context) ? primary : primaryDark;

  /// In-app toast backgrounds — muted in dark mode to avoid glare.
  static Color notificationSuccessBgOf(BuildContext context) => isDark(context)
      ? const Color(0xFF2A3D2C)
      : primaryDark;

  static Color notificationInfoBgOf(BuildContext context) => isDark(context)
      ? cardOf(context)
      : textPrimary.withValues(alpha: 0.95);

  static Color notificationErrorBgOf(BuildContext context) => isDark(context)
      ? const Color(0xFF3D2A2A)
      : const Color(0xFFE57373);

  static Color notificationFgOn(BuildContext context, Color background) {
    return background.computeLuminance() > 0.55
        ? textPrimary
        : (isDark(context) ? darkTextPrimary : Colors.white);
  }

  /// Streak calendar tiles — stronger red/green/blue on dark backgrounds.
  static Color streakCompleteBorderOf(BuildContext context) => isDark(context)
      ? const Color(0xFFFF5252)
      : streakRed.withValues(alpha: 0.55);

  static Color streakCompleteFillOf(BuildContext context) => isDark(context)
      ? const Color(0xFFFF5252).withValues(alpha: 0.2)
      : streakRed.withValues(alpha: 0.18);

  static Color streakMissedMarkOf(BuildContext context) => isDark(context)
      ? const Color(0xFFFF5252)
      : const Color(0xFFE53935);

  static Color streakFlameOf(BuildContext context) => isDark(context)
      ? const Color(0xFFFF9100)
      : streakFlame;

  static Color streakTodayAccentOf(BuildContext context) =>
      isDark(context) ? primary : primaryDark;

  /// Statistics bar chart — highlighted column.
  static Color chartBarActiveOf(BuildContext context) =>
      isDark(context) ? primary : primaryDark;

  /// Statistics bar chart — default columns.
  static Color chartBarIdleOf(BuildContext context) => isDark(context)
      ? primary.withValues(alpha: 0.32)
      : primaryLight;

  /// Statistics bar chart — label for highlighted column.
  static Color chartBarHighlightLabelOf(BuildContext context) =>
      isDark(context) ? primary : primaryDark;

  static Color streakFreezeBorderOf(BuildContext context) => isDark(context)
      ? const Color(0xFF64C8F5)
      : freezeBlue.withValues(alpha: 0.4);

  static Color streakFreezeFillOf(BuildContext context) => isDark(context)
      ? const Color(0xFF64C8F5).withValues(alpha: 0.18)
      : freezeBlue.withValues(alpha: 0.1);

  static Color streakFreezeIconOf(BuildContext context) => isDark(context)
      ? const Color(0xFF64C8F5)
      : freezeBlue;

  /// Pomodoro Start/Pause pill — slightly translucent in both states.
  static BoxDecoration pomodoroPlayButtonDecoration(
    BuildContext context, {
    required bool isRunning,
    required double borderRadius,
  }) {
    final dark = isDark(context);
    final accent = isRunning ? accentYellow : primary;

    return BoxDecoration(
      color: accent.withValues(alpha: dark ? 0.22 : 0.2),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: accent.withValues(alpha: dark ? 0.45 : 0.38),
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: dark ? 0.28 : 0.22),
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
    return isDark(context) ? primary : primaryDark;
  }

  /// Segmented pill (Focus/Task, Week/Month) — selected fill.
  static Color segmentSelectedFillOf(BuildContext context) =>
      isDark(context) ? primaryDark : primary;

  /// Segmented pill — selected label.
  static Color segmentSelectedLabelOf(BuildContext context) => Colors.white;

  /// Calendar — selected day circle fill.
  static Color calendarSelectedDayFillOf(BuildContext context) =>
      isDark(context) ? primaryDark : primary;

  /// Calendar — today ring when the day is not selected.
  static Color calendarTodayRingOf(BuildContext context) =>
      isDark(context)
          ? primaryDark.withValues(alpha: 0.75)
          : primaryDark;

  /// Calendar — selected day number.
  static Color calendarSelectedDayTextOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;
}
