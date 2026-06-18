import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/project_model.dart';
import '../../widgets/background_pattern.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = MediaQuery.of(context).size.width >= 768;

        Widget mainContent = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Projects',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        const _SearchBarWithToggle(),
                        const SizedBox(height: 24),
                        _ProjectCollection(screenWidth: MediaQuery.of(context).size.width),
                        const SizedBox(height: 80),
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
          drawer: isDesktop ? null : const AppDrawer(
            isPermanent: false,
            activeRoute: '/projects',
          ),
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create Project coming soon!')),
              );
            },
            child: const Icon(Icons.add),
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
              Scaffold.of(context).openDrawer();
            } else {
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final taskProvider = context.watch<TaskProvider>();
    
    final activeProjects = projectProvider.activeProjectCount;
    final completedTasks = taskProvider.completedCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Projects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$activeProjects active projects',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$completedTasks tasks completed overall',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Simple decorative icon instead of full CSS illustration
          Container(
            width: 64,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6E8),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: const Border(
                left: BorderSide(color: Color(0xFFF4C8D3), width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                )
              ],
            ),
            child: const Center(
              child: Icon(Icons.star_rounded, color: Color(0xFFF4C8D3), size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarWithToggle extends StatelessWidget {
  const _SearchBarWithToggle();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final isGrid = provider.viewMode == 'grid';

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => provider.setSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Search projects...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                key: ValueKey(isGrid),
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            onPressed: () => provider.toggleViewMode(),
            tooltip: isGrid ? 'Switch to List' : 'Switch to Grid',
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _ProjectCollection extends StatelessWidget {
  final double screenWidth;

  const _ProjectCollection({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final projects = provider.filteredProjects;
    final isGrid = provider.viewMode == 'grid';

    if (projects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No projects found',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    Widget content;
    if (isGrid) {
      content = GridView.builder(
        key: const ValueKey('grid'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 155,
        ),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return _ProjectGridCard(project: projects[index]);
        },
      );
    } else {
      content = ListView.separated(
        key: const ValueKey('list'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: projects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _ProjectListItem(project: projects[index]);
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: content,
    );
  }
}

// ─── Grid Card (compact square) ──────────────────────────────────────────────
class _ProjectGridCard extends StatelessWidget {
  final Project project;

  const _ProjectGridCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final taskCount = taskProvider.getProjectTaskCount(project.name);
    final progress = taskProvider.getProjectProgress(project.name);
    final doneCount = (taskCount * progress).round();
    final Color accentColor = Color(project.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0, width: 5,
              child: Container(color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(project.icon, color: accentColor, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$doneCount/$taskCount', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('${(progress.isNaN ? 0 : progress * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.isNaN ? 0.0 : progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List Item (compact horizontal row) ──────────────────────────────────────
class _ProjectListItem extends StatelessWidget {
  final Project project;

  const _ProjectListItem({required this.project});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final taskCount = taskProvider.getProjectTaskCount(project.name);
    final progress = taskProvider.getProjectProgress(project.name);
    final doneCount = (taskCount * progress).round();
    final Color accentColor = Color(project.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0, width: 5,
              child: Container(color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(project.icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  // Name + Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$doneCount/$taskCount tasks',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Circular progress
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress.isNaN ? 0.0 : progress,
                          strokeWidth: 3.5,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                        Text(
                          '${(progress.isNaN ? 0 : progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
