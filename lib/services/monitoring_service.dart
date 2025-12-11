import 'dart:async';

/// Windows Desktop Monitoring Service
/// Placeholder for app monitoring on Windows
/// Note: Full monitoring requires the Windows Agent (windows_agent/agent.py)
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  bool _isMonitoring = false;
  
  bool get isMonitoring => _isMonitoring;

  Future<void> startMonitoring() async {
    _isMonitoring = true;
    print('[MonitoringService] Started (Windows Desktop mode)');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    print('[MonitoringService] Stopped');
  }

  void dispose() {
    stopMonitoring();
  }
}
