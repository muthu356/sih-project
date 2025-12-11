import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../services/database_service.dart';

class LiveMonitorScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const LiveMonitorScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Activity: $studentName'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.purpleGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: dbService.streamStudentActivity(studentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNoActivityView();
          }

          final data = snapshot.data!;
          final timestamp = data['timestamp'] as Timestamp?;
          final lastUpdated = data['lastUpdated'] as Timestamp?;

          // Check if data is stale (older than 1 minute)
          final isOnline =
              timestamp != null &&
              DateTime.now().difference(timestamp.toDate()).inMinutes < 1;

          if (!isOnline) {
            return _buildOfflineView(lastUpdated?.toDate());
          }

          return _buildLiveActivityView(data);
        },
      ),
    );
  }

  Widget _buildNoActivityView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No activity detected yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineView(DateTime? lastSeen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Student is offline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          if (lastSeen != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Last seen: ${_formatTime(lastSeen)}',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveActivityView(Map<String, dynamic> data) {
    final appName = data['appName'] ?? 'Unknown App';
    final title = data['title'] ?? '';
    final durationSeconds = data['durationSeconds'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pulse animation or online indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE NOW',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Big App Icon/Name
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                  child: Text(
                    appName.isNotEmpty ? appName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active for ${_formatDuration(Duration(seconds: durationSeconds))}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }
}
