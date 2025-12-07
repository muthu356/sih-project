import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../../services/windows_monitoring_service.dart';
import '../../core/theme.dart';

/// App Blocking Screen for Windows Desktop
/// Connects to Windows Agent to get running apps and block them
class AppBlockingScreen extends StatefulWidget {
  final String studentId;
  const AppBlockingScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<AppBlockingScreen> createState() => _AppBlockingScreenState();
}

class _AppBlockingScreenState extends State<AppBlockingScreen> {
  final WindowsMonitoringService _monitorService = WindowsMonitoringService();
  
  List<Map<String, dynamic>> _runningApps = [];
  Set<String> _selectedApps = {};
  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _statusMessage = 'Connecting to Windows Agent...';

  @override
  void initState() {
    super.initState();
    _connectToAgent();
  }

  Future<void> _connectToAgent() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to Windows Agent...';
    });

    final connected = await _monitorService.connect();
    
    if (connected) {
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _statusMessage = 'Connected! Loading apps...';
      });
      await _loadRunningApps();
    } else {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _isLoading = false;
        _statusMessage = 'Failed to connect. Make sure the Windows Agent is running.';
      });
    }
  }

  Future<void> _loadRunningApps() async {
    setState(() => _isLoading = true);
    
    try {
      final apps = await _monitorService.getRunningApps();
      
      // Filter out system apps and group by process name
      final Map<String, Map<String, dynamic>> uniqueApps = {};
      for (var app in apps) {
        final process = app['process'] as String? ?? '';
        if (_isBlockableApp(process)) {
          if (!uniqueApps.containsKey(process)) {
            uniqueApps[process] = app;
          }
        }
      }
      
      setState(() {
        _runningApps = uniqueApps.values.toList();
        _isLoading = false;
        _statusMessage = 'Found ${_runningApps.length} apps';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading apps: $e';
      });
    }
  }

  bool _isBlockableApp(String processName) {
    // Skip system processes
    const systemApps = [
      'explorer.exe', 'taskmgr.exe', 'systemsettings.exe',
      'searchhost.exe', 'startmenuexperiencehost.exe',
      'shellexperiencehost.exe', 'runtimebroker.exe',
      'applicationframehost.exe', 'textinputhost.exe',
      'smartscreen.exe', 'securityhealthservice.exe',
      'sihost.exe', 'ctfmon.exe', 'dwm.exe',
    ];
    
    final lower = processName.toLowerCase();
    return !systemApps.contains(lower) && 
           !lower.startsWith('windows') &&
           !lower.contains('system') &&
           processName.isNotEmpty;
  }

  Future<void> _startStudyMode() async {
    if (_selectedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select apps to block')),
      );
      return;
    }

    await _monitorService.startStudyMode(_selectedApps.toList());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Study Mode started! ${_selectedApps.length} apps blocked.'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Don't disconnect - keep agent running
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Apps'),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isConnected ? _loadRunningApps : _connectToAgent,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
              border: Border(
                bottom: BorderSide(
                  color: _isConnected ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.warning,
                  color: _isConnected ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected ? 'Windows Agent Connected' : 'Agent Not Connected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Instructions
          if (!_isConnected)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'How to Start Windows Agent',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Open folder: windows_agent\n'
                    '2. Run: start_agent.bat\n'
                    '3. Wait for "Server running" message\n'
                    '4. Click Refresh in this app',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _connectToAgent,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

          // App list
          if (_isConnected)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _runningApps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apps, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('No blockable apps found'),
                              TextButton.icon(
                                onPressed: _loadRunningApps,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _runningApps.length,
                          itemBuilder: (context, index) {
                            final app = _runningApps[index];
                            final process = app['process'] as String? ?? '';
                            final title = app['title'] as String? ?? process;
                            final memory = app['memory_mb'] ?? 0;
                            final isSelected = _selectedApps.contains(process);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedApps.add(process);
                                    } else {
                                      _selectedApps.remove(process);
                                    }
                                  });
                                },
                                title: Text(
                                  _getAppDisplayName(process),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '$process • ${memory}MB',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                secondary: _getAppIcon(process),
                                activeColor: Colors.red,
                              ),
                            );
                          },
                        ),
            ),

          // Bottom bar
          if (_isConnected && _runningApps.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedApps.length} of ${_runningApps.length} apps selected',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedApps.isNotEmpty ? _startStudyMode : null,
                    icon: const Icon(Icons.block),
                    label: const Text('Start Study Mode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getAppDisplayName(String processName) {
    final displayNames = {
      'chrome.exe': 'Google Chrome',
      'firefox.exe': 'Mozilla Firefox',
      'msedge.exe': 'Microsoft Edge',
      'discord.exe': 'Discord',
      'slack.exe': 'Slack',
      'spotify.exe': 'Spotify',
      'code.exe': 'VS Code',
      'notepad.exe': 'Notepad',
      'vlc.exe': 'VLC Player',
      'steam.exe': 'Steam',
      'epicgameslauncher.exe': 'Epic Games',
      'whatsapp.exe': 'WhatsApp',
      'telegram.exe': 'Telegram',
      'zoom.exe': 'Zoom',
      'teams.exe': 'Microsoft Teams',
    };
    
    return displayNames[processName.toLowerCase()] ?? 
           processName.replaceAll('.exe', '').replaceAll('_', ' ');
  }

  Widget _getAppIcon(String processName) {
    final iconMap = {
      'chrome.exe': Icons.public,
      'firefox.exe': Icons.public,
      'msedge.exe': Icons.public,
      'discord.exe': Icons.chat,
      'slack.exe': Icons.chat,
      'spotify.exe': Icons.music_note,
      'code.exe': Icons.code,
      'steam.exe': Icons.games,
      'zoom.exe': Icons.video_call,
      'teams.exe': Icons.groups,
    };
    
    final icon = iconMap[processName.toLowerCase()] ?? Icons.apps;
    return CircleAvatar(
      backgroundColor: Colors.grey.shade200,
      child: Icon(icon, color: Colors.grey.shade700),
    );
  }
}
