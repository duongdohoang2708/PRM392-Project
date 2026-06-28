import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/reminder/task_reminder.dart';
import 'custom_reminder_popup.dart';
import '../common/app_popup_transition.dart';

class ReminderSelector extends StatelessWidget {
  final String value;
  final bool isAllDay;
  final ValueChanged<String> onChanged;

  const ReminderSelector({
    super.key,
    required this.value,
    required this.isAllDay,
    required this.onChanged,
  });

  Future<void> _handleSelection(BuildContext context, String? selected) async {
    if (selected == null) return;

    if (selected == TaskReminder.custom) {
      final previous = value;
      final result = await showCustomReminderPopup(
        context,
        isAllDay: isAllDay,
        initialReminder: TaskReminder.isCustomValue(value, isAllDay)
            ? value
            : null,
        anchor: popupAnchorFromContext(context),
      );
      if (result != null) {
        onChanged(result);
      } else if (!TaskReminder.isCustomValue(previous, isAllDay)) {
        onChanged(previous);
      }
      return;
    }

    onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final options = TaskReminder.presetsFor(isAllDay);
    final dropdownValue = TaskReminder.dropdownValue(value, isAllDay);

    return DropdownButton<String>(
      value: dropdownValue,
      isExpanded: true,
      alignment: AlignmentDirectional.centerEnd,
      dropdownColor: AppColors.panelFillOf(context),
      underline: const SizedBox(),
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimaryOf(context),
        fontWeight: FontWeight.w500,
      ),
      selectedItemBuilder: (context) {
        return options.map((option) {
          final displayText = option == TaskReminder.custom &&
                  TaskReminder.isCustomValue(value, isAllDay)
              ? value
              : option;
          return Align(
            alignment: Alignment.centerRight,
            child: Text(
              displayText,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.right,
            ),
          );
        }).toList();
      },
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(option),
              ),
            ),
          )
          .toList(),
      onChanged: (selected) => _handleSelection(context, selected),
    );
  }
}
