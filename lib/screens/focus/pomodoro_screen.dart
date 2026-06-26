import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/focus_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/custom_snackbar.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/focus/pomodoro_settings_popup.dart';
import '../../widgets/common/app_popup_transition.dart';
import '../../widgets/common/animations/app_scale_transition.dart';
import '../../widgets/focus/task_selector_sheet.dart';

class PomodoroScreen extends StatefulWidget {
  final String? taskId;
  final int? focusMinutes;
  final int? breakMinutes;
  final int? longBreakMinutes;
  final int? sessions;
  final int? longBreakInterval;
  final bool autoStart;

  const PomodoroScreen({
    super.key,
    this.taskId,
    this.focusMinutes,
    this.breakMinutes,
    this.longBreakMinutes,
    this.sessions,
    this.longBreakInterval,
    this.autoStart = false,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final GlobalKey _settingsFabKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusProvider = context.read<FocusProvider>();

      // If navigating with specific parameters, update the provider
      bool settingsChanged = false;
      int newFocus = focusProvider.focusMinutes;
      int newShort = focusProvider.shortBreakMinutes;
      int newLong = focusProvider.longBreakMinutes;
      int newRounds = focusProvider.rounds;
      int newInterval = focusProvider.longBreakInterval;

      if (widget.focusMinutes != null && widget.focusMinutes != newFocus) {
        newFocus = widget.focusMinutes!;
        settingsChanged = true;
      }
      if (widget.breakMinutes != null && widget.breakMinutes != newShort) {
        newShort = widget.breakMinutes!;
        settingsChanged = true;
      }
      if (widget.longBreakMinutes != null &&
          widget.longBreakMinutes != newLong) {
        newLong = widget.longBreakMinutes!;
        settingsChanged = true;
      }
      if (widget.sessions != null && widget.sessions != newRounds) {
        newRounds = widget.sessions!;
        settingsChanged = true;
      }
      if (widget.longBreakInterval != null &&
          widget.longBreakInterval != newInterval) {
        newInterval = widget.longBreakInterval!;
        settingsChanged = true;
      }

      if (settingsChanged) {
        focusProvider.updateSettings(
          focus: newFocus,
          shortBreak: newShort,
          longBreak: newLong,
          rounds: newRounds,
          interval: newInterval,
        );
      }

      if (widget.taskId != null) {
        final taskProvider = context.read<TaskProvider>();
        try {
          final task = taskProvider.tasks.firstWhere(
            (t) => t.id == widget.taskId,
          );
          focusProvider.setSelectedTask(task);
        } catch (e) {
          // Task not found
        }
      }

      if (widget.autoStart && focusProvider.timerState != TimerState.running) {
        focusProvider.startTimer();
      }
    });
  }

  void _showSettingsPopup() {
    final focusProvider = context.read<FocusProvider>();
    final fabContext = _settingsFabKey.currentContext;
    showAppPopup(
      context: context,
      anchor: fabContext != null ? popupAnchorFromContext(fabContext) : null,
      child: PomodoroSettingsPopup(
        initialFocusMinutes: focusProvider.focusMinutes,
        initialShortBreakMinutes: focusProvider.shortBreakMinutes,
        initialLongBreakMinutes: focusProvider.longBreakMinutes,
        initialRounds: focusProvider.rounds,
        initialLongBreakInterval: focusProvider.longBreakInterval,
        onSave: (focus, shortBreak, longBreak, rounds, interval) {
          focusProvider.updateSettings(
            focus: focus,
            shortBreak: shortBreak,
            longBreak: longBreak,
            rounds: rounds,
            interval: interval,
          );
        },
      ),
    );
  }

  void _openTaskSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return const TaskSelectorSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = MediaQuery.of(context).size.width >= 768;
        final bool useTwoColumns = constraints.maxWidth >= 1024;

        final titleWidget = Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          child: Text(
            'Focus',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

        final timerState = context.select((FocusProvider p) => p.timerState);

        final leftColumnWidgets = [
          if (timerState == TimerState.completed) ...[
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildSummaryControls(),
          ] else ...[
            _buildTimerCard(),
            const SizedBox(height: 24),
            _buildControls(),
          ],
          if (!useTwoColumns) ...[
            const SizedBox(height: 24),
            _buildSelectedTaskCard(),
            const SizedBox(height: 16),
            _buildHistorySection(),
          ],
        ];

        final rightColumnWidgets = [
          if (useTwoColumns) ...[
            _buildSelectedTaskCard(),
            const SizedBox(height: 24),
            _buildHistorySection(),
          ],
        ];

        Widget mainContent = Stack(
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
                        titleWidget,
                        useTwoColumns
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(children: leftColumnWidgets),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: rightColumnWidgets,
                                    ),
                                  ),
                                ],
                              )
                            : Column(children: leftColumnWidgets),
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
              : const AppDrawer(isPermanent: false, activeRoute: '/focus'),
          appBar: _buildAppBar(context, isDesktop: isDesktop),
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
          floatingActionButton: FloatingActionButton(
            key: _settingsFabKey,
            onPressed: _showSettingsPopup,
            child: const Icon(Icons.settings),
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
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () {
            if (isDesktop) {
              context.read<DrawerProvider>().toggleDesktopCollapse();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            AppNotification.showInfo(context, 'Notifications coming soon!');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTimerCard() {
    final focusProvider = context.watch<FocusProvider>();
    final sequence = focusProvider.sequence;

    if (sequence.isEmpty) return const SizedBox();

    final currentPhase = sequence[focusProvider.currentPhaseIndex];
    String label = '';
    Color phaseColor = AppColors.primary;
    int totalSeconds = 1;

    switch (currentPhase) {
      case PhaseType.focus:
        label = 'Focus Session';
        phaseColor = AppColors.primary;
        totalSeconds = focusProvider.focusMinutes * 60;
        break;
      case PhaseType.shortBreak:
        label = 'Short Break';
        phaseColor = AppColors.accentPeach;
        totalSeconds = focusProvider.shortBreakMinutes * 60;
        break;
      case PhaseType.longBreak:
        label = 'Long Break';
        phaseColor = AppColors.accentYellow;
        totalSeconds = focusProvider.longBreakMinutes * 60;
        break;
    }

    final double progress = totalSeconds == 0
        ? 0
        : 1 - (focusProvider.remainingSeconds / totalSeconds);
    final int minutes = focusProvider.remainingSeconds ~/ 60;
    final int seconds = focusProvider.remainingSeconds % 60;
    final String timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      height: 520,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: phaseColor.withAlpha(30),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: phaseColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(260, 260),
                  painter: TimerTrackPainter(
                    color: AppColors.border,
                    thickness: 8,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  tween: Tween<double>(begin: 0.0, end: progress),
                  builder: (context, value, child) {
                    return CustomPaint(
                      size: const Size(260, 260),
                      painter: TimerProgressPainter(
                        progress: value,
                        color: phaseColor,
                        thickness: 8,
                      ),
                    );
                  },
                ),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border.withAlpha(150)),
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withAlpha(10),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: phaseColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Custom Progress Bar
          _buildSequenceProgressBar(),
          const SizedBox(height: 16),
          Text(
            _getSessionProgressText(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final focusProvider = context.read<FocusProvider>();
    final int rounds = focusProvider.rounds;
    final int focusTime = focusProvider.focusMinutes * rounds;
    final int breaks = rounds > 1 ? rounds - 1 : 0;

    return Container(
      width: double.infinity,
      height: 520,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.primaryDark,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'EXCELLENT WORK!',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Session Completed',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'You stayed focused and productive!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          // Sequence bar for summary
          _buildSummarySequenceBar(),
          const SizedBox(height: 32),
          // Stats row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withAlpha(150)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${focusTime}M',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Focus',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withAlpha(150)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$rounds',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Pomodoros',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withAlpha(150)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$breaks',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Breaks',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 64,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<FocusProvider>().resetEntireCycle();
            },
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Start New Session',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withAlpha(100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySequenceBar() {
    final focusProvider = context.read<FocusProvider>();
    final sequence = focusProvider.sequence;

    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(sequence.length, (index) {
          final phase = sequence[index];
          IconData iconData;

          switch (phase) {
            case PhaseType.focus:
              iconData = Icons.check;
              break;
            case PhaseType.shortBreak:
              iconData = Icons.local_cafe;
              break;
            case PhaseType.longBreak:
              iconData = Icons.nightlight_round;
              break;
          }

          return Icon(iconData, size: 18, color: AppColors.primaryDark);
        }),
      ),
    );
  }

  String _getSessionProgressText() {
    final focusProvider = context.read<FocusProvider>();
    final sequence = focusProvider.sequence;
    if (sequence.isEmpty) return '0/0 Sessions Completed';

    int completedFocus = 0;
    for (
      int i = 0;
      i < focusProvider.currentPhaseIndex && i < sequence.length;
      i++
    ) {
      if (sequence[i] == PhaseType.focus) {
        completedFocus++;
      }
    }

    return '$completedFocus/${focusProvider.rounds} Sessions Completed';
  }

  Widget _buildSequenceProgressBar() {
    final focusProvider = context.watch<FocusProvider>();
    final sequence = focusProvider.sequence;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Total slots
        final int total = sequence.length;
        // The current index is active. Completed is anything < _currentPhaseIndex
        double fillPercentage = 0;
        double currentProgress = 0;
        if (total > 0) {
          final currentPhaseSeconds = _getPhaseDurationInSeconds(
            sequence[focusProvider.currentPhaseIndex],
            focusProvider,
          );
          currentProgress = currentPhaseSeconds > 0
              ? (currentPhaseSeconds - focusProvider.remainingSeconds) /
                    currentPhaseSeconds
              : 0;
          fillPercentage =
              (focusProvider.currentPhaseIndex + currentProgress) / total;
        }

        return Container(
          width: width,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withAlpha(100),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Filled portion
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  tween: Tween<double>(begin: 0.0, end: fillPercentage),
                  builder: (context, value, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value.clamp(0.0, 1.0),
                      heightFactor: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(200),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
                // Icons row
                Row(
                  children: List.generate(total, (index) {
                    final phase = sequence[index];
                    bool isActive = index == focusProvider.currentPhaseIndex;
                    bool isCompleted = index < focusProvider.currentPhaseIndex;

                    IconData iconData;
                    Color iconColor = isActive
                        ? AppColors.primaryDark
                        : (isCompleted ? Colors.white : AppColors.primary);

                    switch (phase) {
                      case PhaseType.focus:
                        iconData = isCompleted ? Icons.check : Icons.menu_book;
                        break;
                      case PhaseType.shortBreak:
                        iconData = Icons.local_cafe;
                        break;
                      case PhaseType.longBreak:
                        iconData = Icons.nightlight_round;
                        break;
                    }

                    Widget iconWidget = AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(isActive ? 4 : 0),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: AnimatedScale(
                        scale: isActive ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: appScaleSwitcher(
                          child: Icon(
                            iconData,
                            key: ValueKey<IconData>(iconData),
                            size: 18,
                            color: iconColor,
                          ),
                        ),
                      ),
                    );

                    return Expanded(child: Center(child: iconWidget));
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getPhaseDurationInSeconds(PhaseType phase, FocusProvider provider) {
    switch (phase) {
      case PhaseType.focus:
        return provider.focusMinutes * 60;
      case PhaseType.shortBreak:
        return provider.shortBreakMinutes * 60;
      case PhaseType.longBreak:
        return provider.longBreakMinutes * 60;
    }
  }

  Widget _buildControls() {
    final focusProvider = context.watch<FocusProvider>();
    final bool isRunning = focusProvider.timerState == TimerState.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => context.read<FocusProvider>().resetEntireCycle(),
          ),
        ),
        const SizedBox(width: 24),
        // Play / Pause
        GestureDetector(
          onTap: () {
            if (isRunning) {
              context.read<FocusProvider>().pauseTimer();
            } else {
              context.read<FocusProvider>().startTimer();
            }
          },
          child: Container(
            width: 140,
            height: 64,
            decoration: BoxDecoration(
              color: isRunning
                  ? AppColors.accentYellow
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color:
                      (isRunning ? AppColors.accentYellow : AppColors.primary)
                          .withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              isRunning ? 'Pause' : 'Start',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isRunning
                    ? AppColors.textPrimary
                    : AppColors.primaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Skip
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: const Icon(Icons.skip_next, color: AppColors.textSecondary),
            onPressed: () => context.read<FocusProvider>().skipPhase(),
          ),
        ),
      ],
    );
  }

  void _handleChangeTask(BuildContext context, VoidCallback onProceed) {
    final focusProvider = context.read<FocusProvider>();
    if (focusProvider.timerState == TimerState.running ||
        focusProvider.timerState == TimerState.paused) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Timer is running',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'You currently have an active focus session. Changing or clearing the task will reset the current timer. Do you want to proceed?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                focusProvider.resetEntireCycle();
                onProceed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPeach,
              ),
              child: const Text(
                'Reset & Proceed',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      onProceed();
    }
  }

  Widget _buildSelectedTaskCard() {
    final focusProvider = context.watch<FocusProvider>();
    final selectedTask = focusProvider.selectedTask;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Task',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: selectedTask == null
                    ? const Text(
                        'Choose a task to focus on',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedTask.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.folder_outlined,
                                    size: 14,
                                    color: AppColors.primaryDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedTask.project,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedTask.dueDate != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppDateTimeFormat.slashDateShort(selectedTask.dueDate!),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selectedTask.priority == 'High'
                                        ? Icons.flag
                                        : (selectedTask.priority == 'Medium'
                                              ? Icons.outlined_flag
                                              : Icons.outlined_flag),
                                    size: 14,
                                    color: selectedTask.priority == 'High'
                                        ? AppColors.accentPeach
                                        : (selectedTask.priority == 'Medium'
                                              ? AppColors.accentYellow
                                              : AppColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedTask.priority,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              if (selectedTask != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => _handleChangeTask(context, () {
                    context.read<FocusProvider>().setSelectedTask(null);
                  }),
                  tooltip: 'Clear Task',
                ),
              ],
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () => _handleChangeTask(context, _openTaskSelector),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: const BorderSide(
                      color: AppColors.primaryLight,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(selectedTask == null ? 'Select Task' : 'Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    final focusProvider = context.watch<FocusProvider>();
    final focusHistory = focusProvider.focusHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Focus History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/focus-history');
              },
              child: const Text('View history'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (focusHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No recent focus sessions.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        if (focusHistory.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: focusHistory.length,
              itemBuilder: (context, index) {
                final log = focusHistory[index];
                final timeStr =
                    AppDateTimeFormat.logTimestamp(log.time);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHistoryItem(
                    log.title,
                    timeStr,
                    '${log.durationMinutes}m',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryItem(String title, String time, String duration) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(150)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              duration,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimerTrackPainter extends CustomPainter {
  final Color color;
  final double thickness;

  TimerTrackPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - thickness / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    // Outer dashed ring
    final dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final double dashLength = 2;
    final double dashSpace = 4;
    final double outerRadius = radius + 6;
    double startAngle = 0;
    while (startAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        dashLength / outerRadius,
        false,
        dashPaint,
      );
      startAngle += (dashLength + dashSpace) / outerRadius;
    }

    // Main thick track
    canvas.drawCircle(center, radius, paint);

    // Inner thin ring
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(center, radius - 8, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double thickness;

  TimerProgressPainter({
    required this.progress,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - thickness / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );

    // Draw the dot at the end of the progress
    if (progress > 0 && progress < 1) {
      final dotPaint = Paint()..color = Colors.white;
      final currentAngle = -math.pi / 2 + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * math.cos(currentAngle),
        center.dy + radius * math.sin(currentAngle),
      );

      // Shadow for dot
      canvas.drawCircle(
        dotCenter,
        4,
        Paint()
          ..color = color.withAlpha(100)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(dotCenter, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
