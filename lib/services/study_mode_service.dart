import 'package:shared_preferences/shared_preferences.dart';

class StudyModeService {
  static const String _keyStudyMode = 'study_mode_enabled';
  static const String _keyBlockedApps = 'blocked_apps';

  Future<bool> isStudyModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyStudyMode) ?? false;
    print('📱 StudyModeService: Reading study mode = $enabled');
    return enabled;
  }

  Future<void> enableStudyMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStudyMode, true);
    print('✅ StudyModeService: Study mode ENABLED');
    await _logCurrentState();
  }

  Future<void> disableStudyMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStudyMode, false);
    print('⏸️ StudyModeService: Study mode DISABLED');
    await _logCurrentState();
  }

  Future<void> updateBlockedApps(String blockedAppsString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBlockedApps, blockedAppsString);
    print('🚫 StudyModeService: Blocked apps updated = $blockedAppsString');
    await _logCurrentState();
  }

  Future<void> _logCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    final studyMode = prefs.getBool(_keyStudyMode) ?? false;
    final blockedApps = prefs.getString(_keyBlockedApps) ?? '';
    print('📋 === SharedPreferences State ===');
    print('Study Mode: $studyMode');
    print('Blocked Apps: $blockedApps');
    print('==================================');
  }
}
