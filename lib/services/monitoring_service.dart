import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_usage/app_usage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_service.dart';
import 'windows_usage_service.dart';

class AppUsageData {
  final String packageName;
  final String appName;
  final String? title;
  final String? text;
  final DateTime timestamp;
  final Duration usageDuration;

  AppUsageData({
    required this.packageName,
    required this.appName,
    this.title,
    this.text,
    required this.timestamp,
    required this.usageDuration,
  });

  @override
  String toString() {
    return 'AppUsageData(package: $packageName, app: $appName, title: $title, duration: ${usageDuration.inSeconds}s)';
  }
}

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  String? _studentId;
  final _databaseService = DatabaseService();

  void setStudentId(String id) {
    _studentId = id;
  }

  final _usageStreamController = StreamController<AppUsageData>.broadcast();
  Stream<AppUsageData> get usageStream => _usageStreamController.stream;

  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  DateTime? _lastCheckTime;

  // Tracking state
  String? _currentPackage;
  DateTime? _currentSessionStart;

  // Cache for durations to avoid writing every second
  final Map<String, Duration> _appUsageMap = {};

  bool get isMonitoring => _isMonitoring;

  Future<bool> requestPermissions() async {
    if (Platform.isWindows) return true;
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    return true;
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _lastCheckTime = DateTime.now();
    _currentPackage = null;
    _currentSessionStart = null;
    _appUsageMap.clear();

    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAppUsage();
    });

    _checkAppUsage();
  }

  Future<void> _checkAppUsage() async {
    try {
      if (Platform.isWindows) {
        await _checkWindowsAppUsage();
      } else if (Platform.isAndroid) {
        await _checkAndroidAppUsage();
      } else {
        _simulateAppUsage();
      }
      _lastCheckTime = DateTime.now();
    } catch (e) {
      debugPrint('Error checking app usage: $e');
      _simulateAppUsage();
    }
  }

  Future<void> _checkWindowsAppUsage() async {
    final now = DateTime.now();

    // Idle detection to be implemented later functionality
    // Currently tracking active window focus

    // Better logic: Compare current lastInputTick with previous stored one?
    // Actually, GetLastInputInfo returns "tick count when the last input event was received".
    // We can just check if (CurrentTickCount - LastInputTick) > IdleThreshold.
    // We need 'GetTickCount'. Since we don't have it bound, let's just use raw heuristic:
    // If the value returned is the SAME as last time, user MIGHT be idle? No, mouse moves constantly.

    // Let's assume non-zero return means valid.
    // If we assume standard Windows tick count (ms), we need the current tick count.
    // Let's rely on change detection for now or implement GetTickCount in WindowsUsageService if needed.
    // For this pass: strict focus app logic.

    final winInfo = WindowsUsageService().getActiveWindowInfo();
    if (winInfo == null) return;

    final packageName = winInfo.appName;

    // Detect app switch
    if (_currentPackage != packageName) {
      // Logic: Close previous session
      if (_currentPackage != null && _currentSessionStart != null) {
        final duration = now.difference(_currentSessionStart!);
        if (duration.inSeconds > 5) {
          // Debounce short switches
          await _logSession(_currentPackage!, winInfo.windowTitle, duration);
        }
      }

      // Start new session
      _currentPackage = packageName;
      _currentSessionStart = now;
    }

    // Update live view
    final currentDuration =
        _currentSessionStart != null
            ? now.difference(_currentSessionStart!)
            : Duration.zero;

    final data = AppUsageData(
      packageName: packageName,
      appName: _getAppDisplayName(packageName),
      title: winInfo.windowTitle,
      text: 'Active Window',
      timestamp: now,
      usageDuration: currentDuration,
    );

    _usageStreamController.add(data);
    _syncLiveActivity(data);
  }

  Future<void> _logSession(
    String packageName,
    String windowTitle,
    Duration duration,
  ) async {
    if (_studentId == null) return;

    try {
      await _databaseService.logUsageEvent(_studentId!, {
        'packageName': packageName,
        'appName': _getAppDisplayName(packageName),
        'title': windowTitle,
        'durationSeconds': duration.inSeconds,
        'startTime': Timestamp.fromDate(DateTime.now().subtract(duration)),
        'endTime': Timestamp.fromDate(DateTime.now()),
        'eventType': 'app_usage',
        'isIdle': false,
      });
    } catch (e) {
      debugPrint('Error logging session: $e');
    }
  }

  Future<void> _syncLiveActivity(AppUsageData data) async {
    if (_studentId == null) return;
    try {
      await _databaseService.updateStudentActivity(_studentId!, {
        'packageName': data.packageName,
        'appName': data.appName,
        'title': data.title,
        'durationSeconds': data.usageDuration.inSeconds,
        'timestamp': Timestamp.fromDate(data.timestamp),
        'isOnline': true,
      });
    } catch (e) {
      /* ignore traffic optimization */
    }
  }

  Future<void> _checkAndroidAppUsage() async {
    // Basic android implementation (same as before but simplified)
    final endTime = DateTime.now();
    final startTime =
        _lastCheckTime ?? endTime.subtract(const Duration(seconds: 5));
    await AppUsage().getAppUsage(startTime, endTime);
    // Android implementation pending
  }

  void _simulateAppUsage() {
    // ... (Simulated logic)
  }

  String _getAppDisplayName(String packageName) {
    if (Platform.isWindows && packageName.toLowerCase().endsWith('.exe')) {
      return packageName.substring(0, packageName.length - 4);
    }
    return packageName;
  }

  void stopMonitoring() async {
    if (!_isMonitoring) return;

    // Close final session
    if (_currentPackage != null && _currentSessionStart != null) {
      final now = DateTime.now();
      final duration = now.difference(_currentSessionStart!);
      if (duration.inSeconds > 5) {
        // Need active window title, but we might not have it easily here without polling.
        // Pass generic title.
        await _logSession(_currentPackage!, "Session End", duration);
      }
    }

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _currentPackage = null;
    _currentSessionStart = null;
    _appUsageMap.clear();
  }

  void dispose() {
    stopMonitoring();
    _usageStreamController.close();
  }
}
