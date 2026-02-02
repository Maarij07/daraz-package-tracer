import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daraz Packing Proof',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _children = [
    const RecordingScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isRecording = false;
  String _invoiceNumber = '';
  String _savedVideoPath = '';
  bool _showCaptureScreen = false;
  final TextEditingController _manualEntryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('App initialized - ready to record');
  }

  @override
  void dispose() {
    _manualEntryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daraz Packing Proof'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _showCaptureScreen 
        ? _buildCaptureScreen() 
        : _buildRecordingScreen(),
    );
  }

  Widget _buildRecordingScreen() {
    return Column(
      children: [
        // Camera Preview Area
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.black87,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera view placeholder
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
                          'Point at packaging area',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                // Record Button
                FloatingActionButton.large(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    size: 32,
                  ),
                ),
                
                // Status
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRecording ? 'Recording...' : 'Ready to Record',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isRecording ? Colors.red : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Press button to start/stop recording',
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
    );
  }

  Widget _buildCaptureScreen() {
    return Column(
      children: [
        // Capture Preview Area
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.black87,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Capture view
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blueGrey[800]!,
                        Colors.blueGrey[900]!,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(
                        Icons.camera_alt,
                        size: 80,
                        color: Colors.white38,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Capture Order Image',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Point camera at order invoice',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Invoice display if captured
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
              ],
            ),
          ),
        ),
        
        // Capture Controls
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Capture Button
                    FloatingActionButton.large(
                      onPressed: _invoiceNumber.isEmpty 
                        ? () => _captureAndProcessImage()
                        : null,
                      backgroundColor: _invoiceNumber.isEmpty ? Colors.blue : Colors.grey,
                      child: const Icon(
                        Icons.camera,
                        size: 32,
                      ),
                    ),
                    
                    // Back to Recording
                    if (_invoiceNumber.isEmpty)
                      FloatingActionButton.large(
                        onPressed: () {
                          setState(() {
                            _showCaptureScreen = false;
                            _isRecording = false;
                          });
                        },
                        backgroundColor: Colors.orange,
                        child: const Icon(
                          Icons.refresh,
                          size: 32,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _invoiceNumber.isEmpty 
                    ? 'Capture order invoice image' 
                    : 'Recording completed successfully!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _invoiceNumber.isEmpty ? Colors.black : Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _invoiceNumber = '';
      _showCaptureScreen = false;
    });
    
    Fluttertoast.showToast(
      msg: 'Recording started...',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    setState(() {
      _isRecording = false;
    });
    
    // Save video
    _savedVideoPath = await _saveVideo();
    
    // Show capture screen
    setState(() {
      _showCaptureScreen = true;
    });
    
    Fluttertoast.showToast(
      msg: 'Recording stopped. Please capture order image.',
      toastLength: Toast.LENGTH_LONG,
    );
  }

  Future<String> _saveVideo() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/packing_videos');
    
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'packing_$timestamp.mp4';
    final newPath = '${videoDir.path}/$fileName';
    
    // Create a dummy file (will be replaced with real video)
    final file = File(newPath);
    await file.writeAsString('Video recording placeholder');
    
    return newPath;
  }

  Future<String> _saveImage() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/packing_images');
    
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'order_$timestamp.jpg';
    final newPath = '${imageDir.path}/$fileName';
    
    // Create a dummy file (will be replaced with real image)
    final file = File(newPath);
    await file.writeAsString('Order image placeholder');
    
    return newPath;
  }

  Future<void> _captureAndProcessImage() async {
    // Save image first
    final imagePath = await _saveImage();
    
    // Simulate image capture and processing
    Fluttertoast.showToast(
      msg: 'Capturing image...',
      toastLength: Toast.LENGTH_SHORT,
    );
    
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate OCR result (50% success rate)
    if (DateTime.now().millisecond % 2 == 0) {
      // Success case
      final simulatedInvoice = 'DRZ${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 15)}';
      setState(() {
        _invoiceNumber = simulatedInvoice;
      });
      
      await _saveLocally(_invoiceNumber, _savedVideoPath, imagePath);
      Fluttertoast.showToast(
        msg: 'Invoice Detected: $_invoiceNumber',
        toastLength: Toast.LENGTH_LONG,
      );
    } else {
      // Failure case - blurry image
      _showValidationDialog();
    }
  }

  void _showValidationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invoice Not Detected'),
          content: const Text('Image is blurry or order number not visible'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showManualEntryDialog();
              },
              child: const Text('Manual Entry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retake image
                setState(() {
                  _showCaptureScreen = true;
                });
              },
              child: const Text('Retake Image'),
            ),
          ],
        );
      },
    );
  }

  void _showManualEntryDialog() {
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
                  _saveImage().then((imagePath) {
                    setState(() {
                      _invoiceNumber = invoiceNum;
                      _showCaptureScreen = false;
                    });
                    _saveLocally(invoiceNum, _savedVideoPath, imagePath);
                    Fluttertoast.showToast(
                      msg: 'Recording saved successfully!',
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLocally(String invoiceNumber, String videoPath, String imagePath) async {
    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);
      final time = DateFormat('HH:mm:ss').format(now);
      
      // Create a local record in JSON
      final appDir = await getApplicationDocumentsDirectory();
      final recordsFile = File('${appDir.path}/records.json');
      
      List<dynamic> existingRecords = [];
      if (await recordsFile.exists()) {
        final content = await recordsFile.readAsString();
        existingRecords = json.decode(content);
      }
      
      final newRecord = {
        'date': date,
        'time': time,
        'invoice_number': invoiceNumber,
        'video_path': videoPath,
        'image_path': imagePath,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      existingRecords.add(newRecord);
      
      await recordsFile.writeAsString(json.encode(existingRecords));
      
      Fluttertoast.showToast(
        msg: 'Recording saved locally!',
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      print('Error saving locally: $e');
    }
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load from local storage
      await _loadLocalRecordings();
    } catch (e) {
      print('Error loading recordings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocalRecordings() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordsFile = File('${appDir.path}/records.json');
      
      if (await recordsFile.exists()) {
        final content = await recordsFile.readAsString();
        final data = json.decode(content);
        setState(() {
          _recordings = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      print('Error loading local recordings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _recordings.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Start recording to see history here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRecordings,
              child: ListView.builder(
                itemCount: _recordings.length,
                itemBuilder: (context, index) {
                  final recording = _recordings[index];
                  return RecordingItem(
                    recording: recording,
                    onTap: () => _showRecordingDetails(recording),
                  );
                },
              ),
            ),
    );
  }

  void _showRecordingDetails(Map<String, dynamic> recording) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recording Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _DetailRow('Date', recording['date'] ?? 'N/A'),
              _DetailRow('Time', recording['time'] ?? 'N/A'),
              _DetailRow('Invoice', recording['invoice_number'] ?? 'N/A'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _playVideo(recording['video_path'] ?? '');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('View Video'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _viewImage(recording['image_path'] ?? '');
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('View Image'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _playVideo(String videoPath) {
    // Video playback implementation
    Fluttertoast.showToast(
      msg: 'Video playback would open here\nPath: $videoPath',
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void _viewImage(String imagePath) {
    // Image viewing implementation
    Fluttertoast.showToast(
      msg: 'Image viewer would open here\nPath: $imagePath',
      toastLength: Toast.LENGTH_LONG,
    );
  }
}

class RecordingItem extends StatelessWidget {
  final Map<String, dynamic> recording;
  final VoidCallback onTap;

  const RecordingItem({
    super.key,
    required this.recording,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          recording['invoice_number'] ?? 'Unknown Invoice',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${recording['date'] ?? 'N/A'}'),
            Text('Time: ${recording['time'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Video',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.image, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Order Image',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}