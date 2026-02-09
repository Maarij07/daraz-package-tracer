import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String orderNumber;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
    required this.orderNumber,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
    _controller.setLooping(false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        title: Text('Order ${widget.orderNumber}'),
      ),
      body: _hasError
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load video',
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : !_initialized
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    // Controls
                    Container(
                      color: AppColors.pureBlack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: _controller,
                            builder: (context, value, child) {
                              return Column(
                                children: [
                                  SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: AppColors.orange,
                                      inactiveTrackColor: AppColors.darkGrey,
                                      thumbColor: AppColors.orange,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 14,
                                      ),
                                    ),
                                    child: Slider(
                                      value: value.position.inMilliseconds
                                          .toDouble()
                                          .clamp(
                                            0,
                                            value.duration.inMilliseconds
                                                .toDouble(),
                                          ),
                                      max: value.duration.inMilliseconds
                                          .toDouble()
                                          .clamp(1, double.infinity),
                                      onChanged: (v) {
                                        _controller.seekTo(
                                          Duration(milliseconds: v.toInt()),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(value.position),
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(value.duration),
                                          style: const TextStyle(
                                            color: AppColors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10),
                                color: AppColors.white,
                                iconSize: 32,
                                onPressed: () {
                                  final pos = _controller.value.position;
                                  _controller.seekTo(
                                    pos - const Duration(seconds: 10),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: _controller,
                                builder: (context, value, child) {
                                  return IconButton(
                                    icon: Icon(
                                      value.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                    ),
                                    color: AppColors.orange,
                                    iconSize: 56,
                                    onPressed: () {
                                      if (value.isPlaying) {
                                        _controller.pause();
                                      } else {
                                        _controller.play();
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.forward_10),
                                color: AppColors.white,
                                iconSize: 32,
                                onPressed: () {
                                  final pos = _controller.value.position;
                                  _controller.seekTo(
                                    pos + const Duration(seconds: 10),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
