import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Inline Cupertino duration wheel (hours + minutes).
class AppCupertinoDurationPicker extends StatelessWidget {
  final Duration duration;
  final ValueChanged<Duration> onDurationChanged;
  final double height;
  final Color? accentColor;

  const AppCupertinoDurationPicker({
    super.key,
    required this.duration,
    required this.onDurationChanged,
    this.height = 180,
    this.accentColor,
  });

  static const Duration minDuration = Duration(minutes: 1);
  static const Duration maxDuration = Duration(hours: 23, minutes: 59);

  static Duration _clamp(Duration value) {
    if (value < minDuration) return minDuration;
    if (value > maxDuration) return maxDuration;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accentColor ?? AppColors.primaryDarkOf(context);

    return SizedBox(
      height: height,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: Theme.of(context).brightness,
          primaryColor: resolvedAccent,
          textTheme: CupertinoTextThemeData(
            pickerTextStyle: TextStyle(
              fontSize: 20,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ),
        child: CupertinoTimerPicker(
          mode: CupertinoTimerPickerMode.hm,
          initialTimerDuration: _clamp(duration),
          onTimerDurationChanged: (value) {
            onDurationChanged(_clamp(value));
          },
        ),
      ),
    );
  }
}

String formatDurationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) {
    return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes min';
  }
  if (hours > 0) {
    return '$hours ${hours == 1 ? 'hour' : 'hours'}';
  }
  return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
}
