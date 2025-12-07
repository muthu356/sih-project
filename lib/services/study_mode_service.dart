import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'windows_monitoring_service.dart';

/// Study Mode Service for Windows Desktop
/// Manages study mode state and communicates with Windows Agent
class StudyModeService {
  static final StudyModeService _instance = StudyModeService._internal();
  factory StudyModeService() => _instance;
  StudyModeService._internal();

  final WindowsMonitoringService _windowsService = WindowsMonitoringService();
  
  bool _isStudyModeEnabled = false;
  List<String> _blockedApps = [];

  bool get isStudyModeEnabled => _isStudyModeEnabled;
  List<String> get blockedApps => _blockedApps;

  /// Check if running on Windows Desktop
  bool get isWindows {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows;
    } catch (e) {
      return false;
    }
  }

  /// Start study mode with blocked apps
  Future<void> startStudyMode(List<String> appsToBlock) async {
    print('[StudyMode] Starting study mode...');
    _blockedApps = appsToBlock;
    _isStudyModeEnabled = true;

    if (isWindows) {
      // Connect to Windows Agent
      final connected = await _windowsService.connect();
      if (connected) {
        await _windowsService.startStudyMode(appsToBlock);
        print('[StudyMode] ✅ Windows study mode started with ${appsToBlock.length} blocked apps');
      } else {
        print('[StudyMode] ❌ Failed to connect to Windows Agent');
      }
    } else {
      // For other platforms, just store locally
      print('[StudyMode] Non-Windows platform - storing locally only');
    }
  }

  /// Stop study mode
  Future<void> stopStudyMode() async {
    print('[StudyMode] Stopping study mode...');
    _isStudyModeEnabled = false;
    _blockedApps = [];

    if (isWindows && _windowsService.isConnected) {
      await _windowsService.stopStudyMode();
      print('[StudyMode] ✅ Windows study mode stopped');
    }
  }

  /// Block a specific app immediately
  Future<void> blockApp(String processName) async {
    if (isWindows && _windowsService.isConnected) {
      await _windowsService.blockApp(processName);
    }
  }

  /// Get usage summary
  Future<void> refreshUsage() async {
    if (isWindows && _windowsService.isConnected) {
      await _windowsService.getUsageSummary();
    }
  }

  /// Dispose
  void dispose() {
    _windowsService.dispose();
  }
}
