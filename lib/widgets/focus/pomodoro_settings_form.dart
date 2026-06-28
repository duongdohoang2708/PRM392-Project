import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_opacity.dart';

class PomodoroSettingsForm extends StatefulWidget {
  final int initialFocusMinutes;
  final int initialShortBreakMinutes;
  final int initialLongBreakMinutes;
  final int initialRounds;
  final int initialLongBreakInterval;
  final void Function(
    int focus,
    int shortBreak,
    int longBreak,
    int rounds,
    int interval,
  ) onSave;
  final bool showHeader;
  final String saveLabel;
  final bool showSaveButton;
  final bool autoSaveOnDispose;

  const PomodoroSettingsForm({
    super.key,
    required this.initialFocusMinutes,
    required this.initialShortBreakMinutes,
    required this.initialLongBreakMinutes,
    required this.initialRounds,
    required this.initialLongBreakInterval,
    required this.onSave,
    this.showHeader = false,
    this.saveLabel = 'Save Settings',
    this.showSaveButton = true,
    this.autoSaveOnDispose = false,
  });

  @override
  State<PomodoroSettingsForm> createState() => _PomodoroSettingsFormState();
}

class _PomodoroSettingsFormState extends State<PomodoroSettingsForm> {
  late int _focusMinutes;
  late int _shortBreakMinutes;
  late int _longBreakMinutes;
  late int _rounds;
  late int _longBreakInterval;
  String _selectedPreset = 'Custom';

  @override
  void initState() {
    super.initState();
    _focusMinutes = widget.initialFocusMinutes;
    _shortBreakMinutes = widget.initialShortBreakMinutes;
    _longBreakMinutes = widget.initialLongBreakMinutes;
    _rounds = widget.initialRounds;
    _longBreakInterval = widget.initialLongBreakInterval;
    _determinePreset();
  }

  void _determinePreset() {
    if (_focusMinutes == 25 &&
        _shortBreakMinutes == 5 &&
        _longBreakMinutes == 15) {
      _selectedPreset = 'Standard';
    } else if (_focusMinutes == 50 &&
        _shortBreakMinutes == 10 &&
        _longBreakMinutes == 15) {
      _selectedPreset = 'Long';
    } else {
      _selectedPreset = 'Custom';
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset == 'Standard') {
        _focusMinutes = 25;
        _shortBreakMinutes = 5;
        _longBreakMinutes = 15;
      } else if (preset == 'Long') {
        _focusMinutes = 50;
        _shortBreakMinutes = 10;
        _longBreakMinutes = 15;
      }
    });
  }

  void _setCustom() {
    if (_selectedPreset != 'Custom') {
      setState(() => _selectedPreset = 'Custom');
    }
  }

  bool get _hasUnsavedChanges {
    return _focusMinutes != widget.initialFocusMinutes ||
        _shortBreakMinutes != widget.initialShortBreakMinutes ||
        _longBreakMinutes != widget.initialLongBreakMinutes ||
        _rounds != widget.initialRounds ||
        _longBreakInterval != widget.initialLongBreakInterval;
  }

  void _persistChanges() {
    widget.onSave(
      _focusMinutes,
      _shortBreakMinutes,
      _longBreakMinutes,
      _rounds,
      _longBreakInterval,
    );
  }

  @override
  void dispose() {
    if (widget.autoSaveOnDispose && _hasUnsavedChanges) {
      _persistChanges();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Text(
            'Default timer durations used when starting a new focus session.',
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPresetButton('Standard', '25/5/15'),
            _buildPresetButton('Long', '50/10/15'),
            _buildPresetButton('Custom', 'Edit'),
          ],
        ),
        const SizedBox(height: 20),
        PomodoroSettingSlider(
          title: 'Work',
          subtitle: 'Focus time',
          icon: Icons.menu_book,
          color: AppColors.primary,
          value: _focusMinutes,
          min: 5,
          max: 60,
          markers: const [5, 15, 25, 45, 60],
          onChanged: (val) {
            setState(() => _focusMinutes = val.toInt());
            _setCustom();
          },
        ),
        const SizedBox(height: 16),
        PomodoroSettingSlider(
          title: 'Short Break',
          subtitle: 'Quick rest',
          icon: Icons.local_cafe,
          color: AppColors.accentPeach,
          value: _shortBreakMinutes,
          min: 1,
          max: 30,
          markers: const [1, 5, 15, 30],
          onChanged: (val) {
            setState(() => _shortBreakMinutes = val.toInt());
            _setCustom();
          },
        ),
        const SizedBox(height: 16),
        PomodoroSettingSlider(
          title: 'Long Break',
          subtitle: 'Extended rest',
          icon: Icons.nightlight_round,
          color: AppColors.accentYellow,
          value: _longBreakMinutes,
          min: 5,
          max: 60,
          markers: const [5, 15, 30, 60],
          onChanged: (val) {
            setState(() => _longBreakMinutes = val.toInt());
            _setCustom();
          },
        ),
        const SizedBox(height: 16),
        PomodoroSettingStepper(
          title: 'Sessions',
          subtitle: 'Number of sessions',
          icon: Icons.loop,
          color: const Color(0xFFE57373),
          value: _rounds,
          min: 1,
          max: 10,
          onChanged: (val) => setState(() => _rounds = val),
        ),
        const SizedBox(height: 16),
        PomodoroSettingStepper(
          title: 'Long Break Interval',
          subtitle: 'Every N sessions',
          icon: Icons.calendar_today,
          color: const Color(0xFFFFB74D),
          value: _longBreakInterval,
          min: 1,
          max: 10,
          onChanged: (val) => setState(() => _longBreakInterval = val),
        ),
        if (widget.showSaveButton) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _persistChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                widget.saveLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetButton(String title, String subtitle) {
    final isSelected = _selectedPreset == title;
    final isDark = AppColors.isDark(context);
    final selectedBg = isDark
        ? AppColors.cardFillOf(
            context,
            accentColor: AppColors.primary,
            lightTintAlpha: 0.22,
            darkTintAlpha: 0.22,
          )
        : AppColors.primaryLightTintOf(context, alpha: 0.55);
    final selectedBorder =
        isDark ? AppColors.primary : AppColors.primaryDark;
    final selectedTitleColor =
        isDark ? AppColors.textPrimaryOf(context) : AppColors.primaryDark;
    final selectedSubtitleColor = isDark
        ? AppColors.textSecondaryOf(context)
        : AppOpacity.fixed(AppColors.primaryDark, 0.75);

    return GestureDetector(
      onTap: () => _applyPreset(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? selectedBorder
                : AppColors.borderOf(context),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected
                    ? selectedTitleColor
                    : AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? selectedSubtitleColor
                    : AppOpacity.fixed(
                        AppColors.textSecondaryOf(context),
                        0.7,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PomodoroSettingSlider extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int value;
  final double min;
  final double max;
  final List<int> markers;
  final ValueChanged<double> onChanged;

  const PomodoroSettingSlider({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.min,
    required this.max,
    required this.markers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceFillOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppOpacity.fixed(color, 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                color: AppColors.textSecondaryOf(context),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                color: AppColors.textSecondaryOf(context),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 16,
                      child: DottedSlider(
                        value: value.toDouble(),
                        min: min,
                        max: max,
                        color: color,
                        onChanged: onChanged,
                      ),
                    ),
                    ...markers.map((m) {
                      final ratio = ((m - min) / (max - min)).clamp(0.0, 1.0);
                      final style = TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondaryOf(context),
                      );
                      if (ratio == 0.0) {
                        return Positioned(
                          left: 0,
                          top: 28,
                          child: Text('$m min', style: style),
                        );
                      } else if (ratio == 1.0) {
                        return Positioned(
                          right: 0,
                          top: 28,
                          child: Text('$m min', style: style),
                        );
                      }
                      return Positioned(
                        left: ratio * constraints.maxWidth,
                        top: 28,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, 0),
                          child: Text('$m min', style: style),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PomodoroSettingStepper extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const PomodoroSettingStepper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceFillOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppOpacity.fixed(color, 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
            color: AppColors.textSecondaryOf(context),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.textSecondaryOf(context),
          ),
        ],
      ),
    );
  }
}

class DottedSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const DottedSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        _handleGesture(context, details.localPosition.dx);
      },
      onTapDown: (details) {
        _handleGesture(context, details.localPosition.dx);
      },
      child: CustomPaint(
        painter: DottedSliderPainter(
          value: value,
          min: min,
          max: max,
          color: color,
          inactiveTrackColor: AppOpacity.fixed(color, 0.2),
          dotColor: AppColors.borderOf(context),
        ),
      ),
    );
  }

  void _handleGesture(BuildContext context, double dx) {
    final box = context.findRenderObject() as RenderBox;
    final ratio = (dx / box.size.width).clamp(0.0, 1.0);
    final newValue = min + ratio * (max - min);
    onChanged(newValue.roundToDouble());
  }
}

class DottedSliderPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;
  final Color inactiveTrackColor;
  final Color dotColor;

  DottedSliderPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.inactiveTrackColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 16.0;
    final trackY = size.height / 2;
    final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final activeWidth = size.width * ratio;

    final inactivePaint = Paint()
      ..color = inactiveTrackColor
      ..style = PaintingStyle.fill;
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackY - trackHeight / 2, size.width, trackHeight),
        Radius.circular(trackHeight / 2),
      ),
      inactivePaint,
    );

    if (activeWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, trackY - trackHeight / 2, activeWidth, trackHeight),
          Radius.circular(trackHeight / 2),
        ),
        activePaint,
      );
    }

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final numDots = (max - min).toInt();
    if (numDots > 0) {
      final dotSpacing = size.width / numDots;
      for (var i = 1; i <= numDots; i++) {
        final dotX = i * dotSpacing;
        if (dotX < size.width) {
          canvas.drawCircle(Offset(dotX, trackY), 1.5, dotPaint);
        }
      }
    }

    final thumbPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const thumbWidth = 4.0;
    const thumbHeight = 34.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          activeWidth - thumbWidth / 2,
          trackY - thumbHeight / 2,
          thumbWidth,
          thumbHeight,
        ),
        const Radius.circular(2),
      ),
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(DottedSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.color != color;
  }
}
