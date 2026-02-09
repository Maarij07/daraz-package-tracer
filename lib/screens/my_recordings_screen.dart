import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database_helper.dart';
import '../models/recording.dart';
import 'video_player_screen.dart';

class MyRecordingsScreen extends StatefulWidget {
  const MyRecordingsScreen({super.key});

  @override
  State<MyRecordingsScreen> createState() => _MyRecordingsScreenState();
}

class _MyRecordingsScreenState extends State<MyRecordingsScreen> {
  List<Recording> _recordings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    final recordings = await DatabaseHelper().getAllRecordings();
    if (mounted) {
      setState(() {
        _recordings = recordings;
        _loading = false;
      });
    }
  }

  void _showPhotoPreview(String photoPath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.file(File(photoPath), fit: BoxFit.cover),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecording(Recording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text('Delete recording for order ${recording.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && recording.id != null) {
      await DatabaseHelper().deleteRecording(recording.id!);
      // Delete files
      try {
        final videoFile = File(recording.videoPath);
        final photoFile = File(recording.photoPath);
        if (await videoFile.exists()) await videoFile.delete();
        if (await photoFile.exists()) await photoFile.delete();
      } catch (_) {}
      _loadRecordings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }

    if (_recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library,
                size: 40,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Recordings Yet',
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
                'Your recorded package deliveries will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: _loadRecordings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.video_library, color: AppColors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_recordings.length} Recording${_recordings.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pureBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                columnWidths: const {
                  0: FixedColumnWidth(40),  // S#
                  1: FlexColumnWidth(2),    // Order Number
                  2: FlexColumnWidth(1.3),  // Date
                  3: FlexColumnWidth(1),    // Time
                  4: FixedColumnWidth(44),  // Photo
                  5: FixedColumnWidth(44),  // Video
                  6: FixedColumnWidth(44),  // Delete
                },
                children: [
                  // Header row
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.pureBlack),
                    children: [
                      _headerCell('#'),
                      _headerCell('Order No.'),
                      _headerCell('Date'),
                      _headerCell('Time'),
                      _headerCell('Pic'),
                      _headerCell('Vid'),
                      _headerCell(''),
                    ],
                  ),
                  // Data rows
                  for (int i = 0; i < _recordings.length; i++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: i.isEven ? AppColors.white : AppColors.offWhite,
                      ),
                      children: [
                        _dataCell('${i + 1}', center: true),
                        _dataCell(_recordings[i].orderNumber, mono: true),
                        _dataCell(_recordings[i].date),
                        _dataCell(_recordings[i].time),
                        _iconCell(
                          Icons.image,
                          AppColors.orange,
                          () => _showPhotoPreview(_recordings[i].photoPath),
                        ),
                        _iconCell(
                          Icons.play_circle_fill,
                          AppColors.orange,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                videoPath: _recordings[i].videoPath,
                                orderNumber: _recordings[i].orderNumber,
                              ),
                            ),
                          ),
                        ),
                        _iconCell(
                          Icons.delete_outline,
                          Colors.red,
                          () => _deleteRecording(_recordings[i]),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _dataCell(String text, {bool center = false, bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontFamily: mono ? 'monospace' : null,
          fontWeight: mono ? FontWeight.w600 : FontWeight.normal,
          color: AppColors.pureBlack,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _iconCell(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
