import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../utils/validation/task_deadline_rules.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/project/create_project_popup.dart';
import '../../widgets/task/reminder_selector.dart';
import '../../widgets/task/subtask_title_field.dart';
import '../../widgets/common/app_time_picker.dart';
import '../../widgets/common/app_date_picker.dart';
import '../../widgets/common/app_dropdown.dart';
import '../../widgets/common/app_popup_transition.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../utils/reminder/task_reminder.dart';
import '../../utils/project_accent_color.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../utils/keyboard/keyboard_insets.dart';

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
    _reminder = TaskReminder.none;
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

  Future<void> _selectDate(BuildContext tapContext) async {
    final pickedDate = await showAppDatePicker(
      context,
      anchor: popupAnchorFromContext(tapContext),
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: TaskDeadlineRules.minSelectableDateForCreate(),
      lastDate: DateTime(2030),
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

  Future<void> _selectTime(BuildContext tapContext) async {
    if (_isAllDay) return;

    final pickedTime = await showAppTimePicker(
      context,
      anchor: popupAnchorFromContext(tapContext),
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
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

  void _addNewProject(BuildContext tapContext) async {
    final newProjectName = await showCreateProjectPopup(
      context,
      anchor: popupAnchorFromContext(tapContext),
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
      reminder: _reminder,
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
    final projectProvider = Provider.of<ProjectProvider>(context);
    final projects = provider.availableProjects
         .where((p) => p != 'All Projects')
         .toList();
    if (!projects.contains('None')) {
      projects.insert(0, 'None');
    }
    if (!projects.contains(_project)) {
      projects.add(_project);
    }

    final projectAccent =
        ProjectAccentColor.resolve(context, projectProvider, _project);

    final titleWidget = Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 24, top: 8),
      child: Text(
        'Create Task',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = MediaQuery.sizeOf(context).width >= 768;
        final bool useTwoColumns = constraints.maxWidth >= 1024;

        // Main Columns
        final leftColumnWidgets = [
          // Title card
          _buildTitleCard(projectAccent),
          const SizedBox(height: 16),

          // Task details info for Mobile/Tablet only
          if (!useTwoColumns) ...[
            _buildInfoCard(projects, projectAccent),
            const SizedBox(height: 16),
          ],

          // Subtasks card
          _buildSubtasksCard(projectAccent),
          const SizedBox(height: 16),

          // Notes card
          _buildNotesCard(projectAccent),

          // Bottom actions for Mobile/Tablet only
          if (!useTwoColumns) ...[
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ];

        final rightColumnWidgets = [
          // Task details info for Desktop only
          if (useTwoColumns) ...[
            _buildInfoCard(projects, projectAccent),
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
                  child: KeyboardAwareSingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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

        return AppScaffold(
          backgroundColor: AppColors.backgroundOf(context),
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
      backgroundColor: AppColors.backgroundOf(context),
      elevation: 0,
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: AppColors.textPrimaryOf(context)),
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
            icon: Icon(
              Icons.chevron_left,
              size: 28,
              color: AppColors.textPrimaryOf(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      actions: [
        const NotificationBellButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTitleCard(Color projectAccent) {
    final projectDot = AppColors.projectAccentOf(context, projectAccent);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColors.taskCardDecorationOf(context, projectAccent),
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
                color: AppColors.textSecondaryOf(context).withValues(alpha: 0.5),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
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
                        color: AppColors.projectTintOf(context, projectAccent),
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
                              color: projectDot,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _project,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
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
                                  : AppColors.primaryDarkOf(context)),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$_priority Priority',
                        style: TextStyle(
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
                  : AppColors.textSecondaryOf(context).withValues(alpha: 0.5),
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

  Widget _buildInfoCard(List<String> projects, Color projectAccent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.taskCardDecorationOf(context, projectAccent),
      child: Column(
        children: [
          // Date Row
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            child: Builder(
              builder: (tapContext) => InkWell(
                onTap: () => _selectDate(tapContext),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    _dueDate == null
                        ? 'Set date'
                        : AppDateTimeFormat.date(_dueDate!),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Divider(color: AppColors.borderOf(context), height: 24),

          // Time Row
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Time',
            child: Builder(
              builder: (tapContext) => InkWell(
                onTap: () => _selectTime(tapContext),
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
                      color: _isAllDay
                          ? AppColors.textSecondaryOf(context)
                          : AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Divider(color: AppColors.borderOf(context), height: 24),

          // All Day Toggle
          _buildInfoRow(
            icon: Icons.all_inclusive,
            label: 'All Day',
            child: Switch(
              value: _isAllDay,
              activeTrackColor: AppColors.primaryDarkOf(context).withValues(alpha: 0.5),
              activeThumbColor: AppColors.primaryDarkOf(context),
              onChanged: (val) {
                setState(() {
                  _isAllDay = val;
                  _reminder = TaskReminder.coerceForMode(_reminder, val);
                });
              },
            ),
          ),
          Divider(color: AppColors.borderOf(context), height: 24),

          // Project Row
          _buildInfoRow(
            icon: Icons.folder_open,
            label: 'Project',
            child: Builder(
              builder: (tapContext) => AppDropdown<String>(
                value: _project,
                isExpanded: true,
                alignment: AlignmentDirectional.centerEnd,
                items: [
                  ...projects.map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: AppDropdown.menuChild(Text(p)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: '__add_new__',
                    child: AppDropdown.menuChild(
                      Text(
                        '+ Add Project',
                        style: TextStyle(
                          color: AppColors.primaryDarkOf(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__add_new__') {
                    _addNewProject(tapContext);
                  } else if (val != null) {
                    setState(() {
                      _project = val;
                    });
                  }
                },
              ),
            ),
          ),
          Divider(color: AppColors.borderOf(context), height: 24),

          // Priority Row
          _buildInfoRow(
            icon: Icons.flag_outlined,
            label: 'Priority',
            child: AppDropdown<String>(
              value: _priority,
              isExpanded: true,
              alignment: AlignmentDirectional.centerEnd,
              items: [
                DropdownMenuItem(
                  value: 'High',
                  child: AppDropdown.menuChild(Text('High')),
                ),
                DropdownMenuItem(
                  value: 'Medium',
                  child: AppDropdown.menuChild(Text('Medium')),
                ),
                DropdownMenuItem(
                  value: 'Low',
                  child: AppDropdown.menuChild(Text('Low')),
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
          Divider(color: AppColors.borderOf(context), height: 24),

          // Reminder Row
          _buildInfoRow(
            icon: Icons.notifications,
            label: 'Reminder',
            child: ReminderSelector(
              value: _reminder,
              isAllDay: _isAllDay,
              onChanged: (val) => setState(() => _reminder = val),
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
        Icon(icon, size: 20, color: AppColors.primaryDarkOf(context)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryOf(context),
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

  Widget _buildSubtasksCard(Color projectAccent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColors.taskCardDecorationOf(context, projectAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: AppColors.primaryDarkOf(context)),
              const SizedBox(width: 8),
              Text(
                'Subtasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
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
                              ? AppColors.primaryDarkOf(context)
                              : Colors.transparent,
                          border: Border.all(
                            color: subtask.isCompleted
                                ? AppColors.primaryDarkOf(context)
                                : AppColors.textSecondaryOf(context).withValues(
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
                      child: SubtaskTitleField(
                        title: subtask.title,
                        isCompleted: subtask.isCompleted,
                        onChanged: (val) {
                          _subTasks[index] = subtask.copyWith(title: val);
                        },
                      ),
                    ),
                    // Delete subtask button
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondaryOf(context),
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
            icon: Icon(Icons.add, size: 18),
            label: const Text('Add subtask'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryDarkOf(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(Color projectAccent) {
    return Container(
      decoration: AppColors.taskCardDecorationOf(context, projectAccent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primaryDarkOf(context)),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomPaint(
              painter: PlannerLinesPainter(
                lineColor: AppColors.borderOf(context),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: 14,
                  height: 2.0,
                  color: AppColors.textPrimaryOf(context),
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
          icon: Icon(Icons.check),
          label: const Text('Create Task'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.primaryOf(context),
            foregroundColor: AppColors.textPrimaryOf(context),
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
    required this.lineColor,
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
