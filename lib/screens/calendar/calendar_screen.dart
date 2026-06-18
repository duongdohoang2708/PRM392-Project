import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/task/task_list_item.dart';
import '../../widgets/calendar/calendar_create_task_popup.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      _monthPageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _navigateToPrevious() {
    if (_monthPageController.hasClients) {
      _monthPageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: CalendarCreateTaskPopup(selectedDate: _selectedDate),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final allTasks = taskProvider.tasks;

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
            return _buildSelectedTasksList(tasksForDay, isMobile: false);
          },
        );

        Widget tasksListForMobile = _buildSelectedTasksList(
          _getTasksForDay(allTasks, _selectedDate),
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

        return Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: false,
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
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    String headerText = DateFormat('MMMM yyyy').format(_focusedDate);

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
          'Tasks for ${DateFormat('EEEE, MMM d').format(_selectedDate)}',
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

  Widget _buildSelectedTasksList(List<Task> selectedDayTasks, {bool isMobile = false}) {
    final sortedTasks = List<Task>.from(selectedDayTasks);
    sortedTasks.sort((a, b) {
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
        itemBuilder: (context, index) {
          final task = sortedTasks[index];
          final timeStr = task.dueDate != null
              ? DateFormat('HH:mm').format(task.dueDate!)
              : 'All Day';

          return TaskListItem(
            task: task,
            disableDismissAnimation: false, // Enable dismiss animation!
            hideTime: true,
            hideActions: true,
            wrapper: (context, taskCard) {
              return Stack(
                children: [
                  // Timeline Connector (drawn first so it is behind the sliding card)
                  Positioned(
                    top: 20,
                    bottom: 0,
                    left: 56,
                    width: 16,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Expanded(
                          child: index == sortedTasks.length - 1
                              ? const SizedBox()
                              : Container(
                                  width: 2,
                                  color: AppColors.border,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time
                      SizedBox(
                        width: 56,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // space for connector
                      // Task Card (rendered via slidable action pane)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: taskCard,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
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
