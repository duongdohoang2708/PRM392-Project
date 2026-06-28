import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_colors.dart';
import '../common/app_popup_transition.dart';
import '../common/animations/app_bottom_slide_fade.dart';
import '../common/popup_surface.dart';
import '../custom_snackbar.dart';
import '../../utils/keyboard/keyboard_insets.dart';

class CreateProjectPopup extends StatefulWidget {
  const CreateProjectPopup({super.key});

  static const List<Color> projectColors = [
    Color(0xFF2E7D32),
    Color(0xFF00A676),
    Color(0xFF0097A7),
    Color(0xFF0277BD),
    Color(0xFF3949AB),
    Color(0xFF7B1FA2),
    Color(0xFFC2185B),
    Color(0xFFD32F2F),
    Color(0xFFE64A19),
    Color(0xFFF9A825),
    Color(0xFF6D4C41),
    Color(0xFF455A64),
    Color(0xFF8BC34A),
    Color(0xFF26C6DA),
    Color(0xFF42A5F5),
    Color(0xFF5E35B1),
    Color(0xFFEC407A),
    Color(0xFFFF7043),
    Color(0xFFFFCA28),
    Color(0xFF78909C),
  ];

  static const List<IconData> projectIcons = [
    Icons.folder_outlined,
    Icons.work_outline,
    Icons.school_outlined,
    Icons.home_outlined,
    Icons.favorite_outline,
    Icons.fitness_center,
    Icons.code,
    Icons.brush_outlined,
    Icons.book_outlined,
    Icons.flight_outlined,
    Icons.restaurant_outlined,
    Icons.music_note_outlined,
    Icons.shopping_bag_outlined,
    Icons.people_outline,
    Icons.star_outline,
    Icons.rocket_launch_outlined,
    Icons.lightbulb_outline,
    Icons.camera_alt_outlined,
    Icons.sports_esports_outlined,
    Icons.pets_outlined,
  ];

  @override
  State<CreateProjectPopup> createState() => _CreateProjectPopupState();
}

class _CreateProjectPopupState extends State<CreateProjectPopup> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  bool _showAllIcons = false;
  bool _showAllColors = false;

  String? _localErrorMessage;
  bool _showLocalError = false;
  Timer? _errorTimer;

  static const int _collapsedCount = 10;

  Color get _accentColor => CreateProjectPopup.projectColors[_selectedColorIndex];

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
    _errorTimer?.cancel();
    super.dispose();
  }

  void _showInlineError(String message) {
    _errorTimer?.cancel();
    setState(() {
      _localErrorMessage = message;
      _showLocalError = true;
    });
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLocalError = false;
        });
      }
    });
  }

  void _createProject() {
    if (_nameController.text.trim().isEmpty) {
      _showInlineError('Please enter a project name');
      return;
    }

    final provider = context.read<ProjectProvider>();
    final newProject = Project(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      colorValue: CreateProjectPopup.projectColors[_selectedColorIndex].toARGB32(),
      icon: CreateProjectPopup.projectIcons[_selectedIconIndex],
      status: 'In Progress',
    );

    provider.addProject(newProject);

    AppNotification.showSuccess(context, 'Project "${newProject.name}" created!');

    Navigator.pop(context, newProject.name);
  }

  @override
  Widget build(BuildContext context) {
    return AppPopupShell(
      alignment: Alignment.centerRight,
      child: PopupSurface(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 16,
                        top: 16,
                        bottom: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create Project',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: AppColors.textSecondaryOf(context),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: AppColors.borderOf(context), height: 1),
                    Flexible(
                      child: KeyboardAwareSingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNameCard(),
                            const SizedBox(height: 16),
                            _buildDescriptionCard(),
                            const SizedBox(height: 16),
                            _buildIconPicker(),
                            const SizedBox(height: 16),
                            _buildColorPicker(),
                            const SizedBox(height: 24),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: AppBottomSlideFade(
                    visible: _showLocalError,
                    child: Material(
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFE57373),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _localErrorMessage ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
        ),
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
                  fontSize: 14,
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
                  fontSize: 14,
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

  Widget _buildIconPicker() {
    final visibleCount = !_showAllIcons
        ? _collapsedCount
        : CreateProjectPopup.projectIcons.length;

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
                  fontSize: 14,
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
                      CreateProjectPopup.projectIcons[index],
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
          if (CreateProjectPopup.projectIcons.length > _collapsedCount)
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

  Widget _buildColorPicker() {
    final visibleCount = !_showAllColors
        ? _collapsedCount
        : CreateProjectPopup.projectColors.length;

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
                  fontSize: 14,
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
              final raw = CreateProjectPopup.projectColors[index];
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
          if (CreateProjectPopup.projectColors.length > _collapsedCount)
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
        minimumSize: const Size(double.infinity, 48),
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

Future<String?> showCreateProjectPopup(
  BuildContext context, {
  Offset? anchor,
}) {
  return showAppPopup<String>(
    context: context,
    anchor: anchor,
    child: const CreateProjectPopup(),
  );
}
