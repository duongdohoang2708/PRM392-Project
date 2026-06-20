import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';

import 'screens/main_shell.dart';
import 'providers/task_provider.dart';
import 'providers/drawer_provider.dart';
import 'providers/project_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

void main() {
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
      ],
      child: SlidableAutoCloseBehavior(
        child: MaterialApp(
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
