import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/task_model.dart';
import '../../models/project_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/project_provider.dart';
import '../../utils/validation/task_deadline_rules.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../custom_snackbar.dart';
import '../../theme/app_colors.dart';
import '../../utils/reminder/task_reminder.dart';
import '../task/reminder_selector.dart';
import '../common/app_time_picker.dart';
import '../common/app_date_picker.dart';
import '../common/app_dropdown.dart';
import '../common/app_popup_transition.dart';
import '../common/animations/app_bottom_slide_fade.dart';

class ProjectCreateTaskPopup extends StatefulWidget {
  final String projectName;
  final DateTime? selectedDate;

  const ProjectCreateTaskPopup({
    super.key,
    required this.projectName,
    this.selectedDate,
  });

  @override
  State<ProjectCreateTaskPopup> createState() => _ProjectCreateTaskPopupState();
}

class _ProjectCreateTaskPopupState extends State<ProjectCreateTaskPopup> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _priority;
  TimeOfDay? _selectedTime;
  bool _isAllDay = false;
  late bool _isImportant;
  late List<SubTask> _subTasks;
  late String _reminder;
  DateTime? _selectedDate;

  String? _localErrorMessage;
  bool _showLocalError = false;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    _priority = 'Low';
    _isImportant = false;
    _subTasks = [];
    _reminder = TaskReminder.none;
    _selectedDate = widget.selectedDate;
    if (_selectedDate != null) {
      _selectedTime = TaskDeadlineRules.defaultTimeOnDatePick();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message) {
    _errorTimer?.cancel();
    setState(() {
      _localErrorMessage = message;
      _showLocalError = true;
    });
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLocalError = false;
        });
      }
    });
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _selectTime(BuildContext tapContext) async {
    if (_isAllDay) return;
    
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final project = projectProvider.projects.firstWhere(
      (p) => p.name == widget.projectName,
      orElse: () => Project(
        id: '',
        name: '',
        description: '',
        colorValue: AppColors.primary.toARGB32(),
      ),
    );
    final Color projectColor = Color(project.colorValue);

    final TimeOfDay? pickedTime = await showAppTimePicker(
      context,
      anchor: popupAnchorFromContext(tapContext),
      initialTime: _selectedTime ?? TimeOfDay.now(),
      accentColor: projectColor,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDate ??= _todayDate();
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _selectDate(BuildContext tapContext) async {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final project = projectProvider.projects.firstWhere(
      (p) => p.name == widget.projectName,
      orElse: () => Project(
        id: '',
        name: '',
        description: '',
        colorValue: AppColors.primary.toARGB32(),
      ),
    );
    final Color projectColor = Color(project.colorValue);

    final pickedDate = await showAppDatePicker(
      context,
      anchor: popupAnchorFromContext(tapContext),
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: TaskDeadlineRules.minSelectableDateForCreate(),
      lastDate: DateTime(2100),
      accentColor: projectColor,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
        _selectedTime ??= TaskDeadlineRules.defaultTimeOnDatePick();
      });
    }
  }

  void _addNewSubTask() {
    setState(() {
      final newId = 'proj_create_sub_${DateTime.now().millisecondsSinceEpoch}';
      _subTasks.add(SubTask(id: newId, title: '', isCompleted: false));
    });
  }

  void _createTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar('Task title cannot be empty');
      return;
    }

    final date = _selectedDate ?? DateTime.now();
    DateTime? finalDueDate;
    if (_selectedTime != null) {
      finalDueDate = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      final defaultTime = TaskDeadlineRules.defaultTimeOnDatePick();
      finalDueDate = DateTime(
        date.year,
        date.month,
        date.day,
        defaultTime.hour,
        defaultTime.minute,
      );
    }

    if (!TaskDeadlineRules.isValidForCreate(finalDueDate)) {
      AppNotification.showError(context, TaskDeadlineRules.createDeadlineError);
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    final taskId = 'task_proj_${DateTime.now().millisecondsSinceEpoch}';

    final newTask = Task(
      id: taskId,
      title: title,
      project: widget.projectName,
      priority: _priority,
      dueDate: finalDueDate,
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
    final projectProvider = Provider.of<ProjectProvider>(context);
    final project = projectProvider.projects.firstWhere(
      (p) => p.name == widget.projectName,
      orElse: () => Project(
        id: '',
        name: '',
        description: '',
        colorValue: AppColors.primary.toARGB32(),
      ),
    );
    final Color projectColor = Color(project.colorValue);

    return AppPopupShell(
      alignment: Alignment.centerRight,
      child: Container(
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
            child: Stack(
              children: [
                Column(
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
                          Expanded(
                            child: Text(
                              'Task for ${widget.projectName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    const Divider(color: AppColors.border, height: 1),

                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleCard(projectColor),
                            const SizedBox(height: 16),
                            _buildInfoCard(projectColor),
                            const SizedBox(height: 16),
                            _buildSubtasksCard(projectColor),
                            const SizedBox(height: 16),
                            _buildNotesCard(projectColor),
                            const SizedBox(height: 24),
                            _buildActionButtons(projectColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Custom SnackBar floating at the bottom of the popup
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: AppBottomSlideFade(
                    visible: _showLocalError,
                    child: Material(
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFE57373),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _localErrorMessage ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildTitleCard(Color projectColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: projectColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Task title...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isImportant ? Icons.star : Icons.star_border,
              color: _isImportant
                  ? AppColors.accentYellow
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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

  Widget _buildInfoCard(Color projectColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            projectColor: projectColor,
            child: Builder(
              builder: (tapContext) => InkWell(
                onTap: () => _selectDate(tapContext),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    _selectedDate == null
                        ? 'Set date'
                        : AppDateTimeFormat.date(_selectedDate!),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Time',
            projectColor: projectColor,
            child: Builder(
              builder: (tapContext) => InkWell(
                onTap: () => _selectTime(tapContext),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    _isAllDay
                        ? 'All Day'
                        : (_selectedTime == null
                            ? 'Set time'
                            : AppDateTimeFormat.timeOfDay(_selectedTime!)),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isAllDay ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
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
                  _reminder = TaskReminder.coerceForMode(_reminder, val);
                });
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
          _buildInfoRow(
            icon: Icons.flag_outlined,
            label: 'Priority',
            projectColor: projectColor,
            child: AppDropdown<String>(
              value: _priority,
              isExpanded: true,
              alignment: AlignmentDirectional.centerEnd,
              accentColor: projectColor,
              items: ['High', 'Medium', 'Low']
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: AppDropdown.menuChild(Text(p)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _priority = val);
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
          _buildInfoRow(
            icon: Icons.notifications,
            label: 'Reminder',
            projectColor: projectColor,
            child: ReminderSelector(
              value: _reminder,
              isAllDay: _isAllDay,
              accentColor: projectColor,
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

  Widget _buildSubtasksCard(Color projectColor) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.checklist, color: projectColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Subtasks',
                style: TextStyle(
                  fontSize: 14,
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
                    GestureDetector(
                      onTap: () => setState(
                        () => _subTasks[index] = subtask.copyWith(
                          isCompleted: !subtask.isCompleted,
                        ),
                      ),
                      child: Container(
                        width: 18,
                        height: 18,
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
                          fillColor: Colors.transparent,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) =>
                            _subTasks[index] = subtask.copyWith(title: val),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          setState(() => _subTasks.removeAt(index)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addNewSubTask,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add subtask', style: TextStyle(fontSize: 14)),
            style: TextButton.styleFrom(
              foregroundColor: projectColor,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: projectColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomPaint(
              painter: PlannerLinesPainter(),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                minLines: 3,
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
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.only(top: 0, bottom: 16),
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
        ElevatedButton(
          onPressed: _createTask,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: projectColor,
            foregroundColor: ThemeData.estimateBrightnessForColor(projectColor) == Brightness.dark
                ? Colors.white
                : AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: const Text(
            'Create Task',
            style: TextStyle(fontWeight: FontWeight.bold),
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

    double y = 28.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
