package com.duongdo.taskflow

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object PomodoroPhaseAlarmScheduler {
    private const val TAG = "PomodoroPhaseAlarm"
    private const val REQUEST_CODE = 2001

    fun schedule(context: Context, args: Map<String, Any>) {
        val deadlineMs = readLong(args, "deadlineEpochMs") ?: return
        if (deadlineMs <= 0L) return

        val intent = Intent(context, PomodoroPhaseAlarmReceiver::class.java)
        putExtrasFromMap(intent, args)

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            pendingIntentFlags(),
        )

        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !alarmManager.canScheduleExactAlarms()
            ) {
                Log.w(TAG, "Exact alarms not allowed; using inexact alarm")
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    deadlineMs,
                    pendingIntent,
                )
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    deadlineMs,
                    pendingIntent,
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    deadlineMs,
                    pendingIntent,
                )
            }
            Log.d(
                TAG,
                "Scheduled phase alarm at $deadlineMs for phase ${readInt(args, "phaseIndex")}",
            )
        } catch (security: SecurityException) {
            Log.e(TAG, "Failed to schedule exact alarm", security)
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                deadlineMs,
                pendingIntent,
            )
        }
    }

    fun cancel(context: Context) {
        val intent = Intent(context, PomodoroPhaseAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            pendingIntentFlags(),
        )
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    fun putExtrasFromMap(intent: Intent, args: Map<String, Any>) {
        for ((key, value) in args) {
            when (value) {
                is Boolean -> intent.putExtra(key, value)
                is String -> intent.putExtra(key, value)
                is Int -> intent.putExtra(key, value)
                is Long -> intent.putExtra(key, value)
                is Double -> intent.putExtra(key, value)
                is Float -> intent.putExtra(key, value)
                is ArrayList<*> -> intent.putStringArrayListExtra(
                    key,
                    ArrayList(value.map { it.toString() }),
                )
                is List<*> -> intent.putStringArrayListExtra(
                    key,
                    ArrayList(value.map { it.toString() }),
                )
                else -> putDynamicExtra(intent, key, value)
            }
        }
    }

    private fun putDynamicExtra(intent: Intent, key: String, value: Any?) {
        when (value) {
            is Boolean -> intent.putExtra(key, value)
            is String -> intent.putExtra(key, value)
            is Number -> putNumberExtra(intent, key, value)
            is ArrayList<*> -> intent.putStringArrayListExtra(
                key,
                ArrayList(value.map { it.toString() }),
            )
            is List<*> -> intent.putStringArrayListExtra(
                key,
                ArrayList(value.map { it.toString() }),
            )
            else -> Log.w(TAG, "Unsupported extra type for $key: ${value?.javaClass}")
        }
    }

    private fun putNumberExtra(intent: Intent, key: String, value: Number) {
        when (key) {
            "deadlineEpochMs" -> intent.putExtra(key, value.toLong())
            else -> intent.putExtra(key, value.toInt())
        }
    }

    private fun readInt(args: Map<String, Any>, key: String): Int? {
        val value = args[key] ?: return null
        return when (value) {
            is Int -> value
            is Number -> value.toInt()
            else -> null
        }
    }

    private fun readLong(args: Map<String, Any>, key: String): Long? {
        val value = args[key] ?: return null
        return when (value) {
            is Long -> value
            is Number -> value.toLong()
            else -> null
        }
    }

    private fun pendingIntentFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }
}
