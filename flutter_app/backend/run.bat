@echo off
echo ========================================
echo Hand Sign Recognition API
echo ========================================
echo.

:: Check if model exists
if not exist "model\hand_sign_model.keras" (
    echo ❌ ERROR: Model file not found!
    echo Please place your .keras model in backend\model\
    pause
    exit
)

:: Check if virtual environment exists
if not exist "venv\" (
    echo Creating virtual environment...
    python -m venv venv
    echo.
)

:: Activate virtual environment
call venv\Scripts\activate.bat

:: Install dependencies
echo Installing dependencies...
pip install -r requirements.txt
echo.

:: Get local IP
echo Your computer's IP addresses:
ipconfig | findstr /R /C:"IPv4 Address"
echo.
echo Use one of these IPs in your Flutter app's api_service.dart
echo Example: http://192.168.1.100:8000
echo.
echo ========================================
echo Starting server...
echo ========================================
echo.

:: Run server
python main.py