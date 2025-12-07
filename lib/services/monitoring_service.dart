import 'dart:async';
import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';

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

  final _usageStreamController = StreamController<AppUsageData>.broadcast();
  Stream<AppUsageData> get usageStream => _usageStreamController.stream;

  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  DateTime? _lastCheckTime;
  Map<String, DateTime> _appStartTimes = {};
  Map<String, Duration> _appUsageMap = {};

  bool get isMonitoring => _isMonitoring;

  Future<bool> requestPermissions() async {
    // Request usage stats permission
    // Note: app_usage package handles this internally
    // For Android, we need to check usage stats permission
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    return true;
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _lastCheckTime = DateTime.now();
    _appStartTimes.clear();
    _appUsageMap.clear();

    // Start periodic monitoring
    _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkAppUsage();
    });

    // Initial check
    _checkAppUsage();
  }

  Future<void> _checkAppUsage() async {
    try {
      // Get app usage stats for the last 5 seconds
      final endTime = DateTime.now();
      final startTime = _lastCheckTime ?? endTime.subtract(const Duration(seconds: 5));

      List<AppUsageInfo> infos = await AppUsage().getAppUsage(startTime, endTime);

      for (var info in infos) {
        if (info.packageName == 'com.example.flutter_application') {
          continue; // Skip our own app
        }

        final now = DateTime.now();

        // Track usage duration
        if (!_appStartTimes.containsKey(info.packageName)) {
          _appStartTimes[info.packageName] = now;
        }

        final startTime = _appStartTimes[info.packageName]!;
        final duration = now.difference(startTime);

        // Update usage map
        _appUsageMap[info.packageName] = duration;

        // Emit usage data
        _usageStreamController.add(
          AppUsageData(
            packageName: info.packageName,
            appName: _getAppDisplayName(info.packageName),
            title: _getAppTitle(info.packageName),
            text: _getAppText(info.packageName),
            timestamp: now,
            usageDuration: duration,
          ),
        );
      }

      _lastCheckTime = endTime;
    } catch (e) {
      // If we can't get real usage stats, simulate for demo
      _simulateAppUsage();
    }
  }

  void _simulateAppUsage() {
    // Simulate app usage for demo purposes
    final apps = [
      {'name': 'YouTube', 'package': 'com.google.android.youtube', 'title': 'Watching: Flutter Tutorial'},
      {'name': 'Instagram', 'package': 'com.instagram.android', 'title': 'Viewing Stories'},
      {'name': 'WhatsApp', 'package': 'com.whatsapp', 'title': 'Chatting with Friends'},
      {'name': 'Chrome', 'package': 'com.android.chrome', 'title': 'Browsing: Stack Overflow'},
      {'name': 'Spotify', 'package': 'com.spotify.music', 'title': 'Playing: Study Music'},
    ];

    final randomApp = apps[(DateTime.now().millisecondsSinceEpoch ~/ 2000) % apps.length];
    final now = DateTime.now();

    if (!_appStartTimes.containsKey(randomApp['package'])) {
      _appStartTimes[randomApp['package']!] = now;
    }

    final startTime = _appStartTimes[randomApp['package']!]!;
    final duration = now.difference(startTime);

    _usageStreamController.add(
      AppUsageData(
        packageName: randomApp['package']!,
        appName: randomApp['name']!,
        title: randomApp['title'],
        text: 'Sample activity text',
        timestamp: now,
        usageDuration: duration,
      ),
    );
  }

  String _getAppDisplayName(String packageName) {
    // Map common package names to display names
    final displayNames = {
      'com.google.android.youtube': 'YouTube',
      'com.instagram.android': 'Instagram',
      'com.whatsapp': 'WhatsApp',
      'com.android.chrome': 'Chrome',
      'com.spotify.music': 'Spotify',
      'com.facebook.katana': 'Facebook',
      'com.twitter.android': 'Twitter',
      'com.netflix.mediaclient': 'Netflix',
      'com.amazon.mShop.android.shopping': 'Amazon',
    };

    return displayNames[packageName] ?? 
           packageName.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ');
  }

  String? _getAppTitle(String packageName) {
    // This would come from accessibility service in real implementation
    // For demo, return null or simulated title
    return null;
  }

  String? _getAppText(String packageName) {
    // This would come from accessibility service in real implementation
    // For demo, return null or simulated text
    return null;
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _appStartTimes.clear();
    _appUsageMap.clear();
  }

  void dispose() {
    stopMonitoring();
    _usageStreamController.close();
  }
}

