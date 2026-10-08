import 'guess_evaluator.dart';
import 'guess_game.dart';

/// Keep the strongest clue for a grapheme, including repeated-letter guesses.
Map<String, LetterResult> keyboardLetterResults(Iterable<GuessTurn> turns) {
  final results = <String, LetterResult>{};
  for (final turn in turns) {
    for (final letter in turn.evaluation) {
      final previous = results[letter.grapheme];
      if (previous == null || letter.result.index > previous.index) {
        results[letter.grapheme] = letter.result;
      }
    }
  }
  return results;
}

Set<String> unavailableKeyboardCharacters(Iterable<GuessTurn> turns) {
  final resultsByCharacter = <String, Set<LetterResult>>{};
  for (final turn in turns) {
    for (final letter in turn.evaluation) {
      resultsByCharacter
          .putIfAbsent(letter.grapheme, () => <LetterResult>{})
          .add(letter.result);
    }
  }
  return {
    for (final entry in resultsByCharacter.entries)
      if (entry.value.length == 1 && entry.value.single == LetterResult.absent)
        entry.key,
  };
}
