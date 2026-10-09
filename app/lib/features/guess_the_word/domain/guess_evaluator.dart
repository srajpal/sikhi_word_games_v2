import '../../../core/language/word_units.dart';

import '../../../core/language/gurmukhi_normalization.dart';

enum LetterResult { absent, present, correct }

class EvaluatedLetter {
  const EvaluatedLetter({required this.grapheme, required this.result});

  final String grapheme;
  final LetterResult result;
}

abstract final class GuessEvaluator {
  static int visibleLength(String value) => wordUnitCount(value);

  static List<String> graphemes(String value) => wordUnits(value);

  static List<EvaluatedLetter> evaluate({
    required String solution,
    required String guess,
  }) {
    final solutionLetters = graphemes(
      normalizeGurmukhi(normalizeRomanizedInput(solution.toUpperCase())),
    );
    final guessLetters = graphemes(
      normalizeGurmukhi(normalizeRomanizedInput(guess.toUpperCase())),
    );
    if (solutionLetters.length != guessLetters.length) {
      throw ArgumentError.value(guess, 'guess', 'Grapheme lengths must match.');
    }

    final results = List<LetterResult>.filled(
      solutionLetters.length,
      LetterResult.absent,
    );
    final remaining = <String, int>{};

    // Exact matches are consumed first so duplicate guesses cannot receive
    // more present matches than the solution actually contains.
    for (var index = 0; index < solutionLetters.length; index++) {
      if (guessLetters[index] == solutionLetters[index]) {
        results[index] = LetterResult.correct;
      } else {
        remaining.update(
          solutionLetters[index],
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    for (var index = 0; index < guessLetters.length; index++) {
      if (results[index] == LetterResult.correct) continue;
      final available = remaining[guessLetters[index]] ?? 0;
      if (available > 0) {
        results[index] = LetterResult.present;
        remaining[guessLetters[index]] = available - 1;
      }
    }

    return [
      for (var index = 0; index < guessLetters.length; index++)
        EvaluatedLetter(grapheme: guessLetters[index], result: results[index]),
    ];
  }
}
