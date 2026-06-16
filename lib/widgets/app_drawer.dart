import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final bool isPermanent;
  final String activeRoute;

  const AppDrawer({
    super.key,
    this.isPermanent = false,
    this.activeRoute = '/home',
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning,';
    } else if (hour < 18) {
      greeting = 'Good afternoon,';
    } else {
      greeting = 'Good evening,';
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'Dương',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home_rounded,
                  title: 'Home',
                  isActive: activeRoute == '/home',
                  onTap: () {
                    if (!isPermanent) {
                      Navigator.pop(context); // Close drawer
                    }
                    if (activeRoute != '/home') {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    }
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.task_alt,
                  title: 'Tasks',
                  isActive: activeRoute == '/task-list',
                  onTap: () {
                    if (!isPermanent) {
                      Navigator.pop(context);
                    }
                    if (activeRoute != '/task-list') {
                      Navigator.pushNamed(context, '/task-list');
                    }
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_month,
                  title: 'Calendar',
                  isActive: activeRoute == '/calendar',
                  onTap: () => _showComingSoon(context),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.folder_open,
                  title: 'Projects',
                  isActive: activeRoute == '/projects',
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(height: 32, color: AppColors.border),
                _buildMenuItem(
                  context,
                  icon: Icons.timer,
                  title: 'Focus',
                  isActive: activeRoute == '/focus',
                  onTap: () => _showComingSoon(context),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Statistics',
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(height: 32, color: AppColors.border),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => _showComingSoon(context),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final color = isActive ? AppColors.primaryDark : AppColors.textSecondary;
    final bgColor = isActive ? AppColors.primaryLight.withAlpha((255 * 0.3).round()) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primaryDark : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: bgColor,
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    if (!isPermanent) {
      Navigator.pop(context); // close drawer first
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon!'),
        backgroundColor: AppColors.primaryDark,
        duration: Duration(seconds: 1),
      ),
    );
  }
}
