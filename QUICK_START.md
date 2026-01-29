# Quick Start Guide

## 1. Start Backend Server

**Windows:**
```cmd
cd backend
setup_backend.bat
```

**Linux/macOS:**
```bash
cd backend
chmod +x setup_backend.sh
./setup_backend.sh
```

Or manually:
```bash
cd backend
pip install -r requirements.txt
python main.py
```

## 2. Run Flutter App

In a new terminal:
```bash
flutter pub get
flutter run
```

## 3. Usage Flow

1. Grant camera and storage permissions when prompted
2. Point camera at Daraz invoice
3. Press GREEN "Record" button to start
4. Keep recording while packaging items
5. App will automatically detect invoice numbers (shown at top)
6. Press RED "Stop" button when done
7. If invoice not detected, choose:
   - **Manual Entry**: Type invoice number
   - **Record Again**: Retake video

## 4. Output Files

- Videos saved to: `<app_documents>/packing_videos/`
- Excel log: `backend/recordings/packing_recordings.xlsx`

## Need Help?

Check `README_APP.md` for detailed documentation.
