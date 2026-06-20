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

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _activeRoute = '/home';

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
          // Exits app when back button is pressed on the root of nested navigator
          Navigator.of(context).pop();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;

          final navigator = Navigator(
            key: _navigatorKey,
            initialRoute: '/home',
            observers: [
              _ShellRouteObserver((route) {
                if (route != null) {
                  // Run in next frame to avoid build phase setState
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
            onGenerateRoute: (settings) {
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
                default:
                  page = const HomeScreen();
              }
              return MaterialPageRoute(
                builder: (context) => page,
                settings: settings,
              );
            },
          );

          if (isDesktop) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: Row(
                children: [
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
                  Expanded(child: navigator),
                ],
              ),
            );
          }

          return navigator;
        },
      ),
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
