class WordPuzzle {
  final String id;
  final String title;
  final String description;
  final List<String> words;
  final List<String> clues;
  final int points;
  final int timeLimit; // in seconds
  final String difficulty; // new field for difficulty level
  final DateTime? startTime;
  DateTime? endTime;
  final List<String> foundWords;
  bool isCompleted;

  WordPuzzle({
    required this.id,
    required this.title,
    required this.description,
    required this.words,
    required this.clues,
    required this.points,
    required this.timeLimit,
    required this.difficulty, // new required parameter
    this.startTime,
    this.endTime,
    List<String>? foundWords,
    this.isCompleted = false,
  }) : foundWords = foundWords ?? [];

  factory WordPuzzle.create() {
    return WordPuzzle(
      id: 'word_puzzle_1',
      title: 'Word Search Challenge',
      description: 'Find all the hidden words in the puzzle',
      words: [
        'HEALTH',
        'WELLNESS',
        'FITNESS',
        'EXERCISE',
        'BALANCE',
        'STRENGTH',
        'ENERGY',
        'VITALITY',
      ],
      clues: [
        'Overall state of being',
        'State of being healthy',
        'Physical condition',
        'Physical activity',
        'Stability and harmony',
        'Physical power',
        'Power to do work',
        'Liveliness and vigor',
      ],
      points: 50,
      timeLimit: 300, // 5 minutes
      difficulty: 'medium',
      startTime: DateTime.now(),
    );
  }

  void addFoundWord(String word) {
    if (!foundWords.contains(word)) {
      foundWords.add(word);
      if (foundWords.length == words.length) {
        isCompleted = true;
        endTime = DateTime.now();
      }
    }
  }

  Duration get duration {
    if (startTime == null) return Duration.zero;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  int get score {
    if (foundWords.isEmpty) return 0;
    final baseScore = (foundWords.length / words.length) * points;
    final timeBonus = endTime != null ? (timeLimit - duration.inSeconds) * 2 : 0;
    final difficultyMultiplier = difficulty == 'hard' ? 1.5 : (difficulty == 'medium' ? 1.2 : 1.0);
    return ((baseScore + timeBonus) * difficultyMultiplier).toInt();
  }

  double get progress => words.isEmpty ? 0 : foundWords.length / words.length;
} 