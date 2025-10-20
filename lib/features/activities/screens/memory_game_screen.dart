import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/memory_game.dart';
import '../blocs/memory_game_bloc.dart';
import '../services/activity_service.dart';
import 'package:go_router/go_router.dart';
import '../activity_bloc.dart';

class MemoryGameScreen extends StatefulWidget {
  final String activityId;
  final int gridSize;

  const MemoryGameScreen({
    super.key,
    required this.activityId,
    this.gridSize = 4,
  });

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late MemoryGame _game;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _game = MemoryGame.create(widget.gridSize);
    context.read<MemoryGameBloc>().add(LoadMemoryGameStats(widget.activityId));
  }

  void _onCardTap(int index) {
    if (_isProcessing) return;

    setState(() {
      _game.flipCard(index);
    });

    if (_game.isGameOver) {
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
            Text('Pairs Found: ${_game.pairsFound}/${_game.cards.length ~/ 2}'),
            Text('Moves: ${_game.moves}'),
            Text('Time: ${_game.duration.inSeconds} seconds'),
            Text('Score: ${_game.score}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/activities'); // Navigate back to activities
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _game = MemoryGame.create(4); // Using 4x4 grid
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    ).then((_) {
      // Save game results when dialog is closed
      context.read<MemoryGameBloc>().add(
            CompleteMemoryGame(
              activityId: widget.activityId,
              score: _game.score,
              moves: _game.moves,
              duration: _game.duration,
            ),
          );
      // Update activity status
      context.read<ActivityBloc>().add(CompleteActivity(widget.activityId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemoryGameBloc, MemoryGameState>(
      listener: (context, state) {
        if (state is MemoryGameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memory Game'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/activities'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _game = MemoryGame.create(widget.gridSize);
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Moves: ${_game.moves}'),
                  Text('Pairs: ${_game.pairsFound}/${(_game.gridSize * _game.gridSize) ~/ 2}'),
                  Text('Score: ${_game.score}'),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.gridSize,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _game.cards.length,
                itemBuilder: (context, index) {
                  final card = _game.cards[index];
                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: Card(
                      elevation: card.isFlipped ? 0 : 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: card.isMatched
                              ? Colors.green.shade100
                              : card.isFlipped
                                  ? Colors.white
                                  : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: card.isFlipped || card.isMatched
                              ? Text(
                                  card.emoji,
                                  style: const TextStyle(fontSize: 32),
                                )
                              : const Icon(Icons.question_mark),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 