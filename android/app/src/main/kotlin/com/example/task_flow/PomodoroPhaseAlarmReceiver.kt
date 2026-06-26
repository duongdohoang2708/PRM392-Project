package com.example.task_flow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class PomodoroPhaseAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val phaseIndex = intent.getIntExtraCompat("phaseIndex", -1)
        val sequence = intent.getStringListExtraCompat("sequence")
        if (phaseIndex < 0 || sequence.isNullOrEmpty() || phaseIndex >= sequence.size) {
            Log.e(
                TAG,
                "Invalid alarm payload: phaseIndex=$phaseIndex sequenceSize=${sequence?.size}",
            )
            return
        }

        cancelFlutterBackupNotification(context)

        Log.d(TAG, "Phase alarm fired for index $phaseIndex")

        val focusMinutes = intent.getIntExtraCompat("focusMinutes", 25)
        val shortBreakMinutes = intent.getIntExtraCompat("shortBreakMinutes", 5)
        val longBreakMinutes = intent.getIntExtraCompat("longBreakMinutes", 15)
        val autoStartFocus = intent.getBooleanExtra("autoStartFocus", false)
        val autoStartBreak = intent.getBooleanExtra("autoStartBreak", false)
        val taskName = intent.getStringExtra("taskName")
        val notificationId = intent.getIntExtraCompat("timerNotificationId", 1001)

        val playSound = intent.getBooleanExtra("playSound", true)
        val enableVibration = intent.getBooleanExtra("enableVibration", true)
        val soundId = intent.getStringExtra("soundId")

        val completeTitle = intent.getStringExtra("completeTitle") ?: "Session complete"
        val completeBody = intent.getStringExtra("completeBody") ?: ""

        PomodoroSessionCompleteHelper.show(
            context = context,
            title = completeTitle,
            body = completeBody,
            playSound = playSound,
            enableVibration = enableVibration,
            soundId = soundId,
        )

        val isLastPhase = phaseIndex >= sequence.size - 1
        if (isLastPhase) {
            PomodoroNotificationHelper.cancel(context, notificationId)
            PomodoroRuntimeStore.save(
                context = context,
                phaseIndex = phaseIndex,
                deadlineMs = 0L,
                timerRunning = false,
                remainingSeconds = 0,
            )
            PomodoroPhaseAlarmScheduler.cancel(context)
            return
        }

        val nextIndex = phaseIndex + 1
        val nextPhase = sequence[nextIndex]
        val shouldAutoStart = when (nextPhase) {
            "focus" -> autoStartFocus
            else -> autoStartBreak
        }

        if (shouldAutoStart) {
            val durationSeconds = phaseDurationSeconds(
                nextPhase,
                focusMinutes,
                shortBreakMinutes,
                longBreakMinutes,
            )
            val deadlineMs = System.currentTimeMillis() + durationSeconds * 1000L
            val phaseLabel = phaseLabelFor(nextPhase)
            val timeString = formatRemainingSeconds(durationSeconds)

            PomodoroNotificationHelper.show(
                context,
                mapOf(
                    "phaseLabel" to phaseLabel,
                    "taskName" to (taskName ?: ""),
                    "timeString" to timeString,
                    "isRunning" to true,
                    "notificationId" to notificationId,
                    "deadlineEpochMs" to deadlineMs,
                    "remainingSeconds" to durationSeconds,
                ),
            )

            PomodoroRuntimeStore.save(
                context = context,
                phaseIndex = nextIndex,
                deadlineMs = deadlineMs,
                timerRunning = true,
                remainingSeconds = durationSeconds,
            )

            val nextPayload = buildNextAlarmPayload(
                intent = intent,
                phaseIndex = nextIndex,
                sequence = sequence,
                deadlineMs = deadlineMs,
            )
            PomodoroPhaseAlarmScheduler.schedule(context, nextPayload)
            return
        }

        val idleDuration = phaseDurationSeconds(
            nextPhase,
            focusMinutes,
            shortBreakMinutes,
            longBreakMinutes,
        )
        val phaseLabel = phaseLabelFor(nextPhase)
        val timeString = formatRemainingSeconds(idleDuration)

        PomodoroNotificationHelper.show(
            context,
            mapOf(
                "phaseLabel" to phaseLabel,
                "taskName" to (taskName ?: ""),
                "timeString" to timeString,
                "isRunning" to false,
                "notificationId" to notificationId,
                "deadlineEpochMs" to 0L,
                "remainingSeconds" to idleDuration,
            ),
        )

        PomodoroRuntimeStore.save(
            context = context,
            phaseIndex = nextIndex,
            deadlineMs = 0L,
            timerRunning = false,
            remainingSeconds = idleDuration,
        )
        PomodoroPhaseAlarmScheduler.cancel(context)
    }

    private fun buildNextAlarmPayload(
        intent: Intent,
        phaseIndex: Int,
        sequence: List<String>,
        deadlineMs: Long,
    ): HashMap<String, Any> {
        val runningPhase = sequence[phaseIndex]
        val isLast = phaseIndex >= sequence.size - 1
        val nextPhase = if (isLast) null else sequence[phaseIndex + 1]

        val focusSoundEnabled = intent.getBooleanExtra("focusSoundEnabled", true)
        val breakSoundEnabled = intent.getBooleanExtra("breakSoundEnabled", true)
        val focusSoundId = intent.getStringExtra("focusSoundId") ?: "clear_chime"
        val breakSoundId = intent.getStringExtra("breakSoundId") ?: "soft_chime"
        val vibrateOnFocusEnd = intent.getBooleanExtra("vibrateOnFocusEnd", true)
        val vibrateOnBreakEnd = intent.getBooleanExtra("vibrateOnBreakEnd", true)

        val playSound = if (runningPhase == "focus") focusSoundEnabled else breakSoundEnabled
        val enableVibration =
            if (runningPhase == "focus") vibrateOnFocusEnd else vibrateOnBreakEnd
        val soundId = if (runningPhase == "focus") focusSoundId else breakSoundId

        val completeTitle = completionTitle(runningPhase, isLast)
        val completeBody = completionBody(runningPhase, isLast, nextPhase)

        val next = HashMap<String, Any>()
        next["deadlineEpochMs"] = deadlineMs
        next["phaseIndex"] = phaseIndex
        next["sequence"] = sequence
        next["focusMinutes"] = intent.getIntExtraCompat("focusMinutes", 25)
        next["shortBreakMinutes"] = intent.getIntExtraCompat("shortBreakMinutes", 5)
        next["longBreakMinutes"] = intent.getIntExtraCompat("longBreakMinutes", 15)
        next["autoStartFocus"] = intent.getBooleanExtra("autoStartFocus", false)
        next["autoStartBreak"] = intent.getBooleanExtra("autoStartBreak", false)
        next["taskName"] = intent.getStringExtra("taskName") ?: ""
        next["timerNotificationId"] = intent.getIntExtraCompat("timerNotificationId", 1001)
        next["focusSoundEnabled"] = focusSoundEnabled
        next["breakSoundEnabled"] = breakSoundEnabled
        next["focusSoundId"] = focusSoundId
        next["breakSoundId"] = breakSoundId
        next["vibrateOnFocusEnd"] = vibrateOnFocusEnd
        next["vibrateOnBreakEnd"] = vibrateOnBreakEnd
        next["playSound"] = playSound
        next["enableVibration"] = enableVibration
        next["soundId"] = soundId
        next["completeTitle"] = completeTitle
        next["completeBody"] = completeBody
        return next
    }

    private fun phaseLabelFor(type: String): String = when (type) {
        "focus" -> "Focus Session"
        "shortBreak" -> "Short Break"
        "longBreak" -> "Long Break"
        else -> "Focus Session"
    }

    private fun phaseDurationSeconds(
        type: String,
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int,
    ): Int = when (type) {
        "focus" -> focusMinutes * 60
        "shortBreak" -> shortBreakMinutes * 60
        "longBreak" -> longBreakMinutes * 60
        else -> focusMinutes * 60
    }

    private fun formatRemainingSeconds(totalSeconds: Int): String {
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%02d:%02d", minutes, seconds)
    }

    private fun completionTitle(completedType: String, isLast: Boolean): String {
        if (isLast) return "All Sessions Complete!"
        return when (completedType) {
            "focus" -> "Focus Session Finished"
            else -> "Break Finished"
        }
    }

    private fun completionBody(
        completedType: String,
        isLast: Boolean,
        nextType: String?,
    ): String {
        if (isLast) return "Excellent job! You finished the entire Pomodoro cycle."
        if (completedType == "focus") {
            return if (nextType == "longBreak") {
                "Great job! Take a long break."
            } else {
                "Great job! Take a short break."
            }
        }
        return "Ready to focus? Start your next session."
    }

    private fun cancelFlutterBackupNotification(context: Context) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        manager.cancel(1003)
    }

    private fun Intent.getIntExtraCompat(key: String, default: Int): Int {
        val extras = extras ?: return default
        if (!extras.containsKey(key)) return default
        return when (val value = extras.get(key)) {
            is Int -> value
            is Number -> value.toInt()
            else -> default
        }
    }

    private fun Intent.getStringListExtraCompat(key: String): List<String>? {
        getStringArrayListExtra(key)?.let { return it }
        val raw = extras?.get(key) ?: return null
        if (raw is ArrayList<*>) return raw.map { it.toString() }
        if (raw is List<*>) return raw.map { it.toString() }
        return null
    }

    companion object {
        private const val TAG = "PomodoroPhaseAlarm"
    }
}
