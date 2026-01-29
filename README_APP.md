# Daraz Packing Proof Recorder

A Flutter mobile app for recording packing proof videos with automatic OCR-based invoice detection for Daraz orders.

## Features

- **Continuous Video Recording**: Start recording with one tap, stop when done
- **Automatic OCR Detection**: Captures invoice/order numbers every 3 seconds during recording
- **Smart Text Extraction**: Identifies order numbers near "Order Number" text
- **Persistent Storage**: Videos saved with timestamped filenames
- **Excel Logging**: Automatic logging of date, time, invoice number, and video path
- **Validation System**: Alerts for unclear invoices with manual entry fallback
- **Retry Logic**: Multiple OCR attempts before requiring manual input

## Setup Instructions

### 1. Flutter App Setup

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 2. Backend Setup (Python/FastAPI)

#### Install Tesseract OCR:
- **Windows**: Download from [Tesseract GitHub](https://github.com/UB-Mannheim/tesseract/wiki)
- **macOS**: `brew install tesseract`
- **Linux**: `sudo apt-get install tesseract-ocr`

#### Install Python dependencies:
```bash
cd backend
pip install -r requirements.txt
```

#### Run the backend:
```bash
python main.py
```

Backend will run on `http://localhost:8000`

### 3. Permissions Required

The app requires:
- Camera permission
- Storage permission

These are requested automatically on first launch.

## How It Works

1. **Start Recording**: Press the green record button to begin video capture
2. **OCR Processing**: Every 3 seconds, the app captures a frame and processes it with OCR
3. **Invoice Detection**: Looks for text near "Order Number" and extracts alphanumeric codes
4. **Real-time Display**: Detected invoice numbers appear at the top of the screen
5. **Stop Recording**: Press the red stop button to finish recording
6. **Validation**: 
   - If invoice detected → Automatically saves to Excel
   - If not detected → Shows "Not Clear, Please try again" alert with options:
     - Manual Entry: Enter invoice number manually
     - Record Again: Delete current recording and start over

## File Structure

```
taimoor_app/
├── lib/
│   └── main.dart           # Main Flutter app
├── backend/
│   ├── main.py            # FastAPI backend with OCR
│   └── requirements.txt   # Python dependencies
├── recordings/             # Created automatically for Excel files
└── app_videos/            # Created automatically for saved videos
```

## API Endpoints

- `POST /process_invoice` - Process image with OCR
- `POST /save_recording` - Save recording metadata to Excel
- `GET /health` - Health check

## Customization

### OCR Settings
Modify in `backend/main.py`:
```python
custom_config = r'--oem 3 --psm 6'  # Tesseract configuration
```

### Retry Logic
Adjust in `lib/main.dart`:
```dart
final int _maxRetries = 5;  // Maximum OCR attempts
const Duration(seconds: 3)  // OCR interval
```

## Troubleshooting

1. **OCR Not Working**: Ensure Tesseract is properly installed and in PATH
2. **Permission Errors**: Grant camera and storage permissions in app settings
3. **Backend Connection**: Make sure FastAPI server is running on port 8000
4. **Blurry Detection**: Improve lighting or adjust camera position

## Data Storage

- **Videos**: Stored in app documents directory under `/packing_videos/`
- **Excel Logs**: Stored in `/recordings/packing_recordings.xlsx`
- **Format**: Date, Time, Invoice Number, Video Path, Timestamp
