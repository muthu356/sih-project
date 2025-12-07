import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Windows Desktop Monitoring Service
/// Communicates with the Python Windows Agent via WebSocket
class WindowsMonitoringService {
  static final WindowsMonitoringService _instance = WindowsMonitoringService._internal();
  factory WindowsMonitoringService() => _instance;
  WindowsMonitoringService._internal();

  WebSocket? _socket;
  bool _isConnected = false;
  bool _isMonitoring = false;
  
  final _activeWindowController = StreamController<Map<String, dynamic>>.broadcast();
  final _appBlockedController = StreamController<String>.broadcast();
  final _usageController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  Stream<Map<String, dynamic>> get activeWindowStream => _activeWindowController.stream;
  Stream<String> get appBlockedStream => _appBlockedController.stream;
  Stream<List<Map<String, dynamic>>> get usageStream => _usageController.stream;
  
  bool get isConnected => _isConnected;
  bool get isMonitoring => _isMonitoring;

  /// Connect to the Windows Agent
  Future<bool> connect({String host = 'localhost', int port = 8765}) async {
    if (_isConnected) return true;
    
    try {
      print('[WindowsMonitor] Connecting to agent at ws://$host:$port');
      _socket = await WebSocket.connect('ws://$host:$port');
      _isConnected = true;
      
      print('[WindowsMonitor] ✅ Connected to Windows Agent');
      
      // Listen for messages from agent
      _socket!.listen(
        _handleMessage,
        onError: (error) {
          print('[WindowsMonitor] ❌ WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('[WindowsMonitor] WebSocket closed');
          _isConnected = false;
        },
      );
      
      return true;
    } catch (e) {
      print('[WindowsMonitor] ❌ Failed to connect: $e');
      _isConnected = false;
      return false;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());
      final type = message['type'] as String?;
      
      print('[WindowsMonitor] Received: $type');
      
      switch (type) {
        case 'active_window':
          _activeWindowController.add({
            'title': message['title'] ?? '',
            'process': message['process'] ?? '',
            'pid': message['pid'] ?? 0,
          });
          break;
          
        case 'app_blocked':
          final process = message['process'] as String? ?? '';
          _appBlockedController.add(process);
          print('[WindowsMonitor] 🚫 App blocked: $process');
          break;
          
        case 'usage_summary':
          final apps = (message['apps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _usageController.add(apps);
          break;
          
        case 'monitoring_started':
          _isMonitoring = true;
          print('[WindowsMonitor] ✅ Monitoring started');
          break;
          
        case 'monitoring_stopped':
          _isMonitoring = false;
          print('[WindowsMonitor] ⏹️ Monitoring stopped');
          break;
      }
    } catch (e) {
      print('[WindowsMonitor] Error parsing message: $e');
    }
  }

  /// Send command to agent
  Future<void> _sendCommand(Map<String, dynamic> command) async {
    if (!_isConnected || _socket == null) {
      print('[WindowsMonitor] Not connected to agent');
      return;
    }
    
    _socket!.add(jsonEncode(command));
  }

  /// Get active window
  Future<void> getActiveWindow() async {
    await _sendCommand({'action': 'get_active_window'});
  }

  /// Get list of running apps
  Future<List<Map<String, dynamic>>> getRunningApps() async {
    if (!_isConnected) return [];
    
    final completer = Completer<List<Map<String, dynamic>>>();
    
    late StreamSubscription sub;
    sub = _socket!.listen((data) {
      final message = jsonDecode(data.toString());
      if (message['type'] == 'running_apps') {
        final apps = (message['apps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        completer.complete(apps);
        sub.cancel();
      }
    });
    
    await _sendCommand({'action': 'get_running_apps'});
    
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => [],
    );
  }

  /// Start study mode with blocked apps
  Future<void> startStudyMode(List<String> blockedApps) async {
    print('[WindowsMonitor] Starting study mode with blocked: $blockedApps');
    await _sendCommand({
      'action': 'start_monitoring',
      'blocked_apps': blockedApps,
    });
    _isMonitoring = true;
  }

  /// Stop study mode
  Future<void> stopStudyMode() async {
    print('[WindowsMonitor] Stopping study mode');
    await _sendCommand({'action': 'stop_monitoring'});
    _isMonitoring = false;
  }

  /// Block a specific app immediately
  Future<void> blockApp(String processName) async {
    print('[WindowsMonitor] Blocking app: $processName');
    await _sendCommand({
      'action': 'block_app',
      'process': processName,
    });
  }

  /// Get usage summary
  Future<void> getUsageSummary() async {
    await _sendCommand({'action': 'get_usage'});
  }

  /// Disconnect from agent
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _isConnected = false;
    print('[WindowsMonitor] Disconnected');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _activeWindowController.close();
    _appBlockedController.close();
    _usageController.close();
  }
}
