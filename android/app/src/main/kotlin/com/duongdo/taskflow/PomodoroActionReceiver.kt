package com.duongdo.taskflow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver

/**
 * Handles notification actions with an immediate native UI refresh,
 * then forwards the action to Flutter for timer state sync.
 */
class PomodoroActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val actionId = intent.getStringExtra(PomodoroNotificationHelper.EXTRA_ACTION_ID)
            ?: return

        when (actionId) {
            PomodoroNotificationHelper.ACTION_PAUSE_RESUME ->
                PomodoroNotificationHelper.toggleRunningOptimistic(context)

            PomodoroNotificationHelper.ACTION_STOP ->
                PomodoroNotificationHelper.cancelOptimistic(context)
        }

        val forward = Intent(context, ActionBroadcastReceiver::class.java).apply {
            action = ActionBroadcastReceiver.ACTION_TAPPED
            putExtra(
                PomodoroNotificationHelper.EXTRA_NOTIFICATION_ID,
                intent.getIntExtra(PomodoroNotificationHelper.EXTRA_NOTIFICATION_ID, 1001),
            )
            putExtra(PomodoroNotificationHelper.EXTRA_ACTION_ID, actionId)
            putExtra("cancelNotification", false)
            putExtra(PomodoroNotificationHelper.EXTRA_PAYLOAD, "pomodoro")
        }
        context.sendBroadcast(forward)
    }
}
