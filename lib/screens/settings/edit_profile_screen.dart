import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _nameController =
        TextEditingController(text: context.read<UserProvider>().fullName);
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<UserProvider>().updateProfile(
          fullName: _nameController.text,
        );

    if (!mounted) return;
    AppNotification.showSuccess(context, 'Profile updated.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: 'Edit Profile',
      showBack: true,
      child: StatPanel(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: UserAvatar(
                  avatarUrl: user.avatarUrl,
                  initials: user.initials,
                  radius: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Full name',
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: 'Your name',
                controller: _nameController,
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.primaryDark,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${user.email}',
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
