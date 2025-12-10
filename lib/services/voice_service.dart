import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _speechAvailable = false;

  VoiceService() {
    _initTTS();
    _initSTT();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _initSTT() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );
  }

  // Text to Speech
  Future<void> speak(String text) async {
    // Add timeout to prevent hanging if TTS completion callback fails
    await _tts
        .speak(text)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('TTS speak timed out for text: $text');
            return;
          },
        );
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // Speech to Text
  Future<String?> listen({
    Duration? timeout,
    Function(String)? onPartialResult,
  }) async {
    // Re-initialize if not available

    if (!_speechAvailable) {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          debugPrint('Microphone permission denied');
          return null;
        }
      }

      _speechAvailable = await _speech.initialize(
        onStatus: (status) => debugPrint('STT Status: $status'),
        onError: (error) => debugPrint('STT Error: $error'),
        debugLogging: true,
      );

      if (_speechAvailable) {
        var locales = await _speech.locales();
        debugPrint(
          'Available locales: ${locales.map((e) => e.localeId).join(', ')}',
        );
      }
    }

    if (!_speechAvailable) {
      debugPrint('Speech recognition FAILED to initialize.');
      return null;
    }

    if (_isListening) return null;

    String? result;
    _isListening = true;

    final completer = Future<void>.delayed(
      timeout ?? const Duration(seconds: 5),
    );

    await _speech.listen(
      onResult: (val) {
        debugPrint('Recognized words: ${val.recognizedWords}');
        result = val.recognizedWords;
        if (onPartialResult != null) {
          onPartialResult(val.recognizedWords);
        }
      },
      listenFor: timeout ?? const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      localeId: "en_US",
      listenOptions: stt.SpeechListenOptions(partialResults: true),
    );

    // Wait for listening to complete
    await completer;
    await _speech.stop();
    _isListening = false;

    return result;
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  bool get isListening => _isListening;
  bool get isSpeechAvailable => _speechAvailable;
}
