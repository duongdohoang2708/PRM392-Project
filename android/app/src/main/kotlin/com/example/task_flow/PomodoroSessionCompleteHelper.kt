package com.example.task_flow

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

object PomodoroSessionCompleteHelper {
    private const val TAG = "PomodoroAlert"

    // Bump this suffix whenever channel sound/vibration behavior changes, because
    // Android locks a NotificationChannel's settings after it is first created.
    private const val CHANNEL_VERSION = "v3"
    private const val ALERT_NOTIFICATION_ID = 1002

    private val VIBRATION_PATTERN = longArrayOf(0, 350, 150, 350)

    fun show(
        context: Context,
        title: String,
        body: String,
        playSound: Boolean,
        enableVibration: Boolean,
        soundId: String?,
    ) {
        val resolvedSoundId = if (playSound && !soundId.isNullOrBlank()) soundId else null
        val channelId = buildChannelId(resolvedSoundId, enableVibration)
        ensureChannel(context, channelId, resolvedSoundId, enableVibration)

        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(PomodoroNotificationHelper.EXTRA_NOTIFICATION_PAYLOAD, "pomodoro")
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            ALERT_NOTIFICATION_ID,
            contentIntent,
            pendingIntentFlags(),
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(contentPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)

        // Pre-O devices honor builder-level sound/vibration (no channels).
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            if (playSound && resolvedSoundId != null) {
                builder.setSound(rawSoundUri(context, resolvedSoundId))
            }
            if (enableVibration) {
                builder.setVibrate(VIBRATION_PATTERN)
            }
        }

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(ALERT_NOTIFICATION_ID, builder.build())
        Log.d(TAG, "Posted alert channel=$channelId sound=$playSound vib=$enableVibration")
    }

    private fun buildChannelId(soundId: String?, enableVibration: Boolean): String {
        val soundPart = soundId ?: "silent"
        val vibPart = if (enableVibration) "vib" else "novib"
        return "pomodoro_alert_${CHANNEL_VERSION}_${soundPart}_$vibPart"
    }

    private fun ensureChannel(
        context: Context,
        channelId: String,
        soundId: String?,
        enableVibration: Boolean,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(channelId) != null) return

        val channel = NotificationChannel(
            channelId,
            context.getString(R.string.pomodoro_alert_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = context.getString(R.string.pomodoro_alert_channel_description)

            if (soundId != null) {
                val uri = rawSoundUri(context, soundId)
                if (uri != null) {
                    setSound(
                        uri,
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build(),
                    )
                }
            } else {
                setSound(null, null)
            }

            enableVibration(enableVibration)
            if (enableVibration) {
                vibrationPattern = VIBRATION_PATTERN
            }
        }
        manager.createNotificationChannel(channel)
        Log.d(TAG, "Created channel $channelId")
    }

    private fun rawSoundUri(context: Context, soundId: String): Uri? {
        val resId = context.resources.getIdentifier(soundId, "raw", context.packageName)
        if (resId == 0) {
            Log.w(TAG, "Raw sound not found: $soundId")
            return null
        }
        return Uri.parse("android.resource://${context.packageName}/$resId")
    }

    private fun pendingIntentFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }
}
