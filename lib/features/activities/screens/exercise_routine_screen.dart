import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../activity_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/activity_service.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ExerciseRoutineScreen extends StatefulWidget {
  final Activity activity;
  const ExerciseRoutineScreen({Key? key, required this.activity}) : super(key: key);

  @override
  State<ExerciseRoutineScreen> createState() => _ExerciseRoutineScreenState();
}

class _ExerciseRoutineScreenState extends State<ExerciseRoutineScreen> with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleted = false;
  late AnimationController _animationController;
  String _currentPhase = 'Ready';
  int _currentStep = 0;
  List<String> _instructions = [];
  int? _effectiveDurationSeconds;

  @override
  void initState() {
    super.initState();
    _effectiveDurationSeconds = _computeEffectiveDurationSeconds();
    _remainingSeconds = _effectiveDurationSeconds!;
    _parseInstructions();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _parseInstructions() {
    final content = widget.activity.content;
    if (content['instructions'] != null) {
      _instructions = (content['instructions'] as String)
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
    }
  }

  int _difficultyToMinSeconds() {
    // Base mins per difficulty for elder-friendly short routines
    switch (widget.activity.difficulty.toLowerCase()) {
      case 'easy':
        return 4 * 60; // 4-6 mins
      case 'medium':
        return 6 * 60; // 6-8 mins
      case 'hard':
        return 8 * 60; // 8-9 mins
      default:
        return 5 * 60;
    }
  }

  int _difficultyToMaxSeconds() {
    switch (widget.activity.difficulty.toLowerCase()) {
      case 'easy':
        return 6 * 60;
      case 'medium':
        return 8 * 60;
      case 'hard':
        return 9 * 60; // keep < 10
      default:
        return 7 * 60;
    }
  }

  int _computeEffectiveDurationSeconds() {
    if (widget.activity.type.toLowerCase() != 'physical') {
      return widget.activity.duration * 60;
    }
    final minS = _difficultyToMinSeconds();
    final maxS = _difficultyToMaxSeconds();
    final seed = DateTime.now().millisecondsSinceEpoch;
    final span = (maxS - minS).clamp(0, 10 * 60);
    final rand = (seed % (span == 0 ? 1 : span));
    final value = minS + rand;
    // Ensure strictly < 10 mins
    return value.clamp(60, (10 * 60) - 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _currentPhase = 'Exercise';
      _animationController.repeat(reverse: true);
    });
    // Mark activity started so completion can use actual startedAt
    context.read<ActivityBloc>().add(StartActivity(widget.activity.id));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeRoutine();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _animationController.stop();
    setState(() {
      _isRunning = false;
      _currentPhase = 'Paused';
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _animationController.reset();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _effectiveDurationSeconds = _computeEffectiveDurationSeconds();
      _remainingSeconds = _effectiveDurationSeconds!;
      _currentPhase = 'Ready';
      _currentStep = 0;
    });
  }

  Future<void> _completeRoutine() async {
    try {
      if (_isRunning) {
        _timer?.cancel();
      }
      
      setState(() {
        _isRunning = false;
        _isCompleted = true;
      });

      // Show completion dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Exercise Completed!'),
          content: Text('You\'ve earned ${widget.activity.points} points!'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  // Complete the activity
                  final newAchievements = await context
                      .read<ActivityService>()
                      .completeActivity(widget.activity.id);

                  if (!mounted) return;

                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Activity completed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  // Show achievements if any were unlocked
                  if (newAchievements.isNotEmpty) {
                    for (var achievement in newAchievements) {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Achievement Unlocked!'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Display emoji instead of Material Icon
                              Text(
                                achievement.icon,
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                achievement.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(achievement.description),
                              const SizedBox(height: 8),
                              Text(
                                '+${achievement.points} points',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Awesome!'),
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  // Navigate back to activities page
                  if (!mounted) return;
                  context.go('/activities');
                } catch (e) {
                  debugPrint('Error completing activity: $e');
                  if (!mounted) return;
                  
                  String errorMessage = 'Error completing activity';
                  if (e.toString().contains('permissions')) {
                    errorMessage = 'Activity completed! Health data unavailable due to permissions.';
                  } else {
                    errorMessage = 'Error completing activity: ${e.toString()}';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: e.toString().contains('permissions') ? Colors.orange : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Okay'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error in _completeRoutine: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isRunning) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exit Exercise?'),
                  content: const Text('Are you sure you want to exit? Your progress will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.activity.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.activity.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            if ((widget.activity.content)['videoUrl'] != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _VideoTutorial(url: (widget.activity.content)['videoUrl'] as String),
              ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(widget.activity.type),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${widget.activity.difficulty}'),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${widget.activity.points} points'),
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPhase,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                          label: Text(_isRunning ? 'Pause' : 'Start'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _resetTimer,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _remainingSeconds == 0 && !_isCompleted ? _completeRoutine : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Complete'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _instructions.length,
                      itemBuilder: (context, index) {
                        final isCurrentStep = index == _currentStep;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrentStep
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            _instructions[index],
                            style: TextStyle(
                              fontWeight: isCurrentStep ? FontWeight.bold : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 

class _VideoTutorial extends StatelessWidget {
  final String url;
  const _VideoTutorial({required this.url});

  Future<void> _openUrl() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openUrl,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.play_circle_fill, size: 64, color: Colors.black54),
            Positioned(
              bottom: 8,
              right: 8,
              left: 8,
              child: Text(
                'Tap to open tutorial video',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}