import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../models/health_content.dart';
import '../services/health_content_service.dart';

class HealthContentScreen extends StatefulWidget {
  final String contentId;

  const HealthContentScreen({
    Key? key,
    required this.contentId,
  }) : super(key: key);

  @override
  State<HealthContentScreen> createState() => _HealthContentScreenState();
}

class _HealthContentScreenState extends State<HealthContentScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _content;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final content = await context
          .read<HealthContentService>()
          .getHealthContentById(widget.contentId);

      if (content.type == ContentType.video && content.mediaUrl != null) {
        _videoController = VideoPlayerController.network(content.mediaUrl!);
        await _videoController!.initialize();
      } else if (content.type == ContentType.audio && content.mediaUrl != null) {
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setUrl(content.mediaUrl!);
      }

      // Check if this is first view before tracking
      final progress = await context
          .read<HealthContentService>()
          .getContentProgress(widget.contentId);
      final isFirstView = progress.isEmpty;

      // Track content progress (awards points if first view)
      await context
          .read<HealthContentService>()
          .trackContentProgress(widget.contentId);

      // Show points notification if first view
      if (isFirstView && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('You earned 5 points for reading this content!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }

      if (mounted) {
        setState(() {
          _content = {
            'title': content.title,
            'description': content.description,
            'content': content.content,
            'type': content.type.toString(),
            'mediaUrl': content.mediaUrl,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        // Show error snackbar after the frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Education'),
      ),
      body: FutureBuilder<HealthContent>(
        future: context
            .read<HealthContentService>()
            .getHealthContentById(widget.contentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final content = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  content.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildContentTypeWidget(content),
                const SizedBox(height: 24),
                Text(
                  content.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentTypeWidget(HealthContent content) {
    switch (content.type) {
      case ContentType.video:
        if (_videoController == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 48,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                    _isPlaying = !_isPlaying;
                  });
                },
              ),
            ],
          ),
        );

      case ContentType.audio:
        if (_audioPlayer == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            StreamBuilder<Duration?>(
              stream: _audioPlayer!.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _audioPlayer!.duration ?? Duration.zero;
                return Column(
                  children: [
                    Slider(
                      value: position.inMilliseconds.toDouble(),
                      max: duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        _audioPlayer!.seek(
                          Duration(milliseconds: value.toInt()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 48,
              ),
              onPressed: () {
                setState(() {
                  if (_isPlaying) {
                    _audioPlayer!.pause();
                  } else {
                    _audioPlayer!.play();
                  }
                  _isPlaying = !_isPlaying;
                });
              },
            ),
          ],
        );

      case ContentType.article:
        return const SizedBox.shrink();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 