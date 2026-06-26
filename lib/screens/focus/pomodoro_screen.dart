import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/focus_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../utils/formatters/app_date_time_format.dart';
import '../../widgets/focus/pomodoro_settings_popup.dart';
import '../../widgets/focus/pomodoro_session_progress_card.dart';
import '../../widgets/common/app_popup_transition.dart';
import '../../widgets/focus/pomodoro_timer_carousel.dart';
import '../../widgets/focus/task_selector_sheet.dart';
import '../../widgets/common/section_action_button.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../widgets/common/app_scaffold.dart';
import 'pomodoro_fullscreen_timer_screen.dart';

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

class _PomodoroScreenState extends State<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _settingsFabKey = GlobalKey();
  Ticker? _liveTicker;

  void _syncLiveTicker(FocusProvider focusProvider) {
    final shouldRun = focusProvider.timerState == TimerState.running &&
        focusProvider.expectedEndTime != null;
    if (shouldRun) {
      if (_liveTicker != null && !_liveTicker!.isActive) {
        _liveTicker!.start();
      }
    } else if (_liveTicker != null && _liveTicker!.isActive) {
      _liveTicker!.stop();
    }
  }

  Widget _buildSessionProgressCard({bool allCompleted = false}) {
    final focusProvider = context.watch<FocusProvider>();
    final sequence = focusProvider.sequence;
    if (sequence.isEmpty) return const SizedBox.shrink();

    final phaseIndex = focusProvider.currentPhaseIndex;
    var phaseProgress = 0.0;
    if (!allCompleted && phaseIndex < sequence.length) {
      final phaseSeconds = _getPhaseDurationInSeconds(
        sequence[phaseIndex],
        focusProvider,
      );
      if (phaseSeconds > 0) {
        phaseProgress = focusProvider.phaseElapsedFraction(phaseSeconds);
      }
    } else if (allCompleted) {
      phaseProgress = 1.0;
    }

    return PomodoroSessionProgressCard(
      sequence: sequence,
      currentPhaseIndex: phaseIndex,
      rounds: focusProvider.rounds,
      focusMinutes: focusProvider.focusMinutes,
      shortBreakMinutes: focusProvider.shortBreakMinutes,
      longBreakMinutes: focusProvider.longBreakMinutes,
      phaseProgress: phaseProgress,
      allCompleted: allCompleted,
    );
  }

  @override
  void initState() {
    super.initState();
    _liveTicker = createTicker((_) {
      if (mounted) setState(() {});
    });

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

  @override
  void deactivate() {
    _liveTicker?.stop();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (mounted) {
      _syncLiveTicker(context.read<FocusProvider>());
    }
  }

  @override
  void dispose() {
    _liveTicker?.dispose();
    super.dispose();
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
    _syncLiveTicker(context.watch<FocusProvider>());

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = MediaQuery.sizeOf(context).width >= 768;
        final bool useTwoColumns = constraints.maxWidth >= 1024;

        final titleWidget = Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          child: Text(
            'Focus',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimaryOf(context),
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

        return AppScaffold(
          backgroundColor: AppColors.backgroundOf(context),
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
      backgroundColor: AppColors.backgroundOf(context),
      elevation: 0,
      leading: Builder(
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
      actions: [
        const NotificationBellButton(),
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
        : focusProvider.phaseElapsedFraction(totalSeconds);
    final int remaining = focusProvider.displayRemainingSeconds;
    final int minutes = remaining ~/ 60;
    final int seconds = remaining % 60;
    final String timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
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
                const SizedBox(height: 24),
                PomodoroTimerCarousel(
                  progress: progress,
                  timeString: timeString,
                  minutes: minutes,
                  seconds: seconds,
                  phaseColor: phaseColor,
                  totalSeconds: totalSeconds,
                  deadline: focusProvider.expectedEndTime,
                  isRunning:
                      focusProvider.timerState == TimerState.running,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildSessionProgressCard(),
          ),
        ],
      ),
    ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Fullscreen timer',
              icon: Icon(
                Icons.open_in_full,
                size: 18,
                color: AppColors.textSecondaryOf(context),
              ),
              onPressed: () => openPomodoroFullscreenTimer(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final focusProvider = context.read<FocusProvider>();
    final int rounds = focusProvider.rounds;
    final int focusTime = focusProvider.focusMinutes * rounds;
    final int breaks = rounds > 1 ? rounds - 1 : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
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
                Text(
                  'Session Completed',
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You stayed focused and productive!',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildSessionProgressCard(allCompleted: true),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOf(context),
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
                      Text(
                        'Focus',
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
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
                    color: AppColors.backgroundOf(context),
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
                      Text(
                        'Pomodoros',
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
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
                    color: AppColors.backgroundOf(context),
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
                      Text(
                        'Breaks',
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
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
            color: AppColors.cardOf(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondaryOf(context)),
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
            decoration: AppColors.pomodoroPlayButtonDecoration(
              context,
              isRunning: isRunning,
              borderRadius: 32,
            ),
            alignment: Alignment.center,
            child: Text(
              isRunning ? 'Pause' : 'Start',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.pomodoroPlayButtonLabelOf(
                  context,
                  isRunning: isRunning,
                ),
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
            color: AppColors.cardOf(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: IconButton(
            icon: Icon(Icons.skip_next, color: AppColors.textSecondaryOf(context)),
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
          backgroundColor: AppColors.cardOf(context),
          title: Text(
            'Timer is running',
            style: TextStyle(color: AppColors.textPrimaryOf(context)),
          ),
          content: Text(
            'You currently have an active focus session. Changing or clearing the task will reset the current timer. Do you want to proceed?',
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondaryOf(context)),
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
        Text(
          'Selected Task',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: selectedTask == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Expanded(
                child: selectedTask == null
                    ? Text(
                        'Choose a task to focus on',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedTask.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryOf(context),
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedTask.dueDate != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: AppColors.textSecondaryOf(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppDateTimeFormat.slashDateShort(selectedTask.dueDate!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryOf(context),
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryOf(context),
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
                  icon: Icon(Icons.close, color: AppColors.textSecondaryOf(context)),
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
                  backgroundColor: AppColors.cardOf(context),
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
            Text(
              'Focus History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            SectionActionButton(
              label: 'View history',
              onPressed: () => Navigator.pushNamed(context, '/focus-history'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (focusHistory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No recent focus sessions.',
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
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
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.completedCheckBgOf(context),
              shape: BoxShape.circle,
              border: AppColors.isDark(context)
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Icon(
              Icons.check,
              color: AppColors.completedCheckFgOf(context),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundOf(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              duration,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
