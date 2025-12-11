import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/voice_service.dart';
import '../../services/llm_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

/// Blind Mode Dashboard for Windows Desktop
/// 
/// Features:
/// - Continuous ASR (Automatic Speech Recognition)
/// - LLM-powered command understanding
/// - Voice-only navigation
/// - 3-second pause detection for command capture
class StudentBlindMode extends StatefulWidget {
  final String studentId;
  const StudentBlindMode({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentBlindMode> createState() => _StudentBlindModeState();
}

class _StudentBlindModeState extends State<StudentBlindMode> {
  final VoiceService _voiceService = VoiceService();
  final LLMService _llmService = LLMService();
  
  String _currentPage = 'home';
  String _statusText = 'Initializing voice mode...';
  String _capturedText = '';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    print('[BlindMode] 🚀 Initializing blind mode for student: ${widget.studentId}');
    _initializeBlindMode();
  }

  Future<void> _initializeBlindMode() async {
    // Wait for voice service to initialize
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    setState(() => _statusText = 'Voice mode ready');
    
    // Welcome message
    await _speak('Welcome to EduGuardian voice mode. I am listening continuously. Say a command like: show assignments, help me study, or ask any question.');
    
    // Start continuous listening
    _startContinuousListening();
  }

  void _startContinuousListening() {
    if (!mounted) return;
    
    print('[BlindMode] 🎤 Starting continuous ASR...');
    
    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
    });
    
    _voiceService.startContinuousListening(
      onResult: (String capturedText) async {
        if (!mounted || _isProcessing) return;
        
        print('[BlindMode] 📝 CAPTURED: "$capturedText"');
        
        setState(() {
          _capturedText = capturedText;
          _statusText = 'You said: $capturedText';
          _isListening = false;
          _isProcessing = true;
        });
        
        // Process the command
        await _processVoiceCommand(capturedText);
        
        if (mounted) {
          setState(() => _isProcessing = false);
          
          // Resume continuous listening after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _startContinuousListening();
          }
        }
      },
      onListeningStarted: () {
        print('[BlindMode] ✅ Continuous listening started');
      },
    );
  }

  Future<void> _processVoiceCommand(String command) async {
    print('[BlindMode] 🤖 Processing command: "$command"');
    
    final lowerCommand = command.toLowerCase();
    
    // Check for direct navigation commands first
    if (_isNavigationCommand(lowerCommand)) {
      await _handleNavigation(lowerCommand);
      return;
    }
    
    // Check if it's a question (contains question words or ends with ?)
    if (_isQuestion(lowerCommand)) {
      await _handleQuestion(command);
      return;
    }
    
    // Use LLM to understand intent
    print('[BlindMode] 🤖 Using LLM to understand: "$command"');
    final intent = await _llmService.parseVoiceCommandForBlindMode(command);
    print('[BlindMode] 🎯 LLM intent: $intent');
    
    if (intent == 'assignments') {
      await _showAssignments();
    } else if (intent == 'ai_assist' || intent == 'help') {
      await _speak('I can help you with your studies. Just ask any question.');
    } else if (intent == 'home') {
      setState(() => _currentPage = 'home');
      await _speak('You are at the home dashboard. Say: assignments, help, or ask a question.');
    } else if (intent == 'logout') {
      await _handleLogout();
    } else if (intent == 'settings') {
      await _speak('Settings page is not yet available in voice mode.');
    } else {
      // Treat as a question
      await _handleQuestion(command);
    }
  }

  bool _isNavigationCommand(String cmd) {
    return cmd.contains('assignment') ||
           cmd.contains('homework') ||
           cmd.contains('logout') ||
           cmd.contains('sign out') ||
           cmd.contains('exit') ||
           cmd.contains('go home') ||
           cmd.contains('go back') ||
           cmd.contains('dashboard');
  }

  bool _isQuestion(String cmd) {
    return cmd.contains('what') ||
           cmd.contains('how') ||
           cmd.contains('why') ||
           cmd.contains('when') ||
           cmd.contains('where') ||
           cmd.contains('who') ||
           cmd.contains('which') ||
           cmd.contains('can you') ||
           cmd.contains('explain') ||
           cmd.contains('tell me') ||
           cmd.contains('help me') ||
           cmd.endsWith('?');
  }

  Future<void> _handleNavigation(String cmd) async {
    if (cmd.contains('assignment') || cmd.contains('homework')) {
      await _showAssignments();
    } else if (cmd.contains('logout') || cmd.contains('sign out') || cmd.contains('exit')) {
      await _handleLogout();
    } else if (cmd.contains('home') || cmd.contains('back') || cmd.contains('dashboard')) {
      setState(() => _currentPage = 'home');
      await _speak('You are at home dashboard.');
    }
  }

  Future<void> _handleQuestion(String question) async {
    setState(() {
      _currentPage = 'ai_assist';
      _statusText = 'Thinking...';
    });
    
    await _speak('Let me think about that.');
    
    try {
      print('[BlindMode] 📚 Asking AI: "$question"');
      final answer = await _llmService.chatWithEducationalAI(question);
      print('[BlindMode] 💡 AI answer: "$answer"');
      
      setState(() => _statusText = 'Answer: $answer');
      
      await _speak(answer);
      
      setState(() => _currentPage = 'home');
    } catch (e) {
      print('[BlindMode] ❌ AI error: $e');
      await _speak('Sorry, I encountered an error. Please try again.');
      setState(() => _currentPage = 'home');
    }
  }

  Future<void> _showAssignments() async {
    setState(() {
      _currentPage = 'assignments';
      _statusText = 'Loading assignments...';
    });
    
    await _speak('Loading your assignments.');
    
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final assignmentsStream = dbService.getStudentAssignments(widget.studentId);
      
      final assignments = await assignmentsStream.first;
      
      if (assignments.isEmpty) {
        await _speak('You have no assignments.');
        setState(() => _currentPage = 'home');
        return;
      }
      
      await _speak('You have ${assignments.length} assignments.');
      
      for (var i = 0; i < assignments.length; i++) {
        final assignment = assignments[i];
        await _speak(
          'Assignment ${i + 1}. ${assignment.title}. '
          '${assignment.description}. '
          'Status: ${assignment.status.name}.'
        );
        
        // Small pause between assignments
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      await _speak('End of assignments. Say another command.');
      setState(() => _currentPage = 'home');
    } catch (e) {
      print('[BlindMode] ❌ Assignment error: $e');
      await _speak('Could not load assignments. Please try again.');
      setState(() => _currentPage = 'home');
    }
  }

  Future<void> _handleLogout() async {
    await _voiceService.stopContinuousListening();
    await _speak('Logging out. Goodbye.');
    
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    print('[BlindMode] 🔊 Speaking: "$text"');
    
    await _voiceService.speak(text);
    
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  @override
  void dispose() {
    print('[BlindMode] 🛑 Disposing blind mode');
    _voiceService.stopContinuousListening();
    _voiceService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Voice Mode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // Emergency exit button (visual fallback)
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Microphone indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening 
                      ? Colors.red.withOpacity(0.2)
                      : _isSpeaking
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: _isListening 
                        ? Colors.red 
                        : _isSpeaking
                            ? Colors.blue
                            : Colors.white30,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _isListening 
                      ? Icons.mic 
                      : _isSpeaking
                          ? Icons.volume_up
                          : _isProcessing
                              ? Icons.psychology
                              : Icons.mic_off,
                  size: 80,
                  color: _isListening 
                      ? Colors.red 
                      : _isSpeaking
                          ? Colors.blue
                          : Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Current page indicator
              Text(
                _currentPage.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Status text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Captured text (if any)
              if (_capturedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Last captured:',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$_capturedText"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Processing indicator
              if (_isProcessing)
                const Column(
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              
              // Help text
              if (!_isProcessing && !_isSpeaking)
                Container(
                  margin: const EdgeInsets.only(top: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Voice Commands:',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '"Show assignments"\n'
                        '"What is photosynthesis?"\n'
                        '"Help me with math"\n'
                        '"Logout"',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
