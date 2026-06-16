import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';
import '../focus/focus_session_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';

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
  late List<SubTask> _subTasks;
  late String _reminder;
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  int _sessions = 1;

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
    _subTasks = List.from(task.subTasks);
    _reminder = '1 hour before'; // default mock value
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task title cannot be empty'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      notes: _notesController.text.trim(),
      subTasks: _subTasks,
    );

    taskProvider.updateTask(updatedTask);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes saved successfully'),
        backgroundColor: AppColors.primaryDark,
      ),
    );

    Navigator.pop(context);
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Task'),
          content: const Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
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
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                navigator.pop(); // Close dialog
                context.read<TaskProvider>().deleteTask(widget.taskId);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                navigator.pop(); // Close detail screen
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

  Future<void> _selectDueDate() async {
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
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
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
    final projects = provider.availableProjects
        .where((p) => p != 'All Projects')
        .toList();
    if (!projects.contains(_project)) {
      projects.add(_project);
    }

    final titleWidget = Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 24, top: 8),
      child: Text(
        'Task Detail',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 768;
        final bool useTwoColumns = constraints.maxWidth >= 1024;

        // Main Columns
        final leftColumnWidgets = [
          // Title card
          _buildTitleCard(),
          const SizedBox(height: 16),

          // Task details info for Mobile/Tablet only
          if (!useTwoColumns) ...[
            _buildInfoCard(projects),
            const SizedBox(height: 16),
          ],

          // Pomodoro focus card
          _buildPomodoroCard(),
          const SizedBox(height: 16),

          // Subtasks card
          _buildSubtasksCard(),
          const SizedBox(height: 16),

          // Notes card
          _buildNotesCard(),

          // Bottom actions for Mobile/Tablet only
          if (!useTwoColumns) ...[
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ];

        final rightColumnWidgets = [
          // Task details info for Desktop only
          if (useTwoColumns) ...[
            _buildInfoCard(projects),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ];

        Widget mainContent = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Center(
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

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                const AppDrawer(isPermanent: true, activeRoute: '/task-list'),
                Expanded(
                  child: Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: _buildAppBar(context, isDesktop: true),
                    body: mainContent,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: const AppDrawer(
            isPermanent: false,
            activeRoute: '/task-list',
          ),
          appBar: _buildAppBar(context, isDesktop: false),
          body: mainContent,
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
      leadingWidth: isDesktop ? 56 : 96,
      leading: isDesktop
          ? IconButton(
              icon: const Icon(
                Icons.chevron_left,
                size: 28,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTitleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                    ? AppColors.primaryDark
                    : Colors.transparent,
                border: Border.all(
                  color: _isCompleted
                      ? AppColors.primaryDark
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
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryDark,
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
                                  : AppColors.primaryLight),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$_priority Priority',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _priority == 'High'
                              ? const Color(0xFFC0392B)
                              : AppColors.textPrimary,
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

  Widget _buildInfoCard(List<String> projects) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Due Date Row
          _buildInfoRow(
            icon: Icons.event,
            label: 'Due Date',
            child: InkWell(
              onTap: _selectDueDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  _dueDate == null
                      ? 'Set due date'
                      : DateFormat('MMM d, yyyy  h:mm a').format(_dueDate!),
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

          // Status Row
          _buildInfoRow(
            icon: Icons.pending_actions,
            label: 'Status',
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
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
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

  Widget _buildPomodoroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer, color: AppColors.primaryDark),
                  SizedBox(width: 8),
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
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.primaryDark.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${_focusMinutes.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdjuster(
                  'Break (m)',
                  _breakMinutes,
                  (val) => setState(() => _breakMinutes = val),
                  min: 1,
                  max: 60,
                  step: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdjuster(
                  'Sessions',
                  _sessions,
                  (val) => setState(() => _sessions = val),
                  min: 1,
                  max: 10,
                  step: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FocusSessionScreen(
                    taskId: widget.taskId,
                    focusMinutes: _focusMinutes,
                    breakMinutes: _breakMinutes,
                    sessions: _sessions,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow),
                SizedBox(width: 8),
                Text('Start Pomodoro'),
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
                icon: const Icon(Icons.remove, color: AppColors.primaryDark),
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
                icon: const Icon(Icons.add, color: AppColors.primaryDark),
                onPressed: value < max ? () => onChanged(value + step) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubtasksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist, color: AppColors.primaryDark),
              SizedBox(width: 8),
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
                              ? AppColors.primaryDark
                              : Colors.transparent,
                          border: Border.all(
                            color: subtask.isCompleted
                                ? AppColors.primaryDark
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
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 20, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primaryDark),
                SizedBox(width: 8),
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
                  hintText: 'Jot down your thoughts here...',
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _saveChanges,
          icon: const Icon(Icons.save),
          label: const Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _deleteTask,
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          label: const Text(
            'Delete Task',
            style: TextStyle(color: Colors.redAccent),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
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
