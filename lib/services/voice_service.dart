import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Voice Service for Windows Desktop & Mobile
/// TTS works on Windows, STT may need Windows-specific handling
class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isContinuousMode = false;

  VoiceService() {
    _initTTS();
    _initSTT();
  }

  bool get isWindows {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initTTS() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.4);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      print('[VoiceService] TTS initialized (Windows: $isWindows)');
    } catch (e) {
      print('[VoiceService] TTS init error: $e');
    }
  }

  Future<void> _initSTT() async {
    try {
      // On Windows, speech_to_text uses Windows SAPI
      // On Android/iOS, it uses native speech recognition
      if (!isWindows) {
        // Request microphone permission on mobile
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          print('[VoiceService] ❌ Microphone permission denied');
          _speechAvailable = false;
          return;
        }
      }
      
      _speechAvailable = await _speech.initialize(
        onStatus: (status) => print('[VoiceService] Speech status: $status'),
        onError: (error) => print('[VoiceService] ❌ Speech error: $error'),
      );
      print('[VoiceService] ✅ Speech recognition initialized: $_speechAvailable');
    } catch (e) {
      print('[VoiceService] STT init error: $e');
      _speechAvailable = false;
    }
  }

  Future<void> speak(String text) async {
    print('[VoiceService] 🔊 Speaking: "$text"');
    try {
      await _tts.speak(text);
    } catch (e) {
      print('[VoiceService] Speak error: $e');
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    print('[VoiceService] Stopped TTS');
  }

  Future<void> waitForSpeech() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> ensurePermission() async {
    if (_speechAvailable) return true;
    
    if (!isWindows) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }
    
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('[VoiceService] Speech status: $status'),
      onError: (error) => print('[VoiceService] ❌ Speech error: $error'),
    );
    return _speechAvailable;
  }

  /// Continuous listening with auto-capture after 3-sec pause
  Future<void> startContinuousListening({
    required Function(String) onResult,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
  }) async {
    if (!await ensurePermission()) {
      print('[VoiceService] ❌ Cannot start listening: no permission');
      return;
    }

    if (_isListening) {
      print('[VoiceService] Already listening');
      return;
    }

    _isContinuousMode = true;
    _isListening = true;
    print('[VoiceService] 🎤 Starting CONTINUOUS listening');
    
    onListeningStarted?.call();

    String lastRecognized = '';

    await _speech.listen(
      onResult: (result) {
        final recognized = result.recognizedWords;
        
        if (recognized != lastRecognized && recognized.isNotEmpty) {
          print('[VoiceService] 📝 Captured: "$recognized" (final: ${result.finalResult})');
          lastRecognized = recognized;
          
          if (result.finalResult) {
            print('[VoiceService] ✅ Final result: "$recognized"');
            onResult(recognized);
            lastRecognized = '';
          }
        }
      },
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 3),
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: false,
      partialResults: true,
    );

    print('[VoiceService] Continuous listening active');
  }

  Future<void> stopContinuousListening() async {
    if (!_isListening) return;
    
    _isContinuousMode = false;
    _isListening = false;
    await _speech.stop();
    print('[VoiceService] 🛑 Stopped continuous listening');
  }

  /// Single-shot listen
  Future<String?> listen({Duration? timeout, bool forBlindMode = false}) async {
    if (!await ensurePermission()) {
      print('[VoiceService] ❌ Cannot listen: no permission');
      return null;
    }

    if (_isListening) return null;

    String? result;
    _isListening = true;

    final actualTimeout = timeout ?? (forBlindMode ? const Duration(seconds: 15) : const Duration(seconds: 8));
    
    print('[VoiceService] 🎤 Single-shot listen (${actualTimeout.inSeconds}s)');
    
    await _speech.listen(
      onResult: (val) {
        result = val.recognizedWords;
        if (val.finalResult) {
          print('[VoiceService] ✅ Final: "$result"');
        } else {
          print('[VoiceService] 📝 Partial: "$result"');
        }
      },
      listenFor: actualTimeout,
      pauseFor: const Duration(seconds: 3),
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: false,
      partialResults: true,
    );

    await Future.delayed(actualTimeout);
    await _speech.stop();
    _isListening = false;

    return result;
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _isContinuousMode = false;
    }
  }

  bool get isListening => _isListening;
  bool get isSpeechAvailable => _speechAvailable;
  bool get isContinuousMode => _isContinuousMode;
}
