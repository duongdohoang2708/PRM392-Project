import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/project/create_project_popup.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../utils/keyboard/keyboard_insets.dart';
import '../../widgets/common/app_scaffold.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  static const List<Color> projectColors = CreateProjectPopup.projectColors;
  static const List<IconData> projectIcons = CreateProjectPopup.projectIcons;

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  bool _showAllIcons = false;
  bool _showAllColors = false;

  static const int _collapsedCount = 10;

  Color get _accentColor => CreateProjectScreen.projectColors[_selectedColorIndex];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createProject() {
    if (_nameController.text.trim().isEmpty) {
      AppNotification.showError(context, 'Please enter a project name');
      return;
    }

    final provider = context.read<ProjectProvider>();
    final newProject = Project(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      colorValue: CreateProjectScreen.projectColors[_selectedColorIndex].toARGB32(),
      icon: CreateProjectScreen.projectIcons[_selectedIconIndex],
      status: 'In Progress',
    );

    provider.addProject(newProject);

    AppNotification.showSuccess(context, 'Project "${newProject.name}" created!');

    Navigator.pop(context, newProject.name);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 768;

        final titleWidget = Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 24, top: 8),
          child: Text(
            'Create Project',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
        );

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
                  child: KeyboardAwareSingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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

        return AppScaffold(
          backgroundColor: AppColors.backgroundOf(context),
          drawer: isDesktop
              ? null
              : const AppDrawer(
                  isPermanent: false,
                  activeRoute: '/create-project',
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
      backgroundColor: AppColors.backgroundOf(context),
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryOf(context)),
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
      leadingWidth: 96,
      actions: const [
        NotificationBellButton(),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceFillOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildNameCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'Project Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOf(context),
            ),
            decoration: InputDecoration(
              hintText: 'Enter project name...',
              hintStyle: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.normal,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimaryOf(context),
            ),
            decoration: InputDecoration(
              hintText: 'Describe your project...',
              hintStyle: TextStyle(color: AppColors.textSecondaryOf(context)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
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

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_emotions_outlined, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'Project Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              final accent = AppColors.projectAccentOf(context, _accentColor);
              return GestureDetector(
                onTap: () => setState(() => _selectedIconIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.2)
                        : AppColors.insetSurfaceOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? accent : AppColors.borderOf(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      CreateProjectScreen.projectIcons[index],
                      color: isSelected
                          ? accent
                          : AppColors.textSecondaryOf(context),
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

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'Project Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              final raw = CreateProjectScreen.projectColors[index];
              final color = AppColors.projectAccentOf(context, raw);
              final isDark = AppColors.isDark(context);
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isSelected ? 1.0 : (isDark ? 0.65 : 0.6)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.textPrimaryOf(context) : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.projectGlowOf(context, raw),
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
    return ElevatedButton(
      onPressed: _createProject,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      child: const Text(
        'Create Project',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
