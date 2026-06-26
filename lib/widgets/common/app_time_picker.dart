import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters/app_date_time_format.dart';
import 'app_popup_transition.dart';

/// Inline Cupertino wheel time picker used inside forms and popups.
class AppCupertinoTimePicker extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final double height;

  const AppCupertinoTimePicker({
    super.key,
    required this.time,
    required this.onTimeChanged,
    this.height = 180,
  });

  static DateTime _dateTimeFromTime(TimeOfDay value) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, value.hour, value.minute);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: Brightness.light,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: const TextStyle(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: !AppDateTimeFormat.use12HourClock,
          initialDateTime: _dateTimeFromTime(time),
          onDateTimeChanged: (dateTime) {
            onTimeChanged(TimeOfDay(hour: dateTime.hour, minute: dateTime.minute));
          },
        ),
      ),
    );
  }
}

/// Shows a Cupertino-style time picker dialog consistent with TaskFlow popups.
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String title = 'Select time',
  Color accentColor = AppColors.primaryDark,
  Offset? anchor,
}) {
  return showAppPopup<TimeOfDay>(
    context: context,
    anchor: anchor,
    child: _AppTimePickerDialog(
      initialTime: initialTime,
      title: title,
      accentColor: accentColor,
    ),
  );
}

class _AppTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;
  final Color accentColor;

  const _AppTimePickerDialog({
    required this.initialTime,
    required this.title,
    required this.accentColor,
  });

  @override
  State<_AppTimePickerDialog> createState() => _AppTimePickerDialogState();
}

class _AppTimePickerDialogState extends State<_AppTimePickerDialog> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final onAccent = ThemeData.estimateBrightnessForColor(widget.accentColor) ==
            Brightness.dark
        ? Colors.white
        : AppColors.textPrimary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: isMobile ? double.infinity : 400,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        widget.title,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppDateTimeFormat.timeOfDay(_selectedTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ),
                AppCupertinoTimePicker(
                  time: _selectedTime,
                  onTimeChanged: (time) => setState(() => _selectedTime = time),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedTime),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: widget.accentColor,
                      foregroundColor: onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
}
