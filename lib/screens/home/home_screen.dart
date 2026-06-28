import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/activity_mode_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../widgets/home/active_focus_section.dart';
import '../../widgets/home/greeting_section.dart';
import '../../widgets/home/home_layout_config.dart';
import '../../widgets/home/overview_section.dart';
import '../../widgets/home/projects_section.dart';
import '../../widgets/home/quick_actions_section.dart';
import '../../widgets/home/smart_lists_section.dart';
import '../../widgets/home/streak_overview_section.dart';
import '../../widgets/home/up_next_tasks_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _sectionSpacing = 32.0;

  @override
  Widget build(BuildContext context) {
    final activityModes = context.watch<ActivityModeProvider>();
    final layout = HomeLayoutConfig.forMode(activityModes.activeModeId);

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
                    child: showTwoColumns
                        ? _buildDesktopLayout(context, layout)
                        : _buildMobileLayout(context, layout),
                  ),
                ),
              ),
            ),
          ],
        );

        return AppScaffold(
          backgroundColor: AppColors.backgroundOf(context),
          drawer: isDesktop ? null : const AppDrawer(isPermanent: false),
          appBar: _buildAppBar(context, showMenuIcon: !isDesktop),
          body: isDesktop
              ? mainContent
              : Builder(
                  builder: (context) => GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 300) {
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

  Widget _buildMobileLayout(BuildContext context, HomeLayoutConfig layout) {
    final children = <Widget>[];
    for (final i in layout.mobileOrder.indexed) {
      final index = i.$1;
      final sectionId = i.$2;
      if (index > 0) children.add(const SizedBox(height: _sectionSpacing));
      children.add(_buildSection(context, layout, sectionId));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildDesktopLayout(BuildContext context, HomeLayoutConfig layout) {
    final children = <Widget>[];

    for (final sectionId in layout.desktopFullWidth) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: _sectionSpacing));
      }
      children.add(_buildSection(context, layout, sectionId));
    }

    final leftSections = layout.desktopLeft
        .map((id) => _buildSection(context, layout, id))
        .toList();
    final rightSections = layout.desktopRight
        .map((id) => _buildSection(context, layout, id))
        .toList();

    if (leftSections.isNotEmpty || rightSections.isNotEmpty) {
      children.add(const SizedBox(height: _sectionSpacing));
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leftSections.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _spacedSections(leftSections),
                ),
              ),
            if (leftSections.isNotEmpty && rightSections.isNotEmpty)
              const SizedBox(width: _sectionSpacing),
            if (rightSections.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _spacedSections(rightSections),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<Widget> _spacedSections(List<Widget> sections) {
    if (sections.isEmpty) return [];
    final result = <Widget>[sections.first];
    for (final section in sections.skip(1)) {
      result.add(const SizedBox(height: _sectionSpacing));
      result.add(section);
    }
    return result;
  }

  Widget _buildSection(
    BuildContext context,
    HomeLayoutConfig layout,
    HomeSectionId id,
  ) {
    return switch (id) {
      HomeSectionId.greeting =>
        GreetingSection(subtitle: layout.greetingSubtitle),
      HomeSectionId.overview => const OverviewSection(),
      HomeSectionId.streak => const StreakOverviewSection(),
      HomeSectionId.activeFocus => const ActiveFocusSection(),
      HomeSectionId.upNext => UpNextTasksSection(
          maxTasks: layout.compactUpNext ? 1 : 4,
        ),
      HomeSectionId.smartLists => const SmartListsSection(),
      HomeSectionId.projects => const ProjectsSection(),
      HomeSectionId.quickActions => const QuickActionsSection(),
    };
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool showMenuIcon,
  }) {
    return AppBar(
      backgroundColor: AppColors.backgroundOf(context),
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryOf(context)),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            if (showMenuIcon) {
              Scaffold.of(context).openDrawer();
            } else {
              context.read<DrawerProvider>().toggleDesktopCollapse();
            }
          },
        ),
      ),
      actions: const [
        NotificationBellButton(),
        SizedBox(width: 8),
      ],
    );
  }
}
