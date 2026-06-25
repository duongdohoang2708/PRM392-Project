import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../models/task_model.dart';
import '../../models/project_model.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/focus_provider.dart';
import '../../screens/task/task_detail_screen.dart';
// Removed focus_session_screen import
import 'package:flutter_slidable/flutter_slidable.dart';
import '../custom_snackbar.dart';
import 'subtask_item.dart';

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
  bool _isExpanded = false; // Tracks if subtasks are expanded
  String? _editingSubTaskId;
  bool? _overrideSubTasksCompleted;

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
        _isExpanded = false;
        _editingSubTaskId = null;
        _overrideSubTasksCompleted = null;
      });
      _animationController.reset();
      // Snap strikethrough to the new task's state without animation
      _strikeController?.value = widget.task.isCompleted ? 1.0 : 0.0;
    } else if (widget.task.isCompleted != oldWidget.task.isCompleted &&
        !_isAnimating) {
      setState(() {
        _isCompletedLocal = widget.task.isCompleted;
        _overrideSubTasksCompleted = null;
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
    if (_isAnimating) return;

    final newCompleted = !_isCompletedLocal;
    setState(() {
      _isCompletedLocal = newCompleted;
      _overrideSubTasksCompleted = newCompleted;
    });

    // Drive the strikethrough animation immediately
    if (newCompleted) {
      _strikeController?.forward();
    } else {
      _strikeController?.reverse();
    }

    if (widget.disableCompleteAnimation) {
      context.read<TaskProvider>().toggleTaskCompletion(widget.task.id);
    } else {
      // Delay fade out by 300ms so user can see the strikethrough of parent AND subtasks
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        
        setState(() {
          _isAnimating = true;
        });
        _animationController.forward();

        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) {
            context.read<TaskProvider>().toggleTaskCompletion(widget.task.id);
          }
        });
      });
    }
  }

  void _addSubTask() {
    final newId = '${widget.task.id}_sub_${DateTime.now().millisecondsSinceEpoch}';
    context.read<TaskProvider>().addSubTask(widget.task.id, subTaskId: newId);
    setState(() {
      _isExpanded = true;
      _editingSubTaskId = newId;
    });
  }

  void _commitSubTaskTitle(String subTaskId, String title) {
    context.read<TaskProvider>().updateSubTaskTitle(
      widget.task.id,
      subTaskId,
      title,
    );
    if (_editingSubTaskId == subTaskId) {
      setState(() => _editingSubTaskId = null);
    }
  }

  void _removeSubTask(String subTaskId) {
    context.read<TaskProvider>().removeSubTask(widget.task.id, subTaskId);
    if (_editingSubTaskId == subTaskId) {
      setState(() => _editingSubTaskId = null);
    }
  }

  void _handleSubTaskToggle(String subTaskId, bool willBeCompleted) {
    final provider = context.read<TaskProvider>();
    final otherSubTasks = widget.task.subTasks.where((st) => st.id != subTaskId);
    final allOthersCompleted = otherSubTasks.isEmpty || otherSubTasks.every((st) => st.isCompleted);

    if (willBeCompleted && allOthersCompleted) {
      // 1. Update subtask locally in provider but keep parent incomplete for now
      provider.toggleSubTaskCompletion(widget.task.id, subTaskId, autoCompleteParent: false);

      // 2. Animate parent checkbox & strikethrough instantly
      setState(() {
        _isCompletedLocal = true;
        _overrideSubTasksCompleted = null;
      });
      _strikeController?.forward();

      // 3. Short wait for user to see the strikethrough
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        
        if (widget.disableCompleteAnimation) {
          provider.toggleTaskCompletion(widget.task.id);
        } else {
          // 4. Trigger fade-out animation
          setState(() {
            _isAnimating = true;
          });
          _animationController.forward();

          // 5. Finally, complete the task in the provider so it leaves the list
          Future.delayed(const Duration(milliseconds: 650), () {
            if (mounted) {
              provider.toggleTaskCompletion(widget.task.id);
            }
          });
        }
      });
    } else if (!willBeCompleted && widget.task.isCompleted) {
      // Unchecking a subtask when the parent is Completed!
      provider.toggleSubTaskCompletion(widget.task.id, subTaskId, autoCompleteParent: false);

      setState(() {
        _isCompletedLocal = false;
        _overrideSubTasksCompleted = null;
      });
      _strikeController?.reverse();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        if (widget.disableCompleteAnimation) {
          final taskIndex = provider.tasks.indexWhere((t) => t.id == widget.task.id);
          if (taskIndex != -1) {
            final task = provider.tasks[taskIndex];
            provider.updateTask(task.copyWith(isCompleted: false, completedAt: null));
          }
        } else {
          setState(() {
            _isAnimating = true;
          });
          _animationController.forward();

          Future.delayed(const Duration(milliseconds: 650), () {
            if (mounted) {
              final taskIndex = provider.tasks.indexWhere((t) => t.id == widget.task.id);
              if (taskIndex != -1) {
                final task = provider.tasks[taskIndex];
                provider.updateTask(task.copyWith(isCompleted: false, completedAt: null));
              }
            }
          });
        }
      });
    } else {
      // Normal subtask toggle
      provider.toggleSubTaskCompletion(widget.task.id, subTaskId);
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

  bool _hasAssignedProject(String projectName, Project resolvedProject) {
    final name = projectName.trim();
    if (name.isEmpty || name == 'None') return false;
    return resolvedProject.id.isNotEmpty;
  }

  String _formatDate(DateTime? date, bool isOverdue, bool isAllDay) {
    if (date == null) return '';
    return AppDateTimeFormat.taskDueLabel(date, isOverdue: isOverdue, isAllDay: isAllDay);
  }

  void _handleStartFocus(BuildContext context) {
    final focusProvider = context.read<FocusProvider>();
    if ((focusProvider.timerState == TimerState.running || focusProvider.timerState == TimerState.paused) && focusProvider.selectedTask?.id != widget.task.id) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Timer is running', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            'You currently have an active focus session. Starting this task will reset the current timer. Do you want to proceed?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                focusProvider.resetEntireCycle();
                Navigator.pushNamed(context, '/focus', arguments: {'taskId': widget.task.id, 'autoStart': true});
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPeach),
              child: const Text('Reset & Proceed', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushNamed(context, '/focus', arguments: {'taskId': widget.task.id, 'autoStart': true});
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

    final timeString = _formatDate(widget.task.dueDate, isOverdue, widget.task.isAllDay);

    final projectProvider = Provider.of<ProjectProvider>(context);
    final project = projectProvider.projects.firstWhere(
      (p) => p.name == widget.task.project,
      orElse: () => Project(
        id: '',
        name: '',
        description: '',
        colorValue: AppColors.primary.toARGB32(),
      ),
    );
    final Color projectColor = Color(project.colorValue);
    final showProject = _hasAssignedProject(widget.task.project, project);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      _buildTitleText(theme),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showProject) ...[
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
                          ],
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
                  onTap: _isCompletedLocal ? null : () => _handleStartFocus(context),
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 28,
                    color: _isCompletedLocal
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : projectColor,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: !widget.hideActions && _isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        if (widget.task.subTasks.isNotEmpty) ...[
                          const Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 12),
                          ...widget.task.subTasks.map((subTask) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12.0,
                                left: 8.0,
                                right: 8.0,
                              ),
                              child: subTask.title.trim().isEmpty
                                  ? _EditableSubTaskRow(
                                      key: ValueKey(subTask.id),
                                      subTask: subTask,
                                      projectColor: projectColor,
                                      autofocus: _editingSubTaskId == subTask.id,
                                      onCommit: (title) =>
                                          _commitSubTaskTitle(subTask.id, title),
                                      onDelete: () => _removeSubTask(subTask.id),
                                    )
                                  : SubTaskItem(
                                      subTask: subTask,
                                      taskId: widget.task.id,
                                      projectColor: projectColor,
                                      onToggle: _handleSubTaskToggle,
                                      overrideCompleted: _overrideSubTasksCompleted,
                                    ),
                            );
                          }),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: widget.task.subTasks
                                    .any((st) => st.title.trim().isEmpty)
                                ? null
                                : _addSubTask,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add subtask'),
                            style: TextButton.styleFrom(
                              foregroundColor: projectColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(height: 0),
            ),
          ),
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

  Widget _buildTitleText(ThemeData theme) {
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: _isCompletedLocal
          ? AppColors.textSecondary
          : AppColors.textPrimary,
    );

    if (_strikeAnimation == null) {
      return Text(
        widget.task.title,
        style: style?.copyWith(
          decoration:
              _isCompletedLocal ? TextDecoration.lineThrough : TextDecoration.none,
          decorationColor: AppColors.textSecondary,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _strikeAnimation!,
      builder: (context, _) {
        return _MultiLineStrikethroughText(
          text: widget.task.title,
          style: style!,
          progress: _strikeAnimation!.value,
          lineColor: AppColors.textSecondary,
        );
      },
    );
  }
}

class _EditableSubTaskRow extends StatefulWidget {
  final SubTask subTask;
  final Color projectColor;
  final bool autofocus;
  final ValueChanged<String> onCommit;
  final VoidCallback onDelete;

  const _EditableSubTaskRow({
    super.key,
    required this.subTask,
    required this.projectColor,
    required this.autofocus,
    required this.onCommit,
    required this.onDelete,
  });

  @override
  State<_EditableSubTaskRow> createState() => _EditableSubTaskRowState();
}

class _EditableSubTaskRowState extends State<_EditableSubTaskRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.subTask.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onCommit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.projectColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: widget.autofocus,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter subtask...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              fillColor: Colors.transparent,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _commit(),
            onEditingComplete: _commit,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.close,
            size: 18,
            color: AppColors.textSecondary,
          ),
          onPressed: widget.onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

class _MultiLineStrikethroughText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double progress;
  final Color lineColor;

  const _MultiLineStrikethroughText({
    required this.text,
    required this.style,
    required this.progress,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _MultiLineStrikethroughPainter(
        text: text,
        style: style,
        progress: progress,
        lineColor: lineColor,
      ),
      child: Text(text, style: style),
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

