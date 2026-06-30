import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/drawer_provider.dart';
import '../../theme/app_colors.dart';
import 'notification_bell_button.dart';

/// Shared scaffold background + app bar styling for main-shell screens.
class ScreenChrome {
  ScreenChrome._();

  /// Breakpoint where [MainShell] shows the permanent sidebar.
  static const double desktopBreakpoint = 768;

  /// Uses full screen width — not [LayoutBuilder] constraints, which exclude
  /// the drawer column inside [MainShell] and would duplicate the sidebar.
  static bool isDesktopShellLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static Color scaffoldBackground(BuildContext context) =>
      AppColors.backgroundOf(context);

  static PreferredSizeWidget appBar(
    BuildContext context, {
    bool showMenuIcon = true,
    bool showBack = false,
    List<Widget>? actions,
    VoidCallback? onBack,
  }) {
    final bg = scaffoldBackground(context);
    final iconColor = AppColors.textPrimaryOf(context);

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      iconTheme: IconThemeData(color: iconColor),
      actions: actions,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMenuIcon)
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  if (ScreenChrome.isDesktopShellLayout(context)) {
                    context.read<DrawerProvider>().toggleDesktopCollapse();
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                },
              ),
            ),
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBack ?? () => Navigator.pop(context),
            ),
        ],
      ),
      leadingWidth: showBack && showMenuIcon
          ? 96
          : (showBack || showMenuIcon ? 56 : 0),
    );
  }

  static PreferredSizeWidget homeAppBar(
    BuildContext context, {
    required bool showMenuIcon,
  }) {
    return appBar(
      context,
      showMenuIcon: showMenuIcon,
      actions: const [
        NotificationBellButton(),
        SizedBox(width: 8),
      ],
    );
  }

  static TextStyle pageTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimaryOf(context),
          fontWeight: FontWeight.bold,
        ) ??
        TextStyle(
          color: AppColors.textPrimaryOf(context),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        );
  }

  static TextStyle sectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryOf(context),
    );
  }
}
