import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'home/home_screen.dart';
import 'task/task_list_screen.dart';
import 'task/create_task_screen.dart';
import 'calendar/calendar_screen.dart';
import 'project/projects_screen.dart';
import 'project/create_project_screen.dart';
import 'project/project_detail_screen.dart';
import 'project/edit_project_screen.dart';
import 'focus/pomodoro_screen.dart';
import 'statistics/statistics_screen.dart';
import 'goals/achievements_screen.dart';
import 'statistics/focus_history_screen.dart';
import 'goals/goals_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _activeRoute = '/home';
  String _initialRoute = '/home';
  bool _initialRouteResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialRouteResolved) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _initialRoute = args?['initialRoute'] as String? ?? '/home';
    _initialRouteResolved = true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = _navigatorKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;

          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: Row(
              children: [
                if (isDesktop)
                  AppDrawer(
                    isPermanent: true,
                    activeRoute: _activeRoute,
                    onNavigate: (route) {
                      final nav = _navigatorKey.currentState;
                      if (nav != null) {
                        if (route == '/home') {
                          nav.pushNamedAndRemoveUntil('/home', (r) => false);
                        } else {
                          nav.pushNamed(route);
                        }
                      }
                    },
                  ),
                Expanded(
                  child: Navigator(
                    key: _navigatorKey,
                    initialRoute: _initialRoute,
                    observers: [
                      _ShellRouteObserver((route) {
                        if (route != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _activeRoute = route;
                              });
                            }
                          });
                        }
                      }),
                    ],
                    onGenerateRoute: _onGenerateRoute,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/home':
        page = const HomeScreen();
        break;
      case '/task-list':
        page = const TaskListScreen();
        break;
      case '/create-task':
        final args = settings.arguments as Map<String, dynamic>?;
        final initialProject = args?['projectName'] as String?;
        page = CreateTaskScreen(initialProjectName: initialProject);
        break;
      case '/calendar':
        page = const CalendarScreen();
        break;
      case '/projects':
        page = const ProjectsScreen();
        break;
      case '/create-project':
        page = const CreateProjectScreen();
        break;
      case '/project-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final projectId = args?['projectId'] as String? ?? '';
        page = ProjectDetailScreen(projectId: projectId);
        break;
      case '/edit-project':
        final args = settings.arguments as Map<String, dynamic>?;
        final projectId = args?['projectId'] as String? ?? '';
        page = EditProjectScreen(projectId: projectId);
        break;
      case '/focus':
        final args = settings.arguments as Map<String, dynamic>?;
        final taskId = args?['taskId'] as String?;
        final focusMinutes = args?['focusMinutes'] as int?;
        final breakMinutes = args?['breakMinutes'] as int?;
        final longBreakMinutes = args?['longBreakMinutes'] as int?;
        final sessions = args?['sessions'] as int?;
        final longBreakInterval = args?['longBreakInterval'] as int?;
        final autoStart = args?['autoStart'] as bool? ?? false;
        page = PomodoroScreen(
          taskId: taskId,
          focusMinutes: focusMinutes,
          breakMinutes: breakMinutes,
          longBreakMinutes: longBreakMinutes,
          sessions: sessions,
          longBreakInterval: longBreakInterval,
          autoStart: autoStart,
        );
        break;
      case '/statistics':
        page = const StatisticsScreen();
        break;
      case '/goals':
        page = const GoalsScreen();
        break;
      case '/achievements':
        page = const AchievementsScreen();
        break;
      case '/focus-history':
        page = const FocusHistoryScreen();
        break;
      default:
        page = const HomeScreen();
    }
    return MaterialPageRoute(
      builder: (context) => page,
      settings: settings,
    );
  }
}

class _ShellRouteObserver extends NavigatorObserver {
  final ValueChanged<String?> onRouteChanged;

  _ShellRouteObserver(this.onRouteChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      onRouteChanged(previousRoute.settings.name);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      onRouteChanged(newRoute.settings.name);
    }
  }
}
