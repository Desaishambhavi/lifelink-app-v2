import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper over flutter_tts that exposes a single [speaking] flag the UI
/// can react to for its read-aloud animation.
class TtsService {
  TtsService() {
    _tts.setCompletionHandler(() => speaking.value = false);
    _tts.setCancelHandler(() => speaking.value = false);
    _tts.setErrorHandler((_) => speaking.value = false);
  }

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  Future<void> speak(String text, {String locale = 'en-US'}) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      speaking.value = true;
      await _tts.speak(text);
    } catch (_) {
      speaking.value = false;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    speaking.value = false;
  }

  void dispose() {
    _tts.stop();
    speaking.dispose();
  }
}
