import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Decorative background icons using a ROYGBIV spectrum.
/// Light mode: soft pastels. Dark mode: neon accents.
class _SpectrumTone {
  final Color light;
  final Color darkNeon;

  const _SpectrumTone({required this.light, required this.darkNeon});
}

class BackgroundPattern extends StatefulWidget {
  const BackgroundPattern({super.key});

  static const List<_SpectrumTone> _spectrum = [
    // Red — đỏ
    _SpectrumTone(light: Color(0xFFF5B0B0), darkNeon: Color(0xFFFF4D6D)),
    // Orange — cam
    _SpectrumTone(light: Color(0xFFF6C9A8), darkNeon: Color(0xFFFF8F3D)),
    // Yellow — vàng
    _SpectrumTone(light: Color(0xFFF6E6A8), darkNeon: Color(0xFFFFEA4D)),
    // Green — xanh lá
    _SpectrumTone(light: Color(0xFFA8CFA3), darkNeon: Color(0xFF5DFF8F)),
    // Blue — xanh lam
    _SpectrumTone(light: Color(0xFFA8C8F4), darkNeon: Color(0xFF4DA6FF)),
    // Indigo — chàm
    _SpectrumTone(light: Color(0xFFB0A8F4), darkNeon: Color(0xFF6B5DFF)),
    // Violet — tím
    _SpectrumTone(light: Color(0xFFD4A8F4), darkNeon: Color(0xFFC45DFF)),
  ];

  @override
  State<BackgroundPattern> createState() => _BackgroundPatternState();
}

class _BackgroundPatternState extends State<BackgroundPattern> {
  Size? _cachedSize;
  Brightness? _cachedBrightness;
  Widget? _cachedPattern;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (_cachedPattern == null ||
        _cachedSize != size ||
        _cachedBrightness != brightness) {
      _cachedSize = size;
      _cachedBrightness = brightness;
      _cachedPattern = _buildPattern(
        size,
        isDark: isDark,
        base: AppColors.backgroundOf(context),
      );
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: OverflowBox(
          maxWidth: size.width,
          maxHeight: size.height,
          alignment: Alignment.topCenter,
          child: _cachedPattern,
        ),
      ),
    );
  }

  _SpectrumTone _toneAt(int index) =>
      BackgroundPattern._spectrum[index % BackgroundPattern._spectrum.length];

  Color _resolveColor(bool isDark, int colorIndex) {
    final tone = _toneAt(colorIndex);
    return isDark ? tone.darkNeon : tone.light;
  }

  double _opacity(bool isDark, double light, double dark) {
    if (!isDark) return light;
    return (dark + 0.22).clamp(0.0, 0.82);
  }

  Widget _buildPattern(
    Size size, {
    required bool isDark,
    required Color base,
  }) {
    final width = size.width;
    final height = size.height;

    Widget icon(
      IconData iconData,
      int colorIndex,
      double lightOpacity,
      double darkOpacity,
      double iconSize,
      double? topPos,
      double? leftPos,
      double rotationDegrees, {
      double? right,
      double? bottom,
    }) {
      return _buildPatternIcon(
        width,
        height,
        iconData,
        _resolveColor(isDark, colorIndex),
        _opacity(isDark, lightOpacity, darkOpacity),
        iconSize,
        topPos,
        leftPos,
        rotationDegrees,
        right: right,
        bottom: bottom,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: base,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            icon(Icons.favorite, 0, 0.7, 0.50, 48, 0.05, 0.12, -15),
            icon(Icons.menu_book, 3, 0.6, 0.44, 36, 0.18, 0.06, 35),
            icon(Icons.star_rounded, 2, 0.8, 0.55, 30, 0.08, 0.28, 20),
            icon(Icons.schedule, 4, 0.6, 0.44, 44, 0.22, 0.22, -25),
            icon(Icons.lightbulb, 1, 0.7, 0.48, 28, 0.32, 0.08, 15),
            icon(Icons.local_florist, 3, 0.7, 0.48, 48, 0.08, null, 15, right: 0.15),
            icon(Icons.cloud, 4, 0.5, 0.40, 40, 0.22, null, -10, right: 0.25),
            icon(Icons.auto_awesome, 2, 0.8, 0.50, 32, 0.06, null, 45, right: 0.35),
            icon(Icons.filter_vintage, 0, 0.6, 0.44, 36, 0.30, null, -20, right: 0.08),
            icon(Icons.wb_sunny, 2, 0.6, 0.44, 26, 0.15, null, 30, right: 0.05),
            icon(Icons.eco, 3, 0.6, 0.44, 48, null, 0.08, 25, bottom: 0.12),
            icon(Icons.edit, 6, 0.6, 0.44, 38, null, 0.25, -15, bottom: 0.22),
            icon(Icons.note, 5, 0.7, 0.48, 44, null, 0.30, 15, bottom: 0.05),
            icon(Icons.emoji_objects, 1, 0.7, 0.48, 30, null, 0.12, -10, bottom: 0.30),
            icon(Icons.flag, 3, 0.5, 0.38, 34, null, 0.05, 5, bottom: 0.40),
            icon(Icons.local_cafe, 1, 0.7, 0.48, 48, null, null, -20, bottom: 0.18, right: 0.18),
            icon(Icons.sentiment_satisfied_alt, 2, 0.7, 0.48, 38, null, null, 30, bottom: 0.08, right: 0.35),
            icon(Icons.check_circle, 3, 0.6, 0.44, 44, null, null, 10, bottom: 0.28, right: 0.10),
            icon(Icons.headset, 5, 0.6, 0.44, 32, null, null, -15, bottom: 0.05, right: 0.10),
            icon(Icons.directions_run, 4, 0.6, 0.44, 40, null, null, 20, bottom: 0.40, right: 0.05),
            icon(Icons.calendar_month, 4, 0.6, 0.44, 32, 0.38, 0.10, 45),
            icon(Icons.favorite, 0, 0.6, 0.44, 40, null, null, -30, bottom: 0.45, right: 0.15),
            icon(Icons.bolt, 1, 0.7, 0.48, 36, 0.45, null, 15, right: 0.25),
            icon(Icons.push_pin, 6, 0.5, 0.38, 30, null, 0.35, -20, bottom: 0.35),
            icon(Icons.work_outline, 3, 0.6, 0.44, 34, 0.15, 0.40, -10),
            icon(Icons.code, 5, 0.5, 0.38, 42, 0.25, 0.60, 20),
            icon(Icons.brush, 6, 0.7, 0.48, 30, 0.35, 0.45, -25),
            icon(Icons.rocket_launch, 1, 0.6, 0.44, 38, 0.55, 0.25, 15),
            icon(Icons.extension, 5, 0.5, 0.38, 36, 0.65, 0.75, -30),
            icon(Icons.mic, 6, 0.6, 0.44, 28, 0.80, 0.50, 10),
            icon(Icons.music_note, 2, 0.7, 0.48, 34, 0.75, 0.30, -15),
            icon(Icons.coffee, 1, 0.6, 0.44, 40, 0.10, 0.70, 25),
            icon(Icons.spa, 0, 0.7, 0.48, 32, 0.45, 0.80, -10),
            icon(Icons.sports_esports, 4, 0.6, 0.44, 38, 0.85, 0.80, 35),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternIcon(
    double maxWidth,
    double maxHeight,
    IconData icon,
    Color color,
    double opacity,
    double size,
    double? topPos,
    double? leftPos,
    double rotationDegrees, {
    double? right,
    double? bottom,
  }) {
    return Positioned(
      top: topPos != null ? maxHeight * topPos : null,
      left: leftPos != null ? maxWidth * leftPos : null,
      right: right != null ? maxWidth * right : null,
      bottom: bottom != null ? maxHeight * bottom : null,
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
}
