import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/home/greeting_section.dart';
import '../../widgets/home/overview_section.dart';
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
        final bool isDesktop = constraints.maxWidth >= 768;

        Widget mainContent = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        GreetingSection(),
                        SizedBox(height: 32),
                        OverviewSection(),
                        SizedBox(height: 32),
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
                  ),
                ),
              ),
            ),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                const AppDrawer(isPermanent: true),
                Expanded(
                  child: Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: _buildAppBar(context, showMenuIcon: false),
                    body: mainContent,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: const AppDrawer(isPermanent: false),
          appBar: _buildAppBar(context, showMenuIcon: true),
          body: mainContent,
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
      automaticallyImplyLeading: showMenuIcon,
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
