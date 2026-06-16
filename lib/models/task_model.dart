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

class Task {
  final String id;
  final String title;
  final String project;
  final String priority;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isImportant;
  final String notes;
  final List<SubTask> subTasks;

  Task({
    required this.id,
    required this.title,
    required this.project,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
    this.isImportant = false,
    this.notes = '',
    this.subTasks = const [],
  });

  Task copyWith({
    String? title,
    String? project,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isImportant,
    String? notes,
    List<SubTask>? subTasks,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      project: project ?? this.project,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      notes: notes ?? this.notes,
      subTasks: subTasks ?? this.subTasks,
    );
  }
}
