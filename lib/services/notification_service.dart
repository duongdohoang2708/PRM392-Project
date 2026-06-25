import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/focus_provider.dart';
import '../main.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _pomodoroChannel =
      MethodChannel('task_flow/pomodoro_notification');

  static FocusProvider? _focusProvider;

  static const int _notificationId = 1001;

  static const String _alertChannelId = 'pomodoro_alerts';
  static const String _alertChannelName = 'Pomodoro Alerts';
  static const String _alertChannelDescription =
      'Alerts when focus or break sessions finish';
  static const int _alertNotificationId = 1002;

  static const String _actionPauseResume = 'pause_resume';
  static const String _actionStop = 'stop';

  static const String portName = 'pomodoro_notification_port';
  static ReceivePort? _receivePort;

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request runtime notification permission for Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Register ReceivePort for isolate communication
    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(portName);
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, portName);

    _receivePort!.listen((message) {
      if (message is String) {
        if (message == _actionPauseResume) {
          _handlePauseResume();
        } else if (message == _actionStop) {
          _handleStop();
        }
      }
    });

    _pomodoroChannel.setMethodCallHandler((call) async {
      if (call.method == 'openPomodoro') {
        _navigateToPomodoro();
      }
    });
  }

  static void setFocusProvider(FocusProvider provider) {
    _focusProvider = provider;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Handle action buttons
    if (response.actionId == _actionPauseResume) {
      _handlePauseResume();
      return;
    }
    if (response.actionId == _actionStop) {
      _handleStop();
      return;
    }

    // Tapping notification body → navigate to Pomodoro screen
    if (response.payload == 'pomodoro') {
      _navigateToPomodoro();
    }
  }

  static void _handlePauseResume() {
    if (_focusProvider == null) return;
    if (_focusProvider!.timerState == TimerState.running) {
      _focusProvider!.pauseTimer();
    } else {
      _focusProvider!.startTimer();
    }
  }

  static void _handleStop() {
    if (_focusProvider == null) return;
    _focusProvider!.resetEntireCycle();
    cancelTimerNotification();
  }

  static void _navigateToPomodoro() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main',
      (route) => false,
      arguments: {'initialRoute': '/focus'},
    );
  }

  static Future<void> showTimerNotification({
    required String phaseLabel,
    required String timeString,
    required bool isRunning,
    required int remainingSeconds,
    String? taskName,
  }) async {
    if (Platform.isAndroid) {
      await _pomodoroChannel.invokeMethod<void>('showTimerNotification', {
        'phaseLabel': phaseLabel,
        'timeString': timeString,
        'isRunning': isRunning,
        'remainingSeconds': remainingSeconds,
        'taskName': taskName,
        'notificationId': _notificationId,
      });
      return;
    }

    // iOS / other platforms: standard local notification fallback
    String title = phaseLabel;
    if (taskName != null && taskName.isNotEmpty) {
      title = '$phaseLabel • $taskName';
    }

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(iOS: darwinDetails);

    await _plugin.show(
      id: _notificationId,
      title: title,
      body: isRunning ? timeString : '$timeString (Paused)',
      notificationDetails: details,
      payload: 'pomodoro',
    );
  }

  static Future<void> cancelTimerNotification() async {
    if (Platform.isAndroid) {
      await _pomodoroChannel.invokeMethod<void>(
        'cancelTimerNotification',
        _notificationId,
      );
      return;
    }

    await _plugin.cancel(id: _notificationId);
  }

  static Future<void> showSessionCompleteNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      channelDescription: _alertChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: _alertNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'pomodoro',
    );
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final actionId = notificationResponse.actionId;
  if (actionId == null) return;

  final sendPort = IsolateNameServer.lookupPortByName('pomodoro_notification_port');
  sendPort?.send(actionId);
}
