import 'package:characters/characters.dart';

import 'guess_evaluator.dart';

enum GuessGameStatus { playing, won, lost }

enum GuessRejection { wrongLength, notAccepted, gameOver }

class GuessTurn {
  const GuessTurn({required this.guess, required this.evaluation});

  final String guess;
  final List<EvaluatedLetter> evaluation;
}

class GuessSubmission {
  const GuessSubmission.accepted(this.turn) : rejection = null;
  const GuessSubmission.rejected(this.rejection) : turn = null;

  final GuessTurn? turn;
  final GuessRejection? rejection;
  bool get isAccepted => turn != null;
}

class GuessGame {
  GuessGame({
    required String solution,
    required Set<String> acceptedGuesses,
    this.maximumAttempts = 6,
  }) : assert(maximumAttempts > 0),
       solution = solution.toUpperCase(),
       acceptedGuesses = acceptedGuesses
           .map((word) => word.toUpperCase())
           .toSet();

  final String solution;
  final Set<String> acceptedGuesses;
  final int maximumAttempts;
  final List<GuessTurn> _turns = [];
  GuessGameStatus _status = GuessGameStatus.playing;

  List<GuessTurn> get turns => List.unmodifiable(_turns);
  GuessGameStatus get status => _status;
  int get wordLength => solution.characters.length;

  GuessSubmission submit(String value) {
    if (_status != GuessGameStatus.playing) {
      return const GuessSubmission.rejected(GuessRejection.gameOver);
    }
    final guess = value.trim().toUpperCase();
    if (guess.characters.length != wordLength) {
      return const GuessSubmission.rejected(GuessRejection.wrongLength);
    }
    if (!acceptedGuesses.contains(guess)) {
      return const GuessSubmission.rejected(GuessRejection.notAccepted);
    }

    final turn = GuessTurn(
      guess: guess,
      evaluation: GuessEvaluator.evaluate(solution: solution, guess: guess),
    );
    _turns.add(turn);
    if (guess == solution) {
      _status = GuessGameStatus.won;
    } else if (_turns.length >= maximumAttempts) {
      _status = GuessGameStatus.lost;
    }
    return GuessSubmission.accepted(turn);
  }
}
