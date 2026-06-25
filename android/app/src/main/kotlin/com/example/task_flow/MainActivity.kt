package com.example.task_flow

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "task_flow/pomodoro_notification"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        PomodoroNotificationHelper.ensureChannel(this)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "showTimerNotification" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as Map<String, Any>
                        PomodoroNotificationHelper.show(this, args)
                        result.success(null)
                    }

                    "cancelTimerNotification" -> {
                        val notificationId =
                            (call.arguments as? Number)?.toInt() ?: 1001
                        PomodoroNotificationHelper.cancel(this, notificationId)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }

        deliverPomodoroOpenIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deliverPomodoroOpenIntent(intent)
    }

    private fun deliverPomodoroOpenIntent(intent: Intent?) {
        if (!PomodoroNotificationHelper.isPomodoroOpenIntent(intent)) return
        methodChannel?.invokeMethod("openPomodoro", null)
        intent?.removeExtra("notification_payload")
    }
}
