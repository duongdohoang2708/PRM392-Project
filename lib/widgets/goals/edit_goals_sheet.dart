import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/popup_surface.dart';

class EditGoalsSheet extends StatefulWidget {
  final int initialTaskGoal;
  final int initialFocusGoal;
  final void Function(int taskGoal, int focusGoal) onSave;

  const EditGoalsSheet({
    super.key,
    required this.initialTaskGoal,
    required this.initialFocusGoal,
    required this.onSave,
  });

  @override
  State<EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<EditGoalsSheet> {
  late int _taskGoal;
  late int _focusGoal;

  @override
  void initState() {
    super.initState();
    _taskGoal = widget.initialTaskGoal;
    _focusGoal = widget.initialFocusGoal;
  }

  void _adjustTaskGoal(int delta) {
    final next = (_taskGoal + delta).clamp(1, 20);
    if (next == _taskGoal) return;
    setState(() {
      _taskGoal = next;
    });
  }

  void _adjustFocusGoal(int delta) {
    final next = (_focusGoal + delta).clamp(15, 480);
    if (next == _focusGoal) return;
    setState(() {
      _focusGoal = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: PopupSurface(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        fillColor: AppColors.popupPanelOverlayFillOf(context),
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
                        'Edit Daily Goals',
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
                  'A day counts as streak only when both goals are completed.',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                _GoalStepper(
                  label: 'Task goal',
                  helper: 'Tasks completed per day',
                  value: _taskGoal,
                  unit: 'tasks',
                  onDecrease: () => _adjustTaskGoal(-1),
                  onIncrease: () => _adjustTaskGoal(1),
                ),
                const SizedBox(height: 12),
                _GoalStepper(
                  label: 'Focus goal',
                  helper: 'Focus minutes per day',
                  value: _focusGoal,
                  unit: 'min',
                  onDecrease: () => _adjustFocusGoal(-15),
                  onIncrease: () => _adjustFocusGoal(15),
                ),
                const SizedBox(height: 18),
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
                          widget.onSave(_taskGoal, _focusGoal);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primaryDarkOf(context),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save Goals',
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
}

class _GoalStepper extends StatelessWidget {
  final String label;
  final String helper;
  final int value;
  final String unit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _GoalStepper({
    required this.label,
    required this.helper,
    required this.value,
    required this.unit,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelFillOf(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onDecrease,
                  icon: Icon(
                    Icons.remove,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  splashRadius: 20,
                ),
                Text(
                  '$value $unit',
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: onIncrease,
                  icon: Icon(
                    Icons.add,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
