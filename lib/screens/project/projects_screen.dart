import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/project_model.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/custom_search_bar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../widgets/staggered_list_entry.dart';
import '../../widgets/common/animations/app_fade_transition.dart';
import '../../widgets/common/animations/app_scale_transition.dart';
import '../../widgets/common/animations/app_delete_transition.dart';

void _confirmDeleteProject(BuildContext parentContext, Project project, VoidCallback onConfirmDelete) {
  showDialog(
    context: parentContext,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surfaceOf(parentContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Project',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryOf(parentContext),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${project.name}"? All tasks associated with this project will be deleted permanently.',
          style: TextStyle(color: AppColors.textSecondaryOf(parentContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondaryOf(parentContext)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              onConfirmDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

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
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 16,
                            bottom: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Projects',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppColors.textPrimaryOf(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              const _SearchBarWithToggle(),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          height: 60.0,
                          backgroundColor: AppColors.backgroundOf(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 8.0,
                            ),
                            child: _ProjectFilterChips(),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              _ProjectCollection(screenWidth: MediaQuery.of(context).size.width),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
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
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              Navigator.pushNamed(context, '/create-project');
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


class _SearchBarWithToggle extends StatelessWidget {
  const _SearchBarWithToggle();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final isGrid = provider.viewMode == 'grid';

    return Row(
      children: [
        Expanded(
          child: CustomSearchBar(
            hintText: 'Search projects...',
            onChanged: (value) => provider.setSearchQuery(value),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: appScaleSwitcher(
              child: Icon(
                isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                key: ValueKey(isGrid),
                color: AppColors.textSecondaryOf(context),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No projects found',
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
        ),
      );
    }

    Widget content;
    if (isGrid) {
      content = LayoutBuilder(
        key: ValueKey('grid_${provider.activeFilter}'),
        builder: (context, constraints) {
          const double spacing = 10.0;
          const double itemHeight = 155.0;
          final double maxWidth = constraints.maxWidth;

          // Calculate columns based on maxCrossAxisExtent of 260
          int cols = ((maxWidth + spacing) / (260.0 + spacing)).ceil();
          if (cols < 1) cols = 1;

          // Calculate the exact item width dynamically to match GridView behavior
          final double calculatedItemWidth = (maxWidth - (cols - 1) * spacing) / cols;

          final double rowHeight = itemHeight + spacing;
          final int rows = (projects.length / cols).ceil();
          final double totalHeight = rows > 0 ? (rows * rowHeight - spacing) : 0;

          return SizedBox(
            width: double.infinity,
            height: totalHeight,
            child: Stack(
              children: List.generate(projects.length, (index) {
                final project = projects[index];
                final int row = index ~/ cols;
                final int col = index % cols;
                final double left = col * (calculatedItemWidth + spacing);
                final double top = row * rowHeight;

                return AnimatedPositioned(
                  key: ValueKey('grid_proj_${project.id}'),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  left: left,
                  top: top,
                  width: calculatedItemWidth,
                  height: itemHeight,
                  child: StaggeredListEntry(
                    index: index,
                    child: _ProjectGridCard(project: project),
                  ),
                );
              }),
            ),
          );
        },
      );
    } else {
      content = ListView.separated(
        key: ValueKey('list_${provider.activeFilter}'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: projects.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return StaggeredListEntry(
            index: index,
            child: _ProjectListItem(project: projects[index]),
          );
        },
      );
    }

    return appFadeSwitcher(child: content);
  }
}

// ─── Grid Card (compact square) ──────────────────────────────────────────────
class _ProjectGridCard extends StatefulWidget {
  final Project project;

  const _ProjectGridCard({required this.project});

  @override
  State<_ProjectGridCard> createState() => _ProjectGridCardState();
}

class _ProjectGridCardState extends State<_ProjectGridCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: kAppScaleDeleteDuration,
    );

    final deleteAnimations = AppScaleDeleteAnimations(_animationController);
    _fadeAnimation = deleteAnimations.fade;
    _sizeAnimation = deleteAnimations.scale;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startDeleteAnimation() {
    setState(() {
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      if (mounted) {
        _executeDelete();
      }
    });

    // Fallback
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted && _isAnimating) {
        _executeDelete();
        _animationController.reset();
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void _executeDelete() {
    final taskProvider = context.read<TaskProvider>();
    final tasksToDelete = taskProvider.tasks
        .where((t) => t.project == widget.project.name)
        .toList();
    for (var t in tasksToDelete) {
      taskProvider.deleteTask(t.id);
    }
    context.read<ProjectProvider>().deleteProject(widget.project.id);
    AppNotification.showError(context, 'Project "${widget.project.name}" deleted');
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final taskCount = taskProvider.getProjectTaskCount(widget.project.name);
    final progress = taskProvider.getProjectProgress(widget.project.name);
    final doneCount = (taskCount * progress).round();
    final Color accentColor = Color(widget.project.colorValue);

    final mainContent = GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/project-detail',
          arguments: {'projectId': widget.project.id},
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderOf(context)),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(widget.project.icon, color: accentColor, size: 18),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              widget.project.status,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.project.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryOf(context)),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$doneCount/$taskCount', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryOf(context))),
                          Text('${(progress.isNaN ? 0 : progress * 100).round()}% completed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.borderOf(context),
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
        ),
      ),
    );

    final slidableContent = LayoutBuilder(
      builder: (context, constraints) {
        final double extentRatio = (130 / constraints.maxWidth).clamp(0.1, 0.6);

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Slidable(
            key: Key('slidable_grid_proj_${widget.project.id}'),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: extentRatio,
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/edit-project',
                        arguments: {'projectId': widget.project.id},
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _confirmDeleteProject(context, widget.project, _startDeleteAnimation),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            child: mainContent,
          ),
        );
      },
    );

    return AppScaleDeleteTransition(
      fade: _fadeAnimation,
      scale: _sizeAnimation,
      child: slidableContent,
    );
  }
}

// ─── List Item (compact horizontal row) ──────────────────────────────────────
class _ProjectListItem extends StatefulWidget {
  final Project project;

  const _ProjectListItem({required this.project});

  @override
  State<_ProjectListItem> createState() => _ProjectListItemState();
}

class _ProjectListItemState extends State<_ProjectListItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: kAppScaleDeleteDuration,
    );

    final deleteAnimations = AppScaleDeleteAnimations(_animationController);
    _fadeAnimation = deleteAnimations.fade;
    _sizeAnimation = deleteAnimations.scale;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startDeleteAnimation() {
    setState(() {
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      if (mounted) {
        _executeDelete();
      }
    });

    // Fallback
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted && _isAnimating) {
        _executeDelete();
        _animationController.reset();
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void _executeDelete() {
    final taskProvider = context.read<TaskProvider>();
    final tasksToDelete = taskProvider.tasks
        .where((t) => t.project == widget.project.name)
        .toList();
    for (var t in tasksToDelete) {
      taskProvider.deleteTask(t.id);
    }
    context.read<ProjectProvider>().deleteProject(widget.project.id);
    AppNotification.showError(context, 'Project "${widget.project.name}" deleted');
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final taskCount = taskProvider.getProjectTaskCount(widget.project.name);
    final progress = taskProvider.getProjectProgress(widget.project.name);
    final doneCount = (taskCount * progress).round();
    final Color accentColor = Color(widget.project.colorValue);

    final mainContent = GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/project-detail',
          arguments: {'projectId': widget.project.id},
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderOf(context)),
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
                        child: Icon(widget.project.icon, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      // Name + Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$doneCount/$taskCount tasks',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryOf(context)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    widget.project.status,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ],
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
                              backgroundColor: AppColors.borderOf(context),
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
        ),
      ),
    );

    final slidableContent = LayoutBuilder(
      builder: (context, constraints) {
        final double extentRatio = (130 / constraints.maxWidth).clamp(0.1, 0.5);

        return Slidable(
          key: Key('slidable_list_proj_${widget.project.id}'),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: extentRatio,
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/edit-project',
                      arguments: {'projectId': widget.project.id},
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _confirmDeleteProject(context, widget.project, _startDeleteAnimation),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: mainContent,
        );
      },
    );

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axis: Axis.vertical,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: slidableContent,
      ),
    );
  }
}

// ─── Project Filter Chips ────────────────────────────────────────────────────
class _ProjectFilterChips extends StatelessWidget {
  const _ProjectFilterChips();

  static const List<Map<String, dynamic>> _filters = [
    {
      'label': 'In Progress',
      'activeColor': AppColors.primaryDark,
      'activeTextColor': Colors.white,
    },
    {
      'label': 'Completed',
      'activeColor': AppColors.accentPeach,
      'activeTextColor': Colors.white,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProjectProvider>();
    final activeFilter = provider.activeFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final filter = _filters[index];
          final isSelected = activeFilter == filter['label'];

          Color bgColor = isSelected
              ? filter['activeColor']
              : Colors.transparent;
          Color borderColor = isSelected
              ? Colors.transparent
              : AppColors.borderOf(context);
          Color textColor = isSelected
              ? filter['activeTextColor']
              : AppColors.textSecondaryOf(context);

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                if (activeFilter == filter['label']) {
                  provider.setActiveFilter('All');
                } else {
                  provider.setActiveFilter(filter['label']);
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 0 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: filter['activeColor'].withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter['label'],
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color backgroundColor;

  _StickyHeaderDelegate({
    required this.child,
    required this.height,
    required this.backgroundColor,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
