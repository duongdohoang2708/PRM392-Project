import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../screens/focus/focus_session_screen.dart';

class TaskListItem extends StatefulWidget {
  final Task task;

  const TaskListItem({
    super.key,
    required this.task,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> with SingleTickerProviderStateMixin {
  late bool _isCompletedLocal;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _isCompletedLocal = widget.task.isCompleted;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.id != oldWidget.task.id) {
      setState(() {
        _isCompletedLocal = widget.task.isCompleted;
        _isAnimating = false;
      });
      _animationController.reset();
    } else if (widget.task.isCompleted != oldWidget.task.isCompleted && !_isAnimating) {
      setState(() {
        _isCompletedLocal = widget.task.isCompleted;
      });
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    setState(() {
      _isCompletedLocal = !_isCompletedLocal;
      _isAnimating = true;
    });

    _animationController.forward();
    
    // Use Future.delayed as a robust fallback to guarantee completion
    // even if Tickers are suspended or throttled by headless browsers
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        context.read<TaskProvider>().toggleTaskCompletion(widget.task.id);
        _animationController.reset();
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case 'High':
        return const Color(0xFFE57373); // Red
      case 'Medium':
        return const Color(0xFFF5B041); // Darker orange
      case 'Low':
        return AppColors.primaryDark; // Deep green
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime? date, bool isOverdue) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final tDate = DateTime(date.year, date.month, date.day);

    if (isOverdue) {
      return 'Overdue, ${DateFormat('MMM d').format(date)}';
    } else if (tDate.isAtSameMomentAs(today)) {
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (tDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _getPriorityColor();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = widget.task.dueDate != null &&
        DateTime(widget.task.dueDate!.year, widget.task.dueDate!.month, widget.task.dueDate!.day).isBefore(today) &&
        !widget.task.isCompleted;
    
    final timeString = _formatDate(widget.task.dueDate, isOverdue);

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axis: Axis.vertical,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isCompletedLocal ? AppColors.background : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: _isCompletedLocal ? null : [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              GestureDetector(
                onTap: _handleToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isCompletedLocal ? AppColors.primaryDark : Colors.transparent,
                    border: Border.all(
                      color: _isCompletedLocal ? AppColors.primaryDark : AppColors.textSecondary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: _isCompletedLocal ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.elasticOut,
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Text(
                          widget.task.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isCompletedLocal ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_isCompletedLocal || _isAnimating)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: widget.task.isCompleted ? 1.0 : 0.0,
                                  end: _isCompletedLocal ? 1.0 : 0.0,
                                ),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, child) {
                                  return FractionallySizedBox(
                                    widthFactor: value,
                                    child: Container(
                                      height: 1.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              widget.task.project,
                              style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            // Priority
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag, size: 14, color: priorityColor),
                                const SizedBox(width: 4),
                                Text(
                                  widget.task.priority,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: priorityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                             if (widget.task.dueDate != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isCompletedLocal ? Icons.calendar_today : Icons.schedule,
                                    size: 14,
                                    color: _isCompletedLocal ? AppColors.textSecondary : (isOverdue ? const Color(0xFFE57373) : AppColors.primaryDark),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeString,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: _isCompletedLocal ? AppColors.textSecondary : (isOverdue ? const Color(0xFFE57373) : AppColors.primaryDark),
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Star Action
              GestureDetector(
                onTap: () {
                  context.read<TaskProvider>().toggleTaskImportance(widget.task.id);
                },
                child: Icon(
                  widget.task.isImportant ? Icons.star : Icons.star_border,
                  color: widget.task.isImportant ? AppColors.accentYellow : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              // Play Action
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FocusSessionScreen(taskId: widget.task.id),
                    ),
                  );
                },
                child: Icon(
                  Icons.play_circle_fill,
                  size: 28,
                  color: _isCompletedLocal ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
