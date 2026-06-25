import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/drawer_provider.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/goals/edit_goals_sheet.dart';
import '../../widgets/statistics/statistics_widgets.dart';

enum _StreakView { week, month }

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _openEditGoalsSheet(BuildContext context, GoalsProvider goalsProvider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGoalsSheet(
        initialTaskGoal: goalsProvider.taskGoal,
        initialFocusGoal: goalsProvider.focusGoal,
        onSave: (taskGoal, focusGoal) {
          goalsProvider.setGoals(taskGoal: taskGoal, focusGoal: focusGoal);
          AppNotification.showSuccess(context, 'Daily goals updated.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final goalsProvider = context.watch<GoalsProvider>();
        final taskGoal = goalsProvider.taskDailyGoal;
        final focusGoal = goalsProvider.focusDailyGoal;

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
                          'Streak & Goals',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        if (constraints.maxWidth >= 768)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _StreakHeroCard(
                                      goalsProvider: goalsProvider,
                                      onEditGoals: () => _openEditGoalsSheet(
                                        context,
                                        goalsProvider,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _TodayGoalsSection(
                                      taskGoal: taskGoal,
                                      focusGoal: focusGoal,
                                    ),
                                    const SizedBox(height: 16),
                                    _AchievementsEntryCard(
                                      unlocked: goalsProvider
                                          .unlockedAchievementsCount,
                                      total:
                                          goalsProvider.totalAchievementsCount,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/achievements',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [const _StreakCalendarWidget()],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _StreakHeroCard(
                            goalsProvider: goalsProvider,
                            onEditGoals: () =>
                                _openEditGoalsSheet(context, goalsProvider),
                          ),
                          const SizedBox(height: 16),
                          _TodayGoalsSection(
                            taskGoal: taskGoal,
                            focusGoal: focusGoal,
                          ),
                          const SizedBox(height: 16),
                          _AchievementsEntryCard(
                            unlocked: goalsProvider.unlockedAchievementsCount,
                            total: goalsProvider.totalAchievementsCount,
                            onTap: () =>
                                Navigator.pushNamed(context, '/achievements'),
                          ),
                          const SizedBox(height: 16),
                          const _StreakCalendarWidget(),
                        ],
                        const SizedBox(height: 40),
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
              : const AppDrawer(isPermanent: false, activeRoute: '/goals'),
          appBar: _buildAppBar(context, showMenuIcon: !isDesktop),
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
    required bool showMenuIcon,
  }) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      leading: Builder(
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
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () =>
              AppNotification.showInfo(context, 'Notifications coming soon!'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _StreakCalendarWidget extends StatefulWidget {
  const _StreakCalendarWidget();

  @override
  State<_StreakCalendarWidget> createState() => _StreakCalendarWidgetState();
}

class _StreakCalendarWidgetState extends State<_StreakCalendarWidget> {
  static const int _initialPage = 10000;

  _StreakView _activeView = _StreakView.week;
  bool _isInit = true;
  int _slideDirection = 1;
  int _lastWeekPage = _initialPage;
  int _lastMonthPage = _initialPage;
  late final DateTime _baseDate;
  late final PageController _weekPageController;
  late final PageController _monthPageController;
  late DateTime _weekAnchor;
  late DateTime _monthAnchor;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);
    _weekAnchor = _baseDate;
    _monthAnchor = DateTime(now.year, now.month);
    _weekPageController = PageController(initialPage: _initialPage);
    _monthPageController = PageController(initialPage: _initialPage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final isDesktop = MediaQuery.of(context).size.width >= 768;
      _activeView = isDesktop ? _StreakView.month : _StreakView.week;
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _monthPageController.dispose();
    super.dispose();
  }

  void _goToPreviousPeriod() {
    _slideDirection = -1;
    if (_activeView == _StreakView.week) {
      _weekPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _monthPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextPeriod() {
    _slideDirection = 1;
    if (_activeView == _StreakView.week) {
      _weekPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _monthPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleWeekPageChanged(int index) {
    final offset = index - _initialPage;
    setState(() {
      _slideDirection = index >= _lastWeekPage ? 1 : -1;
      _lastWeekPage = index;
      _weekAnchor = _baseDate.add(Duration(days: offset * 7));
    });
  }

  void _handleMonthPageChanged(int index) {
    final offset = index - _initialPage;
    setState(() {
      _slideDirection = index >= _lastMonthPage ? 1 : -1;
      _lastMonthPage = index;
      _monthAnchor = DateTime(_baseDate.year, _baseDate.month + offset);
    });
  }

  void _setActiveView(_StreakView view) {
    if (_activeView == view) return;

    setState(() {
      _slideDirection = view == _StreakView.week ? -1 : 1;
      _activeView = view;
    });
  }

  String _periodLabel() {
    if (_activeView == _StreakView.week) {
      final monday = _weekAnchor.subtract(
        Duration(days: _weekAnchor.weekday - 1),
      );
      final sunday = monday.add(const Duration(days: 6));
      return '${_shortMonth(monday.month)} ${monday.day} - ${_shortMonth(sunday.month)} ${sunday.day}';
    }

    return '${_monthName(_monthAnchor.month)} ${_monthAnchor.year}';
  }

  String _shortMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final goalsProvider = context.watch<GoalsProvider>();
    return _StreakCalendarSection(
      activeView: _activeView,
      goalsProvider: goalsProvider,
      weekAnchor: _weekAnchor,
      monthAnchor: _monthAnchor,
      weekPageController: _weekPageController,
      monthPageController: _monthPageController,
      initialPage: _initialPage,
      baseDate: _baseDate,
      periodLabel: _periodLabel(),
      slideDirection: _slideDirection,
      onWeekPageChanged: _handleWeekPageChanged,
      onMonthPageChanged: _handleMonthPageChanged,
      onPreviousPeriod: _goToPreviousPeriod,
      onNextPeriod: _goToNextPeriod,
      onChanged: _setActiveView,
    );
  }
}

class _StreakHeroCard extends StatelessWidget {
  final GoalsProvider goalsProvider;
  final VoidCallback onEditGoals;

  const _StreakHeroCard({
    required this.goalsProvider,
    required this.onEditGoals,
  });

  @override
  Widget build(BuildContext context) {
    final current = goalsProvider.currentStreak;
    final best = goalsProvider.bestStreak;
    final nextAchievement = goalsProvider.nextStreakAchievement;
    final nextAchievementValue = nextAchievement == null
        ? 'Done'
        : '${nextAchievement.target} days';

    return StatPanel(
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.accentPeach.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentPeach.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.accentPeach,
              size: 42,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            current == 0 ? 'Light your first flame' : 'You are on a roll!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            current == 0
                ? 'Complete both daily goals today to begin your streak.'
                : '$current-day streak. Keep both goals completed today.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Current streak',
                  value: '$current days',
                  color: AppColors.primaryDark,
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Best streak',
                  value: '$best days',
                  color: AppColors.accentPeach,
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Next achievements',
                  value: nextAchievementValue,
                  color: AppColors.accentPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditGoals,
              icon: const Icon(Icons.tune, color: AppColors.primaryDark),
              label: const Text(
                'Edit daily goals',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryDark),
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

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TodayGoalsSection extends StatelessWidget {
  final DailyGoalData taskGoal;
  final DailyGoalData focusGoal;

  const _TodayGoalsSection({required this.taskGoal, required this.focusGoal});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final cards = [
          DailyGoalCard(
            titleText: 'Task Goal',
            valueText: '${taskGoal.current}/${taskGoal.goal} tasks',
            captionText: taskGoal.isCompleted
                ? 'Task goal met.'
                : '${taskGoal.remaining} tasks remaining today',
            progress: taskGoal.progress,
            accent: AppColors.accentYellow,
            icon: Icons.task_alt,
          ),
          DailyGoalCard(
            titleText: 'Focus Goal',
            valueText: '${focusGoal.current}/${focusGoal.goal} min',
            captionText: focusGoal.isCompleted
                ? 'Focus goal met.'
                : '${focusGoal.remaining} min remaining today',
            progress: focusGoal.progress,
            accent: AppColors.primaryDark,
            icon: Icons.timer_outlined,
          ),
        ];

        if (!wide) {
          return Column(
            children: [cards[0], const SizedBox(height: 12), cards[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }
}

class _AchievementsEntryCard extends StatelessWidget {
  final int unlocked;
  final int total;
  final VoidCallback onTap;

  const _AchievementsEntryCard({
    required this.unlocked,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (unlocked / total).clamp(0, 1).toDouble();
    final percent = (ratio * 100).round();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: StatPanel(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.accentYellow,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$unlocked/$total unlocked • $percent% completed',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCalendarSection extends StatelessWidget {
  final _StreakView activeView;
  final GoalsProvider goalsProvider;
  final DateTime weekAnchor;
  final DateTime monthAnchor;
  final PageController weekPageController;
  final PageController monthPageController;
  final int initialPage;
  final DateTime baseDate;
  final String periodLabel;
  final int slideDirection;
  final ValueChanged<int> onWeekPageChanged;
  final ValueChanged<int> onMonthPageChanged;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final ValueChanged<_StreakView> onChanged;

  const _StreakCalendarSection({
    required this.activeView,
    required this.goalsProvider,
    required this.weekAnchor,
    required this.monthAnchor,
    required this.weekPageController,
    required this.monthPageController,
    required this.initialPage,
    required this.baseDate,
    required this.periodLabel,
    required this.slideDirection,
    required this.onWeekPageChanged,
    required this.onMonthPageChanged,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ViewSwitcher(activeView: activeView, onChanged: onChanged),
        const SizedBox(height: 12),
        _PeriodNavigator(
          label: periodLabel,
          onPrevious: onPreviousPeriod,
          onNext: onNextPeriod,
        ),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren.map(
                    (child) =>
                        Positioned(top: 0, left: 0, right: 0, child: child),
                  ),
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final isIncoming =
                  (activeView == _StreakView.week &&
                      child.key == const ValueKey('week-page-view')) ||
                  (activeView == _StreakView.month &&
                      child.key == const ValueKey('month-page-view'));

              final inCurve = isIncoming
                  ? CurveTween(curve: Curves.easeOutCubic)
                  : CurveTween(curve: Curves.easeInCubic);

              final slideAnimation = animation.drive(
                Tween<Offset>(
                  begin: Offset(
                    0.28 * (isIncoming ? slideDirection : -slideDirection),
                    0,
                  ),
                  end: Offset.zero,
                ).chain(inCurve),
              );
              final fadeAnimation = animation.drive(
                Tween<double>(begin: 0.0, end: 1.0).chain(
                  CurveTween(
                    curve: isIncoming
                        ? Curves.easeOutCubic
                        : Curves.easeInCubic,
                  ),
                ),
              );

              return ClipRect(
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: activeView == _StreakView.week
                ? SizedBox(
                    key: const ValueKey('week-page-view'),
                    height: 135,
                    child: PageView.builder(
                      controller: weekPageController,
                      onPageChanged: onWeekPageChanged,
                      itemBuilder: (context, index) {
                        final offset = index - initialPage;
                        final displayWeek = baseDate.add(
                          Duration(days: offset * 7),
                        );
                        return _WeeklyStreakPanel(
                          days: goalsProvider.goalWeekDaysFor(displayWeek),
                        );
                      },
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('month-page-view'),
                    height: 505,
                    child: PageView.builder(
                      controller: monthPageController,
                      onPageChanged: onMonthPageChanged,
                      itemBuilder: (context, index) {
                        final offset = index - initialPage;
                        final displayMonth = DateTime(
                          baseDate.year,
                          baseDate.month + offset,
                        );
                        return _MonthlyStreakPanel(
                          days: goalsProvider.goalMonthDaysFor(displayMonth),
                          displayMonth: displayMonth,
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  final _StreakView activeView;
  final ValueChanged<_StreakView> onChanged;

  const _ViewSwitcher({required this.activeView, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwitchButton(
              label: 'Week',
              selected: activeView == _StreakView.week,
              onTap: () => onChanged(_StreakView.week),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SwitchButton(
              label: 'Month',
              selected: activeView == _StreakView.month,
              onTap: () => onChanged(_StreakView.month),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SwitchButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PeriodNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ],
    );
  }
}

class _WeeklyStreakPanel extends StatelessWidget {
  final List<GoalDayData> days;

  const _WeeklyStreakPanel({required this.days});

  @override
  Widget build(BuildContext context) {
    return StatPanel(
      child: Row(
        children: days
            .map((day) => Expanded(child: _WeekDayTile(day: day)))
            .toList(),
      ),
    );
  }
}

class _WeekDayTile extends StatelessWidget {
  final GoalDayData day;

  const _WeekDayTile({required this.day});

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final label = labels[day.date.weekday - 1];
    final missed = day.isMissed;
    final isFuture = day.date.isAfter(DateTime.now());

    final borderColor = day.isToday
        ? AppColors.primaryDark
        : day.isComplete
        ? AppColors.accentPeach.withValues(alpha: 0.55)
        : missed
        ? AppColors.accentPink.withValues(alpha: 0.45)
        : day.isPartial
        ? AppColors.accentYellow.withValues(alpha: 0.55)
        : AppColors.border;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: day.isComplete
                ? AppColors.accentPeach.withValues(alpha: 0.18)
                : AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: day.isToday ? 1.8 : 1,
            ),
          ),
          child: Center(
            child: Text(
              '${day.date.day}',
              style: TextStyle(
                color: day.isToday
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: day.isToday
                ? AppColors.primaryDark
                : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (day.isComplete)
          const Icon(
            Icons.local_fire_department,
            color: AppColors.accentPeach,
            size: 16,
          )
        else if (missed)
          const Text(
            'x',
            style: TextStyle(
              color: AppColors.accentPink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          )
        else
          const SizedBox(height: 16),
        const SizedBox(height: 4),
        if (!isFuture)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GoalStatusDot(
                color: AppColors.accentYellow,
                active: day.taskGoalMet,
              ),
              const SizedBox(width: 4),
              _GoalStatusDot(
                color: AppColors.primaryDark,
                active: day.focusGoalMet,
              ),
            ],
          )
        else
          const SizedBox(height: 7),
      ],
    );
  }
}

class _GoalStatusDot extends StatelessWidget {
  final Color color;
  final bool active;

  const _GoalStatusDot({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : Colors.transparent,
        border: Border.all(color: active ? color : AppColors.border),
      ),
    );
  }
}

class _MonthlyStreakPanel extends StatelessWidget {
  final List<GoalDayData> days;
  final DateTime displayMonth;

  const _MonthlyStreakPanel({required this.days, required this.displayMonth});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const StatPanel(
        child: Text(
          'No streak data yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final cells = days;

    return StatPanel(
      child: Column(
        children: [
          const Row(
            children: [
              _MonthWeekdayLabel('M'),
              _MonthWeekdayLabel('T'),
              _MonthWeekdayLabel('W'),
              _MonthWeekdayLabel('T'),
              _MonthWeekdayLabel('F'),
              _MonthWeekdayLabel('S'),
              _MonthWeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.builder(
                itemCount: cells.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: isWide ? 8 : 5,
                  mainAxisSpacing: isWide ? 8 : 5,
                  childAspectRatio: (constraints.maxWidth / 7) / 72,
                ),
                itemBuilder: (context, index) {
                  final day = cells[index];
                  return _MonthDayTile(
                    day: day,
                    isCurrentMonth: day.date.month == displayMonth.month,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthWeekdayLabel extends StatelessWidget {
  final String label;

  const _MonthWeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MonthDayTile extends StatelessWidget {
  final GoalDayData day;
  final bool isCurrentMonth;

  const _MonthDayTile({required this.day, this.isCurrentMonth = true});

  @override
  Widget build(BuildContext context) {
    final missed = day.isMissed;
    final isFuture = day.date.isAfter(DateTime.now());

    final borderColor = day.isToday
        ? AppColors.primaryDark
        : day.isComplete
        ? AppColors.accentPeach.withValues(alpha: 0.45)
        : missed
        ? AppColors.accentPink.withValues(alpha: 0.35)
        : day.isPartial
        ? AppColors.accentYellow.withValues(alpha: 0.45)
        : AppColors.border;

    return Opacity(
      opacity: isCurrentMonth ? 1.0 : 0.3,
      child: Container(
        decoration: BoxDecoration(
          color: day.isComplete
              ? AppColors.accentPeach.withValues(alpha: 0.16)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: day.isToday ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.date.day}',
              style: TextStyle(
                color: day.isToday
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (day.isComplete)
              const Icon(
                Icons.local_fire_department,
                color: AppColors.accentPeach,
                size: 16,
              )
            else if (missed)
              Transform.translate(
                offset: const Offset(0, -2),
                child: const Text(
                  'x',
                  style: TextStyle(
                    color: AppColors.accentPink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
            const SizedBox(height: 4),
            if (!isFuture)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoalStatusDot(
                    color: AppColors.accentYellow,
                    active: day.taskGoalMet,
                  ),
                  const SizedBox(width: 4),
                  _GoalStatusDot(
                    color: AppColors.primaryDark,
                    active: day.focusGoalMet,
                  ),
                ],
              )
            else
              const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}
