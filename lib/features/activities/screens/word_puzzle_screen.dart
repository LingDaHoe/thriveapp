import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/word_puzzle.dart';
import '../blocs/word_puzzle_bloc.dart';
import '../services/activity_service.dart';
import 'package:go_router/go_router.dart';

class WordPuzzleScreen extends StatefulWidget {
  final String activityId;

  const WordPuzzleScreen({
    super.key,
    required this.activityId,
  });

  @override
  State<WordPuzzleScreen> createState() => _WordPuzzleScreenState();
}

class _WordPuzzleScreenState extends State<WordPuzzleScreen> {
  late WordPuzzle _puzzle;
  final TextEditingController _wordController = TextEditingController();
  bool _isProcessing = false;
  int _totalPoints = 0;
  bool _loadingPoints = true;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
    _fetchTotalPoints();
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  void _onWordSubmitted(String word) {
    if (_isProcessing) return;

    setState(() {
      _puzzle.addFoundWord(word.toUpperCase());
    });

    _wordController.clear();

    if (_puzzle.isCompleted) {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Words Found: ${_puzzle.foundWords.length}/${_puzzle.words.length}'),
            Text('Time: ${_puzzle.duration.inSeconds} seconds'),
            Text('Score: ${_puzzle.score}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to activities
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _puzzle = WordPuzzle.create();
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    ).then((_) {
      // Save game results when dialog is closed
      context.read<WordPuzzleBloc>().add(
            CompleteWordPuzzle(
              activityId: widget.activityId,
              score: _puzzle.score,
              wordsFound: _puzzle.foundWords.length,
              duration: _puzzle.duration,
            ),
          );
    });
  }

  Future<void> _fetchTotalPoints() async {
    final activityService = context.read<ActivityService>();
    try {
      final points = await activityService.getTotalPoints();
      setState(() {
        _totalPoints = points;
        _loadingPoints = false;
      });
    } catch (e) {
      setState(() {
        _totalPoints = 0;
        _loadingPoints = false;
      });
    }
  }

  Future<void> _completePuzzle() async {
    if (_puzzle.isCompleted) {
      setState(() {
        _puzzle.isCompleted = false;
      });

      final activityService = context.read<ActivityService>();
      await activityService.completeActivityWithScore(
        widget.activityId,
        _puzzle.score,
        {'score': _puzzle.score},
      );

      // Fetch updated total points
      await _fetchTotalPoints();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Puzzle Completed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your score: ${_puzzle.score}'),
                const SizedBox(height: 8),
                Text('Points earned: ${_puzzle.points}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/activities');
                },
                child: const Text('Back to Activities'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadPuzzle() async {
    setState(() {
      _puzzle = WordPuzzle.create();
    });
    context.read<WordPuzzleBloc>().add(LoadWordPuzzleStats(widget.activityId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WordPuzzleBloc(
        context.read<ActivityService>(),
      ),
      child: BlocListener<WordPuzzleBloc, WordPuzzleState>(
        listener: (context, state) {
          if (state is WordPuzzleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Word Puzzle'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/activities'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                onPressed: () {
                  final unfoundWords = _puzzle.words.where((word) => !_puzzle.foundWords.contains(word)).toList();
                  if (unfoundWords.isNotEmpty) {
                    final hintWord = unfoundWords[0];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hint: The word starts with "${hintWord[0]}"')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No more hints available!')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _puzzle = WordPuzzle.create();
                  });
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Difficulty: ${_puzzle.difficulty}'),
                    Text('Time: ${_puzzle.duration.inSeconds}/${_puzzle.timeLimit}s'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _puzzle.foundWords.length / _puzzle.words.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                Text('Found Words: ${_puzzle.foundWords.length}/${_puzzle.words.length}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _wordController,
                  decoration: const InputDecoration(
                    labelText: 'Enter a word',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _onWordSubmitted,
                ),
                const SizedBox(height: 16),
                const Text('Clues:', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: _puzzle.clues.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_puzzle.clues[index]),
                        leading: _puzzle.foundWords.contains(_puzzle.words[index])
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.help_outline),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 