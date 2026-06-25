import 'package:flutter/material.dart';

const Duration kAppHorizontalSlideSwitchDuration = Duration(milliseconds: 300);
const Duration kAppHorizontalSlideSizeDuration = Duration(milliseconds: 320);
const double kAppHorizontalSlideOffsetFactor = 0.28;

typedef AppSwitcherIncomingPredicate = bool Function(Widget child);

/// Slide ngang + fade dùng cho AnimatedSwitcher (tab Statistics, Goals, ...).
Widget appHorizontalSlideFadeTransition({
  required Widget child,
  required Animation<double> animation,
  required bool isIncoming,
  required int direction,
  double offsetFactor = kAppHorizontalSlideOffsetFactor,
}) {
  final inCurve = isIncoming
      ? CurveTween(curve: Curves.easeOutCubic)
      : CurveTween(curve: Curves.easeInCubic);

  final slideAnimation = animation.drive(
    Tween<Offset>(
      begin: Offset(offsetFactor * direction, 0),
      end: Offset.zero,
    ).chain(inCurve),
  );
  final fadeAnimation = animation.drive(
    Tween<double>(begin: 0.0, end: 1.0).chain(
      CurveTween(
        curve: isIncoming ? Curves.easeOutCubic : Curves.easeInCubic,
      ),
    ),
  );

  return ClipRect(
    child: FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    ),
  );
}

AnimatedSwitcherLayoutBuilder appSwitcherTopStackLayout({
  bool pinPreviousChildren = false,
}) {
  if (pinPreviousChildren) {
    return (currentChild, previousChildren) {
      return Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previousChildren.map(
            (child) => Positioned(top: 0, left: 0, right: 0, child: child),
          ),
          ?currentChild,
        ],
      );
    };
  }

  return (currentChild, previousChildren) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ...previousChildren,
        ?currentChild,
      ],
    );
  };
}

/// AnimatedSize + AnimatedSwitcher với slide ngang + fade.
Widget appHorizontalSlideSwitcher({
  required Widget child,
  required AppSwitcherIncomingPredicate isIncomingChild,
  required int slideDirection,
  Duration switchDuration = kAppHorizontalSlideSwitchDuration,
  Duration sizeDuration = kAppHorizontalSlideSizeDuration,
  bool pinPreviousChildren = false,
}) {
  return AnimatedSize(
    duration: sizeDuration,
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: AnimatedSwitcher(
      duration: switchDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: appSwitcherTopStackLayout(
        pinPreviousChildren: pinPreviousChildren,
      ),
      transitionBuilder: (switchChild, animation) {
        final isIncoming = isIncomingChild(switchChild);
        final offsetDirection = isIncoming ? slideDirection : -slideDirection;
        return appHorizontalSlideFadeTransition(
          child: switchChild,
          animation: animation,
          isIncoming: isIncoming,
          direction: offsetDirection,
        );
      },
      child: child,
    ),
  );
}
