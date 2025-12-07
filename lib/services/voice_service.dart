import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _initSTT() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
  }

  // Text to Speech
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // Speech to Text
  Future<String?> listen({Duration? timeout}) async {
    // Re-initialize if not available
    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );
    }

    if (!_speechAvailable) {
      print('Speech recognition not available');
      return null;
    }

    if (_isListening) return null;

    String? result;
    _isListening = true;

    final completer = Future<void>.delayed(timeout ?? const Duration(seconds: 5));
    
    await _speech.listen(
      onResult: (val) {
        result = val.recognizedWords;
      },
      listenFor: timeout ?? const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
      listenMode: stt.ListenMode.confirmation,
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
