import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
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
        // Check if it's a YouTube video (ID or URL)
        if (_isYouTubeUrl(content.mediaUrl!)) {
          // YouTube videos will be handled by WebView or url_launcher
          // Don't initialize video controller for YouTube
        } else {
          // Regular video URL
          _videoController = VideoPlayerController.network(content.mediaUrl!);
          await _videoController!.initialize();
        }
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
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '🎉 You earned 5 points for reading this content!',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF4CAF50),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        });
      }

      if (mounted) {
        setState(() {
          // Content loaded, trigger rebuild
        });
      }
    } catch (e) {
      if (mounted) {
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        title: const Text(
          'Health Education',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: Implement bookmark functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<HealthContent>(
        future: context
            .read<HealthContentService>()
            .getHealthContentById(widget.contentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading content',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final content = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image/Media Section
                _buildMediaSection(content),
                
                // Content Section
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            content.category.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF00BCD4),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          content.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Description
                        Text(
                          content.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Divider
                        Container(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 24),
                        
                        // Content
                        Text(
                          content.content,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2C3E50),
                            height: 1.8,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Implement share
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Share feature coming soon!')),
                                  );
                                },
                                icon: const Icon(Icons.share_outlined),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BCD4),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement save for later
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Saved for later!')),
                                );
                              },
                              icon: const Icon(Icons.bookmark_border),
                              label: const Text('Save'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00BCD4),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF00BCD4),
                                  width: 1.5,
                                ),
                              ),
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
        },
      ),
    );
  }

  Widget _buildMediaSection(HealthContent content) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BCD4).withOpacity(0.8),
            const Color(0xFF00ACC1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildContentTypeWidget(content),
      ),
    );
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || 
           url.contains('youtu.be') || 
           (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(url));
  }

  String _getYouTubeEmbedUrl(String videoId) {
    // Extract video ID if it's a full URL
    String id = videoId;
    if (videoId.contains('youtube.com') || videoId.contains('youtu.be')) {
      final regExp = RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})');
      final match = regExp.firstMatch(videoId);
      if (match != null) {
        id = match.group(1)!;
      }
    }
    return 'https://www.youtube.com/watch?v=$id';
  }

  Widget _buildContentTypeWidget(HealthContent content) {
    switch (content.type) {
      case ContentType.video:
        // Check if it's a YouTube video
        if (content.mediaUrl != null && _isYouTubeUrl(content.mediaUrl!)) {
          // YouTube video - show embed button
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'YouTube Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = _getYouTubeEmbedUrl(content.mediaUrl!);
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch on YouTube'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00BCD4),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        } else if (_videoController == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                        _isPlaying = !_isPlaying;
                      });
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 40,
                        color: const Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case ContentType.audio:
        if (_audioPlayer == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.headphones,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              StreamBuilder<Duration?>(
                stream: _audioPlayer!.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = _audioPlayer!.duration ?? Duration.zero;
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble(),
                          max: duration.inMilliseconds > 0 
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            _audioPlayer!.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (_isPlaying) {
                        _audioPlayer!.pause();
                      } else {
                        _audioPlayer!.play();
                      }
                      _isPlaying = !_isPlaying;
                    });
                  },
                  borderRadius: BorderRadius.circular(36),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: const Color(0xFF00BCD4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case ContentType.article:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.article,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Article',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
