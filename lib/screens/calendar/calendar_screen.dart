import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/task/task_list_item.dart';
import '../../widgets/calendar/calendar_create_task_popup.dart';
import '../../widgets/common/app_popup_transition.dart';
import '../../widgets/common/animations/app_page_transition.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/staggered_list_entry.dart';
import '../../widgets/common/notification_bell_button.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../utils/validation/task_deadline_rules.dart';
import '../../utils/formatters/app_date_time_format.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  
  DateTime? _lastSelectedDate;
  Set<String> _knownTaskIds = {};

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _createTaskFabKey = GlobalKey();

  late final PageController _monthPageController;
  late final PageController _dayPageController;
  final int _initialPage = 10000;
  late final DateTime _baseDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);
    _monthPageController = PageController(initialPage: _initialPage);
    _dayPageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _dayPageController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getMonthIndex(DateTime date) {
    int yearDiff = date.year - _baseDate.year;
    int monthDiff = date.month - _baseDate.month;
    return _initialPage + (yearDiff * 12) + monthDiff;
  }

  int _getDayIndex(DateTime date) {
    final baseDateUtc = DateTime.utc(_baseDate.year, _baseDate.month, _baseDate.day);
    final dateUtc = DateTime.utc(date.year, date.month, date.day);
    return _initialPage + dateUtc.difference(baseDateUtc).inDays;
  }

  List<DateTime> _generateMonthlyGridDates(DateTime focusedMonth) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, ..., 7 = Sunday
    final int prevDays = firstWeekday - 1; // days to pad from previous month
    final startDate = firstDayOfMonth.subtract(Duration(days: prevDays));
    
    // Create exactly 42 days (6 weeks) to cover any month grid consistently
    return List.generate(42, (index) => startDate.add(Duration(days: index)));
  }

  List<Task> _getTasksForDay(List<Task> allTasks, DateTime day) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return _isSameDay(task.dueDate!, day);
    }).toList();
  }

  void _navigateToNext() {
    if (_monthPageController.hasClients) {
      animatePageNext(_monthPageController);
    }
  }

  void _navigateToPrevious() {
    if (_monthPageController.hasClients) {
      animatePagePrevious(_monthPageController);
    }
  }

  void _goToToday() {
    final now = DateTime.now();
    final monthIndex = _getMonthIndex(now);
    final dayIndex = _getDayIndex(now);
    if (_monthPageController.hasClients) {
      _monthPageController.jumpToPage(monthIndex);
    }
    if (_dayPageController.hasClients) {
      _dayPageController.jumpToPage(dayIndex);
    }
  }

  void _showCreateTaskPopup() {
    if (TaskDeadlineRules.isPastCalendarDay(_selectedDate)) {
      AppNotification.showError(context, TaskDeadlineRules.createDeadlineError);
      return;
    }

    final fabContext = _createTaskFabKey.currentContext;
    showAppPopup(
      context: context,
      anchor: fabContext != null ? popupAnchorFromContext(fabContext) : null,
      child: CalendarCreateTaskPopup(selectedDate: _selectedDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final allTasks = taskProvider.tasks;
    final selectedDayTasks = _getTasksForDay(allTasks, _selectedDate);

    if (_lastSelectedDate == null || !_isSameDay(_lastSelectedDate!, _selectedDate)) {
      _lastSelectedDate = _selectedDate;
      _knownTaskIds = selectedDayTasks.map((t) => t.id).toSet();
    }
    final currentTaskIds = selectedDayTasks.map((t) => t.id).toSet();
    final newTasks = currentTaskIds.difference(_knownTaskIds);
    _knownTaskIds = currentTaskIds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = MediaQuery.of(context).size.width >= 768;
        final bool useTwoColumns = constraints.maxWidth >= 1024;

        Widget calendarHeader = _buildCalendarHeader();
        Widget tasksHeader = _buildTasksHeader();

        Widget calendarWidgetWithGesture = PageView.builder(
          controller: _monthPageController,
          onPageChanged: (index) {
            final offset = index - _initialPage;
            setState(() {
              _focusedDate = DateTime(_baseDate.year, _baseDate.month + offset, 1);
            });
          },
          itemBuilder: (context, index) {
            final offset = index - _initialPage;
            final displayMonth = DateTime(_baseDate.year, _baseDate.month + offset, 1);
            return _buildMonthView(allTasks, displayMonth);
          },
        );

        Widget tasksListWithGesture = PageView.builder(
          controller: _dayPageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            final offset = index - _initialPage;
            setState(() {
              _selectedDate = _baseDate.add(Duration(days: offset));
              // Sync focused month
              final newMonthIndex = _getMonthIndex(_selectedDate);
              if (_monthPageController.hasClients && _monthPageController.page?.round() != newMonthIndex) {
                 _monthPageController.jumpToPage(newMonthIndex);
                 _focusedDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
              }
            });
          },
          itemBuilder: (context, index) {
            final offset = index - _initialPage;
            final displayDay = _baseDate.add(Duration(days: offset));
            final tasksForDay = _getTasksForDay(allTasks, displayDay);
            return _buildSelectedTasksList(tasksForDay, newTasks, isMobile: false);
          },
        );

        Widget tasksListForMobile = _buildSelectedTasksList(
          _getTasksForDay(allTasks, _selectedDate),
          newTasks,
          isMobile: true,
        );

        Widget pageTitle = Text(
          'Calendar',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        );

        Widget layout;
        if (useTwoColumns) {
          layout = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pageTitle,
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: calendarHeader,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: tasksHeader,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: calendarWidgetWithGesture,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: tasksListWithGesture,
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          layout = SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pageTitle,
                const SizedBox(height: 24),
                calendarHeader,
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1.05,
                  child: calendarWidgetWithGesture,
                ),
                const SizedBox(height: 24),
                tasksHeader,
                const SizedBox(height: 16),
                tasksListForMobile,
              ],
            ),
          );
        }

        Widget mainContent = Stack(
          children: [
            const BackgroundPattern(),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: layout,
                  ),
                ),
              ),
            ),
          ],
        );

        return AppScaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: isDesktop ? null : const AppDrawer(
            isPermanent: false,
            activeRoute: '/calendar',
          ),
          appBar: _buildAppBar(context, isDesktop: isDesktop),
          body: isDesktop ? mainContent : GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
            child: mainContent,
          ),
          floatingActionButton: FloatingActionButton(
            key: _createTaskFabKey,
            onPressed: _showCreateTaskPopup,
            child: const Icon(Icons.add),
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
        const NotificationBellButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    String headerText = AppDateTimeFormat.monthYear(_focusedDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          headerText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
              onPressed: _navigateToPrevious,
            ),
            TextButton(
              onPressed: _goToToday,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Today'),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
              onPressed: _navigateToNext,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTasksHeader() {
    return Row(
      children: [
        const Icon(Icons.today, color: AppColors.primaryDark),
        const SizedBox(width: 8),
        Text(
          'Tasks for ${AppDateTimeFormat.weekdayMonthDay(_selectedDate)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView(List<Task> allTasks, DateTime displayMonth) {
    final gridDates = _generateMonthlyGridDates(displayMonth);
    final weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels.map((label) {
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          // Day grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Number of columns is 7
                // We have horizontal spacing: crossAxisSpacing = 8. (7 - 1) * 8 = 48
                final cellWidth = (constraints.maxWidth - 48) / 7;
                
                // Number of rows is gridDates.length / 7
                final numRows = gridDates.length / 7;
                // We have vertical spacing: mainAxisSpacing = 10.
                final totalMainAxisSpacing = (numRows - 1) * 10;
                // We subtract spacing and also give a tiny bit of buffer (e.g. 1 pixel) to prevent overflow rounding errors
                final cellHeight = (constraints.maxHeight - totalMainAxisSpacing - 1) / numRows;
                
                // Ensure aspect ratio is reasonable
                final aspectRatio = cellHeight > 0 ? (cellWidth / cellHeight) : 1.0;

                return GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 8,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: gridDates.length,
              itemBuilder: (context, index) {
                final day = gridDates[index];
                final isCurrentMonth = day.month == displayMonth.month;
                final isSelected = _isSameDay(day, _selectedDate);
                final isToday = _isSameDay(day, DateTime.now());
                final dayTasks = _getTasksForDay(allTasks, day);

                return GestureDetector(
                  onTap: () {
                    final dayIndex = _getDayIndex(day);
                    final monthIndex = _getMonthIndex(day);
                    setState(() {
                      _selectedDate = day;
                      _focusedDate = DateTime(day.year, day.month, 1);
                    });
                    if (_dayPageController.hasClients) {
                      _dayPageController.jumpToPage(dayIndex);
                    }
                    if (_monthPageController.hasClients && _monthPageController.page?.round() != monthIndex) {
                      _monthPageController.jumpToPage(monthIndex);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primaryDark, width: 2)
                          : null,
                    ),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : (isCurrentMonth
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary.withValues(alpha: 0.4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (dayTasks.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: dayTasks.take(3).map((task) {
                                Color dotColor = AppColors.primaryDark;
                                if (task.priority == 'High') {
                                  dotColor = AppColors.accentPeach;
                                } else if (task.priority == 'Medium') {
                                  dotColor = AppColors.accentYellow;
                                }
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? AppColors.textPrimary : dotColor,
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                );
              },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTasksList(List<Task> selectedDayTasks, Set<String> newTasks, {bool isMobile = false}) {
    final sortedTasks = List<Task>.from(selectedDayTasks);
    sortedTasks.sort((a, b) {
      if (a.isAllDay && !b.isAllDay) return -1;
      if (!a.isAllDay && b.isAllDay) return 1;

      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    Widget listContent;
    if (sortedTasks.isEmpty) {
      listContent = _buildEmptyState();
    } else {
      listContent = ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: isMobile,
        physics: isMobile ? const NeverScrollableScrollPhysics() : null,
        itemCount: sortedTasks.length,
        findChildIndexCallback: (Key key) {
          if (key is ValueKey<String>) {
            final id = key.value.replaceAll('task_wrapper_calendar_', '');
            final index = sortedTasks.indexWhere((t) => t.id == id);
            return index >= 0 ? index : null;
          }
          return null;
        },
        itemBuilder: (context, index) {
          final task = sortedTasks[index];
          final isNew = newTasks.contains(task.id);

          bool isFirstAllDay = task.isAllDay && (index == 0 || !sortedTasks[index - 1].isAllDay);
          bool isSubsequentAllDay = task.isAllDay && !isFirstAllDay;

          final timeStr = isFirstAllDay
              ? 'All Day'
              : (task.isAllDay
                  ? ''
                  : (task.dueDate != null ? AppDateTimeFormat.time(task.dueDate!) : 'All Day'));
          
          final item = TaskListItem(
            key: ValueKey(task.id),
            task: task,
            hideTime: true,
            hideActions: true,
            disableCompleteAnimation: true,
            wrapper: (context, taskCard) {
              return Stack(
                children: [
                  // Timeline Connector (drawn first so it is behind the sliding card)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 56,
                    width: 16,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Offset by 8 to account for margin bottom 16 so the dot is visually centered with the card
                        final dotY = (constraints.maxHeight - 16) / 2;
                        return Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            if (index > 0 || isSubsequentAllDay)
                              Positioned(
                                top: 0,
                                height: dotY,
                                child: Container(width: 2, color: AppColors.border),
                              ),
                            if (index < sortedTasks.length - 1)
                              Positioned(
                                top: dotY,
                                bottom: 0,
                                child: Container(width: 2, color: AppColors.border),
                              ),
                            if (!isSubsequentAllDay)
                              Positioned(
                                top: dotY - 6,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  // Time Text
                  Positioned(
                    top: 0,
                    bottom: 16, // Exclude margin so it centers relative to the task card
                    left: 0,
                    width: 50,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  // Task Card (rendered via slidable action pane)
                  Padding(
                    padding: const EdgeInsets.only(left: 72),
                    child: taskCard,
                  ),
                ],
              );
            },
          );
          return StaggeredListEntry(
            key: ValueKey('task_wrapper_calendar_${task.id}'),
            index: index,
            isNewAddition: isNew,
            child: item,
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: listContent,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.spa_outlined,
              size: 48,
              color: AppColors.primaryDark.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No tasks due today!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enjoy your peaceful day. ☕',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
