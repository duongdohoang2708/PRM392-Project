import 'package:flutter/material.dart';

/// Trailing spacer for [CustomScrollView] / [Column] scroll content.
///
/// Only this widget rebuilds when the keyboard animates, keeping scroll
/// content layout stable and avoiding jank.
class KeyboardBottomSpacer extends StatelessWidget {
  const KeyboardBottomSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.viewInsetsOf(context).bottom;
    if (height <= 0) return const SizedBox.shrink();
    return SizedBox(height: height);
  }
}

/// [SingleChildScrollView] with fixed [padding] and a trailing [KeyboardBottomSpacer].
///
/// Use with [AppScaffold] (`resizeToAvoidBottomInset: false`) on screens that
/// contain text fields or search bars.
class KeyboardAwareSingleChildScrollView extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  const KeyboardAwareSingleChildScrollView({
    super.key,
    required this.padding,
    required this.child,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
    this.controller,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child,
          const KeyboardBottomSpacer(),
        ],
      ),
    );
  }
}
