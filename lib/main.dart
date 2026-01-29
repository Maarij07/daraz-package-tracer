import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daraz Packing Proof Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PackingProofDemoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PackingProofDemoScreen extends StatefulWidget {
  const PackingProofDemoScreen({super.key});

  @override
  State<PackingProofDemoScreen> createState() => _PackingProofDemoScreenState();
}

class _PackingProofDemoScreenState extends State<PackingProofDemoScreen> {
  bool _isRecording = false;
  String _invoiceNumber = '';
  bool _ocrInProgress = false;
  Timer? _ocrTimer;
  int _retryCount = 0;
  final int _maxRetries = 5;
  final TextEditingController _manualEntryController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    print('Demo app initialized');
  }

  void _startOCRProcess() {
    _ocrTimer?.cancel();
    _ocrTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isRecording && !_ocrInProgress && _retryCount < _maxRetries) {
        await _simulateOCRProcess();
      }
    });
  }

  Future<void> _simulateOCRProcess() async {
    if (_ocrInProgress) return;
    
    setState(() {
      _ocrInProgress = true;
      _retryCount++;
    });
    
    // Simulate OCR processing delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate OCR result (random success/failure)
    if (_retryCount >= 3 && _retryCount <= 4) { // Simulate successful detection on 3rd-4th try
      setState(() {
        _invoiceNumber = 'DRZ${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 15)}';
        _retryCount = 0;
      });
      Fluttertoast.showToast(
        msg: 'Invoice Detected: $_invoiceNumber',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
      );
    }
    
    setState(() {
      _ocrInProgress = false;
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _invoiceNumber = '';
      _retryCount = 0;
    });
    _startOCRProcess();
    
    Fluttertoast.showToast(
      msg: 'Recording started...',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    _ocrTimer?.cancel();
    
    setState(() {
      _isRecording = false;
    });
    
    // Simulate saving video
    final savedPath = await _simulateSaveVideo(); 
    
    // Show validation dialog
    if (_invoiceNumber.isEmpty) {
      _showValidationDialog(savedPath);
    } else {
      await _saveToExcel(_invoiceNumber, savedPath);
      Fluttertoast.showToast(
        msg: 'Recording saved successfully!',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<String> _simulateSaveVideo() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/packing_videos_demo');
    
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'packing_demo_$timestamp.mp4';
    final newPath = '${videoDir.path}/$fileName';
    
    // Create a dummy file
    final file = File(newPath);
    await file.writeAsString('Demo video recording placeholder');
    
    return newPath;
  }

  Future<void> _saveToExcel(String invoiceNumber, String videoPath) async {
    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);
      final time = DateFormat('HH:mm:ss').format(now);
      
      // Send to backend for Excel processing
      final uri = Uri.parse('http://localhost:8000/save_recording');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'date': date,
          'time': time,
          'invoice_number': invoiceNumber,
          'video_path': videoPath,
        }),
      );
      
      if (response.statusCode != 200) {
        print('Failed to save to Excel: ${response.body}');
      }
    } catch (e) {
      print('Error saving to Excel: $e');
    }
  }

  void _showValidationDialog(String videoPath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invoice Not Detected'),
          content: const Text('Not Clear, Please try again'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showManualEntryDialog(videoPath);
              },
              child: const Text('Manual Entry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Restart recording simulation
                _startRecording();
              },
              child: const Text('Record Again'),
            ),
          ],
        );
      },
    );
  }

  void _showManualEntryDialog(String videoPath) {
    _manualEntryController.clear();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Invoice Number'),
          content: TextField(
            controller: _manualEntryController,
            decoration: const InputDecoration(hintText: 'Enter order number'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final invoiceNum = _manualEntryController.text.trim();
                if (invoiceNum.isNotEmpty) {
                  Navigator.of(context).pop();
                  _saveToExcel(invoiceNum, videoPath);
                  Fluttertoast.showToast(
                    msg: 'Recording saved successfully!',
                    toastLength: Toast.LENGTH_SHORT,
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _ocrTimer?.cancel();
    _manualEntryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daraz Packing Proof Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Demo Camera View
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black87,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Simulated camera view
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[900]!,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_camera_front,
                            size: 80,
                            color: Colors.white38,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Camera Preview',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '(Demo Mode)',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // OCR Progress indicator
                  if (_ocrInProgress)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  
                  // Invoice display
                  if (_invoiceNumber.isNotEmpty)
                    Positioned(
                      top: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          'Invoice: $_invoiceNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Recording indicator
                  if (_isRecording)
                    const Positioned(
                      top: 20,
                      right: 20,
                      child: Icon(
                        Icons.fiber_manual_record,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Control Panel
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Start/Stop Button
                  FloatingActionButton.large(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    backgroundColor: _isRecording ? Colors.red : Colors.green,
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.videocam,
                      size: 32,
                    ),
                  ),
                  
                  // Status Indicator
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRecording ? 'Recording...' : 'Ready',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isRecording ? Colors.red : Colors.black,
                        ),
                      ),
                      if (_retryCount > 0)
                        Text(
                          'OCR Attempts: $_retryCount/$_maxRetries',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'Demo: Simulates OCR every 3 seconds',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}