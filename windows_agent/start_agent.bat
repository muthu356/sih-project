@echo off
echo ========================================
echo EduGuardian Windows Agent Setup
echo ========================================

echo Installing Python dependencies...
pip install -r requirements.txt

echo.
echo Starting agent...
python agent.py

pause
