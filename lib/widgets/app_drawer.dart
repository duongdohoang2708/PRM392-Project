import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_mode.dart';
import '../theme/app_colors.dart';
import '../providers/activity_mode_provider.dart';
import '../providers/drawer_provider.dart';
import '../providers/user_provider.dart';
import 'common/user_avatar.dart';

const double _kDrawerExpandedWidth = 280;
const double _kDrawerCollapsedWidth = 88;
const double _kDrawerItemRadius = 12;
const double _kDrawerIconColumnWidth = 56;
const Duration _kDrawerAnimDuration = Duration(milliseconds: 300);

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
    final isDesktopCollapsed =
        isPermanent ? context.watch<DrawerProvider>().isDesktopCollapsed : false;
    final user = context.watch<UserProvider>();
    final activityModes = context.watch<ActivityModeProvider>();
    final activeMode = activityModes.activeDefinition;
    final greeting = _greetingForHour(DateTime.now().hour);
    final targetRailWidth =
        isDesktopCollapsed ? _kDrawerCollapsedWidth : _kDrawerExpandedWidth;

    if (isPermanent) {
      return AnimatedContainer(
        duration: _kDrawerAnimDuration,
        curve: Curves.easeInOut,
        width: targetRailWidth,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          border: Border(
            right: BorderSide(color: AppColors.borderOf(context), width: 1),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _kDrawerExpandedWidth,
                  child: _DrawerShell(
                    activeRoute: activeRoute,
                    onNavigate: onNavigate,
                    isPermanent: isPermanent,
                    visualRailWidth: constraints.maxWidth,
                    user: user,
                    greeting: greeting,
                    activeMode: activeMode,
                    onOpenAccount: () => _openAccountSettings(context),
                    onOpenActivityModes: () => _openActivityModes(context),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Drawer(
      backgroundColor: AppColors.surfaceOf(context),
      child: _DrawerShell(
        activeRoute: activeRoute,
        onNavigate: onNavigate,
        isPermanent: isPermanent,
        visualRailWidth: _kDrawerExpandedWidth,
        user: user,
        greeting: greeting,
        activeMode: activeMode,
        onOpenAccount: () => _openAccountSettings(context),
        onOpenActivityModes: () => _openActivityModes(context),
      ),
    );
  }

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  void _openAccountSettings(BuildContext context) {
    final navigator = Navigator.of(context);
    if (!isPermanent) {
      Navigator.pop(context);
    }
    if (activeRoute != '/settings/account') {
      if (onNavigate != null) {
        onNavigate!('/settings/account');
      } else {
        navigator.pushNamed('/settings/account');
      }
    }
  }

  void _openActivityModes(BuildContext context) {
    final navigator = Navigator.of(context);
    if (!isPermanent) {
      Navigator.pop(context);
    }
    if (onNavigate != null) {
      onNavigate!('/settings/activity-modes');
    } else {
      navigator.pushNamed('/settings/activity-modes');
    }
  }
}

double _labelOpacityForRailWidth(double visualRailWidth) {
  if (visualRailWidth >= _kDrawerExpandedWidth) return 1;
  if (visualRailWidth <= _kDrawerCollapsedWidth) return 0;
  return (visualRailWidth - _kDrawerCollapsedWidth) /
      (_kDrawerExpandedWidth - _kDrawerCollapsedWidth);
}

/// Labels always occupy expanded layout space; only opacity fades during clip.
class _DrawerRailLabels extends StatelessWidget {
  final double opacity;
  final Widget child;

  const _DrawerRailLabels({
    required this.opacity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: opacity,
        child: IgnorePointer(
          ignoring: opacity < 0.01,
          child: child,
        ),
      ),
    );
  }
}

class _DrawerShell extends StatelessWidget {
  final String activeRoute;
  final ValueChanged<String>? onNavigate;
  final bool isPermanent;
  final double visualRailWidth;
  final UserProvider user;
  final String greeting;
  final ActivityModeDefinition activeMode;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenActivityModes;

  const _DrawerShell({
    required this.activeRoute,
    required this.onNavigate,
    required this.isPermanent,
    required this.visualRailWidth,
    required this.user,
    required this.greeting,
    required this.activeMode,
    required this.onOpenAccount,
    required this.onOpenActivityModes,
  });

  @override
  Widget build(BuildContext context) {
    final labelOpacity = _labelOpacityForRailWidth(visualRailWidth);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
          decoration: BoxDecoration(color: AppColors.drawerHeaderOf(context)),
          child: Row(
            children: [
              InkWell(
                onTap: onOpenAccount,
                borderRadius: BorderRadius.circular(24),
                child: UserAvatar(
                  avatarUrl: user.avatarUrl,
                  initials: user.initials,
                  radius: 20,
                ),
              ),
              const SizedBox(width: 16),
              _DrawerRailLabels(
                opacity: labelOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ThemeModeButton(
            activeMode: activeMode,
            labelOpacity: labelOpacity,
            onTap: onOpenActivityModes,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _DrawerMenuList(
            activeRoute: activeRoute,
            onNavigate: onNavigate,
            isPermanent: isPermanent,
            labelOpacity: labelOpacity,
          ),
        ),
      ],
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  final ActivityModeDefinition activeMode;
  final double labelOpacity;
  final VoidCallback onTap;

  const _ThemeModeButton({
    required this.activeMode,
    required this.labelOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kDrawerItemRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryLightTintOf(context, alpha: 0.35),
            borderRadius: BorderRadius.circular(_kDrawerItemRadius),
            border: Border.all(
              color: AppColors.projectBorderOf(
                context,
                AppColors.primaryOf(context),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _kDrawerIconColumnWidth,
                child: Icon(
                  activeMode.icon,
                  size: 22,
                  color: AppColors.primaryDarkOf(context),
                ),
              ),
              _DrawerRailLabels(
                opacity: labelOpacity,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        activeMode.name,
                        style: TextStyle(
                          color: AppColors.primaryDarkOf(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerMenuList extends StatelessWidget {
  final String activeRoute;
  final ValueChanged<String>? onNavigate;
  final bool isPermanent;
  final double labelOpacity;

  const _DrawerMenuList({
    required this.activeRoute,
    required this.onNavigate,
    required this.isPermanent,
    required this.labelOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _DrawerMenuItem(
          icon: Icons.home_rounded,
          title: 'Home',
          isActive: activeRoute == '/home',
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/home', replaceAll: true),
        ),
        _DrawerMenuItem(
          icon: Icons.task_alt,
          title: 'Tasks',
          isActive:
              activeRoute == '/task-list' || activeRoute == '/create-task',
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/task-list'),
        ),
        _DrawerMenuItem(
          icon: Icons.calendar_month,
          title: 'Calendar',
          isActive: activeRoute == '/calendar',
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/calendar'),
        ),
        _DrawerMenuItem(
          icon: Icons.folder_open,
          title: 'Projects',
          isActive: activeRoute == '/projects' ||
              activeRoute == '/project-detail' ||
              activeRoute == '/edit-project',
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/projects'),
        ),
        Divider(height: 32, color: AppColors.borderOf(context)),
        _DrawerMenuItem(
          icon: Icons.timer,
          title: 'Focus',
          isActive: activeRoute == '/focus',
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/focus'),
        ),
        _DrawerMenuItem(
          icon: Icons.bar_chart,
          title: 'Statistics',
          isActive:
              activeRoute == '/statistics' || activeRoute == '/focus-history',
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/statistics'),
        ),
        _DrawerMenuItem(
          icon: Icons.local_fire_department,
          title: 'Streak & Goals',
          isActive:
              activeRoute == '/goals' || activeRoute == '/achievements',
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/goals'),
        ),
        Divider(height: 32, color: AppColors.borderOf(context)),
        _DrawerMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          isActive: activeRoute == '/notifications',
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/notifications'),
        ),
        _DrawerMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          isActive: activeRoute.startsWith('/settings'),
          labelOpacity: labelOpacity,
          onTap: () => _navigate(context, '/settings'),
        ),
      ],
    );
  }

  void _navigate(
    BuildContext context,
    String route, {
    bool replaceAll = false,
  }) {
    if (!isPermanent) {
      Navigator.pop(context);
    }
    if (activeRoute == route) return;

    if (onNavigate != null) {
      onNavigate!(route);
      return;
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!context.mounted) return;
      if (replaceAll) {
        Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
      } else {
        Navigator.pushNamed(context, route);
      }
    });
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final double labelOpacity;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.labelOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.isDark(context)
        ? AppColors.primaryOf(context)
        : AppColors.primaryDarkOf(context);
    final color = isActive ? activeColor : AppColors.textSecondaryOf(context);
    final bgColor = isActive
        ? AppColors.primaryLightTintOf(context)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_kDrawerItemRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(_kDrawerItemRadius),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _kDrawerIconColumnWidth,
                  child: Icon(icon, color: color),
                ),
                _DrawerRailLabels(
                  opacity: labelOpacity,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive
                          ? activeColor
                          : AppColors.textPrimaryOf(context),
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
