package com.example.task_flow

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import kotlin.math.max

object PomodoroNotificationHelper {
    const val CHANNEL_ID = "pomodoro_timer_v3"
    const val ACTION_PAUSE_RESUME = "pause_resume"
    const val ACTION_STOP = "stop"

    const val EXTRA_NOTIFICATION_ID = "notificationId"
    const val EXTRA_ACTION_ID = "actionId"
    const val EXTRA_PAYLOAD = "payload"
    private const val EXTRA_CANCEL_NOTIFICATION = "cancelNotification"
    private const val EXTRA_NOTIFICATION_PAYLOAD = "notification_payload"

    private var lastArgs: MutableMap<String, Any>? = null

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.pomodoro_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.pomodoro_channel_description)
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    fun show(context: Context, args: Map<String, Any>) {
        ensureChannel(context)

        val phaseLabel = args["phaseLabel"] as? String ?: "Focus Session"
        val taskName = args["taskName"] as? String
        val timeString = args["timeString"] as? String ?: "00:00"
        val isRunning = args["isRunning"] as? Boolean ?: false
        val notificationId = (args["notificationId"] as? Number)?.toInt() ?: 1001
        val deadlineEpochMs = (args["deadlineEpochMs"] as? Number)?.toLong()
        val remainingSeconds = (args["remainingSeconds"] as? Number)?.toInt() ?: 0

        lastArgs = mutableMapOf(
            "phaseLabel" to phaseLabel,
            "taskName" to (taskName ?: ""),
            "timeString" to timeString,
            "isRunning" to isRunning,
            "notificationId" to notificationId,
            "deadlineEpochMs" to (deadlineEpochMs ?: 0L),
            "remainingSeconds" to remainingSeconds,
        )

        val remoteViews = buildRemoteViews(
            context = context,
            phaseLabel = phaseLabel,
            taskName = taskName,
            timeString = timeString,
            isRunning = isRunning,
            notificationId = notificationId,
            deadlineEpochMs = deadlineEpochMs,
            remainingSeconds = remainingSeconds,
        )

        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_NOTIFICATION_PAYLOAD, "pomodoro")
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            contentIntent,
            pendingIntentFlags(),
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(contentPendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, notification)
    }

    fun cancel(context: Context, notificationId: Int = 1001) {
        lastArgs = null
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(notificationId)
    }

    fun toggleRunningOptimistic(context: Context) {
        val cached = lastArgs ?: return
        val isRunning = cached["isRunning"] as? Boolean ?: false
        val nextRunning = !isRunning
        cached["isRunning"] = nextRunning

        if (!nextRunning) {
            val deadlineEpochMs = (cached["deadlineEpochMs"] as? Number)?.toLong()
            val remainingSeconds = remainingSecondsFromDeadline(deadlineEpochMs)
                ?: (cached["remainingSeconds"] as? Number)?.toInt()
                ?: 0
            cached["timeString"] = formatRemainingSeconds(remainingSeconds)
            cached["remainingSeconds"] = remainingSeconds
        }

        show(context, cached)
    }

    fun cancelOptimistic(context: Context) {
        val notificationId = (lastArgs?.get("notificationId") as? Number)?.toInt() ?: 1001
        cancel(context, notificationId)
    }

    fun isPomodoroOpenIntent(intent: Intent?): Boolean {
        return intent?.getStringExtra(EXTRA_NOTIFICATION_PAYLOAD) == "pomodoro"
    }

    private fun buildRemoteViews(
        context: Context,
        phaseLabel: String,
        taskName: String?,
        timeString: String,
        isRunning: Boolean,
        notificationId: Int,
        deadlineEpochMs: Long?,
        remainingSeconds: Int,
    ): RemoteViews {
        val remoteViews = RemoteViews(context.packageName, R.layout.notification_pomodoro)

        val sessionText = if (isRunning) phaseLabel else "$phaseLabel • Paused"
        remoteViews.setTextViewText(R.id.notification_session_label, sessionText)

        if (!taskName.isNullOrBlank()) {
            remoteViews.setViewVisibility(R.id.notification_task_name, View.VISIBLE)
            remoteViews.setTextViewText(R.id.notification_task_name, taskName)
        } else {
            remoteViews.setViewVisibility(R.id.notification_task_name, View.GONE)
        }

        val canUseCountdownChronometer =
            isRunning && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N

        if (canUseCountdownChronometer) {
            val diffMs = rawRemainingMillis(deadlineEpochMs, remainingSeconds)
            // Flutter shows ceil(diffMs / 1000); Chronometer floors(ms / 1000).
            // +999 ms aligns both formulas on every tick.
            val base = SystemClock.elapsedRealtime() + diffMs + 999L

            remoteViews.setViewVisibility(R.id.notification_chronometer, View.VISIBLE)
            remoteViews.setViewVisibility(R.id.notification_time_text, View.GONE)
            remoteViews.setChronometerCountDown(R.id.notification_chronometer, true)
            remoteViews.setChronometer(
                R.id.notification_chronometer,
                base,
                null,
                true,
            )
        } else {
            remoteViews.setViewVisibility(R.id.notification_chronometer, View.GONE)
            remoteViews.setViewVisibility(R.id.notification_time_text, View.VISIBLE)
            remoteViews.setTextViewText(R.id.notification_time_text, timeString)
        }

        val pauseIcon = if (isRunning) R.drawable.ic_pause else R.drawable.ic_play
        remoteViews.setInt(
            R.id.notification_btn_pause,
            "setBackgroundResource",
            R.drawable.notification_btn_circle,
        )
        remoteViews.setImageViewResource(R.id.notification_btn_pause, pauseIcon)
        remoteViews.setOnClickPendingIntent(
            R.id.notification_btn_pause,
            createActionPendingIntent(context, ACTION_PAUSE_RESUME, notificationId, 1),
        )

        remoteViews.setInt(
            R.id.notification_btn_stop,
            "setBackgroundResource",
            R.drawable.notification_btn_stop_circle,
        )
        remoteViews.setOnClickPendingIntent(
            R.id.notification_btn_stop,
            createActionPendingIntent(context, ACTION_STOP, notificationId, 2),
        )

        return remoteViews
    }

    private fun rawRemainingMillis(
        deadlineEpochMs: Long?,
        remainingSeconds: Int,
    ): Long {
        if (deadlineEpochMs != null && deadlineEpochMs > 0L) {
            return max(0L, deadlineEpochMs - System.currentTimeMillis())
        }
        return max(0L, remainingSeconds.toLong() * 1000L)
    }

    private fun remainingSecondsFromDeadline(deadlineEpochMs: Long?): Int? {
        if (deadlineEpochMs == null || deadlineEpochMs <= 0L) return null
        val diffMs = deadlineEpochMs - System.currentTimeMillis()
        if (diffMs <= 0L) return 0
        return ((diffMs + 999L) / 1000L).toInt()
    }

    private fun formatRemainingSeconds(totalSeconds: Int): String {
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%02d:%02d", minutes, seconds)
    }

    private fun createActionPendingIntent(
        context: Context,
        actionId: String,
        notificationId: Int,
        requestCodeOffset: Int,
    ): PendingIntent {
        val intent = Intent(context, PomodoroActionReceiver::class.java).apply {
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(EXTRA_ACTION_ID, actionId)
        }

        return PendingIntent.getBroadcast(
            context,
            notificationId * 16 + requestCodeOffset,
            intent,
            pendingIntentFlags(),
        )
    }

    private fun pendingIntentFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }
}
