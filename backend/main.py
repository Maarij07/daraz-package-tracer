from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pytesseract
import cv2
import pandas as pd
from PIL import Image
import io
import os
from datetime import datetime
import json
import numpy as np
import re

app = FastAPI(title="Daraz Packing Proof OCR")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure Tesseract is installed and in PATH
# For Windows: Download from https://github.com/UB-Mannheim/tesseract/wiki
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

@app.post("/process_invoice")
async def process_invoice(image: UploadFile = File(...)):
    """
    Process uploaded image with OCR to extract invoice/order information
    """
    try:
        # Read image file
        contents = await image.read()
        image_stream = io.BytesIO(contents)
        pil_image = Image.open(image_stream)
        
        # Convert PIL image to OpenCV format
        opencv_image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
        
        # Preprocess image for better OCR
        gray = cv2.cvtColor(opencv_image, cv2.COLOR_BGR2GRAY)
        
        # Apply threshold to get image with only black and white
        _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Denoise
        denoised = cv2.medianBlur(thresh, 3)
        
        # Perform OCR
        custom_config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(denoised, config=custom_config)
        
        # Extract invoice number
        invoice_number = extract_invoice_number(text)
        
        return {
            "text": text, 
            "success": True,
            "invoice_number": invoice_number
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR processing failed: {str(e)}")

@app.post("/process_single_image")
async def process_single_image(data: dict):
    """
    Process single image file for OCR extraction
    """
    try:
        image_path = data.get('image_path')
        if not image_path or not os.path.exists(image_path):
            raise HTTPException(status_code=400, detail="Image file not found")
        
        # Read image file
        pil_image = Image.open(image_path)
        
        # Convert PIL image to OpenCV format
        opencv_image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
        
        # Preprocess image for better OCR
        gray = cv2.cvtColor(opencv_image, cv2.COLOR_BGR2GRAY)
        
        # Apply threshold
        _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Denoise
        denoised = cv2.medianBlur(thresh, 3)
        
        # Perform OCR
        custom_config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(denoised, config=custom_config)
        
        # Extract invoice number
        invoice_number = extract_invoice_number(text)
        
        return {
            "text": text,
            "success": invoice_number is not None,
            "invoice_number": invoice_number
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR processing failed: {str(e)}")

@app.post("/save_recording")
async def save_recording(data: dict):
    """
    Save recording metadata to Excel file
    """
    try:
        # Create recordings directory if it doesn't exist
        recordings_dir = "recordings"
        if not os.path.exists(recordings_dir):
            os.makedirs(recordings_dir)
            
        # Excel file path
        excel_file = os.path.join(recordings_dir, "packing_recordings.xlsx")
        
        # Create DataFrame with new entry
        new_entry = pd.DataFrame([{
            "Date": data.get("date", ""),
            "Time": data.get("time", ""),
            "Invoice Number": data.get("invoice_number", ""),
            "Video Path": data.get("video_path", ""),
            "Image Path": data.get("image_path", ""),
            "Timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }])
        
        # Save to JSON as backup
        json_file = os.path.join(recordings_dir, "recordings.json")
        all_recordings = []
        if os.path.exists(json_file):
            try:
                with open(json_file, 'r') as f:
                    all_recordings = json.load(f)
            except:
                pass
        
        all_recordings.append({
            "date": data.get("date", ""),
            "time": data.get("time", ""),
            "invoice_number": data.get("invoice_number", ""),
            "video_path": data.get("video_path", ""),
            "image_path": data.get("image_path", ""),
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })
        
        with open(json_file, 'w') as f:
            json.dump(all_recordings, f, indent=2)
        
        # If file exists, append to it; otherwise create new file
        if os.path.exists(excel_file):
            try:
                existing_df = pd.read_excel(excel_file)
                combined_df = pd.concat([existing_df, new_entry], ignore_index=True)
            except:
                combined_df = new_entry
        else:
            combined_df = new_entry
            
        combined_df.to_excel(excel_file, index=False)
        return {"success": True, "message": "Recording saved to Excel"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save recording: {str(e)}")

@app.get("/get_recordings")
async def get_recordings():
    """
    Get all recordings metadata
    """
    try:
        recordings_dir = "recordings"
        json_file = os.path.join(recordings_dir, "recordings.json")
        
        recordings = []
        if os.path.exists(json_file):
            with open(json_file, 'r') as f:
                recordings = json.load(f)
        
        return {"recordings": recordings, "count": len(recordings)}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load recordings: {str(e)}")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

def extract_invoice_number(text):
    """
    Extract invoice/order number from OCR text
    Looks for patterns near "Order Number" text
    """
    lines = text.split('\n')
    
    for i, line in enumerate(lines):
        # Look for "Order Number" text
        if 'order' in line.lower() and ('number' in line.lower() or 'no' in line.lower()):
            # Check nearby lines for alphanumeric codes
            for j in range(max(0, i-2), min(len(lines), i+3)):
                potential_invoice = lines[j].strip()
                # Look for Daraz-like invoice patterns
                if re.match(r'^[A-Z0-9]{7,15}$', potential_invoice) and not potential_invoice.isalpha():
                    return potential_invoice
    
    return None

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
