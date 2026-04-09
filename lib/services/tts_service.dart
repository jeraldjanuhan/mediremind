// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static TtsService? _instance;
  FlutterTts? _tts;
  bool _initialized = false;

  TtsService._();

  static TtsService get instance {
    _instance ??= TtsService._();
    return _instance!;
  }

  Future<void> init() async {
    if (_initialized) return;
    _tts = FlutterTts();
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.45);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init();
    await _tts!.stop();
    await _tts!.speak(text);
  }

  Future<void> stop() async {
    await _tts?.stop();
  }

  Future<void> dispose() async {
    await _tts?.stop();
    _initialized = false;
  }
}
