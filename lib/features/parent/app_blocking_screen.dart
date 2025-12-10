import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_usage/app_usage.dart';
import '../../services/database_service.dart';
import '../../models/app_policy_model.dart';
import '../../core/theme.dart';

class AppBlockingScreen extends StatefulWidget {
  final String studentId;
  final String parentId;

  const AppBlockingScreen({
    super.key,
    required this.studentId,
    required this.parentId,
  });

  @override
  State<AppBlockingScreen> createState() => _AppBlockingScreenState();
}

class _AppBlockingScreenState extends State<AppBlockingScreen> {
  List<AppUsageInfo> _installedApps = [];
  Set<String> _blockedApps = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  String _permissionStatus = 'checking';

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    setState(() {
      _isLoading = true;
      _permissionStatus = 'checking';
    });

    try {
      // Try to get app usage - this requires Usage Access permission on Android
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 1));
      final apps = await AppUsage().getAppUsage(startDate, endDate);

      setState(() {
        _hasPermission = true;
        _installedApps = apps;
        _permissionStatus = 'granted';
      });

      await _loadBlockedApps();
    } catch (e) {
      debugPrint('Permission error: $e');
      setState(() {
        _hasPermission = false;
        _permissionStatus = 'denied';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _openAppSettings() async {
    try {
      // Open app settings using platform channel
      const platform = MethodChannel('com.example.smartapp/app_settings');
      await platform.invokeMethod('openUsageAccessSettings');
    } catch (e) {
      // Fallback: show instructions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please go to Settings > Apps > Special Access > Usage Access and enable for this app',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }

    // Refresh after returning from settings
    await Future.delayed(const Duration(seconds: 1));
    _checkPermissionAndLoad();
  }

  Future<void> _loadBlockedApps() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final policy = await dbService.getAppPolicy(
      widget.studentId,
      widget.parentId,
    );

    if (policy != null) {
      setState(
        () =>
            _blockedApps =
                policy.blockedApps.map((app) => app.packageName).toSet(),
      );
    }
  }

  Future<void> _savePolicy() async {
    if (_blockedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select at least one app to block, or go back.',
          ),
          backgroundColor: Colors.orange.shade400,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final blockedAppsList =
          _blockedApps.map((packageName) {
            // Find app name from installed apps
            final appInfo = _installedApps.firstWhere(
              (app) => app.packageName == packageName,
              orElse:
                  () => AppUsageInfo(
                    packageName,
                    0,
                    DateTime.now(),
                    DateTime.now(),
                    DateTime.now(),
                  ),
            );
            return BlockedApp(
              packageName: packageName,
              appName: appInfo.appName,
            );
          }).toList();

      final policy = AppPolicyModel(
        policyId: '${widget.studentId}_${widget.parentId}',
        studentId: widget.studentId,
        parentId: widget.parentId,
        blockedApps: blockedAppsList,
        updatedAt: DateTime.now(),
      );

      await dbService.saveAppPolicy(policy);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_blockedApps.length} apps blocked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.purpleGradient),
        ),
        title: const Text('Block Apps', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Only show save when apps are visible and some are selected
          if (_hasPermission && _installedApps.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _savePolicy,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _permissionStatus == 'checking') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking permissions...'),
          ],
        ),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionRequestUI();
    }

    if (_installedApps.isEmpty) {
      return _buildNoAppsUI();
    }

    return _buildAppList();
  }

  Widget _buildPermissionRequestUI() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security,
              size: 80,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Permission Required',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'To block apps on your child\'s device, we need permission to see which apps are installed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'How to enable:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Tap "Open Settings" below\n'
                  '2. Find "EduGuardian" in the list\n'
                  '3. Toggle the switch to enable\n'
                  '4. Return to this screen',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _openAppSettings,
              icon: const Icon(Icons.settings),
              label: const Text(
                'Open Settings',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _checkPermissionAndLoad,
            child: const Text('I\'ve enabled it, refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAppsUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No apps found',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Apps will appear here once the student\nuses their device',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _checkPermissionAndLoad,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.purpleGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.block, size: 50, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Select Apps to Block',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_blockedApps.length} of ${_installedApps.length} apps selected',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _installedApps.length,
            itemBuilder: (context, index) {
              final app = _installedApps[index];
              final isBlocked = _blockedApps.contains(app.packageName);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      isBlocked
                          ? BorderSide(color: Colors.red.shade300, width: 2)
                          : BorderSide.none,
                ),
                child: CheckboxListTile(
                  value: isBlocked,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _blockedApps.add(app.packageName);
                      } else {
                        _blockedApps.remove(app.packageName);
                      }
                    });
                  },
                  title: Text(
                    app.appName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isBlocked ? Colors.red.shade700 : null,
                    ),
                  ),
                  subtitle: Text(
                    app.packageName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isBlocked ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isBlocked ? Icons.block : Icons.check_circle,
                      color: isBlocked ? Colors.red : Colors.green,
                    ),
                  ),
                  activeColor: AppTheme.accentPink,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
