#!/bin/bash

echo "========================================"
echo "Hand Sign Recognition API"
echo "========================================"
echo ""

# Check if model exists
if [ ! -f "model/hand_sign_model.keras" ]; then
    echo "❌ ERROR: Model file not found!"
    echo "Please place your .keras model in backend/model/"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo ""
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt
echo ""

# Get local IP
echo "Your computer's IP address:"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    ipconfig getifaddr en0
else
    # Linux
    hostname -I | awk '{print $1}'
fi
echo ""
echo "Use this IP in your Flutter app's api_service.dart"
echo "Example: http://192.168.1.100:8000"
echo ""
echo "========================================"
echo "Starting server..."
echo "========================================"
echo ""

# Run server
python3 main.py