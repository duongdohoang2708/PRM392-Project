import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/drawer_provider.dart';
import 'custom_snackbar.dart';

class AppDrawer extends StatelessWidget {
  final bool isPermanent;
  final String activeRoute;
  final ValueChanged<String>? onNavigate;

  const AppDrawer({
    super.key,
    this.isPermanent = false,
    this.activeRoute = '/home',
    this.onNavigate,
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

    final isDesktopCollapsed =
        isPermanent ? context.watch<DrawerProvider>().isDesktopCollapsed : false;
    final width = isDesktopCollapsed ? 88.0 : 280.0;

    final drawerContent = Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(
            top: 60,
            bottom: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(color: AppColors.primaryLight),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isDesktopCollapsed ? 0.0 : 1.0,
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
                isCollapsed: isDesktopCollapsed,
                onTap: () {
                  if (!isPermanent) {
                    Navigator.pop(context); // Close drawer
                  }
                  if (activeRoute != '/home') {
                    if (onNavigate != null) {
                      onNavigate!('/home');
                    } else {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (route) => false,
                          );
                        }
                      });
                    }
                  }
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.task_alt,
                title: 'Tasks',
                isActive: activeRoute == '/task-list' || activeRoute == '/create-task',
                isCollapsed: isDesktopCollapsed,
                onTap: () {
                  if (!isPermanent) {
                    Navigator.pop(context);
                  }
                  if (activeRoute != '/task-list') {
                    if (onNavigate != null) {
                      onNavigate!('/task-list');
                    } else {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/task-list');
                        }
                      });
                    }
                  }
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.calendar_month,
                title: 'Calendar',
                isActive: activeRoute == '/calendar',
                isCollapsed: isDesktopCollapsed,
                onTap: () {
                  if (!isPermanent) {
                    Navigator.pop(context);
                  }
                  if (activeRoute != '/calendar') {
                    if (onNavigate != null) {
                      onNavigate!('/calendar');
                    } else {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/calendar');
                        }
                      });
                    }
                  }
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.folder_open,
                title: 'Projects',
                isActive: activeRoute == '/projects' ||
                    activeRoute == '/project-detail' ||
                    activeRoute == '/edit-project',
                isCollapsed: isDesktopCollapsed,
                onTap: () {
                  if (!isPermanent) {
                    Navigator.pop(context);
                  }
                  if (activeRoute != '/projects') {
                    if (onNavigate != null) {
                      onNavigate!('/projects');
                    } else {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/projects');
                        }
                      });
                    }
                  }
                },
              ),
              const Divider(height: 32, color: AppColors.border),
              _buildMenuItem(
                context,
                icon: Icons.timer,
                title: 'Focus',
                isActive: activeRoute == '/focus',
                isCollapsed: isDesktopCollapsed,
                onTap: () {
                  if (!isPermanent) {
                    Navigator.pop(context);
                  }
                  if (activeRoute != '/focus') {
                    if (onNavigate != null) {
                      onNavigate!('/focus');
                    } else {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/focus');
                        }
                      });
                    }
                  }
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.bar_chart,
                title: 'Statistics',
                isActive: activeRoute == '/statistics' || activeRoute == '/focus-history',
                isCollapsed: isDesktopCollapsed,
                onTap: () {
                  if (!isPermanent) {
                    Navigator.pop(context);
                  }
                  if (activeRoute != '/statistics') {
                    if (onNavigate != null) {
                      onNavigate!('/statistics');
                    } else {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            '/statistics',
                          );
                        }
                      });
                    }
                  }
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.local_fire_department,
                title: 'Streak & Goals',
                isActive: activeRoute == '/goals' ||
                    activeRoute == '/achievements',
                isCollapsed: isDesktopCollapsed,
                onTap: () {
                  if (!isPermanent) {
                    Navigator.pop(context);
                  }
                  if (activeRoute != '/goals') {
                    if (onNavigate != null) {
                      onNavigate!('/goals');
                    } else {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/goals');
                        }
                      });
                    }
                  }
                },
              ),
              const Divider(height: 32, color: AppColors.border),
              _buildMenuItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                isActive: activeRoute == '/notifications',
                isCollapsed: isDesktopCollapsed,
                onTap: () {
                  if (!isPermanent) Navigator.pop(context);
                  if (onNavigate != null) {
                    onNavigate!('/notifications');
                  } else {
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          '/notifications',
                        );
                      }
                    });
                  }
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.settings_outlined,
                title: 'Settings',
                isCollapsed: isDesktopCollapsed,
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
      ],
    );

    if (isPermanent) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: 280,
            child: drawerContent,
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      child: drawerContent,
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isActive = false,
    bool isCollapsed = false,
    required VoidCallback onTap,
  }) {
    final color = isActive ? AppColors.primaryDark : AppColors.textSecondary;
    final bgColor = isActive
        ? AppColors.primaryLight.withAlpha((255 * 0.3).round())
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56, // Centers the icon perfectly in 88px - 16*2(padding) = 56px
                  child: Icon(icon, color: color),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isCollapsed ? 0.0 : 1.0,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isActive ? AppColors.primaryDark : AppColors.textPrimary,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    if (!isPermanent) {
      Navigator.pop(context); // close drawer first
    }
    AppNotification.showInfo(context, 'Feature coming soon!');
  }
}

