import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/firestore_paths.dart';

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

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory SubTask.fromMap(Map<String, dynamic> data) {
    return SubTask(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }
}

const Object _noValue = Object();

class Task {
  final String id;
  final String title;
  final String? projectId;
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
    this.projectId,
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

  /// Legacy alias — prefer resolving via [ProjectProvider].
  String get project => projectId ?? 'None';

  bool get hasProject =>
      projectId != null && projectId!.isNotEmpty && projectId != 'None';

  Task copyWith({
    String? title,
    Object? projectId = _noValue,
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
      projectId: identical(projectId, _noValue)
          ? this.projectId
          : projectId as String?,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt:
          completedAt == _noValue ? this.completedAt : completedAt as DateTime?,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isAllDay: isAllDay ?? this.isAllDay,
      notes: notes ?? this.notes,
      reminder: reminder ?? this.reminder,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  Map<String, dynamic> toMap() {
    return stripNulls({
      'title': title,
      'projectId': hasProject ? projectId : null,
      'priority': priority,
      'dueDate': dateTimeToTimestamp(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': dateTimeToTimestamp(completedAt),
      'isCompleted': isCompleted,
      'isImportant': isImportant,
      'isAllDay': isAllDay,
      'notes': notes,
      'reminder': reminder,
      'subTasks': subTasks.map((st) => st.toMap()).toList(),
    });
  }

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    final legacyProject = data['project'] as String?;
    final rawProjectId = data['projectId'] as String? ?? legacyProject;
    final projectId = rawProjectId == null ||
            rawProjectId.isEmpty ||
            rawProjectId == 'None'
        ? null
        : rawProjectId;

    final subTasksRaw = data['subTasks'];
    final subTasks = subTasksRaw is List
        ? subTasksRaw
            .whereType<Map>()
            .map((item) => SubTask.fromMap(Map<String, dynamic>.from(item)))
            .toList()
        : <SubTask>[];

    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      projectId: projectId,
      priority: data['priority'] as String? ?? 'Medium',
      dueDate: timestampToDateTime(data['dueDate']),
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      completedAt: timestampToDateTime(data['completedAt']),
      isCompleted: data['isCompleted'] as bool? ?? false,
      isImportant: data['isImportant'] as bool? ?? false,
      isAllDay: data['isAllDay'] as bool? ?? false,
      notes: data['notes'] as String? ?? '',
      reminder: data['reminder'] as String? ?? 'None',
      subTasks: subTasks,
    );
  }
}
