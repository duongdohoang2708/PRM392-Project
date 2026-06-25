import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/project_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/focus_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/custom_snackbar.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _project;
  late String _priority;
  late DateTime? _dueDate;
  late bool _isCompleted;
  late bool _isImportant;
  late bool _isAllDay;
  late List<SubTask> _subTasks;
  late String _reminder;
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  int _longBreakMinutes = 15;
  int _sessions = 1;
  int _longBreakInterval = 4;

  @override
  void initState() {
    super.initState();
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final task = taskProvider.tasks.firstWhere(
      (t) => t.id == widget.taskId,
      orElse: () => Task(
        id: '',
        title: 'Task not found',
        project: 'None',
        priority: 'Low',
      ),
    );

    _titleController = TextEditingController(text: task.title);
    _notesController = TextEditingController(text: task.notes);
    _project = task.project;
    _priority = task.priority;
    _dueDate = task.dueDate;
    _isCompleted = task.isCompleted;
    _isImportant = task.isImportant;
    _isAllDay = task.isAllDay;
    _subTasks = List.from(task.subTasks);
    _reminder = '1 hour before'; // default mock value

    final focusProvider = Provider.of<FocusProvider>(context, listen: false);
    _focusMinutes = focusProvider.focusMinutes;
    _breakMinutes = focusProvider.shortBreakMinutes;
    _longBreakMinutes = focusProvider.longBreakMinutes;
    _sessions = focusProvider.rounds;
    _longBreakInterval = focusProvider.longBreakInterval;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_titleController.text.trim().isEmpty) {
      AppNotification.showError(context, 'Task title cannot be empty');
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    final originalTask = taskProvider.tasks.firstWhere(
      (t) => t.id == widget.taskId,
    );

    final updatedTask = originalTask.copyWith(
      title: _titleController.text.trim(),
      project: _project,
      priority: _priority,
      dueDate: _dueDate,
      isCompleted: _isCompleted,
      isImportant: _isImportant,
      isAllDay: _isAllDay,
      notes: _notesController.text.trim(),
      subTasks: _subTasks,
    );

    taskProvider.updateTask(updatedTask);

    final focusProvider = context.read<FocusProvider>();
    focusProvider.updateSettings(
      focus: _focusMinutes,
      shortBreak: _breakMinutes,
      longBreak: _longBreakMinutes,
      rounds: _sessions,
      interval: _longBreakInterval,
    );

    AppNotification.showSuccess(context, 'Changes saved successfully');

    Navigator.pop(context);
  }

  void _confirmDeleteTask(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Task'),
          content: const Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                parentContext.read<TaskProvider>().deleteTask(widget.taskId);
                AppNotification.showError(parentContext, 'Task deleted');
                Navigator.pop(parentContext); // Close detail screen
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (_dueDate == null) {
          _dueDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 12, 0);
        } else {
          _dueDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, _dueDate!.hour, _dueDate!.minute);
        }
      });
    }
  }

  Future<void> _selectTime() async {
    if (_isAllDay) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        final date = _dueDate ?? DateTime.now();
        _dueDate = DateTime(date.year, date.month, date.day, pickedTime.hour, pickedTime.minute);
      });
    }
  }

  void _addNewProject() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add New Project'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Enter project name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  setState(() {
                    _project = textController.text.trim();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addNewSubTask() {
    setState(() {
      final newId =
          '${widget.taskId}_sub_${DateTime.now().millisecondsSinceEpoch}';
      _subTasks.add(SubTask(id: newId, title: '', isCompleted: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final projectProvider = Provider.of<ProjectProvider>(context);
    final projectObj = projectProvider.projects.firstWhere(
      (p) => p.name == _project,
      orElse: () => Project(
        id: '',
        name: '',
        description: '',
        colorValue: AppColors.primary.toARGB32(),
      ),
    );
    final Color projectColor = Color(projectObj.colorValue);

    final projects = provider.availableProjects
        .where((p) => p != 'All Projects')
        .toList();
    if (!projects.contains(_project)) {
      projects.add(_project);
    }

    final titleWidget = Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 24, top: 8),
      child: Text(
        'Task Details',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = MediaQuery.of(context).size.width >= 768;
        final bool useTwoColumns = constraints.maxWidth >= 1024;

        // Main Columns
        final leftColumnWidgets = [
          // Title card
          _buildTitleCard(projectColor),
          const SizedBox(height: 16),

          // Task details info for Mobile/Tablet only
          if (!useTwoColumns) ...[
            _buildInfoCard(projects, projectColor),
            const SizedBox(height: 16),
          ],

          // Pomodoro focus card
          _buildPomodoroCard(projectColor),
          const SizedBox(height: 16),

          // Subtasks card for Mobile/Tablet only
          if (!useTwoColumns) ...[
            _buildSubtasksCard(projectColor),
            const SizedBox(height: 16),
          ],

          // Notes card
          _buildNotesCard(projectColor),

          // Bottom actions for Mobile/Tablet only
          if (!useTwoColumns) ...[
            const SizedBox(height: 24),
            _buildActionButtons(projectColor),
          ],
        ];

        final rightColumnWidgets = [
          // Task details info for Desktop only
          if (useTwoColumns) ...[
            _buildInfoCard(projects, projectColor),
            const SizedBox(height: 16),
            _buildSubtasksCard(projectColor),
            const SizedBox(height: 16),
            _buildActionButtons(projectColor),
          ],
        ];

        Widget mainContent = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleWidget,
                        useTwoColumns
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: leftColumnWidgets,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: rightColumnWidgets,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: leftColumnWidgets,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isDesktop
              ? null
              : const AppDrawer(isPermanent: false, activeRoute: '/task-list'),
          appBar: _buildAppBar(context, isDesktop: isDesktop),
          body: isDesktop
              ? mainContent
              : Builder(
                  builder: (context) => GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 300) {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                    child: mainContent,
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isDesktop,
  }) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () {
                if (isDesktop) {
                  context.read<DrawerProvider>().toggleDesktopCollapse();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              size: 28,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Delete Task',
          onPressed: () => _confirmDeleteTask(context),
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            AppNotification.showInfo(context, 'Notifications coming soon!');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTitleCard(Color projectColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completed checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                _isCompleted = !_isCompleted;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isCompleted
                    ? projectColor
                    : Colors.transparent,
                border: Border.all(
                  color: _isCompleted
                      ? projectColor
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: _isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Title edit field & labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Task title...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Project Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: projectColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: projectColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _project,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _priority == 'High'
                            ? AppColors.accentPeach
                            : (_priority == 'Medium'
                                  ? AppColors.accentYellow
                                  : AppColors.primaryDark),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$_priority Priority',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Star Important button
          IconButton(
            icon: Icon(
              _isImportant ? Icons.star : Icons.star_border,
              color: _isImportant
                  ? AppColors.accentYellow
                  : AppColors.textSecondary.withValues(alpha: 0.5),
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isImportant = !_isImportant;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<String> projects, Color projectColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          // Date Row
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            projectColor: projectColor,
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  _dueDate == null
                      ? 'Set date'
                      : AppDateTimeFormat.date(_dueDate!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 24),

          // Time Row
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Time',
            projectColor: projectColor,
            child: InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  _isAllDay
                      ? 'All Day'
                      : (_dueDate == null
                          ? 'Set time'
                          : AppDateTimeFormat.time(_dueDate!)),
                  style: TextStyle(
                    fontSize: 14,
                    color: _isAllDay ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 24),

          // All Day Row
          _buildInfoRow(
            icon: Icons.all_inclusive,
            label: 'All Day',
            projectColor: projectColor,
            child: Switch(
              value: _isAllDay,
              activeTrackColor: projectColor.withValues(alpha: 0.5),
              activeThumbColor: projectColor,
              onChanged: (val) {
                setState(() {
                  _isAllDay = val;
                });
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 24),

          // Status Row
          _buildInfoRow(
            icon: Icons.pending_actions,
            label: 'Status',
            projectColor: projectColor,
            child: DropdownButton<bool>(
              value: _isCompleted,
              isExpanded: true,
              alignment: AlignmentDirectional.centerEnd,
              dropdownColor: AppColors.surface,
              underline: const SizedBox(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem(
                  value: false,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('In Progress'),
                  ),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Completed'),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _isCompleted = val;
                  });
                }
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 24),

          // Project Row
          _buildInfoRow(
            icon: Icons.folder_open,
            label: 'Project',
            projectColor: projectColor,
            child: DropdownButton<String>(
              value: _project,
              isExpanded: true,
              alignment: AlignmentDirectional.centerEnd,
              dropdownColor: AppColors.surface,
              underline: const SizedBox(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: [
                ...projects.map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(p),
                    ),
                  ),
                ),
                const DropdownMenuItem(
                  value: '__add_new__',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '+ Add Project',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == '__add_new__') {
                  _addNewProject();
                } else if (val != null) {
                  setState(() {
                    _project = val;
                  });
                }
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 24),

          // Priority Row
          _buildInfoRow(
            icon: Icons.flag_outlined,
            label: 'Priority',
            projectColor: projectColor,
            child: DropdownButton<String>(
              value: _priority,
              isExpanded: true,
              alignment: AlignmentDirectional.centerEnd,
              dropdownColor: AppColors.surface,
              underline: const SizedBox(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'High',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('High'),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Medium',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Medium'),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Low',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Low'),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _priority = val;
                  });
                }
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 24),

          // Reminder Row
          _buildInfoRow(
            icon: Icons.notifications,
            label: 'Reminder',
            projectColor: projectColor,
            child: DropdownButton<String>(
              value: _reminder,
              isExpanded: true,
              alignment: AlignmentDirectional.centerEnd,
              dropdownColor: AppColors.surface,
              underline: const SizedBox(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'None',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('None'),
                  ),
                ),
                DropdownMenuItem(
                  value: '10 minutes before',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('10 minutes before'),
                  ),
                ),
                DropdownMenuItem(
                  value: '1 hour before',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('1 hour before'),
                  ),
                ),
                DropdownMenuItem(
                  value: '1 day before',
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('1 day before'),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _reminder = val;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Widget child,
    required Color projectColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: projectColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: child),
        ),
      ],
    );
  }

  Widget _buildPomodoroCard(Color projectColor) {
    final focusProvider = context.watch<FocusProvider>();
    final isCurrentTaskActive = focusProvider.selectedTask?.id == widget.taskId && 
        (focusProvider.timerState == TimerState.running || focusProvider.timerState == TimerState.paused);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: projectColor),
                  const SizedBox(width: 8),
                  Text(
                    'Pomodoro Focus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: projectColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: projectColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${_focusMinutes.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: projectColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Settings Adjusters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildAdjuster(
                  'Focus (m)',
                  _focusMinutes,
                  (val) => setState(() => _focusMinutes = val),
                  min: 5,
                  max: 120,
                  step: 5,
                  projectColor: projectColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdjuster(
                  'Short Break',
                  _breakMinutes,
                  (val) => setState(() => _breakMinutes = val),
                  min: 1,
                  max: 60,
                  step: 1,
                  projectColor: projectColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdjuster(
                  'Long Break',
                  _longBreakMinutes,
                  (val) => setState(() => _longBreakMinutes = val),
                  min: 5,
                  max: 60,
                  step: 5,
                  projectColor: projectColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAdjuster(
                  'Sessions',
                  _sessions,
                  (val) => setState(() => _sessions = val),
                  min: 1,
                  max: 10,
                  step: 1,
                  projectColor: projectColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdjuster(
                  'Long Break Interval',
                  _longBreakInterval,
                  (val) => setState(() => _longBreakInterval = val),
                  min: 1,
                  max: 10,
                  step: 1,
                  projectColor: projectColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isCompleted ? null : () {
              final focusProvider = context.read<FocusProvider>();
              bool settingsChanged = focusProvider.focusMinutes != _focusMinutes ||
                  focusProvider.shortBreakMinutes != _breakMinutes ||
                  focusProvider.longBreakMinutes != _longBreakMinutes ||
                  focusProvider.rounds != _sessions ||
                  focusProvider.longBreakInterval != _longBreakInterval;
              
              if ((focusProvider.timerState == TimerState.running || focusProvider.timerState == TimerState.paused) && 
                  (focusProvider.selectedTask?.id != widget.taskId || settingsChanged)) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Timer is running', style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text(
                      'You currently have an active focus session. Starting this will reset the current timer. Do you want to proceed?',
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
                          Navigator.pushNamed(
                            context,
                            '/focus',
                            arguments: {
                              'taskId': widget.taskId,
                              'focusMinutes': _focusMinutes,
                              'breakMinutes': _breakMinutes,
                              'longBreakMinutes': _longBreakMinutes,
                              'sessions': _sessions,
                              'longBreakInterval': _longBreakInterval,
                              'autoStart': true,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPeach),
                        child: const Text('Reset & Proceed', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.pushNamed(
                  context,
                  '/focus',
                  arguments: {
                    'taskId': widget.taskId,
                    'focusMinutes': _focusMinutes,
                    'breakMinutes': _breakMinutes,
                    'longBreakMinutes': _longBreakMinutes,
                    'sessions': _sessions,
                    'longBreakInterval': _longBreakInterval,
                    'autoStart': true,
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: isCurrentTaskActive ? AppColors.accentYellow : projectColor,
              foregroundColor: isCurrentTaskActive 
                  ? AppColors.textPrimary 
                  : (ThemeData.estimateBrightnessForColor(projectColor) == Brightness.dark
                      ? Colors.white
                      : AppColors.textPrimary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isCurrentTaskActive ? Icons.play_arrow : Icons.play_arrow),
                const SizedBox(width: 8),
                Text(isCurrentTaskActive ? 'Continue Pomodoro' : 'Start Pomodoro'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjuster(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    required int min,
    required int max,
    required int step,
    required Color projectColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(Icons.remove, color: projectColor),
                onPressed: value > min ? () => onChanged(value - step) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(Icons.add, color: projectColor),
                onPressed: value < max ? () => onChanged(value + step) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubtasksCard(Color projectColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: projectColor),
              const SizedBox(width: 8),
              Text(
                'Subtasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subTasks.length,
            itemBuilder: (context, index) {
              final subtask = _subTasks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Subtask checkbox
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _subTasks[index] = subtask.copyWith(
                            isCompleted: !subtask.isCompleted,
                          );
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: subtask.isCompleted
                              ? projectColor
                              : Colors.transparent,
                          border: Border.all(
                            color: subtask.isCompleted
                                ? projectColor
                                : AppColors.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                            width: 1.5,
                          ),
                        ),
                        child: subtask.isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Subtask input
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: subtask.title)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: subtask.title.length),
                          ),
                        style: TextStyle(
                          fontSize: 14,
                          color: subtask.isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          decoration: subtask.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter subtask...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (val) {
                          _subTasks[index] = subtask.copyWith(title: val);
                        },
                      ),
                    ),
                    // Delete subtask button
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _subTasks.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addNewSubTask,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add subtask'),
            style: TextButton.styleFrom(foregroundColor: projectColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(Color projectColor) {
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: projectColor),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Custom Paint notes container
          CustomPaint(
            painter: PlannerLinesPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 14,
                  height: 2.0, // exactly 28 logical pixels tall per line
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Note down your thoughts here...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 8, bottom: 20),
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color projectColor) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _saveChanges,
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: projectColor,
            foregroundColor: ThemeData.estimateBrightnessForColor(projectColor) == Brightness.dark
                ? Colors.white
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Custom Painter to draw lines like a paper notepad
class PlannerLinesPainter extends CustomPainter {
  final double lineHeight;
  final Color lineColor;

  PlannerLinesPainter({
    this.lineHeight = 28.0,
    this.lineColor = AppColors.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    // Start drawing horizontal lines below the first row of text
    double y = 34.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
