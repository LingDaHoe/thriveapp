import 'dart:math';

class MemoryCard {
  final String id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryGame {
  final List<MemoryCard> cards;
  final int gridSize;
  int moves;
  int pairsFound;
  bool isGameOver;
  DateTime? startTime;
  DateTime? endTime;

  MemoryGame({
    required this.cards,
    required this.gridSize,
    this.moves = 0,
    this.pairsFound = 0,
    this.isGameOver = false,
    this.startTime,
    this.endTime,
  });

  factory MemoryGame.create(int gridSize) {
    final emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];
    final random = Random();
    final pairs = (gridSize * gridSize) ~/ 2;
    final selectedEmojis = emojis.take(pairs).toList();
    final cardPairs = [...selectedEmojis, ...selectedEmojis];
    cardPairs.shuffle(random);

    final cards = List.generate(
      cardPairs.length,
      (index) => MemoryCard(
        id: 'card_$index',
        emoji: cardPairs[index],
      ),
    );

    return MemoryGame(
      cards: cards,
      gridSize: gridSize,
      startTime: DateTime.now(),
    );
  }

  void flipCard(int index) {
    if (isGameOver) return;

    final card = cards[index];
    if (card.isMatched || card.isFlipped) return;

    card.isFlipped = true;
    moves++;

    final flippedCards = cards.where((c) => c.isFlipped && !c.isMatched).toList();
    if (flippedCards.length == 2) {
      if (flippedCards[0].emoji == flippedCards[1].emoji) {
        flippedCards[0].isMatched = true;
        flippedCards[1].isMatched = true;
        pairsFound++;
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          flippedCards[0].isFlipped = false;
          flippedCards[1].isFlipped = false;
        });
      }
    }

    if (pairsFound == (gridSize * gridSize) ~/ 2) {
      isGameOver = true;
      endTime = DateTime.now();
    }
  }

  Duration get duration {
    if (startTime == null) return Duration.zero;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  int get score {
    if (moves == 0) return 0;
    final timeBonus = max(0, 1000 - duration.inSeconds * 10);
    final movesBonus = max(0, 1000 - moves * 10);
    return timeBonus + movesBonus;
  }
} 