import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/drawer_provider.dart';
import '../../widgets/home/greeting_section.dart';
import '../../widgets/home/overview_section.dart';
import '../../widgets/home/streak_overview_section.dart';
import '../../widgets/home/active_focus_section.dart';
import '../../widgets/home/up_next_tasks_section.dart';
import '../../widgets/home/smart_lists_section.dart';
import '../../widgets/home/projects_section.dart';
import '../../widgets/home/quick_actions_section.dart';

import '../../widgets/background_pattern.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = MediaQuery.of(context).size.width >= 768;
        final bool showTwoColumns = constraints.maxWidth >= 600;

        Widget mainContent = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GreetingSection(),
                        const SizedBox(height: 32),
                        const OverviewSection(),
                        const SizedBox(height: 32),
                        const StreakOverviewSection(),
                        const SizedBox(height: 32),
                        if (showTwoColumns) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    ActiveFocusSection(),
                                    SizedBox(height: 32),
                                    UpNextTasksSection(),
                                    SizedBox(height: 32),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    SmartListsSection(),
                                    SizedBox(height: 32),
                                    QuickActionsSection(),
                                    SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const ProjectsSection(),
                          const SizedBox(height: 32),
                        ] else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              ActiveFocusSection(),
                              SizedBox(height: 32),
                              UpNextTasksSection(),
                              SizedBox(height: 32),
                              SmartListsSection(),
                              SizedBox(height: 32),
                              ProjectsSection(),
                              SizedBox(height: 32),
                              QuickActionsSection(),
                              SizedBox(height: 32),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isDesktop ? null : const AppDrawer(isPermanent: false),
          appBar: _buildAppBar(context, showMenuIcon: !isDesktop),
          body: isDesktop ? mainContent : Builder(
            builder: (context) => GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                  Scaffold.of(context).openDrawer();
                }
              },
              child: mainContent,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool showMenuIcon,
  }) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            if (showMenuIcon) {
              // Mobile: Open overlay drawer
              Scaffold.of(context).openDrawer();
            } else {
              // Desktop: Toggle collapsed state
              context.read<DrawerProvider>().toggleDesktopCollapse();
            }
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
