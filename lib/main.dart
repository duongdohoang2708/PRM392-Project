import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';

import 'screens/main_shell.dart';
import 'providers/task_provider.dart';
import 'providers/drawer_provider.dart';
import 'providers/project_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/goals_provider.dart';
import 'services/notification_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => DrawerProvider()),
        ChangeNotifierProxyProvider<TaskProvider, ProjectProvider>(
          create: (_) => ProjectProvider(),
          update: (_, taskProvider, projectProvider) =>
              projectProvider!..update(taskProvider),
        ),
        ChangeNotifierProvider(create: (_) => FocusProvider(navigatorKey)),
        ChangeNotifierProxyProvider2<TaskProvider, FocusProvider, StatisticsProvider>(
          create: (_) => StatisticsProvider(),
          update: (_, taskProvider, focusProvider, statisticsProvider) =>
              statisticsProvider!..updateSources(taskProvider, focusProvider),
        ),
        ChangeNotifierProxyProvider2<TaskProvider, FocusProvider, GoalsProvider>(
          create: (_) => GoalsProvider(),
          update: (_, taskProvider, focusProvider, goalsProvider) =>
              goalsProvider!..updateSources(taskProvider, focusProvider),
        ),
      ],
      child: SlidableAutoCloseBehavior(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'TaskFlow',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/main': (context) => const MainShell(),
          },
        ),
      ),
    );
  }
}
