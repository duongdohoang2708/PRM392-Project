import 'package:flutter/material.dart';

const Duration kAppTopSlideDuration = Duration(milliseconds: 250);
const Duration kAppTopFadeDuration = Duration(milliseconds: 150);
const Offset kAppTopSlideHiddenOffset = Offset(0, -1.5);

/// Trượt từ trên xuống + fade — dùng cho thông báo đổi Theme Mode.
class AppTopSlideFade extends StatelessWidget {
  final bool visible;
  final Widget child;
  final bool ignorePointerWhenHidden;
  final Duration slideDuration;
  final Duration fadeDuration;
  final Offset hiddenOffset;
  final Curve slideCurve;

  const AppTopSlideFade({
    super.key,
    required this.visible,
    required this.child,
    this.ignorePointerWhenHidden = true,
    this.slideDuration = kAppTopSlideDuration,
    this.fadeDuration = kAppTopFadeDuration,
    this.hiddenOffset = kAppTopSlideHiddenOffset,
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
