import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

/// Decorative background icons using a ROYGBIV spectrum.
/// Light mode: vivid pastels. Dark mode: neon accents.
class _SpectrumTone {
  final Color light;
  final Color darkNeon;

  const _SpectrumTone({required this.light, required this.darkNeon});
}

class _DecorIconSpec {
  final IconData icon;
  final int colorIndex;
  final double x;
  final double y;
  final double size;
  final double rotation;
  final double lightOpacity;
  final double darkOpacity;

  const _DecorIconSpec({
    required this.icon,
    required this.colorIndex,
    required this.x,
    required this.y,
    this.size = 36,
    this.rotation = 0,
    this.lightOpacity = 0.65,
    this.darkOpacity = 0.44,
  });
}

class BackgroundPattern extends StatelessWidget {
  const BackgroundPattern({super.key});

  static const List<_SpectrumTone> _spectrum = [
    _SpectrumTone(light: Color(0xFFF5B0B0), darkNeon: Color(0xFFFF4D6D)),
    _SpectrumTone(light: Color(0xFFF6C9A8), darkNeon: Color(0xFFFF8F3D)),
    _SpectrumTone(light: Color(0xFFF6E6A8), darkNeon: Color(0xFFFFEA4D)),
    _SpectrumTone(light: Color(0xFFA8CFA3), darkNeon: Color(0xFF5DFF8F)),
    _SpectrumTone(light: Color(0xFFA8C8F4), darkNeon: Color(0xFF4DA6FF)),
    _SpectrumTone(light: Color(0xFFB0A8F4), darkNeon: Color(0xFF6B5DFF)),
    _SpectrumTone(light: Color(0xFFD4A8F4), darkNeon: Color(0xFFC45DFF)),
  ];

  /// Even staggered layout — one icon per zone, avoids edge/corner clusters.
  static const List<_DecorIconSpec> _decorIcons = [
    _DecorIconSpec(icon: Icons.favorite, colorIndex: 0, x: 0.10, y: 0.06, size: 44, rotation: -15, lightOpacity: 0.72),
    _DecorIconSpec(icon: Icons.menu_book, colorIndex: 3, x: 0.32, y: 0.06, size: 34, rotation: 35),
    _DecorIconSpec(icon: Icons.star_rounded, colorIndex: 2, x: 0.54, y: 0.06, size: 30, rotation: 20, lightOpacity: 0.78),
    _DecorIconSpec(icon: Icons.schedule, colorIndex: 4, x: 0.76, y: 0.06, size: 40, rotation: -25),
    _DecorIconSpec(icon: Icons.lightbulb, colorIndex: 1, x: 0.90, y: 0.06, size: 28, rotation: 15, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.water_drop, colorIndex: 4, x: 0.02, y: 0.16, size: 30, rotation: 25),
    _DecorIconSpec(icon: Icons.local_florist, colorIndex: 3, x: 0.18, y: 0.16, size: 46, rotation: 15, lightOpacity: 0.68),
    _DecorIconSpec(icon: Icons.cloud, colorIndex: 4, x: 0.42, y: 0.16, size: 38, rotation: -10, lightOpacity: 0.52, darkOpacity: 0.40),
    _DecorIconSpec(icon: Icons.auto_awesome, colorIndex: 2, x: 0.66, y: 0.16, size: 32, rotation: 45, lightOpacity: 0.78),
    _DecorIconSpec(icon: Icons.filter_vintage, colorIndex: 0, x: 0.86, y: 0.16, size: 34, rotation: -20),
    _DecorIconSpec(icon: Icons.wb_sunny, colorIndex: 2, x: 0.08, y: 0.28, size: 28, rotation: 30),
    _DecorIconSpec(icon: Icons.eco, colorIndex: 3, x: 0.30, y: 0.28, size: 44, rotation: 25),
    _DecorIconSpec(icon: Icons.edit, colorIndex: 6, x: 0.52, y: 0.28, size: 36, rotation: -15),
    _DecorIconSpec(icon: Icons.note, colorIndex: 5, x: 0.74, y: 0.28, size: 40, rotation: 15, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.emoji_objects, colorIndex: 1, x: 0.92, y: 0.28, size: 30, rotation: -10, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.pets, colorIndex: 2, x: 0.04, y: 0.40, size: 34, rotation: -15, lightOpacity: 0.65),
    _DecorIconSpec(icon: Icons.flag, colorIndex: 3, x: 0.20, y: 0.40, size: 32, rotation: 5, lightOpacity: 0.52, darkOpacity: 0.38),
    _DecorIconSpec(icon: Icons.local_cafe, colorIndex: 1, x: 0.44, y: 0.40, size: 46, rotation: -20, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.sentiment_satisfied_alt, colorIndex: 2, x: 0.68, y: 0.40, size: 36, rotation: 30, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.check_circle, colorIndex: 3, x: 0.88, y: 0.40, size: 40, rotation: 10),
    _DecorIconSpec(icon: Icons.headset, colorIndex: 5, x: 0.10, y: 0.52, size: 30, rotation: -15),
    _DecorIconSpec(icon: Icons.directions_run, colorIndex: 4, x: 0.36, y: 0.52, size: 38, rotation: 20),
    _DecorIconSpec(icon: Icons.calendar_month, colorIndex: 4, x: 0.58, y: 0.52, size: 32, rotation: 45),
    _DecorIconSpec(icon: Icons.favorite, colorIndex: 0, x: 0.82, y: 0.52, size: 36, rotation: -30),
    _DecorIconSpec(icon: Icons.local_fire_department, colorIndex: 0, x: 0.02, y: 0.64, size: 38, rotation: 20, lightOpacity: 0.60),
    _DecorIconSpec(icon: Icons.bolt, colorIndex: 1, x: 0.22, y: 0.64, size: 34, rotation: 15, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.push_pin, colorIndex: 6, x: 0.48, y: 0.64, size: 28, rotation: -20, lightOpacity: 0.52, darkOpacity: 0.38),
    _DecorIconSpec(icon: Icons.work_outline, colorIndex: 3, x: 0.72, y: 0.64, size: 32, rotation: -10),
    _DecorIconSpec(icon: Icons.code, colorIndex: 5, x: 0.06, y: 0.76, size: 40, rotation: 20, lightOpacity: 0.52),
    _DecorIconSpec(icon: Icons.brush, colorIndex: 6, x: 0.28, y: 0.76, size: 30, rotation: -25, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.rocket_launch, colorIndex: 1, x: 0.50, y: 0.76, size: 36, rotation: 15),
    _DecorIconSpec(icon: Icons.extension, colorIndex: 5, x: 0.74, y: 0.76, size: 34, rotation: -30, lightOpacity: 0.52),
    _DecorIconSpec(icon: Icons.mic, colorIndex: 6, x: 0.90, y: 0.76, size: 28, rotation: 10),
    _DecorIconSpec(icon: Icons.bedtime, colorIndex: 5, x: 0.04, y: 0.88, size: 32, rotation: -25, lightOpacity: 0.65),
    _DecorIconSpec(icon: Icons.music_note, colorIndex: 2, x: 0.16, y: 0.88, size: 32, rotation: -15, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.coffee, colorIndex: 1, x: 0.40, y: 0.88, size: 38, rotation: 25),
    _DecorIconSpec(icon: Icons.spa, colorIndex: 0, x: 0.64, y: 0.88, size: 30, rotation: -10, lightOpacity: 0.70),
    _DecorIconSpec(icon: Icons.sports_esports, colorIndex: 4, x: 0.84, y: 0.88, size: 36, rotation: 35),
  ];

  static _SpectrumTone _toneAt(int index) =>
      _spectrum[index % _spectrum.length];

  /// Max icons per designed row — keeps the full vertical grid on all screens.
  static int _maxIconsPerRow(Size size) {
    if (size.width < 360) return 2;
    if (size.width < 480) return 3;
    if (size.width < 640) return 4;
    return _decorIcons.length;
  }

  /// Evenly picks [count] items from [icons] (sorted left → right).
  static List<_DecorIconSpec> _pickEvenly(
    List<_DecorIconSpec> icons,
    int count,
  ) {
    if (icons.length <= count) return List<_DecorIconSpec>.of(icons);
    if (count <= 1) return [icons[icons.length ~/ 2]];

    final picked = <_DecorIconSpec>[];
    for (var i = 0; i < count; i++) {
      final idx = (i * (icons.length - 1) / (count - 1)).round();
      picked.add(icons[idx]);
    }
    return picked;
  }

  /// Keeps every designed row; thins columns on narrow screens so spacing stays even.
  static List<_DecorIconSpec> _iconsForSize(Size size) {
    if (size.width >= 640) return _decorIcons;

    final maxPerRow = _maxIconsPerRow(size);
    final rows = <double, List<_DecorIconSpec>>{};
    for (final spec in _decorIcons) {
      (rows[spec.y] ??= []).add(spec);
    }

    final selected = <_DecorIconSpec>[];
    for (final y in (rows.keys.toList()..sort())) {
      final row = rows[y]!..sort((a, b) => a.x.compareTo(b.x));
      selected.addAll(_pickEvenly(row, maxPerRow));
    }
    return selected;
  }

  static double _iconSizeForScreen(double baseSize, Size size) {
    if (size.shortestSide < 400) return baseSize * 0.88;
    if (size.shortestSide < 600) return baseSize * 0.94;
    return baseSize;
  }

  static Color _resolveColor(bool isDark, int colorIndex) {
    final tone = _toneAt(colorIndex);
    if (isDark) return tone.darkNeon;
    return _vividLightColor(tone.light);
  }

  static Color _vividLightColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation + 0.16).clamp(0.0, 0.78);
    final lightness = (hsl.lightness - 0.05).clamp(0.48, 0.68);
    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }

  static double _opacity(bool isDark, double light, double dark) {
    if (!isDark) return (light + 0.06).clamp(0.0, 0.88);
    return (dark + 0.22).clamp(0.0, 0.82);
  }

  static Widget _buildPatternIcon(
    double maxWidth,
    double maxHeight,
    IconData icon,
    Color color,
    double opacity,
    double size,
    double x,
    double y,
    double rotationDegrees,
  ) {
    return Positioned(
      left: maxWidth * x,
      top: maxHeight * y,
      child: Transform.rotate(
        angle: rotationDegrees * (math.pi / 180),
        child: Icon(
          icon,
          color: color.withValues(alpha: opacity),
          size: size,
        ),
      ),
    );
  }

  static Widget _buildPattern(
    Size size, {
    required bool isDark,
    required Color base,
    required bool showDecorIcons,
  }) {
    if (!showDecorIcons) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: ColoredBox(color: base),
      );
    }

    return SizedBox(
      width: size.width,
      height: size.height,
      child: ColoredBox(
        color: base,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final spec in _iconsForSize(size))
              _buildPatternIcon(
                size.width,
                size.height,
                spec.icon,
                _resolveColor(isDark, spec.colorIndex),
                _opacity(isDark, spec.lightOpacity, spec.darkOpacity),
                _iconSizeForScreen(spec.size, size),
                spec.x,
                spec.y,
                spec.rotation,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    context.watch<SettingsProvider>();
    final decorEnabled =
        context.read<SettingsProvider>().backgroundDecorIconsEnabled;
    final pattern = _buildPattern(
      size,
      isDark: isDark,
      base: AppColors.backgroundOf(context),
      showDecorIcons: decorEnabled,
    );

    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: pattern,
        ),
      ),
    );
  }
}
