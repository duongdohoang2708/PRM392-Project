import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';

const _kTimerStylePrefKey = 'pomodoro_timer_style_index';
const double kPomodoroTimerSize = 260;

enum PomodoroTimerStyle {
  classicRing,
  flipCard,
}

extension PomodoroTimerStyleX on PomodoroTimerStyle {
  String get label => switch (this) {
        PomodoroTimerStyle.classicRing => 'Classic',
        PomodoroTimerStyle.flipCard => 'Flip',
      };
}

class PomodoroTimerCarousel extends StatefulWidget {
  final double progress;
  final String timeString;
  final int minutes;
  final int seconds;
  final Color phaseColor;
  final int totalSeconds;
  final DateTime? deadline;
  final bool isRunning;
  final double timerSize;
  final double bottomPadding;

  const PomodoroTimerCarousel({
    super.key,
    required this.progress,
    required this.timeString,
    required this.minutes,
    required this.seconds,
    required this.phaseColor,
    required this.totalSeconds,
    this.deadline,
    this.isRunning = false,
    this.timerSize = kPomodoroTimerSize,
    this.bottomPadding = 0,
  });

  @override
  State<PomodoroTimerCarousel> createState() => _PomodoroTimerCarouselState();
}

class _PomodoroTimerCarouselState extends State<PomodoroTimerCarousel>
    with SingleTickerProviderStateMixin {
  static const _styles = PomodoroTimerStyle.values;

  late final PageController _pageController;
  Ticker? _liveTicker;
  int _currentIndex = 0;
  bool _prefLoaded = false;

  double get _timerSize => widget.timerSize;
  double get _scale => _timerSize / kPomodoroTimerSize;

  int _remainingFromDeadline() {
    if (widget.isRunning && widget.deadline != null) {
      final diffMs =
          widget.deadline!.difference(DateTime.now()).inMilliseconds;
      if (diffMs <= 0) return 0;
      return (diffMs + 999) ~/ 1000;
    }
    return widget.minutes * 60 + widget.seconds;
  }

  String get _liveTimeString {
    final remaining = _remainingFromDeadline();
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _liveProgress {
    if (widget.isRunning &&
        widget.deadline != null &&
        widget.totalSeconds > 0) {
      final totalMs = widget.totalSeconds * 1000;
      final remainMs =
          widget.deadline!.difference(DateTime.now()).inMilliseconds;
      if (remainMs <= 0) return 1.0;
      return ((totalMs - remainMs) / totalMs).clamp(0.0, 1.0);
    }
    return widget.progress;
  }

  void _syncLiveTicker() {
    if (widget.isRunning && widget.deadline != null) {
      if (_liveTicker != null && !_liveTicker!.isActive) {
        _liveTicker!.start();
      }
    } else if (_liveTicker != null && _liveTicker!.isActive) {
      _liveTicker!.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _liveTicker = createTicker((_) {
      if (mounted) setState(() {});
    });
    _loadStylePreference();
  }

  @override
  void didUpdateWidget(covariant PomodoroTimerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLiveTicker();
  }

  @override
  void dispose() {
    _liveTicker?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _normalizeSavedIndex(int saved) {
    return switch (saved) {
      2 => 1,
      1 || 3 => 0,
      _ => saved.clamp(0, _styles.length - 1),
    };
  }

  Future<void> _loadStylePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kTimerStylePrefKey) ?? 0;
    final index = _normalizeSavedIndex(saved);

    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _prefLoaded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && index > 0) {
        _pageController.jumpToPage(index);
      }
    });
  }

  Future<void> _saveStylePreference(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTimerStylePrefKey, index);
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _saveStylePreference(index);
  }

  @override
  Widget build(BuildContext context) {
    _syncLiveTicker();

    if (!_prefLoaded) {
      return SizedBox(
        width: _timerSize,
        height: _timerSize + 28 * _scale + widget.bottomPadding,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _timerSize,
          height: _timerSize,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _styles.length,
            itemBuilder: (context, index) {
              return Center(
                child: _buildStyle(
                  _styles[index],
                  key: ValueKey(_styles[index]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12 * _scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_styles.length, (index) {
            final active = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.symmetric(horizontal: 4 * _scale),
              width: (active ? 18 : 7) * _scale,
              height: 7 * _scale,
              decoration: BoxDecoration(
                color: active ? widget.phaseColor : AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
        SizedBox(height: 4 * _scale),
        Text(
          _styles[_currentIndex].label,
          style: TextStyle(
            color: widget.phaseColor,
            fontSize: 11 * _scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        if (widget.bottomPadding > 0)
          SizedBox(height: widget.bottomPadding),
      ],
    );
  }

  Widget _buildStyle(PomodoroTimerStyle style, {Key? key}) {
    final remaining = _remainingFromDeadline();
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;

    switch (style) {
      case PomodoroTimerStyle.classicRing:
        return _ClassicRingTimer(
          key: key,
          progress: _liveProgress,
          timeString: _liveTimeString,
          phaseColor: widget.phaseColor,
          timerSize: _timerSize,
          scale: _scale,
        );
      case PomodoroTimerStyle.flipCard:
        return _FlipCardTimer(
          key: key,
          deadline: widget.deadline,
          isRunning: widget.isRunning,
          pausedMinutes: minutes,
          pausedSeconds: seconds,
          phaseColor: widget.phaseColor,
          timerSize: _timerSize,
          scale: _scale,
        );
    }
  }
}

class _ClassicRingTimer extends StatelessWidget {
  final double progress;
  final String timeString;
  final Color phaseColor;
  final double timerSize;
  final double scale;

  const _ClassicRingTimer({
    super.key,
    required this.progress,
    required this.timeString,
    required this.phaseColor,
    required this.timerSize,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final ringThickness = 8 * scale;
    return SizedBox(
      width: timerSize,
      height: timerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(timerSize, timerSize),
            painter: _TimerTrackPainter(
              color: AppColors.border,
              thickness: ringThickness,
            ),
          ),
          CustomPaint(
            size: Size(timerSize, timerSize),
            painter: _TimerProgressPainter(
              progress: progress,
              color: phaseColor,
              thickness: ringThickness,
            ),
          ),
          _TimerCenterDisplay(
            timeString: timeString,
            phaseColor: phaseColor,
            scale: scale,
          ),
        ],
      ),
    );
  }
}

class _FlipCardTimer extends StatefulWidget {
  final DateTime? deadline;
  final bool isRunning;
  final int pausedMinutes;
  final int pausedSeconds;
  final Color phaseColor;
  final double timerSize;
  final double scale;

  const _FlipCardTimer({
    super.key,
    required this.deadline,
    required this.isRunning,
    required this.pausedMinutes,
    required this.pausedSeconds,
    required this.phaseColor,
    required this.timerSize,
    required this.scale,
  });

  @override
  State<_FlipCardTimer> createState() => _FlipCardTimerState();
}

class _FlipCardTimerState extends State<_FlipCardTimer> {
  Timer? _secondTimer;

  (int minutes, int seconds) _timeParts() {
    if (widget.isRunning && widget.deadline != null) {
      final diffMs =
          widget.deadline!.difference(DateTime.now()).inMilliseconds;
      if (diffMs <= 0) return (0, 0);
      final remaining = (diffMs + 999) ~/ 1000;
      return (remaining ~/ 60, remaining % 60);
    }
    return (widget.pausedMinutes, widget.pausedSeconds);
  }

  void _syncSecondTimer() {
    _secondTimer?.cancel();
    if (!widget.isRunning || widget.deadline == null) return;

    void scheduleNext() {
      if (!mounted || !widget.isRunning || widget.deadline == null) return;

      final now = DateTime.now();
      final msUntilNextSecond = 1000 - (now.millisecond % 1000);
      final delayMs = msUntilNextSecond == 0 ? 1000 : msUntilNextSecond;

      _secondTimer = Timer(Duration(milliseconds: delayMs), () {
        if (!mounted) return;
        setState(() {});
        scheduleNext();
      });
    }

    setState(() {});
    scheduleNext();
  }

  @override
  void initState() {
    super.initState();
    _syncSecondTimer();
  }

  @override
  void didUpdateWidget(covariant _FlipCardTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning != widget.isRunning ||
        oldWidget.deadline != widget.deadline) {
      _syncSecondTimer();
    }
  }

  @override
  void dispose() {
    _secondTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (minutes, seconds) = _timeParts();
    final minuteStr = minutes.toString().padLeft(2, '0');
    final secondStr = seconds.toString().padLeft(2, '0');

    return SizedBox(
      width: widget.timerSize,
      height: widget.timerSize,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FlipUnitRow(
            digits: minuteStr,
            isRunning: widget.isRunning,
            phaseColor: widget.phaseColor,
            scale: widget.scale,
          ),
          SizedBox(height: 12 * widget.scale),
          _FlipUnitRow(
            digits: secondStr,
            isRunning: widget.isRunning,
            phaseColor: widget.phaseColor,
            scale: widget.scale,
          ),
          SizedBox(height: 16 * widget.scale),
          Text(
            'REMAINING',
            style: TextStyle(
              fontSize: 11 * widget.scale,
              fontWeight: FontWeight.w800,
              color: widget.phaseColor,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipUnitRow extends StatelessWidget {
  final String digits;
  final bool isRunning;
  final Color phaseColor;
  final double scale;

  const _FlipUnitRow({
    required this.digits,
    required this.isRunning,
    required this.phaseColor,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FlipDigit(
          digit: digits[0],
          isRunning: isRunning,
          phaseColor: phaseColor,
          scale: scale,
        ),
        _FlipDigit(
          digit: digits[1],
          isRunning: isRunning,
          phaseColor: phaseColor,
          scale: scale,
        ),
      ],
    );
  }
}

class _FlipDigit extends StatefulWidget {
  final String digit;
  final bool isRunning;
  final Color phaseColor;
  final double scale;

  const _FlipDigit({
    required this.digit,
    required this.isRunning,
    required this.phaseColor,
    required this.scale,
  });

  @override
  State<_FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<_FlipDigit>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 600);

  late final AnimationController _controller;
  late String _shownDigit;

  @override
  void initState() {
    super.initState();
    _shownDigit = widget.digit;
    _controller = AnimationController(vsync: this, duration: _duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _shownDigit = widget.digit);
        _controller.value = 0;
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isRunning) {
      if (_shownDigit != widget.digit) {
        _controller.stop();
        _controller.value = 0;
        setState(() => _shownDigit = widget.digit);
      }
      return;
    }

    if (oldWidget.digit != widget.digit) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _card(String digit) {
    final s = widget.scale;
    return Container(
      width: 80 * s,
      height: 96 * s,
      margin: EdgeInsets.symmetric(horizontal: 5 * s),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: widget.phaseColor.withValues(alpha: 0.12),
            blurRadius: 10 * s,
            offset: Offset(0, 5 * s),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 56 * s,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return SizedBox(
      width: 88 * s,
      height: 96 * s,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (!_controller.isAnimating) {
            return _card(_shownDigit);
          }

          final t = _controller.value;
          final showingNew = t >= 0.5;
          final activeDigit = showingNew ? widget.digit : _shownDigit;
          final localT = showingNew ? (t - 0.5) * 2 : t * 2;
          final angle = showingNew
              ? (1 - localT) * -math.pi / 2
              : localT * math.pi / 2;

          return ClipRect(
            child: Transform(
              alignment: showingNew
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(angle),
              child: _card(activeDigit),
            ),
          );
        },
      ),
    );
  }
}

class _TimerCenterDisplay extends StatelessWidget {
  final String timeString;
  final Color phaseColor;
  final double scale;

  const _TimerCenterDisplay({
    required this.timeString,
    required this.phaseColor,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160 * scale,
      height: 160 * scale,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withValues(alpha: 0.1),
            blurRadius: 8 * scale,
            spreadRadius: 2 * scale,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeString,
            style: TextStyle(
              fontSize: 48 * scale,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Remaining',
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.bold,
              color: phaseColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerTrackPainter extends CustomPainter {
  final Color color;
  final double thickness;

  const _TimerTrackPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - thickness / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    final dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const dashLength = 2.0;
    const dashSpace = 4.0;
    final outerRadius = radius + 6;
    var startAngle = 0.0;
    while (startAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        dashLength / outerRadius,
        false,
        dashPaint,
      );
      startAngle += (dashLength + dashSpace) / outerRadius;
    }

    canvas.drawCircle(center, radius, paint);

    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(center, radius - 8, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerTrackPainter oldDelegate) => false;
}

class _TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double thickness;

  const _TimerProgressPainter({
    required this.progress,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - thickness / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );

    if (progress > 0 && progress < 1 && thickness >= 6) {
      final currentAngle = -math.pi / 2 + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * math.cos(currentAngle),
        center.dy + radius * math.sin(currentAngle),
      );

      canvas.drawCircle(
        dotCenter,
        4,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(dotCenter, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
