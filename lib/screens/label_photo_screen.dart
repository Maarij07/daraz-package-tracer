import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme/app_theme.dart';
import '../db/database_helper.dart';
import '../models/recording.dart';

class LabelPhotoScreen extends StatefulWidget {
  final String videoPath;

  const LabelPhotoScreen({super.key, required this.videoPath});

  @override
  State<LabelPhotoScreen> createState() => _LabelPhotoScreenState();
}

class _LabelPhotoScreenState extends State<LabelPhotoScreen> {
  String? _labelPhotoPath;
  String? _confirmedOrderNumber;
  bool _saving = false;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (photo != null && mounted) {
      setState(() {
        _labelPhotoPath = photo.path;
        _confirmedOrderNumber = null;
      });
      await _scanAndShowPopup(photo.path);
    }
  }

  Future<void> _scanAndShowPopup(String imagePath) async {
    // Show scanning dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.orange,
              ),
            ),
            SizedBox(width: 20),
            Text('Scanning label...'),
          ],
        ),
      ),
    );

    String? orderNumber;
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      orderNumber = _findOrderNumber(recognizedText.text);
    } catch (_) {
      // OCR failed, let user enter manually
    }

    if (!mounted) return;
    // Dismiss scanning dialog
    Navigator.of(context).pop();

    // Show order number popup
    _showOrderNumberPopup(orderNumber);
  }

  String? _findOrderNumber(String text) {
    // Look for text right after "Order Number" on the label
    final patterns = [
      // "Order Number" followed by value (next line or after colon/space)
      RegExp(r'order\s*number[\s:]*([A-Z0-9]{6,25})', caseSensitive: false),
      // "Order No" / "Order #" followed by value
      RegExp(r'order\s*(?:#|no\.?)[\s:]*([A-Z0-9]{6,25})', caseSensitive: false),
      // "Order" followed by a long number
      RegExp(r'order[\s:]+(\d{6,20})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }
    return null;
  }

  void _showOrderNumberPopup(String? detectedNumber) {
    final controller = TextEditingController(text: detectedNumber ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              detectedNumber != null ? Icons.check_circle : Icons.edit,
              color: detectedNumber != null ? Colors.green : AppColors.orange,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              detectedNumber != null ? 'Order Number Found' : 'Enter Order Number',
              style: const TextStyle(fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detectedNumber != null)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'You can edit the order number if needed',
                  style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Could not detect order number. Please enter it manually.',
                  style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
                ),
              ),
            TextField(
              controller: controller,
              autofocus: detectedNumber == null,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                labelText: 'Order Number',
                labelStyle: const TextStyle(color: AppColors.darkGrey),
                hintText: 'e.g. 3204857291064',
                filled: true,
                fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.orange, width: 2),
                ),
                prefixIcon: const Icon(Icons.tag, color: AppColors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Reset and retake
              setState(() {
                _labelPhotoPath = null;
                _confirmedOrderNumber = null;
              });
              _takePhoto();
            },
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Retake Image'),
            style: TextButton.styleFrom(foregroundColor: AppColors.darkGrey),
          ),
          ElevatedButton(
            onPressed: () {
              final orderNum = controller.text.trim();
              if (orderNum.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an order number'),
                    backgroundColor: AppColors.black,
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              setState(() {
                _confirmedOrderNumber = orderNum;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecording() async {
    setState(() => _saving = true);

    try {
      // Copy files to permanent app storage
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(p.join(appDir.path, 'recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoExt = p.extension(widget.videoPath);
      final photoExt = p.extension(_labelPhotoPath!);
      final savedVideo = await File(widget.videoPath)
          .copy(p.join(recordingsDir.path, 'video_$timestamp$videoExt'));
      final savedPhoto = await File(_labelPhotoPath!)
          .copy(p.join(recordingsDir.path, 'photo_$timestamp$photoExt'));

      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final recording = Recording(
        orderNumber: _confirmedOrderNumber!,
        date: date,
        time: time,
        videoPath: savedVideo.path,
        photoPath: savedPhoto.path,
      );

      await DatabaseHelper().insertRecording(recording);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording saved successfully!'),
            backgroundColor: AppColors.black,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Label Photo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Video recorded banner
            _buildVideoBanner(),
            const SizedBox(height: 16),

            // Confirmed order number card
            if (_confirmedOrderNumber != null) _buildOrderNumberCard(),

            const SizedBox(height: 16),

            // Heading when no photo taken yet
            if (_labelPhotoPath == null) ...[
              const Text(
                'Now take a photo of the package label',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pureBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'ll automatically extract the order number',
                style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
              ),
              const SizedBox(height: 20),
            ],

            // Photo preview or capture prompt
            Expanded(
              child: _labelPhotoPath != null
                  ? _buildPhotoPreview()
                  : _buildCapturePrompt(),
            ),
            const SizedBox(height: 16),

            // Bottom actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video Recorded',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  widget.videoPath.split('/').last,
                  style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNumberCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag, color: AppColors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Number',
                  style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                ),
                const SizedBox(height: 2),
                Text(
                  _confirmedOrderNumber!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                    color: AppColors.pureBlack,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showOrderNumberPopup(_confirmedOrderNumber),
            child: const Icon(Icons.edit, color: AppColors.orange, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_labelPhotoPath!), fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.pureBlack.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Label Photo',
                    style: TextStyle(color: AppColors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturePrompt() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 56, color: AppColors.orange),
              SizedBox(height: 16),
              Text(
                'Tap to capture label photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGrey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Order number will be extracted automatically',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_confirmedOrderNumber != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _saveRecording,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'Saving...' : 'Save Recording'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _takePhoto,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Take Label Photo'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
