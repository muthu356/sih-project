package com.example.smartapp

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.widget.Toast
import android.content.Context

class AppMonitoringService : AccessibilityService() {

    companion object {
        private const val TAG = "AppMonitoring"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_STUDY_MODE = "flutter.study_mode_enabled"
        private const val KEY_BLOCKED_APPS = "flutter.blocked_apps"
        
        var instance: AppMonitoringService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "✅ Accessibility Service Connected")
        
        // Log current configuration
        logConfiguration()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "❌ Accessibility Service Destroyed")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            // Only check on window state changes
            if (it.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
                checkAndBlockApp(it)
            }
        }
    }

    private fun checkAndBlockApp(event: AccessibilityEvent) {
        try {
            // Get SharedPreferences with proper context
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            // Read study mode status
            val isStudyMode = prefs.getBoolean(KEY_STUDY_MODE, false)
            
            Log.d(TAG, "📋 Study Mode: $isStudyMode")
            
            if (!isStudyMode) {
                Log.d(TAG, "⏸️ Study mode disabled - not blocking")
                return
            }

            // Get current app package
            val packageName = event.packageName?.toString() ?: return
            
            // Don't block our own app
            if (packageName == applicationContext.packageName) {
                return
            }

            // Get blocked apps list
            val blockedAppsString = prefs.getString(KEY_BLOCKED_APPS, "") ?: ""
            Log.d(TAG, "🚫 Blocked apps config: $blockedAppsString")
            
            if (blockedAppsString.isEmpty()) {
                Log.d(TAG, "⚠️ No apps configured for blocking")
                return
            }

            // Parse blocked apps (comma-separated)
            val blockedApps = blockedAppsString.split(",").map { it.trim() }.filter { it.isNotEmpty() }
            
            Log.d(TAG, "🔍 Checking: $packageName")
            Log.d(TAG, "📝 Blocked list: ${blockedApps.joinToString()}")

            // Check if current app is blocked
            if (blockedApps.contains(packageName)) {
                Log.d(TAG, "🛑 BLOCKING: $packageName")
                
                // Block the app by going home
                performGlobalAction(GLOBAL_ACTION_HOME)
                
                // Show toast notification
                Toast.makeText(
                    this,
                    "This app is blocked during Study Mode",
                    Toast.LENGTH_SHORT
                ).show()
                
                Log.d(TAG, "✅ Successfully blocked $packageName")
            } else {
                Log.d(TAG, "✅ App allowed: $packageName")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in checkAndBlockApp: ${e.message}", e)
        }
    }

    private fun logConfiguration() {
        try {
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isStudyMode = prefs.getBoolean(KEY_STUDY_MODE, false)
            val blockedApps = prefs.getString(KEY_BLOCKED_APPS, "") ?: ""
            
            Log.d(TAG, "📱 === ACCESSIBILITY SERVICE CONFIGURATION ===")
            Log.d(TAG, "Study Mode: $isStudyMode")
            Log.d(TAG, "Blocked Apps: $blockedApps")
            Log.d(TAG, "Service Package: ${applicationContext.packageName}")
            Log.d(TAG, "===========================================")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error logging configuration: ${e.message}", e)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "⚠️ Accessibility service interrupted")
    }
    
    // Public method to refresh configuration (can be called from Flutter)
    fun refreshConfiguration() {
        Log.d(TAG, "🔄 Refreshing configuration...")
        logConfiguration()
    }
}
