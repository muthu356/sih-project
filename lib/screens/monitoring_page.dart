import 'package:flutter/material.dart';
import 'package:flutter_application/services/monitoring_service.dart';
import 'package:intl/intl.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final MonitoringService _monitoringService = MonitoringService();
  final List<AppUsageData> _usageHistory = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _monitoringService.usageStream.listen((data) {
      if (mounted) {
        setState(() {
          // Add to history, keeping only last 50 entries
          _usageHistory.insert(0, data);
          if (_usageHistory.length > 50) {
            _usageHistory.removeLast();
          }
        });

        // Auto-scroll to top when new data arrives
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }

  IconData _getAppIcon(String packageName) {
    if (packageName.contains('youtube')) {
      return Icons.play_circle;
    } else if (packageName.contains('instagram')) {
      return Icons.camera_alt;
    } else if (packageName.contains('whatsapp')) {
      return Icons.chat;
    } else if (packageName.contains('chrome')) {
      return Icons.language;
    } else if (packageName.contains('spotify')) {
      return Icons.music_note;
    } else if (packageName.contains('facebook')) {
      return Icons.facebook;
    } else if (packageName.contains('twitter')) {
      return Icons.alternate_email;
    } else {
      return Icons.apps;
    }
  }

  Color _getAppColor(String packageName) {
    if (packageName.contains('youtube')) {
      return Colors.red;
    } else if (packageName.contains('instagram')) {
      return Colors.purple;
    } else if (packageName.contains('whatsapp')) {
      return Colors.green;
    } else if (packageName.contains('chrome')) {
      return Colors.blue;
    } else if (packageName.contains('spotify')) {
      return Colors.green.shade700;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Monitoring'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<AppUsageData>(
            stream: _monitoringService.usageStream,
            builder: (context, snapshot) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _monitoringService.isMonitoring
                          ? Colors.green
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _monitoringService.isMonitoring ? 'LIVE' : 'OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body:
          _monitoringService.isMonitoring
              ? _buildMonitoringView()
              : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Study Mode is not active',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start Study Mode from the home screen\nto begin monitoring',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringView() {
    if (_usageHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Waiting for app usage data...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh logic if needed
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _usageHistory.length,
        itemBuilder: (context, index) {
          final data = _usageHistory[index];
          return _buildUsageCard(data);
        },
      ),
    );
  }

  Widget _buildUsageCard(AppUsageData data) {
    final appColor = _getAppColor(data.packageName);
    final timeFormat = DateFormat('HH:mm:ss');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: appColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAppIcon(data.packageName),
                color: appColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // App info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.appName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDuration(data.usageDuration),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: appColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (data.title != null) ...[
                    Text(
                      data.title!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat.format(data.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.phone_android,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data.packageName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
