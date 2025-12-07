"""
EduGuardian Windows Monitoring Agent
====================================
Background agent that monitors running applications and blocks apps during study mode.

Features:
- Detect active window (title + process)
- List running processes
- Block/kill specified apps
- Track app usage time
- WebSocket server for Flutter communication
- Firebase sync for logging

Usage:
    python agent.py
    
Or compile to EXE:
    pyinstaller --onefile --noconsole agent.py
"""

import asyncio
import json
import time
import ctypes
import subprocess
from datetime import datetime, timedelta
from collections import defaultdict
import websockets
import psutil

# Windows API imports
try:
    import win32gui
    import win32process
    import win32con
    HAS_WIN32 = True
except ImportError:
    HAS_WIN32 = False
    print("[WARN] pywin32 not installed. Run: pip install pywin32")

# Firebase imports (optional)
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    HAS_FIREBASE = False  # Set to True after config
except ImportError:
    HAS_FIREBASE = False


class WindowsMonitorAgent:
    def __init__(self):
        self.is_monitoring = False
        self.study_mode_enabled = False
        self.blocked_apps = set()  # Process names to block (e.g., "chrome.exe")
        self.usage_tracker = defaultdict(lambda: {"start": None, "total_seconds": 0})
        self.connected_clients = set()
        self.current_window = {"title": "", "process": "", "pid": 0}
        
        print("[Agent] EduGuardian Windows Agent initialized")
        
    def get_active_window(self):
        """Get the currently active window title and process name"""
        if not HAS_WIN32:
            return {"title": "Unknown", "process": "unknown.exe", "pid": 0}
            
        try:
            hwnd = win32gui.GetForegroundWindow()
            _, pid = win32process.GetWindowThreadProcessId(hwnd)
            title = win32gui.GetWindowText(hwnd)
            
            try:
                process = psutil.Process(pid)
                process_name = process.name()
            except:
                process_name = "unknown.exe"
                
            return {
                "title": title,
                "process": process_name,
                "pid": pid
            }
        except Exception as e:
            print(f"[Error] get_active_window: {e}")
            return {"title": "", "process": "", "pid": 0}
    
    def get_running_apps(self):
        """Get list of all running applications with windows"""
        apps = []
        
        def enum_windows_callback(hwnd, results):
            if win32gui.IsWindowVisible(hwnd):
                title = win32gui.GetWindowText(hwnd)
                if title:
                    try:
                        _, pid = win32process.GetWindowThreadProcessId(hwnd)
                        process = psutil.Process(pid)
                        results.append({
                            "title": title,
                            "process": process.name(),
                            "pid": pid,
                            "memory_mb": round(process.memory_info().rss / 1024 / 1024, 1)
                        })
                    except:
                        pass
            return True
        
        if HAS_WIN32:
            win32gui.EnumWindows(enum_windows_callback, apps)
        else:
            # Fallback using psutil only
            for proc in psutil.process_iter(['pid', 'name', 'memory_info']):
                try:
                    apps.append({
                        "title": proc.info['name'],
                        "process": proc.info['name'],
                        "pid": proc.info['pid'],
                        "memory_mb": round(proc.info['memory_info'].rss / 1024 / 1024, 1)
                    })
                except:
                    pass
                    
        return apps
    
    def kill_process(self, process_name):
        """Kill a process by name"""
        try:
            # Use taskkill command
            result = subprocess.run(
                ["taskkill", "/F", "/IM", process_name],
                capture_output=True,
                text=True
            )
            success = result.returncode == 0
            print(f"[Agent] Kill {process_name}: {'SUCCESS' if success else 'FAILED'}")
            return success
        except Exception as e:
            print(f"[Error] kill_process: {e}")
            return False
    
    def check_and_block(self):
        """Check if current window is blocked and kill it"""
        if not self.study_mode_enabled or not self.blocked_apps:
            return False
            
        current = self.get_active_window()
        process_name = current["process"].lower()
        
        for blocked in self.blocked_apps:
            if blocked.lower() in process_name:
                print(f"[BLOCK] Killing blocked app: {current['process']}")
                self.kill_process(current["process"])
                return True
                
        return False
    
    def track_usage(self, window_info):
        """Track time spent in each application"""
        process = window_info["process"]
        now = time.time()
        
        # End previous tracking
        for proc, data in self.usage_tracker.items():
            if proc != process and data["start"] is not None:
                elapsed = now - data["start"]
                data["total_seconds"] += elapsed
                data["start"] = None
        
        # Start tracking current
        if self.usage_tracker[process]["start"] is None:
            self.usage_tracker[process]["start"] = now
    
    def get_usage_summary(self):
        """Get app usage summary"""
        now = time.time()
        summary = []
        
        for process, data in self.usage_tracker.items():
            total = data["total_seconds"]
            if data["start"] is not None:
                total += now - data["start"]
            
            if total > 0:
                summary.append({
                    "process": process,
                    "minutes": round(total / 60, 1),
                    "seconds": round(total, 0)
                })
        
        return sorted(summary, key=lambda x: x["minutes"], reverse=True)
    
    async def broadcast(self, message):
        """Broadcast message to all connected Flutter clients"""
        if self.connected_clients:
            msg_str = json.dumps(message)
            await asyncio.gather(
                *[client.send(msg_str) for client in self.connected_clients],
                return_exceptions=True
            )
    
    async def handle_client(self, websocket):
        """Handle incoming WebSocket connections from Flutter"""
        self.connected_clients.add(websocket)
        client_addr = websocket.remote_address
        print(f"[WS] Client connected: {client_addr}")
        
        try:
            async for message in websocket:
                try:
                    data = json.loads(message)
                    action = data.get("action", "")
                    print(f"[WS] Received: {action}")
                    
                    response = await self.process_command(data)
                    await websocket.send(json.dumps(response))
                    
                except json.JSONDecodeError:
                    await websocket.send(json.dumps({"error": "Invalid JSON"}))
                    
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            self.connected_clients.discard(websocket)
            print(f"[WS] Client disconnected: {client_addr}")
    
    async def process_command(self, data):
        """Process commands from Flutter"""
        action = data.get("action", "")
        
        if action == "get_active_window":
            return {"type": "active_window", **self.get_active_window()}
            
        elif action == "get_running_apps":
            apps = self.get_running_apps()
            return {"type": "running_apps", "apps": apps}
            
        elif action == "block_app":
            process = data.get("process", "")
            if process:
                self.kill_process(process)
                return {"type": "app_blocked", "process": process, "success": True}
            return {"type": "error", "message": "No process specified"}
            
        elif action == "start_monitoring":
            self.study_mode_enabled = True
            self.blocked_apps = set(data.get("blocked_apps", []))
            self.is_monitoring = True
            print(f"[Agent] Study mode STARTED. Blocked: {self.blocked_apps}")
            return {"type": "monitoring_started", "blocked_apps": list(self.blocked_apps)}
            
        elif action == "stop_monitoring":
            self.study_mode_enabled = False
            self.is_monitoring = False
            print("[Agent] Study mode STOPPED")
            return {"type": "monitoring_stopped"}
            
        elif action == "get_usage":
            return {"type": "usage_summary", "apps": self.get_usage_summary()}
            
        elif action == "ping":
            return {"type": "pong", "timestamp": time.time()}
            
        else:
            return {"type": "error", "message": f"Unknown action: {action}"}
    
    async def monitoring_loop(self):
        """Background loop to monitor and block apps"""
        last_window = ""
        
        while True:
            try:
                current = self.get_active_window()
                
                # Track usage
                self.track_usage(current)
                
                # Broadcast window change
                window_sig = f"{current['process']}:{current['title']}"
                if window_sig != last_window:
                    last_window = window_sig
                    await self.broadcast({
                        "type": "active_window",
                        **current
                    })
                    print(f"[Monitor] Active: {current['process']} - {current['title'][:50]}")
                
                # Check and block if in study mode
                if self.study_mode_enabled:
                    blocked = self.check_and_block()
                    if blocked:
                        await self.broadcast({
                            "type": "app_blocked",
                            "process": current["process"]
                        })
                        
            except Exception as e:
                print(f"[Error] monitoring_loop: {e}")
                
            await asyncio.sleep(1)  # Check every second
    
    async def run_server(self, host="localhost", port=8765):
        """Start the WebSocket server"""
        print(f"[Agent] Starting WebSocket server on ws://{host}:{port}")
        
        async with websockets.serve(self.handle_client, host, port):
            print("[Agent] Server running. Waiting for Flutter connection...")
            await asyncio.Future()  # Run forever


async def main():
    agent = WindowsMonitorAgent()
    
    # Run both server and monitoring loop
    await asyncio.gather(
        agent.run_server(),
        agent.monitoring_loop()
    )


if __name__ == "__main__":
    print("=" * 50)
    print("EduGuardian Windows Monitoring Agent")
    print("=" * 50)
    asyncio.run(main())
