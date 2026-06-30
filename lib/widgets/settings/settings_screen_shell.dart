import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/activity_mode_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../app_drawer.dart';
import '../background_pattern.dart';
import '../common/app_scaffold.dart';
import '../common/drawer_swipe_body.dart';
import '../common/screen_chrome.dart';

class SettingsScreenShell extends StatelessWidget {
  final String activeRoute;
  final String title;
  final Widget child;
  final bool showBack;
  final bool showPageTitle;
  final List<Widget>? actions;
  final bool independentBodyScroll;

  const SettingsScreenShell({
    super.key,
    required this.activeRoute,
    required this.title,
    required this.child,
    this.showBack = false,
    this.showPageTitle = true,
    this.actions,
    this.independentBodyScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final activityModes = context.watch<ActivityModeProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = ScreenChrome.isDesktopShellLayout(context);
        final bg = AppColors.backgroundOf(context);

        final titleWidget = Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.bold,
              ),
        );

        final content = Stack(
          children: [
            BackgroundPattern(
              key: ValueKey(
                '${settings.themeMode.index}_'
                '${activityModes.activeModeId}_'
                '${Theme.of(context).brightness}',
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: independentBodyScroll
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showPageTitle) ...[
                                titleWidget,
                                const SizedBox(height: 20),
                              ],
                              Expanded(child: child),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showPageTitle) ...[
                                  titleWidget,
                                  const SizedBox(height: 20),
                                ],
                                child,
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );

        return AppScaffold(
          backgroundColor: bg,
          drawer: isDesktop
              ? null
              : AppDrawer(
                  isPermanent: false,
                  activeRoute: activeRoute,
                ),
          appBar: _buildAppBar(context, isDesktop: isDesktop, bg: bg),
          body: isDesktop ? content : DrawerSwipeBody(child: content),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isDesktop,
    required Color bg,
  }) {
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryOf(context)),
      actions: actions,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                if (isDesktop) {
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
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      leadingWidth: showBack ? 96 : 56,
    );
  }
}
