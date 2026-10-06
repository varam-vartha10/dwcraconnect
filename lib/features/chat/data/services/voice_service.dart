import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) print('TTS Init Error: $e');
    }
  }

  Future<void> speak(String text, {String? language}) async {
    await _init();
    try {
      await stop();
      final lang = language == 'te' || language == 'te-en' ? 'te-IN' : 'en-IN';
      await _flutterTts.setLanguage(lang);
      
      // Clean speech text (remove markdown formatting or bullet symbols for natural audio)
      final cleanText = text
          .replaceAll(RegExp(r'[\*\•\-\#]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      await _flutterTts.speak(cleanText);
    } catch (e) {
      if (kDebugMode) print('TTS Speak Error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    if (_isAvailable) return true;
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) => ifDebugPrint('Speech error: $error'),
        onStatus: (status) => ifDebugPrint('Speech status: $status'),
      );
      return _isAvailable;
    } catch (e) {
      if (kDebugMode) print('Speech initialize error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    String? localeId,
  }) async {
    final available = await initialize();
    if (!available) return;

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Speech listen error: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  void ifDebugPrint(String msg) {
    if (kDebugMode) print(msg);
  }
}
