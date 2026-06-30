import 'package:flutter/material.dart';

import '../../models/activity_mode.dart';
import '../../theme/app_colors.dart';
import '../common/animations/app_popup_transition.dart';
import '../common/app_duration_picker.dart';
import '../common/popup_surface.dart';

/// Result from [showTurnOnModeDurationPopup].
class TurnOnModeDurationSelection {
  final bool untilStopped;
  final Duration duration;

  const TurnOnModeDurationSelection.untilStopped()
      : untilStopped = true,
        duration = Duration.zero;

  const TurnOnModeDurationSelection.timed(this.duration) : untilStopped = false;
}

Future<TurnOnModeDurationSelection?> showTurnOnModeDurationPopup(
  BuildContext context, {
  required ActivityModeId modeId,
  required String modeName,
  Color? accentColor,
  Offset? anchor,
  Alignment? shellAlignment,
  Offset? shellCenterAt,
}) {
  final resolvedAccent = accentColor ?? AppColors.primaryDarkOf(context);
  return showAppPopup<TurnOnModeDurationSelection>(
    context: context,
    anchor: anchor,
    child: _TurnOnModeDurationDialog(
      modeName: modeName,
      accentColor: resolvedAccent,
      shellAlignment: shellAlignment,
      shellCenterAt: shellCenterAt,
    ),
  );
}

enum _DurationChoice { untilStopped, timed }

class _TurnOnModeDurationDialog extends StatefulWidget {
  final String modeName;
  final Color accentColor;
  final Alignment? shellAlignment;
  final Offset? shellCenterAt;

  const _TurnOnModeDurationDialog({
    required this.modeName,
    required this.accentColor,
    this.shellAlignment,
    this.shellCenterAt,
  });

  @override
  State<_TurnOnModeDurationDialog> createState() =>
      _TurnOnModeDurationDialogState();
}

class _TurnOnModeDurationDialogState extends State<_TurnOnModeDurationDialog> {
  _DurationChoice _choice = _DurationChoice.untilStopped;
  Duration _duration = const Duration(hours: 1);

  TurnOnModeDurationSelection get _result =>
      _choice == _DurationChoice.untilStopped
          ? const TurnOnModeDurationSelection.untilStopped()
          : TurnOnModeDurationSelection.timed(_duration);

  String get _summaryLabel => _choice == _DurationChoice.untilStopped
      ? 'Until I stop it manually'
      : formatDurationLabel(_duration);

  @override
  Widget build(BuildContext context) {
    final onAccent = ThemeData.estimateBrightnessForColor(widget.accentColor) ==
            Brightness.dark
        ? Colors.white
        : AppColors.textPrimaryOf(context);

    return AppPopupShell(
      alignment: widget.shellAlignment ?? Alignment.centerRight,
      centerAt: widget.shellCenterAt,
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
                  Expanded(
                    child: Text(
                      'Turn on ${widget.modeName} for how long?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
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
                  _summaryLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
                  ),
                ),
              ),
            ),
            _DurationOptionTile(
              selected: _choice == _DurationChoice.untilStopped,
              label: 'Until I stop it manually',
              accentColor: widget.accentColor,
              onTap: () => setState(() => _choice = _DurationChoice.untilStopped),
            ),
            _DurationOptionTile(
              selected: _choice == _DurationChoice.timed,
              label: formatDurationLabel(_duration),
              accentColor: widget.accentColor,
              onTap: () => setState(() => _choice = _DurationChoice.timed),
            ),
            if (_choice == _DurationChoice.timed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCupertinoDurationPicker(
                  duration: _duration,
                  accentColor: widget.accentColor,
                  onDurationChanged: (value) => setState(() => _duration = value),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _result),
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

class _DurationOptionTile extends StatelessWidget {
  final bool selected;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _DurationOptionTile({
    required this.selected,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? accentColor
                      : AppColors.textSecondaryOf(context),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
