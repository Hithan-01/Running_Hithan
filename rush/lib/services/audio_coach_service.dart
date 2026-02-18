import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioCoachService {
  // Singleton
  static final AudioCoachService _instance = AudioCoachService._internal();
  factory AudioCoachService() => _instance;
  AudioCoachService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _enabled = true;

  static bool get isEnabled => _instance._enabled;
  static void setEnabled(bool value) => _instance._enabled = value;

  /// Initialize TTS engine. Call once in main().
  static Future<void> init() async {
    await _instance._tts.setLanguage('es-MX');
    await _instance._tts.setSpeechRate(0.5);
    await _instance._tts.setVolume(1.0);
    await _instance._tts.setPitch(1.0);
    // iOS: use default audio session category so it mixes with other audio
    await _instance._tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.ambient,
      [IosTextToSpeechAudioCategoryOptions.duckOthers],
    );
    debugPrint('AudioCoachService initialized');
  }

  /// Speak arbitrary text (if enabled).
  static Future<void> speak(String text) async {
    if (!_instance._enabled) return;
    await _instance._tts.speak(text);
  }

  /// Stop current speech.
  static Future<void> stop() async {
    await _instance._tts.stop();
  }

  // ── Pre-built cues ───────────────────────────────────────────────

  /// Countdown before starting a run: "3... 2... 1... Ya!"
  static Future<void> countdown() async {
    if (!_instance._enabled) return;
    await _instance._tts.speak('3');
    await Future.delayed(const Duration(milliseconds: 900));
    await _instance._tts.speak('2');
    await Future.delayed(const Duration(milliseconds: 900));
    await _instance._tts.speak('1');
    await Future.delayed(const Duration(milliseconds: 900));
    await _instance._tts.speak('Ya!');
  }

  /// Announce a distance milestone (called when crossing a full km).
  static Future<void> distanceMilestone(int km) async {
    if (!_instance._enabled) return;
    final label = km == 1 ? 'kilómetro' : 'kilómetros';
    await _instance._tts.speak('$km $label completado${km > 1 ? 's' : ''}');
  }

  /// Announce run completion.
  static Future<void> runComplete(double km) async {
    if (!_instance._enabled) return;
    final formatted = km.toStringAsFixed(1);
    await _instance._tts.speak(
      'Carrera terminada. Recorriste $formatted kilómetros.',
    );
  }

  /// Announce a POI visit.
  static Future<void> poiVisited(String poiName) async {
    if (!_instance._enabled) return;
    await _instance._tts.speak('Visitaste $poiName');
  }

  /// Announce an achievement unlock.
  static Future<void> achievementUnlocked(String name) async {
    if (!_instance._enabled) return;
    await _instance._tts.speak('Logro desbloqueado: $name');
  }
}
