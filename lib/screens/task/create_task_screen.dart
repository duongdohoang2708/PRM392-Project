import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../utils/validation/task_deadline_rules.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/custom_snackbar.dart';
import '../project/create_project_screen.dart';

class CreateTaskScreen extends StatefulWidget {
  final String? initialProjectName;

  const CreateTaskScreen({super.key, this.initialProjectName});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _project;
  late String _priority;
  late DateTime? _dueDate;
  late bool _isImportant;
  late List<SubTask> _subTasks;
  late String _reminder;
  bool _isAllDay = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    _project = widget.initialProjectName ?? 'None';
    _priority = 'Low';
    _dueDate = null;
    _isImportant = false;
    _subTasks = [];
    _reminder = 'None';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: TaskDeadlineRules.minSelectableDateForCreate(),
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
          final defaultTime = TaskDeadlineRules.defaultTimeOnDatePick();
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            defaultTime.hour,
            defaultTime.minute,
          );
        } else {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _dueDate!.hour,
            _dueDate!.minute,
          );
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
        final date = _dueDate ?? _todayDate();
        _dueDate = DateTime(
          date.year,
          date.month,
          date.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _addNewProject() async {
    final newProjectName = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateProjectScreen(),
      ),
    );

    if (newProjectName != null && newProjectName.isNotEmpty) {
      setState(() {
        _project = newProjectName;
      });
    }
  }

  void _addNewSubTask() {
    setState(() {
      final newId = 'create_sub_${DateTime.now().millisecondsSinceEpoch}';
      _subTasks.add(SubTask(id: newId, title: '', isCompleted: false));
    });
  }

  void _createTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppNotification.showError(context, 'Task title cannot be empty');
      return;
    }

    if (!TaskDeadlineRules.isValidForCreate(_dueDate)) {
      AppNotification.showError(context, TaskDeadlineRules.createDeadlineError);
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    final taskId = 'task_create_${DateTime.now().millisecondsSinceEpoch}';

    final newTask = Task(
      id: taskId,
      title: title,
      project: _project,
      priority: _priority,
      dueDate: _dueDate,
      isCompleted: false,
      isImportant: _isImportant,
      isAllDay: _isAllDay,
      notes: _notesController.text.trim(),
      subTasks: _subTasks,
    );

    if (!taskProvider.addTask(newTask)) {
      AppNotification.showError(context, TaskDeadlineRules.createDeadlineError);
      return;
    }

    AppNotification.showSuccess(context, 'Task created successfully');

    Navigator.pop(context);
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
        'Create Task',
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
          _buildTitleCard(),
          const SizedBox(height: 16),

          // Task details info for Mobile/Tablet only
          if (!useTwoColumns) ...[
            _buildInfoCard(projects),
            const SizedBox(height: 16),
          ],

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
          drawer: isDesktop ? null : const AppDrawer(
            isPermanent: false,
            activeRoute: '/task-list',
          ),
          appBar: _buildAppBar(context, isDesktop: isDesktop),
          body: isDesktop ? mainContent : Builder(
            builder: (context) => GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
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
          // Simulated empty checkbox for task creation context
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                width: 2,
              ),
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
          // Date Row
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
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

          // All Day Toggle
          _buildInfoRow(
            icon: Icons.all_inclusive,
            label: 'All Day',
            child: Switch(
              value: _isAllDay,
              activeTrackColor: AppColors.primaryDark.withValues(alpha: 0.5),
              activeThumbColor: AppColors.primaryDark,
              onChanged: (val) {
                setState(() {
                  _isAllDay = val;
                });
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomPaint(
              painter: PlannerLinesPainter(),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 14,
                  height: 2.0,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _createTask,
          icon: const Icon(Icons.check),
          label: const Text('Create Task'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

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

    double y = 34.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
