import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsActiveWindowInfo {
  final String windowTitle;
  final String appName;

  WindowsActiveWindowInfo({required this.windowTitle, required this.appName});

  @override
  String toString() => 'Window: $windowTitle, App: $appName';
}

class WindowsUsageService {
  static final WindowsUsageService _instance = WindowsUsageService._internal();
  factory WindowsUsageService() => _instance;
  WindowsUsageService._internal();

  /// Gets information about the currently active foreground window.
  /// Returns null if unable to retrieve information.
  WindowsActiveWindowInfo? getActiveWindowInfo() {
    try {
      final hwnd = GetForegroundWindow();
      if (hwnd == 0) return null;

      final windowTitle = _getWindowTitle(hwnd);
      final processId = _getWindowProcessId(hwnd);

      if (processId == 0) {
        return WindowsActiveWindowInfo(
          windowTitle: windowTitle,
          appName: 'Unknown',
        );
      }

      final appName = _getProcessName(processId);

      return WindowsActiveWindowInfo(
        windowTitle: windowTitle,
        appName: appName,
      );
    } catch (e) {
      debugPrint('Error getting active window info: $e');
      return null;
    }
  }

  String _getWindowTitle(int hwnd) {
    final length = GetWindowTextLength(hwnd);
    if (length == 0) return '';

    final buffer = wsalloc(length + 1);
    try {
      GetWindowText(hwnd, buffer, length + 1);
      return buffer.toDartString();
    } finally {
      free(buffer);
    }
  }

  int _getWindowProcessId(int hwnd) {
    final processId = calloc<DWORD>();
    try {
      GetWindowThreadProcessId(hwnd, processId);
      return processId.value;
    } finally {
      free(processId);
    }
  }

  String _getProcessName(int processId) {
    final hProcess = OpenProcess(
      PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
      FALSE,
      processId,
    );

    if (hProcess == 0) return 'Unknown';

    try {
      // Try to get the module filename
      final buffer = wsalloc(MAX_PATH);
      try {
        final size = GetModuleFileNameEx(hProcess, 0, buffer, MAX_PATH);
        if (size > 0) {
          final fullPath = buffer.toDartString();
          final fileName = fullPath.split('\\').last;
          return fileName;
        }
      } finally {
        free(buffer);
      }

      return 'Unknown';
    } finally {
      CloseHandle(hProcess);
    }
  }

  /// Returns the time of the last input event (mouse or keyboard).
  /// Returns 0 if failed.
  int getLastInputTime() {
    final lastInputInfo = calloc<LASTINPUTINFO>();
    lastInputInfo.ref.cbSize = sizeOf<LASTINPUTINFO>();

    try {
      final result = GetLastInputInfo(lastInputInfo);
      if (result != 0) {
        return lastInputInfo.ref.dwTime;
      }
      return 0;
    } finally {
      free(lastInputInfo);
    }
  }
}
