/// Stable notification IDs for scheduled insight / digest alerts.
class InsightNotificationIds {
  InsightNotificationIds._();

  static const int morningDigest = 120001;
  static const int overdueDigest = 120002;
  static const int importantEod = 120003;
  static const int goalsEod = 120004;
  static const int weeklySummary = 120005;
  static const int freezeDayMorning = 120006;

  static const List<int> allScheduled = [
    morningDigest,
    overdueDigest,
    importantEod,
    goalsEod,
    weeklySummary,
    freezeDayMorning,
  ];
}
