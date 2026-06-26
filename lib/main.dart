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
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'navigation/app_navigator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  final settingsProvider = SettingsProvider();
  final userProvider = UserProvider();
  await settingsProvider.load();
  await userProvider.load();

  runApp(
    MyApp(
      settingsProvider: settingsProvider,
      userProvider: userProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final UserProvider userProvider;

  const MyApp({
    super.key,
    required this.settingsProvider,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProxyProvider<SettingsProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, settings, taskProvider) =>
              taskProvider!..bindSettings(settings),
        ),
        ChangeNotifierProvider(create: (_) => DrawerProvider()),
        ChangeNotifierProxyProvider<TaskProvider, ProjectProvider>(
          create: (_) => ProjectProvider(),
          update: (_, taskProvider, projectProvider) =>
              projectProvider!..update(taskProvider),
        ),
        ChangeNotifierProvider(create: (_) => FocusProvider(navigatorKey)),
        ChangeNotifierProxyProvider2<TaskProvider, FocusProvider, GoalsProvider>(
          create: (_) => GoalsProvider(),
          update: (_, taskProvider, focusProvider, goalsProvider) =>
              goalsProvider!..updateSources(taskProvider, focusProvider),
        ),
        ChangeNotifierProxyProvider3<TaskProvider, FocusProvider, GoalsProvider,
            StatisticsProvider>(
          create: (_) => StatisticsProvider(),
          update: (_, taskProvider, focusProvider, goalsProvider,
                  statisticsProvider) =>
              statisticsProvider!
                ..updateSources(taskProvider, focusProvider, goalsProvider),
        ),
        ChangeNotifierProxyProvider4<TaskProvider, FocusProvider, GoalsProvider,
            SettingsProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, taskProvider, focusProvider, goalsProvider,
              settingsProvider, notificationProvider) {
            notificationProvider!.bindSources(
              taskProvider: taskProvider,
              focusProvider: focusProvider,
              goalsProvider: goalsProvider,
              settingsProvider: settingsProvider,
            );
            return notificationProvider;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return SlidableAutoCloseBehavior(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              title: 'TaskFlow',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settings.themeMode,
              debugShowCheckedModeBanner: false,
              home: const SplashScreen(),
              routes: {
                '/main': (context) => const MainShell(),
              },
            ),
          );
        },
      ),
    );
  }
}
