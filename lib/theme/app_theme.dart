import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/activity_mode.dart';
import 'activity_mode_palette.dart';

class AppTheme {
  static ThemeData get lightTheme => build(
        brightness: Brightness.light,
        palette: ActivityModePalette.forMode(
          ActivityModeId.defaultMode,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get darkTheme => build(
        brightness: Brightness.dark,
        palette: ActivityModePalette.forMode(
          ActivityModeId.defaultMode,
          brightness: Brightness.dark,
        ),
      );

  static ThemeData build({
    required Brightness brightness,
    required ActivityModePalette palette,
  }) {
    final dark = brightness == Brightness.dark;
    final onPrimary = palette.textPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [palette],
      colorScheme: dark
          ? ColorScheme.dark(
              primary: palette.primary,
              onPrimary: onPrimary,
              secondary: palette.primaryDark,
              onSecondary: palette.textPrimary,
              surface: palette.surface,
              onSurface: palette.textPrimary,
              error: palette.accentPeach,
              onError: palette.textPrimary,
            )
          : ColorScheme.light(
              primary: palette.primary,
              onPrimary: onPrimary,
              secondary: palette.primaryLight,
              onSecondary: palette.textPrimary,
              surface: palette.surface,
              onSurface: palette.textPrimary,
              error: palette.accentPeach,
              onError: palette.textPrimary,
            ),
      scaffoldBackgroundColor: palette.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: palette.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.textPrimary,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        hintStyle: TextStyle(color: palette.textSecondary),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.macOS: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.windows: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.linux: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
