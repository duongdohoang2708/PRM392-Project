import '../repositories/firestore_paths.dart';

class FocusSession {
  final String id;
  final String title;
  final String? taskId;
  final DateTime time;
  final int durationMinutes;

  FocusSession({
    required this.id,
    required this.title,
    this.taskId,
    required this.time,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return stripNulls({
      'title': title,
      'taskId': taskId,
      'time': dateTimeToTimestamp(time),
      'durationMinutes': durationMinutes,
    });
  }

  factory FocusSession.fromMap(String id, Map<String, dynamic> data) {
    return FocusSession(
      id: id,
      title: data['title'] as String? ?? '',
      taskId: data['taskId'] as String?,
      time: timestampToDateTime(data['time']) ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] as int? ?? 0,
    );
  }
}

/// Legacy alias used across focus UI.
typedef FocusSessionLog = FocusSession;
