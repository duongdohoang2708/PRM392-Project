import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
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
import 'providers/activity_mode_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'navigation/app_navigator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'widgets/theme/mode_change_notification_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await NotificationService.init();

  final settingsProvider = SettingsProvider();
  final activityModeProvider = ActivityModeProvider();
  final userProvider = UserProvider();
  await settingsProvider.load();
  await activityModeProvider.load();
  await userProvider.load();

  runApp(
    MyApp(
      settingsProvider: settingsProvider,
      activityModeProvider: activityModeProvider,
      userProvider: userProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final ActivityModeProvider activityModeProvider;
  final UserProvider userProvider;

  const MyApp({
    super.key,
    required this.settingsProvider,
    required this.activityModeProvider,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Must be first — ProxyProviders below read UserProvider during mount.
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProxyProvider<UserProvider, SettingsProvider>(
          create: (_) => settingsProvider,
          update: (_, user, previous) {
            previous!.bindUser(user.uid);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, ActivityModeProvider>(
          create: (_) => activityModeProvider,
          update: (_, user, previous) {
            previous!.bindUser(user.uid);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider2<UserProvider, SettingsProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, user, settings, taskProvider) {
            final provider = taskProvider ?? TaskProvider();
            provider
              ..bindUser(user.uid)
              ..bindSettings(settings);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => DrawerProvider()),
        ChangeNotifierProxyProvider2<UserProvider, TaskProvider, ProjectProvider>(
          create: (_) => ProjectProvider(),
          update: (_, user, taskProvider, projectProvider) {
            final provider = projectProvider ?? ProjectProvider();
            provider
              ..bindUser(user.uid)
              ..update(taskProvider);
            taskProvider.bindProjects(provider);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, FocusProvider>(
          create: (_) => FocusProvider(navigatorKey),
          update: (_, user, focusProvider) {
            final provider = focusProvider ?? FocusProvider(navigatorKey);
            provider.bindUser(user.uid);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider3<UserProvider, TaskProvider, FocusProvider,
            GoalsProvider>(
          create: (_) => GoalsProvider(),
          update: (_, user, taskProvider, focusProvider, goalsProvider) {
            final provider = goalsProvider ?? GoalsProvider();
            provider
              ..bindUser(user.uid)
              ..updateSources(taskProvider, focusProvider);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider3<TaskProvider, FocusProvider, GoalsProvider,
            StatisticsProvider>(
          create: (_) => StatisticsProvider(),
          update: (_, taskProvider, focusProvider, goalsProvider,
                  statisticsProvider) =>
              statisticsProvider!
                ..updateSources(taskProvider, focusProvider, goalsProvider),
        ),
        ChangeNotifierProxyProvider5<UserProvider, TaskProvider, FocusProvider,
            GoalsProvider, SettingsProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, user, taskProvider, focusProvider, goalsProvider,
              settingsProvider, notificationProvider) {
            final provider = notificationProvider ?? NotificationProvider();
            provider.bindUser(user.uid);
            provider.bindSources(
              taskProvider: taskProvider,
              focusProvider: focusProvider,
              goalsProvider: goalsProvider,
              settingsProvider: settingsProvider,
            );
            return provider;
          },
        ),
      ],
      child: Consumer2<SettingsProvider, ActivityModeProvider>(
        builder: (context, settings, activityModes, _) {
          final lightPalette =
              activityModes.paletteFor(Brightness.light);
          final darkPalette = activityModes.paletteFor(Brightness.dark);

          return SlidableAutoCloseBehavior(
            child: ModeChangeNotificationListener(
              child: MaterialApp(
                key: ValueKey(activityModes.activeModeId),
                navigatorKey: navigatorKey,
                title: 'TaskFlow',
                theme: AppTheme.build(
                  brightness: Brightness.light,
                  palette: lightPalette,
                ),
                darkTheme: AppTheme.build(
                  brightness: Brightness.dark,
                  palette: darkPalette,
                ),
                themeMode: settings.themeMode,
                debugShowCheckedModeBanner: false,
                home: const SplashScreen(),
                routes: {
                  '/main': (context) => const MainShell(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
