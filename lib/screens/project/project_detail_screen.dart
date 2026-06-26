import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/task/task_list_item.dart';
import '../../widgets/project/project_create_task_popup.dart';
import '../../widgets/common/app_popup_transition.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/staggered_list_entry.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../widgets/common/app_scaffold.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _showCompleted = true;
  Set<String> _knownActiveIds = {};
  Set<String> _knownCompletedIds = {};
  bool _isFirstBuild = true;
  final GlobalKey _createTaskFabKey = GlobalKey();

  void _showCreateTaskPopup(BuildContext context, String projectName) {
    final fabContext = _createTaskFabKey.currentContext;
    showAppPopup(
      context: context,
      anchor: fabContext != null ? popupAnchorFromContext(fabContext) : null,
      child: ProjectCreateTaskPopup(
        projectName: projectName,
      ),
    );
  }

  void _confirmDeleteProject(BuildContext parentContext, Project project) {
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Project',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${project.name}"? All tasks associated with this project will be deleted permanently.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog

                // Delete all tasks associated with this project
                final taskProvider = parentContext.read<TaskProvider>();
                final tasksToDelete = taskProvider.tasks
                    .where((t) => t.project == project.name)
                    .toList();
                for (var t in tasksToDelete) {
                  taskProvider.deleteTask(t.id);
                }

                // Delete project
                parentContext.read<ProjectProvider>().deleteProject(project.id);
                AppNotification.showError(parentContext, 'Project "${project.name}" deleted');

                Navigator.pop(parentContext); // Close detail screen
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final projectProvider = context.watch<ProjectProvider>();
    final project = projectProvider.projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => Project(
        id: '',
        name: 'Not Found',
        description: '',
        colorValue: Colors.grey.toARGB32(),
      ),
    );

    if (project.id.isEmpty) {
      return AppScaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Project not found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    final taskProvider = context.watch<TaskProvider>();
    final projectTasks = taskProvider.tasks
        .where((t) => t.project == project.name)
        .toList();

    final activeTasks = projectTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = projectTasks.where((t) => t.isCompleted).toList();

    // Xác định task nào vừa mới xuất hiện trong section
    final currentActiveIds = activeTasks.map((t) => t.id).toSet();
    final currentCompletedIds = completedTasks.map((t) => t.id).toSet();
    
    final Set<String> newActiveIds;
    final Set<String> newCompletedIds;
    if (_isFirstBuild) {
      newActiveIds = {};
      newCompletedIds = {};
      _isFirstBuild = false;
    } else {
      newActiveIds = currentActiveIds.difference(_knownActiveIds);
      newCompletedIds = currentCompletedIds.difference(_knownCompletedIds);
    }
    _knownActiveIds = currentActiveIds;
    _knownCompletedIds = currentCompletedIds;

    final progress = taskProvider.getProjectProgress(project.name);
    final int doneCount = completedTasks.length;
    final int totalCount = projectTasks.length;
    final Color projectColor = Color(project.colorValue);

    Widget headerCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: projectColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(project.icon, color: projectColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: projectColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        project.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: projectColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              project.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );

    Widget progressCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Project Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Text(
                  '${(progress.isNaN ? 0 : progress * 100).round()}% Completed',
                  key: ValueKey<int>((progress.isNaN ? 0 : progress * 100).round()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: projectColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final fillWidth = barWidth * (progress.isNaN ? 0.0 : progress);
              return Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: fillWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      color: projectColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Tasks completed',
                '$doneCount/$totalCount',
                Icons.check_circle_outline,
                projectColor,
              ),
              _buildStatItem(
                'Active tasks',
                '${activeTasks.length}',
                Icons.hourglass_empty,
                AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );

    Widget tasksSectionContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          alignment: Alignment.centerLeft,
          child: Text(
            'Tasks (${activeTasks.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (activeTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Color.alphaBlend(projectColor.withValues(alpha: 0.08), AppColors.surface),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: projectColor.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 40,
                  color: projectColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No active tasks',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: activeTasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              final isNew = newActiveIds.contains(task.id);
              final item = TaskListItem(
                key: ValueKey(task.id),
                task: task,
                hideActions: true,
              );
              return StaggeredListEntry(
                key: ValueKey('task_wrapper_${task.id}'),
                index: index,
                isNewAddition: isNew,
                child: item,
              );
            }).toList(),
          ),
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => _showCompleted = !_showCompleted),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed Tasks (${completedTasks.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(
                  _showCompleted
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_showCompleted)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: completedTasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                final isNew = newCompletedIds.contains(task.id);
                final item = TaskListItem(
                  key: ValueKey(task.id),
                  task: task,
                  hideActions: true,
                );
                return StaggeredListEntry(
                  key: ValueKey('task_wrapper_completed_${task.id}'),
                  index: index,
                  isNewAddition: isNew,
                  child: item,
                );
              }).toList(),
            ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 768;

        Widget mainContent;
        if (useTwoColumns) {
          mainContent = Stack(
            children: [
              const BackgroundPattern(),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Details',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 40,
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Overview',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        headerCard,
                                        const SizedBox(height: 16),
                                        progressCard,
                                        const SizedBox(height: 80),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 3,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        tasksSectionContent,
                                        const SizedBox(height: 80),
                                      ],
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
              ),
            ],
          );
        } else {
          mainContent = Stack(
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
                          Text(
                            'Project Details',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 24),
                          headerCard,
                          const SizedBox(height: 16),
                          progressCard,
                          const SizedBox(height: 24),
                          tasksSectionContent,
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return AppScaffold(
          backgroundColor: AppColors.background,
          drawer: isDesktop
              ? null
              : const AppDrawer(isPermanent: false, activeRoute: '/projects'),
          appBar: _buildAppBar(context, project, isDesktop: isDesktop),
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
          floatingActionButton: FloatingActionButton(
            key: _createTaskFabKey,
            backgroundColor: projectColor,
            foregroundColor: Colors.white,
            onPressed: () => _showCreateTaskPopup(context, project.name),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Project project, {
    required bool isDesktop,
  }) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      leadingWidth: 96,
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
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit Project',
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/edit-project',
              arguments: {'projectId': project.id},
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete Project',
          onPressed: () => _confirmDeleteProject(context, project),
        ),
        const NotificationBellButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
