import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/reminder/task_reminder.dart';
import 'custom_reminder_popup.dart';
import '../common/app_popup_transition.dart';
import '../common/app_dropdown.dart';

class ReminderSelector extends StatelessWidget {
  final String value;
  final bool isAllDay;
  final ValueChanged<String> onChanged;
  final Color accentColor;

  const ReminderSelector({
    super.key,
    required this.value,
    required this.isAllDay,
    required this.onChanged,
    this.accentColor = AppColors.primaryDark,
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
        accentColor: accentColor,
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

    return AppDropdown<String>(
      value: dropdownValue,
      isExpanded: true,
      alignment: AlignmentDirectional.centerEnd,
      accentColor: accentColor,
      selectedItemBuilder: (context) {
        return options.map((option) {
          final displayText = option == TaskReminder.custom &&
                  TaskReminder.isCustomValue(value, isAllDay)
              ? value
              : option;
          return AppDropdown.menuChild(
            Text(
              displayText,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.right,
              style: TextStyle(color: accentColor),
            ),
          );
        }).toList();
      },
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: AppDropdown.menuChild(Text(option)),
            ),
          )
          .toList(),
      onChanged: (selected) => _handleSelection(context, selected),
    );
  }
}
