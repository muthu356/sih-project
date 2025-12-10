import 'package:flutter/material.dart';
import '../../services/voice_service.dart';
import 'student_dashboard.dart';
import 'student_blind_mode.dart';

class StudentDashboardEntry extends StatefulWidget {
  final String studentId;
  const StudentDashboardEntry({super.key, required this.studentId});

  @override
  State<StudentDashboardEntry> createState() => _StudentDashboardEntryState();
}

class _StudentDashboardEntryState extends State<StudentDashboardEntry> {
  final VoiceService _voiceService = VoiceService();
  bool _isChecking = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _checkBlindMode();
  }

  Future<void> _checkBlindMode() async {
    // Safety timeout to ensure UI never hangs indefinitely
    Future.delayed(const Duration(seconds: 20)).then((_) {
      if (mounted && _isChecking) {
        setState(() {
          _isChecking = false;
          _statusMessage = 'Voice check timed out.';
        });
      }
    });

    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    // Speak the question
    setState(() => _statusMessage = 'Asking: Are you blind?');

    try {
      await _voiceService
          .speak("Are you blind? Please say yes or no.")
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint("Speak timed out");
              return;
            },
          );
    } catch (e) {
      debugPrint("Error speaking: $e");
    }

    // Listen for answer
    if (!mounted) return;
    setState(() => _statusMessage = 'Listening... Say YES or NO');

    String? response;
    try {
      response = await _voiceService.listen(
        timeout: const Duration(seconds: 10),
        onPartialResult: (text) {
          if (mounted) {
            setState(() => _statusMessage = 'Heard: "$text"');
          }
        },
      );
    } catch (e) {
      debugPrint("Error listening: $e");
      setState(() => _statusMessage = 'Error listening: $e');
    }

    if (!mounted) return;

    if (response != null && response.isNotEmpty) {
      final text = response.toLowerCase();
      debugPrint("Voice response: $text");

      setState(() => _statusMessage = 'Processing: "$text"');

      if (text.contains('yes') ||
          text.contains('yeah') ||
          text.contains('sure') ||
          text.contains('ok') ||
          text.contains('yep')) {
        _navigateToBlindMode();
        return;
      } else if (text.contains('no') || text.contains('nope')) {
        _navigateToStandardDashboard();
        return;
      }
    }

    // Fallback if no clear voice response
    if (mounted) {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Could not hear you clearly. Please select an option.';
      });

      // Announce fallback options for blind accessibility even if first check failed
      try {
        await _voiceService.speak(
          "Could not detect response. Please select a mode on screen.",
        );
      } catch (e) {
        // ignore
      }
    }
  }

  void _navigateToBlindMode() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudentBlindMode(studentId: widget.studentId),
      ),
    );
  }

  void _navigateToStandardDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudentDashboard(studentId: widget.studentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show the main UI, with optional status overlay at the top
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Select Mode"), centerTitle: true),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Select Dashboard Experience",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Status Indicator (Visible when checking)
                  if (_isChecking)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.mic, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed:
                                () => setState(() => _isChecking = false),
                            child: const Text("Stop Voice Check"),
                          ),
                        ],
                      ),
                    ),

                  if (!_isChecking)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _isChecking = true);
                        _checkBlindMode();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry Voice Check"),
                    ),

                  const SizedBox(height: 40),

                  // Standard Option
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(24),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _navigateToStandardDashboard,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility, size: 32),
                        SizedBox(width: 16),
                        Text(
                          "Standard Dashboard",
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Blind Mode Option
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(24),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _navigateToBlindMode,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_off, size: 32),
                        SizedBox(width: 16),
                        Text("Blind Mode", style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} // End of class. Extra methods removed.
