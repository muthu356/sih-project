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

class _StudentLoginScreenState extends State<StudentLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isLoading = false;
  bool _isListeningForId = false;
  bool _isAskingBlindMode = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    
    // Announce for blind students
    _announceScreen();
  }

  Future<void> _announceScreen() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _voiceService.speak('Student login. Please say your student ID or type it.');
  }

  @override
  void dispose() {
    _animController.dispose();
    _studentIdController.dispose();
    _voiceService.stop();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _listenForStudentId() async {
    setState(() => _isListeningForId = true);
    
    await _voiceService.speak('Please say your student ID');
    final id = await _voiceService.listen(timeout: const Duration(seconds: 6));
    
    setState(() => _isListeningForId = false);
    
    if (id != null && id.isNotEmpty) {
      // Remove spaces and convert to uppercase (e.g., "S T 1 0 1" -> "ST101")
      final cleanId = id.replaceAll(' ', '').toUpperCase();
      _studentIdController.text = cleanId;
      await _voiceService.speak('Student ID entered as $cleanId. Logging in.');
      await _login();
    } else {
      await _voiceService.speak('I did not catch that. Please try again.');
    }
  }

  /// CRITICAL: Voice-first blind mode detection
  /// After login, ask "Are you blind?" and listen for response
  /// No touches needed - completely hands-free
  Future<void> _askIfBlindAndNavigate(String studentId) async {
    if (!mounted) return;
    
    setState(() => _isAskingBlindMode = true);
    
    // Ask the question
    await _voiceService.speak('Are you blind? Say yes or no.');
    
    // Listen for response - 8 seconds to give time to respond
    final response = await _voiceService.listen(timeout: const Duration(seconds: 8));
    
    if (!mounted) return;
    setState(() => _isAskingBlindMode = false);
    
    // Check if user said yes
    final lowerResponse = response?.toLowerCase() ?? '';
    final isBlind = lowerResponse.contains('yes') || 
                    lowerResponse.contains('yeah') || 
                    lowerResponse.contains('yep') ||
                    lowerResponse.contains('blind');
    
    if (isBlind) {
      await _voiceService.speak('Entering voice mode.');
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => StudentBlindMode(studentId: studentId),
          ),
          (route) => false,
        );
      }
    } else {
      // No response, timeout, or said "no" - go to visual dashboard
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
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      final studentId = _studentIdController.text.trim();
      
      // Sign in
      final user = await authService.signInAsStudent(studentId);

      if (user != null && mounted) {
        // Fetch student data to verify exists
        final student = await dbService.getStudent(studentId);
        
        if (student == null) {
          throw Exception('Student not found');
        }
        
        // CRITICAL: Ask if blind via voice instead of checking stored field
        await _voiceService.speak('Login successful.');
        await _askIfBlindAndNavigate(studentId);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = 'Login failed: ${e.toString()}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red.shade400),
        );
        
        // Announce error for blind students
        _voiceService.speak('Login failed. Please check your student ID and try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
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
                            const Icon(Icons.person, size: 70, color: AppTheme.primaryLight),
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
                              'Enter your Student ID',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            
                            // Student ID field with voice button
                            TextFormField(
                              controller: _studentIdController,
                              decoration: InputDecoration(
                                labelText: 'Student ID',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isListeningForId ? Icons.mic : Icons.mic_none,
                                    color: _isListeningForId ? Colors.red : AppTheme.primaryLight,
                                  ),
                                  onPressed: _isListeningForId ? null : _listenForStudentId,
                                  tooltip: 'Speak your Student ID',
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your student ID';
                                }
                                return null;
                              },
                            ),
                            
                            if (_isListeningForId)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.mic, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Listening for ID...',
                                      style: TextStyle(color: Colors.red.shade400),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Show when asking blind mode question
                            if (_isAskingBlindMode)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.primaryLight),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.mic, color: Colors.red, size: 40),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Are you blind?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Say YES or NO',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 32),
                            
                            // Login button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
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
                            
                            // Voice login help
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.accessibility_new, color: AppTheme.primaryLight),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Voice Input Available',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the microphone or just login - after login, you will be asked "Are you blind?" via voice. Say YES for voice mode.',
                                    style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }
}
