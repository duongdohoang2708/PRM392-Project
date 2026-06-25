import 'package:flutter/material.dart';

import 'app_horizontal_slide_transition.dart';

const Duration kAppFadeSwitchDuration = Duration(milliseconds: 350);
const Duration kAppSplashFadeDuration = Duration(milliseconds: 1500);

AnimatedSwitcherTransitionBuilder appFadeSwitcherBuilder = (
  Widget child,
  Animation<double> animation,
) {
  return FadeTransition(opacity: animation, child: child);
};

/// AnimatedSwitcher chỉ fade — dùng khi đổi filter/view mode content.
Widget appFadeSwitcher({
  required Widget child,
  Duration duration = kAppFadeSwitchDuration,
  Curve switchInCurve = Curves.easeOutCubic,
  Curve switchOutCurve = Curves.easeInCubic,
}) {
  return AnimatedSwitcher(
    duration: duration,
    switchInCurve: switchInCurve,
    switchOutCurve: switchOutCurve,
    transitionBuilder: appFadeSwitcherBuilder,
    layoutBuilder: appSwitcherTopStackLayout(),
    child: child,
  );
}

/// Tạo animation fade-in cho splash hoặc màn hình intro.
Animation<double> createFadeInAnimation(
  AnimationController controller, {
  Curve curve = Curves.easeInOut,
}) {
  return CurvedAnimation(parent: controller, curve: curve);
}
