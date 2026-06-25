import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PomodoroSettingsPopup extends StatefulWidget {
  final int initialFocusMinutes;
  final int initialShortBreakMinutes;
  final int initialLongBreakMinutes;
  final int initialRounds;
  final int initialLongBreakInterval;
  final Function(
    int focus,
    int shortBreak,
    int longBreak,
    int rounds,
    int interval,
  )
  onSave;

  const PomodoroSettingsPopup({
    super.key,
    required this.initialFocusMinutes,
    required this.initialShortBreakMinutes,
    required this.initialLongBreakMinutes,
    required this.initialRounds,
    required this.initialLongBreakInterval,
    required this.onSave,
  });

  @override
  State<PomodoroSettingsPopup> createState() => _PomodoroSettingsPopupState();
}

class _PomodoroSettingsPopupState extends State<PomodoroSettingsPopup> {
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
      setState(() {
        _selectedPreset = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Align(
        alignment: isMobile ? Alignment.center : Alignment.centerRight,
        child: Container(
          width: isMobile ? double.infinity : 400,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 16,
                    top: 16,
                    bottom: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Timer Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Presets
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresetButton('Standard', '25/5/15'),
                      _buildPresetButton('Long', '50/10/15'),
                      _buildPresetButton('Custom', 'Edit'),
                    ],
                  ),
                ),

                const Divider(color: AppColors.border, height: 1),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSettingSlider(
                          title: 'Work',
                          subtitle: 'Focus time',
                          icon: Icons.menu_book,
                          color: AppColors.primary,
                          value: _focusMinutes,
                          min: 5,
                          max: 60,
                          markers: [5, 15, 25, 45, 60],
                          onChanged: (val) {
                            setState(() => _focusMinutes = val.toInt());
                            _setCustom();
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSettingSlider(
                          title: 'Short Break',
                          subtitle: 'Quick rest',
                          icon: Icons.local_cafe,
                          color: AppColors.accentPeach,
                          value: _shortBreakMinutes,
                          min: 1,
                          max: 30,
                          markers: [1, 5, 15, 30],
                          onChanged: (val) {
                            setState(() => _shortBreakMinutes = val.toInt());
                            _setCustom();
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSettingSlider(
                          title: 'Long Break',
                          subtitle: 'Extended rest',
                          icon: Icons.nightlight_round,
                          color: AppColors
                              .accentYellow, // Or use purple if preferred
                          value: _longBreakMinutes,
                          min: 5,
                          max: 60,
                          markers: [5, 15, 30, 60],
                          onChanged: (val) {
                            setState(() => _longBreakMinutes = val.toInt());
                            _setCustom();
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSettingStepper(
                          title: 'Sessions',
                          subtitle: 'Number of sessions',
                          icon: Icons.loop,
                          color: const Color(0xFFE57373), // Accent color
                          value: _rounds,
                          min: 1,
                          max: 10,
                          onChanged: (val) => setState(() => _rounds = val),
                        ),
                        const SizedBox(height: 20),
                        _buildSettingStepper(
                          title: 'Long Break Interval',
                          subtitle: 'Every N sessions',
                          icon: Icons.calendar_today,
                          color: const Color(0xFFFFB74D), // Accent color
                          value: _longBreakInterval,
                          min: 1,
                          max: 10,
                          onChanged: (val) =>
                              setState(() => _longBreakInterval = val),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onSave(
                                _focusMinutes,
                                _shortBreakMinutes,
                                _longBreakMinutes,
                                _rounds,
                                _longBreakInterval,
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: const Text(
                              'Save Settings',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(String title, String subtitle) {
    final isSelected = _selectedPreset == title;
    return GestureDetector(
      onTap: () => _applyPreset(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSlider({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int value,
    required double min,
    required double max,
    required List<int> markers,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ), // Minimum spacing to prevent text from touching
              Text(
                '${value.toString().padLeft(2, '0')}:00',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                      final style = const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
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
                      } else {
                        return Positioned(
                          left: ratio * constraints.maxWidth,
                          top: 28,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, 0),
                            child: Text('$m min', style: style),
                          ),
                        );
                      }
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

  Widget _buildSettingStepper({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
        ),
      ),
    );
  }

  void _handleGesture(BuildContext context, double dx) {
    RenderBox box = context.findRenderObject() as RenderBox;
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

  DottedSliderPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackHeight = 16.0;
    final trackY = size.height / 2;

    final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final activeWidth = size.width * ratio;

    // Draw background track (inactive)
    final inactivePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
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

    // Draw active track
    if (activeWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, trackY - trackHeight / 2, activeWidth, trackHeight),
          Radius.circular(trackHeight / 2),
        ),
        activePaint,
      );
    }

    // Draw dots
    // We use AppColors.surface to create a "hole" effect, revealing the background.
    final dotPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final int numDots = (max - min).toInt();
    if (numDots > 0) {
      final dotSpacing = size.width / numDots;
      for (int i = 1; i <= numDots; i++) {
        final dotX = i * dotSpacing;
        if (dotX < size.width) {
          canvas.drawCircle(Offset(dotX, trackY), 1.5, dotPaint);
        }
      }
    }

    // Draw thumb (tall vertical bar)
    final thumbPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final thumbWidth = 4.0;
    final thumbHeight = 34.0;

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
