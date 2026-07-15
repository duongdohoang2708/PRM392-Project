import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/drawer_provider.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_opacity.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/statistics/statistics_widgets.dart';
import '../../widgets/common/accent_icon_well.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/screen_chrome.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = ScreenChrome.isDesktopShellLayout(context);
        final goalsProvider = context.watch<GoalsProvider>();

        final achievements = goalsProvider.achievements;
        final unlocked = achievements.where((a) => a.isUnlocked).length;
        final total = achievements.length;

        final groupedAchievements = _groupAchievements(achievements);

        final content = Stack(
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
                          'Achievements',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        _UnlockedSummaryCard(unlocked: unlocked, total: total),
                        const SizedBox(height: 18),
                        _AchievementGroupSection(
                          title: 'Tasks Completed',
                          subtitle:
                              'Unlock by growing your total completed tasks',
                          icon: Icons.task_alt,
                          achievements: groupedAchievements.tasksCompleted,
                        ),
                        const SizedBox(height: 18),
                        _AchievementGroupSection(
                          title: 'Focus Minutes',
                          subtitle: 'Unlock by growing your total focus time',
                          icon: Icons.timer_outlined,
                          achievements: groupedAchievements.focusMinutes,
                        ),
                        const SizedBox(height: 18),
                        _AchievementGroupSection(
                          title: 'Session Milestones',
                          subtitle:
                              'Unlock by completing more Pomodoro sessions',
                          icon: Icons.done_all,
                          achievements: groupedAchievements.sessions,
                        ),
                        const SizedBox(height: 18),
                        _AchievementGroupSection(
                          title: 'Streaks',
                          subtitle:
                              'Unlock by completing both goals on consecutive days',
                          icon: Icons.local_fire_department,
                          achievements: groupedAchievements.streak,
                        ),
                        const SizedBox(height: 40),
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
              : const AppDrawer(isPermanent: false, activeRoute: '/goals'),
          appBar: _buildAppBar(context, isDesktop: isDesktop),
          body: isDesktop
              ? content
              : Builder(
                  builder: (context) => GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 300) {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                    child: content,
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isDesktop,
  }) {
    return AppBar(
      backgroundColor: AppColors.backgroundOf(context),
      elevation: 0,
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: AppColors.textPrimaryOf(context)),
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
            icon: Icon(
              Icons.chevron_left,
              size: 28,
              color: AppColors.textPrimaryOf(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      actions: [
        const NotificationBellButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  _GroupedAchievements _groupAchievements(List<Achievement> achievements) {
    return _GroupedAchievements(
      sessions: achievements
          .where(
            (achievement) =>
                achievement.category == AchievementCategory.sessions,
          )
          .toList(),
      focusMinutes: achievements
          .where(
            (achievement) =>
                achievement.category == AchievementCategory.focusMinutes,
          )
          .toList(),
      streak: achievements
          .where(
            (achievement) => achievement.category == AchievementCategory.streak,
          )
          .toList(),
      tasksCompleted: achievements
          .where(
            (achievement) =>
                achievement.category == AchievementCategory.tasksCompleted,
          )
          .toList(),
    );
  }
}

class _GroupedAchievements {
  final List<Achievement> sessions;
  final List<Achievement> focusMinutes;
  final List<Achievement> streak;
  final List<Achievement> tasksCompleted;

  const _GroupedAchievements({
    required this.sessions,
    required this.focusMinutes,
    required this.streak,
    required this.tasksCompleted,
  });
}

class _UnlockedSummaryCard extends StatelessWidget {
  final int unlocked;
  final int total;

  const _UnlockedSummaryCard({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final progress = total == 0
        ? 0.0
        : (unlocked / total).clamp(0, 1).toDouble();
    final progressPercent = (progress * 100).round();
    final percentBadgeBg = AppColors.primaryLightTintOf(
      context,
      alpha: isDark ? 0.56 : 0.45,
    );
    final percentBadgeText = isDark ? AppColors.primaryOf(context) : AppColors.primaryDarkOf(context);

    return StatPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentIconWell(
                accentColor: AppColors.accentYellow,
                icon: Icons.emoji_events,
                size: 44,
                iconSize: 24,
                borderRadius: 14,
                iconColor: isDark ? const Color(0xFFFFD54F) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$unlocked/$total unlocked',
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$progressPercent% of all achievements completed',
                      style: TextStyle(
                        color: AppOpacity.fixed(
                          AppColors.textPrimaryOf(context),
                          isDark ? 0.82 : 0.72,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: percentBadgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppOpacity.fixed(
                      AppColors.primaryOf(context),
                      isDark ? 0.55 : AppOpacity.borderAccent,
                    ),
                  ),
                ),
                child: Text(
                  '$progressPercent%',
                  style: TextStyle(
                    color: percentBadgeText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppOpacity.fixed(
                AppColors.borderOf(context),
                0.6,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.primaryOf(context) : AppColors.primaryDarkOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementGroupSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Achievement> achievements;

  const _AchievementGroupSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements
        .where((achievement) => achievement.isUnlocked)
        .length;
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryLightTintOf(
                  context,
                  alpha: isDark ? 0.56 : 0.45,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.primaryOf(context) : AppColors.primaryDarkOf(context),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardFillOf(
                        context,
                        accentColor: AppColors.primaryOf(context),
                        lightTintAlpha: 0.22,
                        darkTintAlpha: 0.22,
                      )
                    : AppColors.cardSurfaceFillOf(context),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark
                      ? AppOpacity.fixed(AppColors.primaryOf(context), 0.45)
                      : AppColors.borderOf(context),
                ),
              ),
              child: Text(
                '$unlocked/${achievements.length}',
                style: TextStyle(
                  color: isDark ? AppColors.primaryOf(context) : AppColors.primaryDarkOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 1100
                ? 6
                : width >= 920
                ? 5
                : width >= 700
                ? 4
                : width >= 480
                ? 3
                : 2;

            return GridView.builder(
              itemCount: achievements.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                return _AchievementCard(achievement: achievements[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  IconData get _icon {
    switch (achievement.category) {
      case AchievementCategory.sessions:
        return Icons.done_all;
      case AchievementCategory.focusMinutes:
        return Icons.timer_outlined;
      case AchievementCategory.streak:
        return Icons.local_fire_department;
      case AchievementCategory.tasksCompleted:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final isDark = AppColors.isDark(context);
    final accent = unlocked
        ? (isDark ? AppColors.primaryOf(context) : AppColors.primaryDarkOf(context))
        : AppColors.textSecondaryOf(context);
    final bgColor = unlocked
        ? AppColors.primaryLightTintOf(context, alpha: isDark ? 0.35 : 0.45)
        : AppColors.cardSurfaceFillOf(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppOpacity.fixed(AppColors.primaryOf(context), AppOpacity.borderStrong)
              : AppColors.borderOf(context),
          width: unlocked ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AccentIconWell(
                accentColor: accent,
                icon: _icon,
                size: 35,
                iconSize: 16,
                borderRadius: 10,
                muted: !unlocked,
              ),
              Icon(
                unlocked ? Icons.check_circle : Icons.lock_outline,
                color: unlocked
                    ? (isDark ? AppColors.primaryOf(context) : AppColors.primaryDarkOf(context))
                    : AppColors.textSecondaryOf(context),
                size: 17,
              ),
            ],
          ),
          const Spacer(),
          Text(
            achievement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_displayCurrent()}/${achievement.target}',
            style: TextStyle(
              color: unlocked
                  ? AppColors.textPrimaryOf(context)
                  : AppColors.textSecondaryOf(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: achievement.progress,
              minHeight: 5,
              backgroundColor: AppOpacity.fixed(
                AppColors.borderOf(context),
                0.6,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  int _displayCurrent() {
    return achievement.current > achievement.target
        ? achievement.target
        : achievement.current;
  }
}
