import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../theme/app_colors.dart';

class SubTaskItem extends StatefulWidget {
  final SubTask subTask;
  final String taskId;
  final Color projectColor;
  final Function(String subTaskId, bool willBeCompleted) onToggle;
  final bool? overrideCompleted;

  const SubTaskItem({
    super.key,
    required this.subTask,
    required this.taskId,
    required this.projectColor,
    required this.onToggle,
    this.overrideCompleted,
  });

  @override
  State<SubTaskItem> createState() => _SubTaskItemState();
}

class _SubTaskItemState extends State<SubTaskItem> with SingleTickerProviderStateMixin {
  late bool _isCompletedLocal;
  AnimationController? _strikeController;
  Animation<double>? _strikeAnimation;

  @override
  void initState() {
    super.initState();
    _isCompletedLocal = widget.subTask.isCompleted;

    _strikeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.subTask.isCompleted ? 1.0 : 0.0,
    );
    _strikeAnimation = CurvedAnimation(
      parent: _strikeController!,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant SubTaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final currentCompleted = widget.overrideCompleted ?? widget.subTask.isCompleted;
    final oldCompleted = oldWidget.overrideCompleted ?? oldWidget.subTask.isCompleted;

    if (widget.subTask.id != oldWidget.subTask.id) {
      setState(() {
        _isCompletedLocal = currentCompleted;
      });
      _strikeController?.value = currentCompleted ? 1.0 : 0.0;
    } else if (currentCompleted != oldCompleted) {
      setState(() {
        _isCompletedLocal = currentCompleted;
      });
      if (currentCompleted) {
        _strikeController?.forward();
      } else {
        _strikeController?.reverse();
      }
    }
  }

  @override
  void dispose() {
    _strikeController?.dispose();
    super.dispose();
  }

  void _handleToggle() {
    final newCompleted = !_isCompletedLocal;
    setState(() {
      _isCompletedLocal = newCompleted;
    });

    if (newCompleted) {
      _strikeController?.forward();
    } else {
      _strikeController?.reverse();
    }

    widget.onToggle(widget.subTask.id, newCompleted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: _isCompletedLocal ? AppColors.textSecondary : AppColors.textPrimary,
    );

    return Row(
      children: [
        GestureDetector(
          onTap: _handleToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isCompletedLocal ? widget.projectColor : Colors.transparent,
              border: Border.all(
                color: _isCompletedLocal ? widget.projectColor : widget.projectColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: AnimatedScale(
              scale: _isCompletedLocal ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.elasticOut,
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: _strikeAnimation!,
            builder: (context, _) {
              return CustomPaint(
                foregroundPainter: _MultiLineStrikethroughPainter(
                  text: widget.subTask.title,
                  style: style!,
                  progress: _strikeAnimation!.value,
                  lineColor: AppColors.textSecondary,
                ),
                child: Text(
                  widget.subTask.title,
                  style: style,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MultiLineStrikethroughPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double progress;
  final Color lineColor;

  _MultiLineStrikethroughPainter({
    required this.text,
    required this.style,
    required this.progress,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: size.width);

    final lines = textPainter.computeLineMetrics();
    if (lines.isEmpty) return;

    final totalWidth = lines.fold<double>(0, (sum, line) => sum + line.width);
    var remaining = progress * totalWidth;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;

    for (final line in lines) {
      if (remaining <= 0) break;
      final strikeWidth = remaining < line.width ? remaining : line.width;
      final y = line.baseline - line.ascent + line.height / 2;
      canvas.drawLine(
        Offset(line.left, y),
        Offset(line.left + strikeWidth, y),
        paint,
      );
      remaining -= line.width;
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLineStrikethroughPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.progress != progress ||
        oldDelegate.lineColor != lineColor;
  }
}
