import 'package:flutter/material.dart';

import '../../models/notification_record.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters/app_date_time_format.dart';

class NotificationListItem extends StatelessWidget {
  final NotificationRecord record;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.record,
    required this.onTap,
  });

  IconData get _icon {
    switch (record.category) {
      case NotificationCategory.taskReminder:
        return Icons.notifications;
      case NotificationCategory.taskDue:
        return Icons.event;
      case NotificationCategory.focus:
        return Icons.timer_outlined;
      case NotificationCategory.goals:
        return Icons.local_fire_department_outlined;
      case NotificationCategory.achievement:
        return Icons.emoji_events_outlined;
      case NotificationCategory.statistics:
        return Icons.insights_outlined;
      case NotificationCategory.system:
        return Icons.info_outline;
    }
  }

  Color _accentColor(BuildContext context) {
    switch (record.category) {
      case NotificationCategory.taskReminder:
        return AppColors.primaryDark;
      case NotificationCategory.taskDue:
        return AppColors.accentPeach;
      case NotificationCategory.focus:
        return AppColors.accentYellow;
      case NotificationCategory.goals:
        return AppColors.streakFlame;
      case NotificationCategory.achievement:
        return const Color(0xFF6A1B9A);
      case NotificationCategory.statistics:
        return const Color(0xFF0277BD);
      case NotificationCategory.system:
        return AppColors.textSecondaryOf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceFillOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, color: _accentColor(context), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        Text(
                          AppDateTimeFormat.time(record.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.body,
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categoryLabel(record.category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accentColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
