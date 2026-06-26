import 'package:flutter/material.dart';

/// App-wide [Scaffold] that avoids resizing the entire body when the keyboard
/// opens. Pair scrollable content with [KeyboardAwareSingleChildScrollView] or
/// [KeyboardBottomSpacer] so focused fields stay visible.
class AppScaffold extends Scaffold {
  const AppScaffold({
    super.key,
    super.appBar,
    super.body,
    super.drawer,
    super.endDrawer,
    super.backgroundColor,
    super.floatingActionButton,
    super.floatingActionButtonLocation,
    super.bottomNavigationBar,
    super.extendBody,
    super.extendBodyBehindAppBar,
    super.resizeToAvoidBottomInset = false,
  });
}
