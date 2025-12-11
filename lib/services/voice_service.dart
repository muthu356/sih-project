import 'dart:async';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice Service for Windows Desktop
/// Uses Windows PowerShell TTS and speech_to_text for STT
/// 
/// Features:
/// - Continuous ASR with 3-second pause detection
/// - Windows-native TTS via PowerShell SpeechSynthesizer
/// - Comprehensive logging for debugging
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechAvailable = false;
  bool _isInitialized = false;
  
  // Callback for continuous listening
  Function(String)? _continuousCallback;
  Timer? _restartTimer;

  VoiceService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    print('[VoiceService] 🚀 Initializing for Windows Desktop...');
    
    // Initialize STT
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          print('[VoiceService] 📊 STT status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            // Auto-restart if in continuous mode
            if (_continuousCallback != null) {
              _scheduleRestart();
            }
          }
        },
        onError: (error) {
          print('[VoiceService] ❌ STT error: ${error.errorMsg}');
          _isListening = false;
        },
      );
      print('[VoiceService] ✅ STT initialized: $_speechAvailable');
    } catch (e) {
      print('[VoiceService] ❌ STT init error: $e');
      _speechAvailable = false;
    }
    
    _isInitialized = true;
    print('[VoiceService] ✅ Windows TTS ready (PowerShell)');
  }

  /// Speak text aloud using Windows PowerShell TTS
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Stop listening while speaking to avoid echo
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    
    print('[VoiceService] 🔊 Speaking: "$text"');
    _isSpeaking = true;
    
    try {
      // Use PowerShell to speak on Windows
      final escapedText = text.replaceAll('"', '`"').replaceAll("'", "`'");
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Add-Type -AssemblyName System.Speech; '
          '\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; '
          '\$synth.Rate = 1; '
          '\$synth.Speak("$escapedText");'
        ],
      );
      
      if (result.exitCode != 0) {
        print('[VoiceService] ⚠️ TTS warning: ${result.stderr}');
      }
    } catch (e) {
      print('[VoiceService] ❌ TTS error: $e');
    }
    
    _isSpeaking = false;
    print('[VoiceService] 🔊 TTS completed');
    
    // Small pause after speaking
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Stop speaking (note: PowerShell TTS runs to completion)
  Future<void> stop() async {
    _isSpeaking = false;
  }

  /// Wait for TTS to complete
  Future<void> waitForSpeech() async {
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Start continuous listening mode
  Future<void> startContinuousListening({
    required Function(String) onResult,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
  }) async {
    print('[VoiceService] 🎤 Starting CONTINUOUS listening mode...');
    
    if (!_speechAvailable) {
      await _initialize();
      if (!_speechAvailable) {
        print('[VoiceService] ❌ Speech recognition not available');
        return;
      }
    }
    
    _continuousCallback = onResult;
    onListeningStarted?.call();
    
    await _startListeningSession();
  }

  Future<void> _startListeningSession() async {
    if (_isListening || _isSpeaking) return;
    
    _isListening = true;
    print('[VoiceService] 🎤 Listening session started...');
    
    String lastRecognized = '';
    
    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        
        if (text.isNotEmpty && text != lastRecognized) {
          print('[VoiceService] 📝 Partial: "$text" (final: ${result.finalResult})');
          lastRecognized = text;
          
          if (result.finalResult) {
            print('[VoiceService] ✅ CAPTURED: "$text"');
            _isListening = false;
            
            // Call the callback with captured text
            if (_continuousCallback != null) {
              _continuousCallback!(text);
            }
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3), // 3-second pause = end of command
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 500), () {
      if (_continuousCallback != null && !_isSpeaking && !_isListening) {
        print('[VoiceService] 🔄 Restarting listening session...');
        _startListeningSession();
      }
    });
  }

  /// Stop continuous listening mode
  Future<void> stopContinuousListening() async {
    print('[VoiceService] 🛑 Stopping continuous listening');
    _continuousCallback = null;
    _restartTimer?.cancel();
    await _speech.stop();
    _isListening = false;
  }

  /// Single-shot listen (for specific prompts)
  Future<String?> listen({Duration? timeout}) async {
    if (!_speechAvailable) {
      await _initialize();
      if (!_speechAvailable) {
        print('[VoiceService] ❌ Speech not available');
        return null;
      }
    }
    
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    
    final actualTimeout = timeout ?? const Duration(seconds: 10);
    print('[VoiceService] 🎤 Single-shot listen (${actualTimeout.inSeconds}s)');
    
    String? result;
    final completer = Completer<String?>();
    
    _isListening = true;
    
    await _speech.listen(
      onResult: (val) {
        final text = val.recognizedWords.trim();
        if (text.isNotEmpty) {
          print('[VoiceService] 📝 Captured: "$text" (final: ${val.finalResult})');
          result = text;
          if (val.finalResult && !completer.isCompleted) {
            print('[VoiceService] ✅ Final result: "$text"');
            completer.complete(text);
          }
        }
      },
      listenFor: actualTimeout,
      pauseFor: const Duration(seconds: 3),
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: false,
      partialResults: true,
    );
    
    // Wait for result or timeout
    try {
      result = await completer.future.timeout(actualTimeout, onTimeout: () {
        print('[VoiceService] ⏰ Listen timeout');
        return result;
      });
    } catch (e) {
      print('[VoiceService] Listen error: $e');
    }
    
    await _speech.stop();
    _isListening = false;
    
    return result;
  }

  /// Stop all listening
  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    _continuousCallback = null;
    _restartTimer?.cancel();
  }

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSpeechAvailable => _speechAvailable;
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    stopListening();
    _restartTimer?.cancel();
  }
}
