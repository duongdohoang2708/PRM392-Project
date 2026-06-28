import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/drawer_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/calendar_week_config.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_opacity.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/goals/weekly_streak_panel.dart';
import '../../widgets/common/accent_icon_well.dart';
import '../../widgets/common/animations/app_horizontal_slide_transition.dart';
import '../../widgets/common/animations/app_page_transition.dart';
import '../../widgets/statistics/statistics_widgets.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../widgets/common/app_scaffold.dart';

enum _StreakView { week, month }

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _confirmFreezeDay(BuildContext context, GoalsProvider goalsProvider) async {
    final credits = goalsProvider.manualRestCreditsRemaining;
    final total = GoalsProvider.manualRestCreditsPerMonth;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Mark freeze day?',
      content:
          'Mark today as a freeze day? Your streak won\'t break, but today '
          'won\'t increase your streak number.\n\n'
          'This will use 1 of your $credits remaining freeze days '
          'this month ($total per month).',
      confirmLabel: 'Confirm',
      confirmButtonStyle: AppConfirmButtonStyle.accentText,
      confirmForegroundColor: AppIcons.freezeDayColor,
    );
    if (confirmed == true && context.mounted) {
      _handleManualRest(context, goalsProvider);
    }
  }

  void _handleManualRest(BuildContext context, GoalsProvider goalsProvider) {
    switch (goalsProvider.markTodayAsManualRest()) {
      case ManualRestResult.success:
        AppNotification.showSuccess(
          context,
          'Freeze day marked.',
        );
      case ManualRestResult.alreadyManualRest:
        AppNotification.showInfo(
          context,
          'Today is already marked as a freeze day.',
        );
      case ManualRestResult.scheduledRestDay:
        AppNotification.showInfo(
          context,
          'Today is already a scheduled weekly freeze day.',
        );
      case ManualRestResult.noCreditsRemaining:
        AppNotification.showInfo(
          context,
          'No freeze days left this month.',
        );
      case ManualRestResult.streakAlreadyMet:
        AppNotification.showInfo(
          context,
          'Today\'s streak is already secured — no freeze day needed.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final goalsProvider = context.watch<GoalsProvider>();
        context.watch<SettingsProvider>();
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
                                color: AppColors.textPrimaryOf(context),
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
                                    ),
                                    if (goalsProvider.shouldShowFreezeDaySection) ...[
                                      const SizedBox(height: 16),
                                      _FreezeDaySection(
                                        goalsProvider: goalsProvider,
                                        onUseManualRest: goalsProvider
                                                .canUseManualRestCreditToday
                                            ? () => _confirmFreezeDay(
                                                context,
                                                goalsProvider,
                                              )
                                            : null,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    _TodayGoalsSection(
                                      taskGoal: taskGoal,
                                      focusGoal: focusGoal,
                                      isRestDay: goalsProvider.isTodayRestDay,
                                      isManualRestDay:
                                          goalsProvider.isTodayManualRestDay,
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
                          ),
                          const SizedBox(height: 16),
                          const _StreakCalendarWidget(),
                          if (goalsProvider.shouldShowFreezeDaySection) ...[
                            const SizedBox(height: 16),
                            _FreezeDaySection(
                              goalsProvider: goalsProvider,
                              onUseManualRest:
                                  goalsProvider.canUseManualRestCreditToday
                                      ? () => _confirmFreezeDay(
                                          context,
                                          goalsProvider,
                                        )
                                      : null,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _TodayGoalsSection(
                            taskGoal: taskGoal,
                            focusGoal: focusGoal,
                            isRestDay: goalsProvider.isTodayRestDay,
                            isManualRestDay:
                                goalsProvider.isTodayManualRestDay,
                          ),
                          const SizedBox(height: 16),
                          _AchievementsEntryCard(
                            unlocked: goalsProvider.unlockedAchievementsCount,
                            total: goalsProvider.totalAchievementsCount,
                            onTap: () =>
                                Navigator.pushNamed(context, '/achievements'),
                          ),
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

        return AppScaffold(
          backgroundColor: AppColors.backgroundOf(context),
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
      backgroundColor: AppColors.backgroundOf(context),
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryOf(context)),
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
        const NotificationBellButton(),
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
      animatePagePrevious(_weekPageController);
    } else {
      animatePagePrevious(_monthPageController);
    }
  }

  void _goToNextPeriod() {
    _slideDirection = 1;
    if (_activeView == _StreakView.week) {
      animatePageNext(_weekPageController);
    } else {
      animatePageNext(_monthPageController);
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
      final weekStart = CalendarWeekConfig.weekStartFor(_weekAnchor);
      final weekEnd = weekStart.add(const Duration(days: 6));
      return '${_shortMonth(weekStart.month)} ${weekStart.day} - ${_shortMonth(weekEnd.month)} ${weekEnd.day}';
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

  const _StreakHeroCard({
    required this.goalsProvider,
  });

  @override
  Widget build(BuildContext context) {
    final current = goalsProvider.currentStreak;
    final best = goalsProvider.bestStreak;
    final nextAchievement = goalsProvider.nextStreakAchievement;
    final nextAchievementValue = nextAchievement == null
        ? 'Done'
        : '${nextAchievement.target} days';
    final isRestDay = goalsProvider.isTodayRestDay;

    final streakAccent =
        isRestDay ? AppColors.freezeBlue : AppColors.accentPeach;

    return StatPanel(
      child: Column(
        children: [
          AccentIconWell(
            accentColor: streakAccent,
            icon: isRestDay
                ? AppIcons.freezeDay
                : Icons.local_fire_department,
            size: 76,
            iconSize: 42,
            shape: BoxShape.circle,
            borderWidth: 1.5,
          ),
          const SizedBox(height: 14),
          Text(
            goalsProvider.streakHeroTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            goalsProvider.streakHeroSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
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
        ],
      ),
    );
  }
}

class _FreezeDaySection extends StatelessWidget {
  final GoalsProvider goalsProvider;
  final VoidCallback? onUseManualRest;

  const _FreezeDaySection({
    required this.goalsProvider,
    this.onUseManualRest,
  });

  @override
  Widget build(BuildContext context) {
    return StatPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onUseManualRest != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUseManualRest,
                icon: const Icon(
                  AppIcons.freezeDay,
                  color: AppIcons.freezeDayColor,
                ),
                label: const Text(
                  'Mark today as freeze day',
                  style: TextStyle(
                    color: AppIcons.freezeDayColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppIcons.freezeDayColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          if (onUseManualRest != null) const SizedBox(height: 8),
          Text(
            '${goalsProvider.manualRestCreditsRemaining} of ${GoalsProvider.manualRestCreditsPerMonth} freeze days left this month',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your streak won\'t break, but today won\'t increase your '
            'streak number.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.35,
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
          style: TextStyle(
            color: AppColors.textSecondaryOf(context),
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
  final bool isRestDay;
  final bool isManualRestDay;

  const _TodayGoalsSection({
    required this.taskGoal,
    required this.focusGoal,
    required this.isRestDay,
    required this.isManualRestDay,
  });

  String get _taskCaption {
    if (isRestDay) {
      return isManualRestDay
          ? 'Task goal waived — freeze day.'
          : 'Task goal waived — weekly freeze day.';
    }
    if (taskGoal.goal == 0) {
      return 'No tasks planned today.';
    }
    if (taskGoal.isCompleted) {
      return 'All planned tasks completed.';
    }
    return '${taskGoal.remaining} tasks remaining today';
  }

  String get _focusCaption {
    if (isRestDay) {
      return isManualRestDay
          ? 'Focus goal waived — freeze day.'
          : 'Focus goal waived — weekly freeze day.';
    }
    if (focusGoal.isCompleted) {
      return 'Focus goal met.';
    }
    return '${focusGoal.remaining} min remaining today';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final freezeAccent = AppIcons.freezeDayColor;
        final cards = [
          DailyGoalCard(
            titleText: 'Task Goal',
            valueText: taskGoal.goal == 0
                ? 'No tasks today'
                : '${taskGoal.current}/${taskGoal.goal} tasks',
            captionText: _taskCaption,
            progress: taskGoal.progress,
            accent: isRestDay ? freezeAccent : AppColors.accentYellow,
            icon: Icons.task_alt,
          ),
          DailyGoalCard(
            titleText: 'Focus Goal',
            valueText: '${focusGoal.current}/${focusGoal.goal} min',
            captionText: _focusCaption,
            progress: focusGoal.progress,
            accent: isRestDay ? freezeAccent : AppColors.primaryDark,
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
            AccentIconWell(
              accentColor: AppColors.accentYellow,
              icon: Icons.emoji_events_outlined,
              size: 50,
              iconSize: 28,
              borderRadius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$unlocked/$total unlocked • $percent% completed',
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryOf(context),
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
        appHorizontalSlideSwitcher(
          slideDirection: slideDirection,
          pinPreviousChildren: true,
          isIncomingChild: (child) =>
              (activeView == _StreakView.week &&
                  child.key == const ValueKey('week-page-view')) ||
              (activeView == _StreakView.month &&
                  child.key == const ValueKey('month-page-view')),
          child: activeView == _StreakView.week
                ? SizedBox(
                    key: const ValueKey('week-page-view'),
                    height: 118,
                    child: PageView.builder(
                      controller: weekPageController,
                      onPageChanged: onWeekPageChanged,
                      itemBuilder: (context, index) {
                        final offset = index - initialPage;
                        final displayWeek = baseDate.add(
                          Duration(days: offset * 7),
                        );
                        return WeeklyStreakPanel(
                          days: goalsProvider.goalWeekDaysFor(displayWeek),
                          panelPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
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
        color: AppColors.panelFillOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
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
          color: selected
              ? AppColors.segmentSelectedFillOf(context)
              : AppColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primaryDark
                : AppColors.borderOf(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.segmentSelectedLabelOf(context)
                : AppColors.textSecondaryOf(context),
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
          icon: Icon(Icons.chevron_left, color: AppColors.textPrimaryOf(context)),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.cardSurfaceFillOf(context),
            side: BorderSide(color: AppColors.borderOf(context)),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right, color: AppColors.textPrimaryOf(context)),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.cardSurfaceFillOf(context),
            side: BorderSide(color: AppColors.borderOf(context)),
          ),
        ),
      ],
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
      return StatPanel(
        child: Text(
          'No streak data yet.',
          style: TextStyle(color: AppColors.textSecondaryOf(context)),
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
        style: TextStyle(
          color: AppColors.textSecondaryOf(context),
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
    final isRestDay = day.isRestDay;

    final borderColor = day.isToday
        ? AppColors.streakTodayAccentOf(context)
        : missed
        ? AppColors.borderOf(context)
        : day.isComplete
        ? AppColors.streakCompleteBorderOf(context)
        : isRestDay
        ? AppColors.streakFreezeBorderOf(context)
        : day.isPartial
        ? AppOpacity.fixed(AppColors.accentYellow, 0.45)
        : AppColors.borderOf(context);

    return Opacity(
      opacity: isCurrentMonth ? 1.0 : 0.3,
      child: Container(
        decoration: BoxDecoration(
          color: day.isComplete
              ? AppColors.streakCompleteFillOf(context)
              : isRestDay
              ? AppColors.streakFreezeFillOf(context)
              : AppColors.panelFillOf(context),
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
                    ? AppColors.streakTodayAccentOf(context)
                    : AppColors.textSecondaryOf(context),
                fontSize: 11,
                fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (missed)
              Text(
                'x',
                style: TextStyle(
                  color: AppColors.streakMissedMarkOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              )
            else if (day.isComplete)
              Icon(
                Icons.local_fire_department,
                color: AppColors.streakFlameOf(context),
                size: 20,
              )
            else if (isRestDay)
              Icon(
                AppIcons.freezeDay,
                color: AppColors.streakFreezeIconOf(context),
                size: 18,
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
