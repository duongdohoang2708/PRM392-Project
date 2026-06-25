import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../utils/validation/task_deadline_rules.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../custom_snackbar.dart';
import '../../theme/app_colors.dart';

class CalendarCreateTaskPopup extends StatefulWidget {
  final DateTime selectedDate;
  final String? initialProjectName;

  const CalendarCreateTaskPopup({
    super.key,
    required this.selectedDate,
    this.initialProjectName,
  });

  @override
  State<CalendarCreateTaskPopup> createState() =>
      _CalendarCreateTaskPopupState();
}

class _CalendarCreateTaskPopupState extends State<CalendarCreateTaskPopup> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _project;
  late String _priority;
  TimeOfDay? _selectedTime;
  late bool _isImportant;
  late List<SubTask> _subTasks;
  late String _reminder;
  bool _isAllDay = false;

  String? _localErrorMessage;
  bool _showLocalError = false;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    _project = widget.initialProjectName ?? 'None';
    _priority = 'Low';
    _isImportant = false;
    _subTasks = [];
    _reminder = 'None';
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

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
        _selectedTime = pickedTime;
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
            decoration: const InputDecoration(
              hintText: 'Enter project name',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
            ),
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
      final newId = 'cal_create_sub_${DateTime.now().millisecondsSinceEpoch}';
      _subTasks.add(SubTask(id: newId, title: '', isCompleted: false));
    });
  }

  void _createTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar('Task title cannot be empty');
      return;
    }

    DateTime? finalDueDate;
    if (_selectedTime != null) {
      finalDueDate = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      // If time is not picked, default to noon or start of day, or null
      // Let's use 12:00 PM for the selected date as a default if no time is selected but a task is created for a date
      finalDueDate = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        12,
        0,
      );
    }

    if (!TaskDeadlineRules.isValidForCreate(finalDueDate)) {
      AppNotification.showError(context, TaskDeadlineRules.createDeadlineError);
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    final taskId = 'task_cal_${DateTime.now().millisecondsSinceEpoch}';

    final newTask = Task(
      id: taskId,
      title: title,
      project: _project,
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
    final provider = Provider.of<TaskProvider>(context);
    final projects = provider.availableProjects
        .where((p) => p != 'All Projects')
        .toList();
    if (!projects.contains(_project)) {
      projects.add(_project);
    }

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: isMobile ? double.infinity : 400,
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
                          Text(
                            'Task for ${AppDateTimeFormat.shortDate(widget.selectedDate)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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
                            _buildTitleCard(),
                            const SizedBox(height: 16),
                            _buildInfoCard(projects),
                            const SizedBox(height: 16),
                            _buildSubtasksCard(),
                            const SizedBox(height: 16),
                            _buildNotesCard(),
                            const SizedBox(height: 24),
                            _buildActionButtons(),
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
                  child: IgnorePointer(
                    ignoring: !_showLocalError,
                    child: AnimatedSlide(
                      offset: _showLocalError ? Offset.zero : const Offset(0, 1.5),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      child: AnimatedOpacity(
                        opacity: _showLocalError ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                color: AppColors.textSecondary.withValues(alpha: 0.5),
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

  Widget _buildInfoCard(List<String> projects) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Time',
            child: InkWell(
              onTap: _isAllDay ? null : _selectTime,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  _selectedTime == null
                      ? 'Set time'
                      : AppDateTimeFormat.timeOfDay(_selectedTime!),
                  style: TextStyle(
                    fontSize: 14,
                    color: _isAllDay
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
          _buildInfoRow(
            icon: Icons.all_inclusive,
            label: 'All Day',
            child: Switch(
              value: _isAllDay,
              onChanged: (val) {
                setState(() {
                  _isAllDay = val;
                  if (val) {
                    _selectedTime = null;
                  }
                });
              },
              activeTrackColor: AppColors.primaryDark.withValues(alpha: 0.5),
              activeColor: AppColors.primaryDark,
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
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
                  setState(() => _project = val);
                }
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
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
              items: ['High', 'Medium', 'Low']
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(p),
                      ),
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
              items:
                  ['None', '10 minutes before', '1 hour before', '1 day before']
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(r),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _reminder = val);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist, color: AppColors.primaryDark, size: 20),
              SizedBox(width: 8),
              Text(
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
                              ? AppColors.primaryDark
                              : Colors.transparent,
                          border: Border.all(
                            color: subtask.isCompleted
                                ? AppColors.primaryDark
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
              foregroundColor: AppColors.primaryDark,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primaryDark, size: 20),
                SizedBox(width: 8),
                Text(
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
          CustomPaint(
            painter: PlannerLinesPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _createTask,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
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

    double y = 34.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
