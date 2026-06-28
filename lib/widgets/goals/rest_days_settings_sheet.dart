import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../common/popup_surface.dart';

class RestDaysSettingsSheet extends StatefulWidget {
  final Set<int> initialRestWeekdays;
  final void Function(Set<int> weekdays) onSave;

  const RestDaysSettingsSheet({
    super.key,
    required this.initialRestWeekdays,
    required this.onSave,
  });

  @override
  State<RestDaysSettingsSheet> createState() => _RestDaysSettingsSheetState();
}

class _RestDaysSettingsSheetState extends State<RestDaysSettingsSheet> {
  static const _weekdayLabels = [
    (1, 'Monday'),
    (2, 'Tuesday'),
    (3, 'Wednesday'),
    (4, 'Thursday'),
    (5, 'Friday'),
    (6, 'Saturday'),
    (7, 'Sunday'),
  ];

  late int? _selectedWeekday;

  @override
  void initState() {
    super.initState();
    if (widget.initialRestWeekdays.isEmpty) {
      _selectedWeekday = null;
    } else {
      final sorted = widget.initialRestWeekdays.toList()..sort();
      _selectedWeekday = sorted.first;
    }
  }

  void _selectWeekday(int? weekday) {
    setState(() => _selectedWeekday = weekday);
  }

  Set<int> _buildSelection() =>
      _selectedWeekday == null ? {} : {_selectedWeekday!};

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: PopupSurface(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Freeze Days',
                        style: TextStyle(
                          color: AppColors.textPrimaryOf(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick one weekly freeze day, or choose None. Goals are waived and the day preserves your streak without adding to the count.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildOption(
                  label: 'None',
                  selected: _selectedWeekday == null,
                  icon: Icons.block_outlined,
                  onTap: () => _selectWeekday(null),
                ),
                ..._weekdayLabels.map((entry) {
                  final weekday = entry.$1;
                  final label = entry.$2;
                  return _buildOption(
                    label: label,
                    selected: _selectedWeekday == weekday,
                    icon: AppIcons.freezeDay,
                    freezeIcon: true,
                    onTap: () => _selectWeekday(weekday),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(color: AppColors.borderOf(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onSave(_buildSelection());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
    bool freezeIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.freezeBlue.withValues(alpha: 0.1)
                : AppColors.insetSurfaceOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.freezeBlue.withValues(alpha: 0.4)
                  : AppColors.borderOf(context),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? (freezeIcon
                        ? AppIcons.freezeDayColor
                        : AppColors.freezeBlue)
                    : AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.freezeBlue
                        : AppColors.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? AppIcons.freezeDayColor
                    : AppColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
