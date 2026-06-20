import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/custom_snackbar.dart';
import 'create_project_screen.dart';

class EditProjectScreen extends StatefulWidget {
  final String projectId;

  const EditProjectScreen({super.key, required this.projectId});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  bool _showAllIcons = false;
  bool _showAllColors = false;

  static const int _collapsedCount = 10;

  @override
  void initState() {
    super.initState();
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final project = projectProvider.projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => Project(id: '', name: '', description: '', colorValue: Colors.grey.value),
    );

    _nameController = TextEditingController(text: project.name);
    _descriptionController = TextEditingController(text: project.description);

    _selectedColorIndex = CreateProjectScreen.projectColors
        .indexWhere((c) => c.value == project.colorValue);
    if (_selectedColorIndex == -1) _selectedColorIndex = 0;

    _selectedIconIndex = CreateProjectScreen.projectIcons
        .indexWhere((icon) => icon.codePoint == project.icon.codePoint);
    if (_selectedIconIndex == -1) _selectedIconIndex = 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppNotification.showError(context, 'Please enter a project name');
      return;
    }

    final projectProvider = context.read<ProjectProvider>();
    final originalProject = projectProvider.projects.firstWhere(
      (p) => p.id == widget.projectId,
    );

    // Update tasks project name if project name changed
    final taskProvider = context.read<TaskProvider>();
    if (originalProject.name != name) {
      final tasksToRename = taskProvider.tasks
          .where((t) => t.project == originalProject.name)
          .toList();
      for (var t in tasksToRename) {
        taskProvider.updateTask(t.copyWith(project: name));
      }
    }

    final updatedProject = originalProject.copyWith(
      name: name,
      description: _descriptionController.text.trim(),
      colorValue: CreateProjectScreen.projectColors[_selectedColorIndex].value,
      icon: CreateProjectScreen.projectIcons[_selectedIconIndex],
    );

    projectProvider.updateProject(updatedProject);

    AppNotification.showSuccess(context, 'Project "${updatedProject.name}" updated!');

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 768;

        final titleWidget = Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 24, top: 8),
          child: Text(
            'Edit Project',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        );

        // Left column: Name + Description
        final leftColumnWidgets = [
          _buildNameCard(),
          const SizedBox(height: 16),
          _buildDescriptionCard(),
          if (!useTwoColumns) ...[
            const SizedBox(height: 16),
            _buildIconPicker(isCompact: true),
            const SizedBox(height: 16),
            _buildColorPicker(isCompact: true),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(),
        ];

        // Right column: Icon + Color picker (desktop only)
        final rightColumnWidgets = [
          _buildIconPicker(isCompact: false),
          const SizedBox(height: 16),
          _buildColorPicker(isCompact: false),
        ];

        Widget bodyContent;
        if (useTwoColumns) {
          bodyContent = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: leftColumnWidgets,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rightColumnWidgets,
                ),
              ),
            ],
          );
        } else {
          bodyContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftColumnWidgets,
          );
        }

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
                        titleWidget,
                        bodyContent,
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
          drawer: isDesktop
              ? null
              : const AppDrawer(
                  isPermanent: false,
                  activeRoute: '/projects',
                ),
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool showMenuIcon,
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
                if (showMenuIcon) {
                  Scaffold.of(context).openDrawer();
                } else {
                  context.read<DrawerProvider>().toggleDesktopCollapse();
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
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            AppNotification.showInfo(context, 'Notifications coming soon!');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNameCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text(
                'Project Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter project name...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe your project...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPicker({required bool isCompact}) {
    final visibleCount = isCompact && !_showAllIcons
        ? _collapsedCount
        : CreateProjectScreen.projectIcons.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_emotions_outlined, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text(
                'Project Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 52,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: visibleCount,
            itemBuilder: (context, index) {
              final isSelected = _selectedIconIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedIconIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CreateProjectScreen.projectColors[_selectedColorIndex].withValues(alpha: 0.2)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? CreateProjectScreen.projectColors[_selectedColorIndex]
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      CreateProjectScreen.projectIcons[index],
                      color: isSelected
                          ? CreateProjectScreen.projectColors[_selectedColorIndex]
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          ),
          if (isCompact && CreateProjectScreen.projectIcons.length > _collapsedCount)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllIcons = !_showAllIcons),
                  icon: Icon(
                    _showAllIcons ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  label: Text(
                    _showAllIcons ? 'Show Less' : 'Show More',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorPicker({required bool isCompact}) {
    final visibleCount = isCompact && !_showAllColors
        ? _collapsedCount
        : CreateProjectScreen.projectColors.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette_outlined, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text(
                'Project Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 48,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: visibleCount,
            itemBuilder: (context, index) {
              final isSelected = _selectedColorIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: CreateProjectScreen.projectColors[index].withValues(alpha: isSelected ? 1.0 : 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.textPrimary : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: CreateProjectScreen.projectColors[index].withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, color: Colors.white, size: 20),
                        )
                      : null,
                ),
              );
            },
          ),
          if (isCompact && CreateProjectScreen.projectColors.length > _collapsedCount)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllColors = !_showAllColors),
                  icon: Icon(
                    _showAllColors ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  label: Text(
                    _showAllColors ? 'Show Less' : 'Show More',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _saveChanges,
          icon: const Icon(Icons.check),
          label: const Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
