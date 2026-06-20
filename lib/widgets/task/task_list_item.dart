import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/project_model.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/project_provider.dart';
import '../../screens/task/task_detail_screen.dart';
import '../../screens/focus/focus_session_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../custom_snackbar.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final bool disableCompleteAnimation;
  final bool hideTime;
  final bool hideActions;
  final Widget Function(BuildContext context, Widget child)? wrapper;

  const TaskListItem({
    super.key,
    required this.task,
    this.disableCompleteAnimation = false,
    this.hideTime = false,
    this.hideActions = true,
    this.wrapper,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem>
    with TickerProviderStateMixin {
  late bool _isCompletedLocal;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;
  bool _isAnimating = false;
  bool _deleteTriggered = false; // Prevents fallback from running after .then() already ran

  // Dedicated controller for the strikethrough line
  AnimationController? _strikeController;
  Animation<double>? _strikeAnimation;

  @override
  void initState() {
    super.initState();
    _isCompletedLocal = widget.task.isCompleted;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInCubic,
      ),
    );

    // Strikethrough controller — starts at the current completed state
    _strikeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.task.isCompleted ? 1.0 : 0.0,
    );
    _strikeAnimation = CurvedAnimation(
      parent: _strikeController!,
      curve: Curves.easeOut,
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
      // Snap strikethrough to the new task's state without animation
      _strikeController?.value = widget.task.isCompleted ? 1.0 : 0.0;
    } else if (widget.task.isCompleted != oldWidget.task.isCompleted &&
        !_isAnimating) {
      setState(() {
        _isCompletedLocal = widget.task.isCompleted;
      });
      _animationController.reset();
      // External change (e.g. from detail screen) — animate to new state
      if (widget.task.isCompleted) {
        _strikeController?.forward();
      } else {
        _strikeController?.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _strikeController?.dispose();
    super.dispose();
  }

  void _handleToggle() {
    final newCompleted = !_isCompletedLocal;
    setState(() {
      _isCompletedLocal = newCompleted;
      _isAnimating = true;
    });

    // Drive the strikethrough animation immediately, regardless of dismiss mode
    if (newCompleted) {
      _strikeController?.forward();
    } else {
      _strikeController?.reverse();
    }

    if (widget.disableCompleteAnimation) {
      context.read<TaskProvider>().toggleTaskCompletion(widget.task.id);
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    } else {
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
  }

  void _showDeleteSnackbar(BuildContext context) {
    AppNotification.showError(context, 'Task deleted');
  }

  void _handleDelete(BuildContext context) {
    if (_isAnimating) return;

    // Save the slidable controller to close it if the user cancels
    final slidable = Slidable.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              slidable?.close(); // Close the slidable action pane
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              _executeDelete(slidable);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _executeDelete([SlidableController? slidable]) {
    slidable?.close(); // MUST close before destroying to prevent GlobalKey crashes

    _deleteTriggered = false;
    setState(() {
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      if (mounted && !_deleteTriggered) {
        _deleteTriggered = true;
        context.read<TaskProvider>().deleteTask(widget.task.id);
        _showDeleteSnackbar(context);
        // Do NOT call setState here — widget is about to be unmounted
        // by the parent ListView rebuild triggered by deleteTask().
      }
    });

    // Fallback in case animation gets stuck (e.g. headless browser)
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted && _isAnimating && !_deleteTriggered) {
        _deleteTriggered = true;
        context.read<TaskProvider>().deleteTask(widget.task.id);
        _showDeleteSnackbar(context);
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
    final isOverdue =
        widget.task.dueDate != null &&
        DateTime(
          widget.task.dueDate!.year,
          widget.task.dueDate!.month,
          widget.task.dueDate!.day,
        ).isBefore(today) &&
        !widget.task.isCompleted;

    final timeString = _formatDate(widget.task.dueDate, isOverdue);

    final projectProvider = Provider.of<ProjectProvider>(context);
    final project = projectProvider.projects.firstWhere(
      (p) => p.name == widget.task.project,
      orElse: () => Project(
        id: '',
        name: '',
        description: '',
        colorValue: AppColors.primary.value,
      ),
    );
    final Color projectColor = Color(project.colorValue);

    final mainContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCompletedLocal
            ? AppColors.background
            : Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: _isCompletedLocal
            ? null
            : [
                BoxShadow(
                  color: projectColor.withValues(alpha: 0.04),
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
                color: _isCompletedLocal
                    ? projectColor
                    : Colors.transparent,
                border: Border.all(
                  color: _isCompletedLocal
                      ? projectColor
                      : projectColor.withValues(alpha: 0.5),
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TaskDetailScreen(taskId: widget.task.id),
                  ),
                );
              },
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
                          color: _isCompletedLocal
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (_strikeAnimation != null)
                        AnimatedBuilder(
                          animation: _strikeAnimation!,
                          builder: (context, child) {
                            final value = _strikeAnimation!.value;
                            if (value == 0) return const SizedBox.shrink();
                            return Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    height: 1.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      else if (_isCompletedLocal)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 1.5,
                              color: AppColors.textSecondary,
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
                          Icon(
                            Icons.folder_outlined,
                            size: 14,
                            color: projectColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.task.project,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: projectColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                          if (widget.task.dueDate != null && !widget.hideTime)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCompletedLocal
                                      ? Icons.check_circle_outline
                                      : Icons.schedule,
                                  size: 14,
                                  color: _isCompletedLocal
                                      ? AppColors.primaryDark
                                      : (isOverdue
                                            ? const Color(0xFFE57373)
                                            : AppColors.textPrimary),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeString,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: _isCompletedLocal
                                        ? AppColors.primaryDark
                                        : (isOverdue
                                              ? const Color(0xFFE57373)
                                              : AppColors.textPrimary),
                                    fontWeight: isOverdue || _isCompletedLocal
                                        ? FontWeight.bold
                                        : FontWeight.w600,
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
          ),
          if (!widget.hideActions) ...[
            const SizedBox(width: 16),
            // Star Action
            GestureDetector(
              onTap: () {
                context.read<TaskProvider>().toggleTaskImportance(
                  widget.task.id,
                );
              },
              child: Icon(
                widget.task.isImportant ? Icons.star : Icons.star_border,
                color: widget.task.isImportant
                    ? AppColors.accentYellow
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            // Play Action
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FocusSessionScreen(taskId: widget.task.id),
                  ),
                );
              },
              child: Icon(
                Icons.play_circle_fill,
                size: 28,
                color: _isCompletedLocal
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : projectColor,
              ),
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Precisely calculate extentRatio so the ActionPane is EXACTLY 80px wide.
        // This ensures the slide distance matches the button perfectly.
        final double extentRatio = (80 / constraints.maxWidth).clamp(0.05, 0.5);

        final dismissibleContent = Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Slidable(
            key: Key('slidable_${widget.task.id}'),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: extentRatio,
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _handleDelete(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350), // Brighter, darker red
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            child: mainContent,
          ),
        );

        Widget finalContent = Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: dismissibleContent,
        );
        
        if (widget.wrapper != null) {
          finalContent = widget.wrapper!(context, finalContent);
        }


        // Always wrap in SizeTransition/FadeTransition so the dismiss
        // animation can play smoothly without a layout jump.
        // At rest (controller value=0), sizeFactor=1.0 and opacity=1.0
        // so there is no visual difference from a plain container.
        return SizeTransition(
          sizeFactor: _sizeAnimation,
          axis: Axis.vertical,
          axisAlignment: -1.0,
          child: FadeTransition(opacity: _fadeAnimation, child: finalContent),
        );
      },
    );
  }
}

