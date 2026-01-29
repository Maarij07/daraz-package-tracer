@echo off
echo Installing Python dependencies...
pip install -r requirements.txt

echo.
echo Starting FastAPI backend server...
echo Server will be available at http://localhost:8000
echo Press Ctrl+C to stop the server
echo.

python main.py
