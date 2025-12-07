import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/voice_service.dart';
import '../../services/database_service.dart';
import '../student/student_dashboard.dart';
import '../student/student_blind_mode.dart';
import '../../core/theme.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({Key? key}) : super(key: key);

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  late final VoiceService _voiceService;
  
  bool _isLoading = false;
  bool _isListening = false;
  bool _isBlindMode = false;
  bool _blindModeDetected = false;
  bool _inputsEnabled = false;
  
  String _statusText = 'Checking accessibility mode...';

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    
    print('[StudentLogin] Screen initialized');
    _askIfBlindImmediately();
  }

  /// Ask "Are you blind?" using continuous listening
  Future<void> _askIfBlindImmediately() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    
    print('[StudentLogin] Starting blind mode detection...');
    
    setState(() {
      _isListening = true;
      _statusText = 'Are you blind? Say YES or NO';
    });
    
    await _voiceService.speak('Are you blind? Say yes or no.');
    if (!mounted) return;
    
    await _voiceService.waitForSpeech();
    if (!mounted) return;
    
    print('[StudentLogin] Waiting for yes/no response...');
    
    // Use continuous listening - auto-detects speech and stops after 3-sec pause
    await _voiceService.startContinuousListening(
      onResult: (response) async {
        if (!mounted) return;
        
        print('[StudentLogin] Got response for blind mode: "$response"');
        
        final lowerResponse = response.toLowerCase();
        final isBlind = lowerResponse.contains('yes') || 
                        lowerResponse.contains('yeah') || 
                        lowerResponse.contains('yep') ||
                        lowerResponse.contains('blind');
        
        await _voiceService.stopContinuousListening();
        
        if (!mounted) return;
        
        setState(() {
          _isListening = false;
          _isBlindMode = isBlind;
          _blindModeDetected = true;
        });
        
        if (isBlind) {
          print('[StudentLogin] ✅ Blind mode ENABLED');
          await _voiceService.speak('Voice mode activated. Please say your student ID.');
          if (!mounted) return;
          
          setState(() => _statusText = 'Voice mode active. Say your student ID');
          await _listenForStudentIdContinuous();
        } else {
          print('[StudentLogin] ❌ Blind mode DISABLED - normal mode');
          await _voiceService.speak('Normal mode. You can now type your student ID.');
          if (!mounted) return;
          
          setState(() {
            _statusText = 'Type your student ID to login';
            _inputsEnabled = true;
          });
        }
      },
      onListeningStarted: () {
        print('[StudentLogin] 🎤 Listening for yes/no...');
      },
    );
    
    // Timeout fallback (30 seconds max)
    await Future.delayed(const Duration(seconds: 30));
    if (!mounted) return;
    
    if (!_blindModeDetected) {
      print('[StudentLogin] ⏱️ Timeout - defaulting to normal mode');
      await _voiceService.stopContinuousListening();
      setState(() {
        _isListening = false;
        _blindModeDetected = true;
        _inputsEnabled = true;
        _statusText = 'Timeout. Type your student ID';
      });
    }
  }

  /// Continuous listening for Student ID
  Future<void> _listenForStudentIdContinuous() async {
    if (!mounted) return;
    
    print('[StudentLogin] Starting continuous listening for student ID...');
    
    setState(() {
      _isListening = true;
      _statusText = 'Listening for student ID...';
    });
    
    await _voiceService.speak('Say your student ID now.');
    if (!mounted) return;
    
    await _voiceService.waitForSpeech();
    if (!mounted) return;
    
    // Continuous listening - auto-captures ID and processes after 3-sec pause
    await _voiceService.startContinuousListening(
      onResult: (studentId) async {
        if (!mounted) return;
        
        final cleanId = studentId.replaceAll(' ', '').toUpperCase();
        print('[StudentLogin] 🎯 Captured student ID: "$cleanId"');
        
        _studentIdController.text = cleanId;
        
        await _voiceService.stopContinuousListening();
        
        if (!mounted) return;
        
        setState(() {
          _isListening = false;
          _statusText = 'Student ID: $cleanId';
        });
        
        await _voiceService.speak('You said $cleanId. Logging in now.');
        if (!mounted) return;
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        
        await _loginWithVoice();
      },
      onListeningStarted: () {
        print('[StudentLogin] 🎤 Listening for student ID...');
      },
    );
  }

  Future<void> _loginWithVoice() async {
    if (!mounted) return;
    
    if (_studentIdController.text.trim().isEmpty) {
      print('[StudentLogin] ❌ Student ID is empty');
      await _voiceService.speak('Student ID is empty. Please try again.');
      if (!mounted) return;
      await _listenForStudentIdContinuous();
      return;
    }

    setState(() => _isLoading = true);
    print('[StudentLogin] Attempting login with ID: ${_studentIdController.text.trim()}');

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      final studentId = _studentIdController.text.trim();
      
      final user = await authService.signInAsStudent(studentId);

      if (user != null && mounted) {
        final student = await dbService.getStudent(studentId);
        
        if (student == null) {
          throw Exception('Student not found');
        }
        
        print('[StudentLogin] ✅ Login successful for $studentId');
        await _voiceService.speak('Login successful. Entering voice mode.');
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => StudentBlindMode(studentId: studentId),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('[StudentLogin] ❌ Login failed: $e');
      if (mounted) {
        await _voiceService.speak('Login failed. Student ID not found. Please try again.');
        setState(() {
          _statusText = 'Login failed. Try again';
          _studentIdController.clear();
        });
        
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        await _listenForStudentIdContinuous();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginNormal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    print('[StudentLogin] Normal login with ID: ${_studentIdController.text.trim()}');

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      final studentId = _studentIdController.text.trim();
      
      final user = await authService.signInAsStudent(studentId);

      if (user != null && mounted) {
        final student = await dbService.getStudent(studentId);
        
        if (student == null) {
          throw Exception('Student not found');
        }
        
        print('[StudentLogin] ✅ Login successful (normal mode)');
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboard(studentId: studentId),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('[StudentLogin] ❌ Login failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    print('[StudentLogin] Disposing...');
    _studentIdController.dispose();
    _voiceService.stop();
    _voiceService.stopContinuousListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            _isListening ? Icons.mic : Icons.person,
                            size: 70,
                            color: _isListening ? Colors.red : AppTheme.primaryLight,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Student Login',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _isListening ? Colors.red.shade600 : Colors.grey.shade600,
                                  fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          
                          if (_isBlindMode && _blindModeDetected)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade300, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.accessibility_new, color: Colors.blue.shade700, size: 30),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Voice Mode Active',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Speak clearly. Will auto-capture after 3-sec pause.',
                                          style: TextStyle(
                                            color: Colors.blue.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isListening)
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                ],
                              ),
                            ),
                          
                          IgnorePointer(
                            ignoring: !_inputsEnabled,
                            child: Opacity(
                              opacity: _inputsEnabled ? 1.0 : 0.4,
                              child: TextFormField(
                                controller: _studentIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Student ID',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                readOnly: !_inputsEnabled,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your student ID';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          
                          if (_isListening)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.mic, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Listening... (auto-process after 3-sec pause)',
                                    style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_inputsEnabled) ? null : _loginNormal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryLight,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Login', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppTheme.primaryLight),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _blindModeDetected 
                                        ? (_isBlindMode 
                                            ? 'Voice mode: Speak clearly. Auto-captures after 3-sec pause.' 
                                            : 'Normal mode: Type your student ID and tap Login.')
                                        : 'Please wait while we check accessibility settings...',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
