import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/settings/avatar_picker_sheet.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/settings/settings_widgets.dart';
import '../../widgets/statistics/statistics_widgets.dart';
import '../auth/login_screen.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access your tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPeach,
              foregroundColor: AppColors.textPrimaryOf(context),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return SettingsScreenShell(
      activeRoute: '/settings/account',
      title: 'Account Details',
      showBack: true,
      child: Column(
        children: [
          StatPanel(
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => AvatarPickerSheet.show(context),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        UserAvatar(
                          avatarUrl: user.avatarUrl,
                          initials: user.initials,
                          radius: 44,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cardOf(context),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => AvatarPickerSheet.show(context),
                    child: const Text(
                      'Change avatar',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Account',
            children: [
              SettingsNavTile(
                icon: Icons.person_outline,
                title: 'Username',
                subtitle: user.fullName,
                onTap: () =>
                    Navigator.pushNamed(context, '/settings/edit-profile'),
              ),
              SettingsNavTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: user.email,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Security',
            children: [
              SettingsNavTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () =>
                    Navigator.pushNamed(context, '/settings/change-password'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: AppColors.accentPeach),
              label: const Text(
                'Sign out',
                style: TextStyle(
                  color: AppColors.accentPeach,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(
                  color: AppColors.accentPeach.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
