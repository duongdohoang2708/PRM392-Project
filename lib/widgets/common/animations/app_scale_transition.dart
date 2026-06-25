import 'package:flutter/material.dart';

const Duration kAppScaleSwitchDuration = Duration(milliseconds: 200);

AnimatedSwitcherTransitionBuilder appScaleSwitcherBuilder = (
  Widget child,
  Animation<double> animation,
) {
  return ScaleTransition(scale: animation, child: child);
};

/// AnimatedSwitcher scale — dùng cho icon toggle (grid/list, pomodoro phase).
Widget appScaleSwitcher({
  required Widget child,
  Duration duration = kAppScaleSwitchDuration,
  Curve switchInCurve = Curves.linear,
  Curve switchOutCurve = Curves.linear,
}) {
  return AnimatedSwitcher(
    duration: duration,
    switchInCurve: switchInCurve,
    switchOutCurve: switchOutCurve,
    transitionBuilder: appScaleSwitcherBuilder,
    child: child,
  );
}
