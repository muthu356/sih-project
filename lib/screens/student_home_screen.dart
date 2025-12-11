import 'package:flutter/material.dart';
import 'package:flutter_application/services/monitoring_service.dart';
import 'package:flutter_application/screens/monitoring_page.dart';
import 'package:app_settings/app_settings.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final MonitoringService _monitoringService = MonitoringService();
  bool _isStudyModeActive = false;

  @override
  void initState() {
    super.initState();
    _monitoringService.usageStream.listen((data) {
      // Stream is active, monitoring is working
    });
  }

  Future<void> _toggleStudyMode() async {
    if (_isStudyModeActive) {
      // Stop monitoring
      _monitoringService.stopMonitoring();
      setState(() {
        _isStudyModeActive = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study Mode stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Request permissions and start monitoring
      final hasPermission = await _requestPermissions();

      if (hasPermission) {
        await _monitoringService.startMonitoring();
        setState(() {
          _isStudyModeActive = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Study Mode started! Monitoring active.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          _showPermissionDialog();
        }
      }
    }
  }

  Future<bool> _requestPermissions() async {
    // Request usage stats permission
    // Note: app_usage package will handle the permission request
    // We'll check if we can open settings if needed
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'To monitor app usage, please enable "Usage Access" permission in Settings.\n\n'
              'This allows the app to track which apps you use during study time.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  AppSettings.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MonitoringPage()),
              );
            },
            tooltip: 'View Monitoring',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(Icons.school, size: 60, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome, Student!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isStudyModeActive
                              ? 'Study Mode is Active'
                              : 'Ready to start studying?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Study Mode button
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _toggleStudyMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isStudyModeActive
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isStudyModeActive
                              ? Icons.stop_circle
                              : Icons.play_circle_filled,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isStudyModeActive
                              ? 'Stop Study Mode'
                              : 'Start Study Mode',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isStudyModeActive
                              ? 'Tap to stop monitoring'
                              : 'Tap to begin monitoring',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Status indicator
                if (_isStudyModeActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Monitoring active - App usage is being tracked',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Info card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'View real-time monitoring data in the Analytics tab',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    // Don't dispose monitoring service here as it's a singleton
    super.dispose();
  }
}
