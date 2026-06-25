import 'package:flutter/material.dart';

const Duration kAppPageSwipeDuration = Duration(milliseconds: 300);
const Curve kAppPageSwipeCurve = Curves.easeInOut;

/// Scale + fade khi chuyển route — có thể gắn vào [PageTransitionsTheme].
class BouncyPageTransitionsBuilder extends PageTransitionsBuilder {
  const BouncyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final scaleTween = Tween<double>(begin: 0.8, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack));
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut));

    return ScaleTransition(
      scale: animation.drive(scaleTween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}

Future<void> animatePageNext(PageController controller) {
  return controller.nextPage(
    duration: kAppPageSwipeDuration,
    curve: kAppPageSwipeCurve,
  );
}

Future<void> animatePagePrevious(PageController controller) {
  return controller.previousPage(
    duration: kAppPageSwipeDuration,
    curve: kAppPageSwipeCurve,
  );
}
