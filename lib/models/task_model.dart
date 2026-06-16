class Task {
  final String id;
  final String title;
  final String project;
  final String priority;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isImportant;

  Task({
    required this.id,
    required this.title,
    required this.project,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
    this.isImportant = false,
  });

  Task copyWith({
    String? title,
    String? project,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isImportant,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      project: project ?? this.project,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
    );
  }
}
