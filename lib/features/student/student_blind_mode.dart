import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/voice_service.dart';
import '../../services/llm_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

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
  String _statusText = 'Welcome to Voice Mode';
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeBlindMode();
  }

  Future<void> _initializeBlindMode() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _voiceService.speak('You are in main dashboard. Say a command to navigate. Available options: assignments, AI assist, or logout.');
    _startListeningLoop();
  }

  Future<void> _startListeningLoop() async {
    while (mounted) {
      await _listenForCommand();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _listenForCommand() async {
    if (_isProcessing) return;

    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
    });

    final command = await _voiceService.listen(timeout: const Duration(seconds: 10));

    setState(() => _isListening = false);

    if (command == null || command.isEmpty) {
      setState(() => _statusText = 'No command detected');
      return;
    }

    setState(() {
      _statusText = 'You said: $command';
      _isProcessing = true;
    });
    
    await _processCommand(command);
    
    setState(() => _isProcessing = false);
  }

  Future<void> _processCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    // Direct command matching
    if (lowerCommand.contains('home') || lowerCommand.contains('dashboard')) {
      await _navigateTo('home', 'Going to home dashboard');
    } else if (lowerCommand.contains('assignment')) {
      await _navigateTo('assignments', 'Going to assignments page');
    } else if (lowerCommand.contains('ai') || 
               lowerCommand.contains('assist') || 
               lowerCommand.contains('help') ||
               lowerCommand.contains('question')) {
      await _handleAIAssist(command);
    } else if (lowerCommand.contains('logout') || lowerCommand.contains('exit')) {
      await _voiceService.speak('Logging out');
      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      // AI-powered intent detection
      final page = await _llmService.parseVoiceCommandForBlindMode(command);
      if (page == 'ai_assist' || page == 'help') {
        await _handleAIAssist(command);
      } else if (page != null) {
        await _navigateTo(page, 'Going to $page page');
      } else {
        await _voiceService.speak('I did not understand. Say assignments, AI assist, home, or logout.');
      }
    }
  }

  Future<void> _handleAIAssist(String initialCommand) async {
    setState(() => _currentPage = 'ai_assist');
    
    // Check if the command itself is a question
    final lowerCmd = initialCommand.toLowerCase();
    if (lowerCmd.contains('help') || 
        lowerCmd.contains('assist') || 
        lowerCmd.contains('ai')) {
      // User is just navigating to AI assist
      await _voiceService.speak('AI assistant activated. Ask me any study question.');
      await _waitForQuestion();
    } else {
      // User asked a direct question
      await _answerQuestion(initialCommand);
    }
  }

  Future<void> _waitForQuestion() async {
    setState(() {
      _isListening = true;
      _statusText = 'Ask your question...';
    });

    final question = await _voiceService.listen(timeout: const Duration(seconds: 10));

    setState(() => _isListening = false);

    if (question != null && question.isNotEmpty) {
      await _answerQuestion(question);
    } else {
      await _voiceService.speak('I did not hear a question. Say help again to try.');
    }
  }

  Future<void> _answerQuestion(String question) async {
    setState(() => _statusText = 'Processing your question...');

    await _voiceService.speak('Let me think about that.');

    try {
      // Get AI response using the educational chatbot agent
      final answer = await _llmService.chatWithEducationalAI(question);

      setState(() => _statusText = 'Question: $question\n\nAnswer: $answer');

      // Read answer aloud
      await _voiceService.speak(answer);
      
      // Ask if they want to continue
      await _voiceService.speak('Do you have another question? Say yes or no.');
      
      final response = await _voiceService.listen(timeout: const Duration(seconds: 5));
      
      if (response != null && response.toLowerCase().contains('yes')) {
        await _waitForQuestion();
      } else {
        await _voiceService.speak('Returning to main dashboard.');
        setState(() => _currentPage = 'home');
      }
    } catch (e) {
      await _voiceService.speak('Sorry, I encountered an error. Please try again.');
      setState(() => _currentPage = 'home');
    }
  }

  Future<void> _navigateTo(String page, String announcement) async {
    setState(() => _currentPage = page);
    await _voiceService.speak(announcement);
    
    if (page == 'assignments') {
      await _handleAssignments();
    }
  }

  Future<void> _handleAssignments() async {
    await _voiceService.speak('Loading your assignments.');
    
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final assignmentsStream = dbService.getStudentAssignments(widget.studentId);
      
      final snapshot = await assignmentsStream.first;
      
      if (snapshot.isEmpty) {
        await _voiceService.speak('You have no assignments.');
        setState(() => _currentPage = 'home');
        return;
      }
      
      await _voiceService.speak('You have ${snapshot.length} assignments.');
      
      for (var i = 0; i < snapshot.length; i++) {
        final assignment = snapshot[i];
        await _voiceService.speak(
          'Assignment ${i + 1}. ${assignment.title}. ${assignment.description}. Status: ${assignment.status.name}'
        );
      }
      
      await _voiceService.speak('End of assignments. Returning to home.');
      setState(() => _currentPage = 'home');
    } catch (e) {
      await _voiceService.speak('Could not load assignments.');
      setState(() => _currentPage = 'home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Mode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_off,
              size: 100,
              color: _isListening ? Colors.red : Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              _currentPage.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _statusText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.stop();
    _voiceService.stopListening();
    super.dispose();
  }
}
