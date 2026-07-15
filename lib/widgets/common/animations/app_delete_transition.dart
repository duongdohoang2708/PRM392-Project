import 'package:flutter/material.dart';

const Duration kAppScaleDeleteDuration = Duration(milliseconds: 650);
const Duration kAppCollapseDeleteDuration = Duration(milliseconds: 500);

/// Scale shrink + fade — dùng khi xóa project card/list item.
class AppScaleDeleteAnimations {
  final Animation<double> fade;
  final Animation<double> scale;

  const AppScaleDeleteAnimations._({
    required this.fade,
    required this.scale,
  });

  factory AppScaleDeleteAnimations(AnimationController controller) {
    return AppScaleDeleteAnimations._(
      fade: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
        ),
      ),
      scale: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
        ),
      ),
    );
  }
}

/// Collapse height + fade — dùng khi xóa/dismiss task list item.
class AppCollapseDeleteAnimations {
  final Animation<double> fade;
  final Animation<double> size;

  const AppCollapseDeleteAnimations._({
    required this.fade,
    required this.size,
  });

  factory AppCollapseDeleteAnimations(AnimationController controller) {
    return AppCollapseDeleteAnimations._(
      fade: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
        ),
      ),
      size: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOutCubic,
        ),
      ),
    );
  }
}

class AppScaleDeleteTransition extends StatelessWidget {
  final Animation<double> fade;
  final Animation<double> scale;
  final Widget child;

  const AppScaleDeleteTransition({
    super.key,
    required this.fade,
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scale,
      child: FadeTransition(
        opacity: fade,
        child: child,
      ),
    );
  }
}

class AppCollapseDeleteTransition extends StatelessWidget {
  final Animation<double> fade;
  final Animation<double> size;
  final Widget child;

  const AppCollapseDeleteTransition({
    super.key,
    required this.fade,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: size,
      axis: Axis.vertical,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: fade,
        child: child,
      ),
    );
  }
}