import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import 'label_photo_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool _cameraGranted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _cameraGranted = status.isGranted;
        _checking = false;
      });
    }
  }

  Future<void> _startRecording() async {
    // Re-check permission before opening camera
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to record'),
              backgroundColor: AppColors.black,
            ),
          );
        }
        return;
      }
    }

    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null && mounted) {
      // Video recorded, now navigate to label photo screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LabelPhotoScreen(videoPath: video.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }

    if (!_cameraGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            const Text(
              'Camera access needed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.pureBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Grant camera permission to start recording package deliveries',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await Permission.camera.request();
                if (result.isPermanentlyDenied) {
                  openAppSettings();
                }
                _checkPermission();
              },
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.videocam,
              size: 48,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Record Package Delivery',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.pureBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Record a video of your delivery, then snap a photo of the package label',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 220,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.add, size: 22),
              label: const Text(
                'New Recording',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
