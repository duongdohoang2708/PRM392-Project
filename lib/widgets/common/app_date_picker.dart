import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters/app_date_time_format.dart';
import 'app_popup_transition.dart';
import 'popup_surface.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _clampDate(DateTime date, DateTime min, DateTime max) {
  final normalized = _dateOnly(date);
  final minDate = _dateOnly(min);
  final maxDate = _dateOnly(max);
  if (normalized.isBefore(minDate)) return minDate;
  if (normalized.isAfter(maxDate)) return maxDate;
  return normalized;
}

/// Inline Cupertino wheel date picker used inside forms and popups.
class AppCupertinoDatePicker extends StatelessWidget {
  final DateTime date;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final ValueChanged<DateTime> onDateChanged;
  final double height;
  final Color? accentColor;

  const AppCupertinoDatePicker({
    super.key,
    required this.date,
    required this.minimumDate,
    required this.maximumDate,
    required this.onDateChanged,
    this.height = 180,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = _clampDate(date, minimumDate, maximumDate);
    final resolvedAccent = accentColor ?? AppColors.primaryDarkOf(context);

    return SizedBox(
      height: height,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: resolvedAccent,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              fontSize: 20,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: initial,
          minimumDate: _dateOnly(minimumDate),
          maximumDate: _dateOnly(maximumDate),
          onDateTimeChanged: (dateTime) {
            onDateChanged(_dateOnly(dateTime));
          },
        ),
      ),
    );
  }
}

/// Shows a Cupertino-style date picker dialog consistent with TaskFlow popups.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Select date',
  Color? accentColor,
  Offset? anchor,
}) {
  final resolvedAccent = accentColor ?? AppColors.primaryDarkOf(context);
  return showAppPopup<DateTime>(
    context: context,
    anchor: anchor,
    child: _AppDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      accentColor: resolvedAccent,
    ),
  );
}

class _AppDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final Color accentColor;

  const _AppDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.accentColor,
  });

  @override
  State<_AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<_AppDatePickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _clampDate(
      widget.initialDate,
      widget.firstDate,
      widget.lastDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onAccent = ThemeData.estimateBrightnessForColor(widget.accentColor) ==
            Brightness.dark
        ? Colors.white
        : AppColors.textPrimaryOf(context);

    return AppPopupShell(
      alignment: Alignment.centerRight,
      child: PopupSurface(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textSecondaryOf(context),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(color: AppColors.borderOf(context), height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppDateTimeFormat.date(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ),
                AppCupertinoDatePicker(
                  date: _selectedDate,
                  minimumDate: widget.firstDate,
                  maximumDate: widget.lastDate,
                  accentColor: widget.accentColor,
                  onDateChanged: (date) => setState(() => _selectedDate = date),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
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
    );
  }
}
