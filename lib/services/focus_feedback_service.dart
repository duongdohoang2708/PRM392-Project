import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../utils/focus_sound_options.dart';

class FocusFeedbackService {
  FocusFeedbackService._();

  static final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static Future<void> playSound(String soundId) async {
    final assetPath = FocusSoundOption.assetPath(soundId);
    await _player.stop();
    await _player.play(AssetSource(assetPath));
  }

  static Future<void> vibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(
          pattern: [0, 280, 120, 280],
          intensities: [0, 180, 0, 220],
        );
      } else {
        await Vibration.vibrate(pattern: [0, 280, 120, 280]);
      }
      return;
    }

    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 140));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> preview(String soundId) => playSound(soundId);
}
