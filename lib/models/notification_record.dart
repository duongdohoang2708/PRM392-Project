import '../repositories/firestore_paths.dart';
import '../utils/reminder/task_reminder.dart';

enum NotificationCategory {
  taskReminder,
  taskDue,
  focus,
  goals,
  achievement,
  statistics,
  system,
}

class NotificationRecord {
  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? taskId;

  const NotificationRecord({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.taskId,
  });

  NotificationRecord copyWith({
    String? id,
    NotificationCategory? category,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? taskId,
  }) {
    return NotificationRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      taskId: taskId ?? this.taskId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'taskId': taskId,
      };

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: json['id'] as String,
      category: NotificationCategory.values.byName(json['category'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      taskId: json['taskId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'category': category.name,
        'title': title,
        'body': body,
        'timestamp': dateTimeToTimestamp(timestamp),
        'isRead': isRead,
        'taskId': taskId,
      };

  factory NotificationRecord.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return NotificationRecord(
      id: id,
      category: NotificationCategory.values.byName(
        data['category'] as String? ?? NotificationCategory.system.name,
      ),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      timestamp: timestampToDateTime(data['timestamp']) ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      taskId: data['taskId'] as String?,
    );
  }
}

NotificationCategory categoryFromType(String type) {
  switch (type) {
    case 'task_reminder':
      return NotificationCategory.taskReminder;
    case 'task_due':
      return NotificationCategory.taskDue;
    case 'focus':
    case 'focus_goal_met':
    case 'focus_goal_near':
      return NotificationCategory.focus;
    case 'streak_secured':
    case 'streak_reminder':
    case 'freeze_day':
    case 'freeze_credit':
      return NotificationCategory.goals;
    case 'achievement_unlock':
    case 'achievement_near':
      return NotificationCategory.achievement;
    case 'morning_digest':
    case 'overdue_digest':
    case 'important_eod':
    case 'weekly_summary':
    case 'stats_milestone':
      return NotificationCategory.statistics;
    default:
      return NotificationCategory.system;
  }
}

String categoryLabel(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.taskReminder:
      return 'Task reminder';
    case NotificationCategory.taskDue:
      return 'Due now';
    case NotificationCategory.focus:
      return 'Focus';
    case NotificationCategory.goals:
      return 'Goals & streak';
    case NotificationCategory.achievement:
      return 'Achievement';
    case NotificationCategory.statistics:
      return 'Summary';
    case NotificationCategory.system:
      return 'System';
  }
}

String? routeForNotificationType(String type) {
  switch (type) {
    case 'task_reminder':
    case 'task_due':
    case 'morning_digest':
    case 'overdue_digest':
    case 'important_eod':
      return '/task-list';
    case 'focus':
    case 'focus_goal_met':
    case 'focus_goal_near':
      return '/focus';
    case 'streak_secured':
    case 'streak_reminder':
    case 'freeze_day':
    case 'freeze_credit':
      return '/goals';
    case 'achievement_unlock':
    case 'achievement_near':
      return '/achievements';
    case 'weekly_summary':
    case 'stats_milestone':
      return '/statistics';
    default:
      return null;
  }
}

bool taskHasUpcomingReminder({
  required String reminder,
  required DateTime? dueDate,
  required bool isCompleted,
}) {
  return !isCompleted &&
      dueDate != null &&
      reminder != TaskReminder.none &&
      dueDate.isAfter(DateTime.now());
}
