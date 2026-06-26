import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/reminder/task_reminder.dart';
import '../common/app_popup_transition.dart';
import '../common/app_time_picker.dart';

Future<String?> showCustomReminderPopup(
  BuildContext context, {
  required bool isAllDay,
  String? initialReminder,
  Offset? anchor,
}) {
  return showAppPopup<String>(
    context: context,
    anchor: anchor,
    child: CustomReminderPopup(
      isAllDay: isAllDay,
      initialReminder: initialReminder,
    ),
  );
}

class CustomReminderPopup extends StatefulWidget {
  final bool isAllDay;
  final String? initialReminder;

  const CustomReminderPopup({
    super.key,
    required this.isAllDay,
    this.initialReminder,
  });

  @override
  State<CustomReminderPopup> createState() => _CustomReminderPopupState();
}

class _CustomReminderPopupState extends State<CustomReminderPopup> {
  static const double _pickerHeight = 180;

  late FixedExtentScrollController _valueController;
  late FixedExtentScrollController _unitController;

  late int _maxValue;
  late List<String> _units;
  late int _value;
  late int _unitIndex;
  late TimeOfDay _notificationTime;

  @override
  void initState() {
    super.initState();
    _maxValue = widget.isAllDay ? 365 : 360;
    _units = widget.isAllDay ? TaskReminder.allDayUnits : TaskReminder.timedUnits;

    _value = widget.isAllDay ? 2 : 30;
    _unitIndex = 0;
    _notificationTime = const TimeOfDay(hour: 20, minute: 45);

    _applyInitialReminder();

    _valueController = FixedExtentScrollController(initialItem: _value - 1);
    _unitController = FixedExtentScrollController(initialItem: _unitIndex);
  }

  void _applyInitialReminder() {
    if (widget.initialReminder == null) return;

    if (widget.isAllDay) {
      final parsed = TaskReminder.parseAllDayCustom(widget.initialReminder!);
      if (parsed == null) return;
      _value = parsed.value.clamp(1, _maxValue);
      _unitIndex = _units.indexOf(parsed.unit).clamp(0, _units.length - 1);
      _notificationTime = parsed.time;
      return;
    }

    final parsed = TaskReminder.parseTimedCustom(widget.initialReminder!);
    if (parsed == null) return;
    _value = parsed.value.clamp(1, _maxValue);
    _unitIndex = _units.indexOf(parsed.unit).clamp(0, _units.length - 1);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  String get _previewLabel {
    if (widget.isAllDay) {
      return TaskReminder.formatAllDayCustom(
        _value,
        _units[_unitIndex],
        _notificationTime,
      );
    }
    return TaskReminder.formatTimedCustom(_value, _units[_unitIndex]);
  }

  void _save() {
    Navigator.pop(context, _previewLabel);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

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
                      const Text(
                        'Custom reminder',
                        style: TextStyle(
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
                      _previewLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: _pickerHeight,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CupertinoPicker(
                          scrollController: _valueController,
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setState(() => _value = index + 1);
                          },
                          children: List.generate(
                            _maxValue,
                            (index) => Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: CupertinoPicker(
                          scrollController: _unitController,
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setState(() => _unitIndex = index);
                          },
                          children: _units
                              .map(
                                (unit) => Center(
                                  child: Text(
                                    TaskReminder.unitPickerLabel(unit, _value),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isAllDay) ...[
                  const Divider(color: AppColors.border, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Notification time',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  AppCupertinoTimePicker(
                    time: _notificationTime,
                    onTimeChanged: (time) {
                      setState(() => _notificationTime = time);
                    },
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
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
