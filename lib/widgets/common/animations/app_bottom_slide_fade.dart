import 'package:flutter/material.dart';

const Duration kAppBottomSlideDuration = Duration(milliseconds: 250);
const Duration kAppBottomFadeDuration = Duration(milliseconds: 150);
const Offset kAppBottomSlideHiddenOffset = Offset(0, 1.5);

/// Trượt từ dưới lên + fade — dùng cho AppNotification và banner lỗi inline.
class AppBottomSlideFade extends StatelessWidget {
  final bool visible;
  final Widget child;
  final bool ignorePointerWhenHidden;
  final Duration slideDuration;
  final Duration fadeDuration;
  final Offset hiddenOffset;
  final Curve slideCurve;

  const AppBottomSlideFade({
    super.key,
    required this.visible,
    required this.child,
    this.ignorePointerWhenHidden = true,
    this.slideDuration = kAppBottomSlideDuration,
    this.fadeDuration = kAppBottomFadeDuration,
    this.hiddenOffset = kAppBottomSlideHiddenOffset,
    this.slideCurve = Curves.fastOutSlowIn,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: ignorePointerWhenHidden && !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : hiddenOffset,
        duration: slideDuration,
        curve: slideCurve,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: fadeDuration,
          child: child,
        ),
      ),
    );
  }
}
