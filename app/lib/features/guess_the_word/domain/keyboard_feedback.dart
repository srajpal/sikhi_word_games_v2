import 'guess_evaluator.dart';
import 'guess_game.dart';

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
