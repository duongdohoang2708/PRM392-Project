package com.example.task_flow

import android.content.Context

object PomodoroRuntimeStore {
    private const val PREFS = "pomodoro_runtime"

    const val DEADLINE_MS = "deadline_ms"
    const val PHASE_INDEX = "phase_index"
    const val TIMER_RUNNING = "timer_running"
    const val REMAINING_SECONDS = "remaining_seconds"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(
        context: Context,
        phaseIndex: Int,
        deadlineMs: Long,
        timerRunning: Boolean,
        remainingSeconds: Int,
    ) {
        prefs(context).edit()
            .putInt(PHASE_INDEX, phaseIndex)
            .putLong(DEADLINE_MS, deadlineMs)
            .putBoolean(TIMER_RUNNING, timerRunning)
            .putInt(REMAINING_SECONDS, remainingSeconds)
            .apply()
    }

    fun read(context: Context): Map<String, Any>? {
        val p = prefs(context)
        if (!p.contains(PHASE_INDEX)) return null
        return mapOf(
            PHASE_INDEX to p.getInt(PHASE_INDEX, 0),
            DEADLINE_MS to p.getLong(DEADLINE_MS, 0L),
            TIMER_RUNNING to p.getBoolean(TIMER_RUNNING, false),
            REMAINING_SECONDS to p.getInt(REMAINING_SECONDS, 0),
        )
    }

    fun clear(context: Context) {
        prefs(context).edit().clear().apply()
    }
}
