import 'package:characters/characters.dart';

/// The state of a Chardi Kala: Word Quest round.
enum WordQuestStatus { playing, won, lost }

/// What happened when a player chose a grapheme.
enum WordQuestGuessResult { correct, incorrect, repeated, invalid, gameOver }

/// The outcome of asking the game to reveal a letter.
enum WordQuestHintResult { revealed, unavailable, gameOver }

/// A small, UI-friendly description of a letter guess.
class WordQuestGuess {
  const WordQuestGuess({
    required this.value,
    required this.result,
    required this.triesRemaining,
  });

  final String value;
  final WordQuestGuessResult result;
  final int triesRemaining;

  bool get changedRound =>
      result == WordQuestGuessResult.correct ||
      result == WordQuestGuessResult.incorrect;
}

/// A small, UI-friendly description of a hint request.
class WordQuestHint {
  const WordQuestHint({required this.result, required this.revealedGrapheme});

  final WordQuestHintResult result;
  final String? revealedGrapheme;
}

/// Rules and state for the child-friendly letter-revealing game.
///
/// Every visible letter is stored as a Unicode grapheme cluster, so a Punjabi
/// character with combining marks is always revealed as one tile.
class WordQuestGame {
  WordQuestGame({required String solution, int? maximumTries})
    : solution = _normaliseWord(solution),
      maximumTries =
          maximumTries ?? recommendedMaximumTriesForSolution(solution),
      _solutionGraphemes = _normaliseWord(solution).characters
          .toList(growable: false) {
    if (_solutionGraphemes.isEmpty) {
      throw ArgumentError.value(solution, 'solution', 'Cannot be empty.');
    }
    if (this.maximumTries <= 0) {
      throw ArgumentError.value(
        this.maximumTries,
        'maximumTries',
        'Must be greater than zero.',
      );
    }
  }

  static const int schemaVersion = 2;

  /// Gives shorter words a smaller, still forgiving miss budget.
  ///
  /// The supported 4-, 5-, and 6-grapheme rounds receive 5, 6, and 7 tries.
  static int recommendedMaximumTriesForSolution(String solution) =>
      (_normaliseWord(solution).characters.length + 1).clamp(5, 7);

  final String solution;
  final int maximumTries;
  final List<String> _solutionGraphemes;
  final Set<String> _guessed = <String>{};
  final Set<String> _hinted = <String>{};
  WordQuestStatus _status = WordQuestStatus.playing;
  int _incorrectGuesses = 0;

  /// The solution split into visible, tappable letter tiles.
  List<String> get solutionGraphemes => List.unmodifiable(_solutionGraphemes);

  /// One copy of each answer grapheme, in answer order.
  ///
  /// A presentation can shuffle this list to create a child-friendly letter
  /// bank without needing to inspect or split the answer itself.
  List<String> get letterBankGraphemes =>
      List.unmodifiable(_solutionGraphemes.toSet().toList(growable: false));

  Set<String> get guessedGraphemes => Set.unmodifiable(_guessed);
  Set<String> get hintedGraphemes => Set.unmodifiable(_hinted);
  WordQuestStatus get status => _status;
  int get incorrectGuesses => _incorrectGuesses;
  int get triesRemaining => maximumTries - _incorrectGuesses;
  int get hintsUsed => _hinted.length;

  /// A tile for each solution grapheme, with null for a still-hidden tile.
  List<String?> get revealedGraphemes => [
    for (final grapheme in _solutionGraphemes)
      _guessed.contains(grapheme) ? grapheme : null,
  ];

  /// A display string that preserves tile positions without leaking letters.
  String get maskedWord =>
      revealedGraphemes.map((grapheme) => grapheme ?? '•').join(' ');

  bool get isComplete => _status != WordQuestStatus.playing;

  /// Whether [value] has already been chosen, accepting a single grapheme.
  bool isGuessed(String value) {
    final grapheme = _normaliseGuess(value);
    return grapheme != null && _guessed.contains(grapheme);
  }

  /// Guesses exactly one Unicode grapheme. Case is folded for Latin words.
  WordQuestGuess guess(String value) {
    final grapheme = _normaliseGuess(value);
    if (_status != WordQuestStatus.playing) {
      return WordQuestGuess(
        value: grapheme ?? value,
        result: WordQuestGuessResult.gameOver,
        triesRemaining: triesRemaining,
      );
    }
    if (grapheme == null) {
      return WordQuestGuess(
        value: value,
        result: WordQuestGuessResult.invalid,
        triesRemaining: triesRemaining,
      );
    }
    if (!_guessed.add(grapheme)) {
      return WordQuestGuess(
        value: grapheme,
        result: WordQuestGuessResult.repeated,
        triesRemaining: triesRemaining,
      );
    }

    if (_solutionGraphemes.contains(grapheme)) {
      _updateWinStatus();
      return WordQuestGuess(
        value: grapheme,
        result: WordQuestGuessResult.correct,
        triesRemaining: triesRemaining,
      );
    }

    _incorrectGuesses++;
    if (_incorrectGuesses >= maximumTries) {
      _status = WordQuestStatus.lost;
    }
    return WordQuestGuess(
      value: grapheme,
      result: WordQuestGuessResult.incorrect,
      triesRemaining: triesRemaining,
    );
  }

  /// Reveals the first still-hidden grapheme, making hint behavior predictable.
  WordQuestHint useHint() {
    if (_status != WordQuestStatus.playing) {
      return const WordQuestHint(
        result: WordQuestHintResult.gameOver,
        revealedGrapheme: null,
      );
    }
    String? next;
    for (final letter in _solutionGraphemes) {
      if (!_guessed.contains(letter)) {
        next = letter;
        break;
      }
    }
    if (next == null) {
      return const WordQuestHint(
        result: WordQuestHintResult.unavailable,
        revealedGrapheme: null,
      );
    }
    _guessed.add(next);
    _hinted.add(next);
    _updateWinStatus();
    return WordQuestHint(
      result: WordQuestHintResult.revealed,
      revealedGrapheme: next,
    );
  }

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'solution': solution,
    'maximumTries': maximumTries,
    'guessedGraphemes': _guessed.toList(growable: false),
    'hintedGraphemes': _hinted.toList(growable: false),
  };

  static WordQuestGame restore(Map<String, Object?> json) {
    if (json['schemaVersion'] != schemaVersion ||
        json['solution'] is! String ||
        json['maximumTries'] is! int ||
        json['guessedGraphemes'] is! List ||
        json['hintedGraphemes'] is! List) {
      throw const FormatException(
        'Unsupported or malformed Word Quest snapshot.',
      );
    }
    final game = WordQuestGame(
      solution: json['solution']! as String,
      maximumTries: json['maximumTries']! as int,
    );
    final guessed = _readGraphemeList(
      json['guessedGraphemes']! as List<Object?>,
    );
    final hinted = _readGraphemeList(json['hintedGraphemes']! as List<Object?>);
    if (!hinted.every(guessed.contains) ||
        guessed.any(
          (letter) =>
              !game._solutionGraphemes.contains(letter) &&
              hinted.contains(letter),
        )) {
      throw const FormatException('Snapshot contains invalid hint state.');
    }
    game._guessed.addAll(guessed);
    game._hinted.addAll(hinted);
    game._incorrectGuesses = guessed
        .where((letter) => !game._solutionGraphemes.contains(letter))
        .length;
    if (game._incorrectGuesses >= game.maximumTries) {
      game._status = WordQuestStatus.lost;
    } else {
      game._updateWinStatus();
    }
    return game;
  }

  void _updateWinStatus() {
    if (_solutionGraphemes.every(_guessed.contains)) {
      _status = WordQuestStatus.won;
    }
  }

  static String _normaliseWord(String value) => value.trim().toUpperCase();

  static String? _normaliseGuess(String value) {
    final normalised = _normaliseWord(value);
    return normalised.characters.length == 1 ? normalised : null;
  }

  static Set<String> _readGraphemeList(List<Object?> values) {
    final result = <String>{};
    for (final value in values) {
      if (value is! String) {
        throw const FormatException('Snapshot contains a non-string grapheme.');
      }
      final grapheme = _normaliseGuess(value);
      if (grapheme == null || !result.add(grapheme)) {
        throw const FormatException('Snapshot contains an invalid grapheme.');
      }
    }
    return result;
  }
}
