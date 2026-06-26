import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Keeps a stable [TextEditingController] so parent rebuilds do not leak
/// controllers or reopen the keyboard.
class SubtaskTitleField extends StatefulWidget {
  final String title;
  final bool isCompleted;
  final ValueChanged<String> onChanged;

  const SubtaskTitleField({
    super.key,
    required this.title,
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  State<SubtaskTitleField> createState() => _SubtaskTitleFieldState();
}

class _SubtaskTitleFieldState extends State<SubtaskTitleField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(covariant SubtaskTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != oldWidget.title && widget.title != _controller.text) {
      _controller.text = widget.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: TextStyle(
        fontSize: 14,
        color: widget.isCompleted
            ? AppColors.textSecondaryOf(context)
            : AppColors.textPrimaryOf(context),
        decoration:
            widget.isCompleted ? TextDecoration.lineThrough : null,
      ),
      decoration: const InputDecoration(
        hintText: 'Enter subtask...',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      onChanged: widget.onChanged,
    );
  }
}
