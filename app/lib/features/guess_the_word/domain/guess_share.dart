import 'guess_evaluator.dart';
import 'guess_game.dart';
import 'language_mode.dart';

String buildSpoilerSafeResult({
  required GuessGame game,
  required LanguageMode mode,
}) {
  if (game.status == GuessGameStatus.playing) {
    throw StateError('A result can only be shared after the game ends.');
  }
  final score = game.status == GuessGameStatus.won
      ? '${game.turns.length}/${game.maximumAttempts}'
      : 'X/${game.maximumAttempts}';
  final rows = game.turns.map((turn) => turn.evaluation.map(_symbolFor).join());
  return [
    'Sikhi Word Games · ${mode.label} · ${game.wordLength} letters · $score',
    '',
    ...rows,
  ].join('\n');
}

String _symbolFor(EvaluatedLetter letter) => switch (letter.result) {
  LetterResult.correct => '✓',
  LetterResult.present => '↔',
  LetterResult.absent => '×',
};
