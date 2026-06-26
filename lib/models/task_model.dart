class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  SubTask({required this.id, required this.title, this.isCompleted = false});

  SubTask copyWith({String? id, String? title, bool? isCompleted}) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

const Object _noValue = Object();

class Task {
  final String id;
  final String title;
  final String project;
  final String priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final bool isImportant;
  final bool isAllDay;
  final String notes;
  final String reminder;
  final List<SubTask> subTasks;

  Task({
    required this.id,
    required this.title,
    required this.project,
    required this.priority,
    this.dueDate,
    DateTime? createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.isImportant = false,
    this.isAllDay = false,
    this.notes = '',
    this.reminder = 'None',
    this.subTasks = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? project,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    Object? completedAt = _noValue,
    bool? isCompleted,
    bool? isImportant,
    bool? isAllDay,
    String? notes,
    String? reminder,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      project: project ?? this.project,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt == _noValue ? this.completedAt : completedAt as DateTime?,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isAllDay: isAllDay ?? this.isAllDay,
      notes: notes ?? this.notes,
      reminder: reminder ?? this.reminder,
      subTasks: subTasks ?? this.subTasks,
    );
  }
}
