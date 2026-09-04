import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';

void main() {
  group('WordQuestGame', () {
    test('reveals every matching Latin grapheme and folds case', () {
      final game = WordQuestGame(solution: 'Seva');

      final result = game.guess('s');

      expect(result.result, WordQuestGuessResult.correct);
      expect(game.revealedGraphemes, const ['S', null, null, null]);
      game.guess('a');
      game.guess('e');
      game.guess('v');
      expect(game.status, WordQuestStatus.won);
      expect(game.maskedWord, 'S E V A');
    });

    test('keeps Gurmukhi grapheme clusters together and reveals repeats', () {
      final game = WordQuestGame(solution: 'ਕਿਤਾਬ');

      expect(game.solutionGraphemes, const ['ਕਿ', 'ਤਾ', 'ਬ']);
      expect(game.guess('ਤਾ').result, WordQuestGuessResult.correct);
      expect(game.revealedGraphemes, const [null, 'ਤਾ', null]);

      final repeated = WordQuestGame(solution: 'ਕਾਕਾ');
      expect(repeated.letterBankGraphemes, const ['ਕਾ']);
      repeated.guess('ਕਾ');
      expect(repeated.revealedGraphemes, const ['ਕਾ', 'ਕਾ']);
    });

    test('repeated guesses are harmless', () {
      final game = WordQuestGame(solution: 'SEVA');

      expect(game.guess('x').result, WordQuestGuessResult.incorrect);
      expect(game.triesRemaining, 6);
      expect(game.guess('X').result, WordQuestGuessResult.repeated);
      expect(game.triesRemaining, 6);
      expect(game.guess('s').result, WordQuestGuessResult.correct);
      expect(game.guess('S').result, WordQuestGuessResult.repeated);
      expect(game.triesRemaining, 6);
    });

    test('uses exactly seven tries and ends a lost game', () {
      final game = WordQuestGame(solution: 'SEVA');

      for (final letter in const ['B', 'C', 'D', 'F', 'G', 'H', 'I']) {
        game.guess(letter);
      }

      expect(game.incorrectGuesses, 7);
      expect(game.triesRemaining, 0);
      expect(game.status, WordQuestStatus.lost);
      expect(game.guess('S').result, WordQuestGuessResult.gameOver);
    });

    test('rejects multi-grapheme inputs without consuming a try', () {
      final game = WordQuestGame(solution: 'SEVA');

      expect(game.guess('SE').result, WordQuestGuessResult.invalid);
      expect(game.guess(' ').result, WordQuestGuessResult.invalid);
      expect(game.triesRemaining, 7);
    });

    test(
      'hint deterministically reveals an unguessed grapheme and tracks it',
      () {
        final game = WordQuestGame(solution: 'SEVA');

        final hint = game.useHint();

        expect(hint.result, WordQuestHintResult.revealed);
        expect(hint.revealedGrapheme, 'S');
        expect(game.hintsUsed, 1);
        expect(game.hintedGraphemes, {'S'});
        expect(game.triesRemaining, 7);
        game.guess('E');
        game.guess('V');
        expect(game.useHint().revealedGrapheme, 'A');
        expect(game.status, WordQuestStatus.won);
        expect(game.useHint().result, WordQuestHintResult.gameOver);
      },
    );

    test('round-trips its snapshot and rejects malformed snapshots', () {
      final game = WordQuestGame(solution: 'ਕਿਤਾਬ');
      game.useHint();
      game.guess('ਬ');
      game.guess('ਗ');
      final restored = WordQuestGame.restore(game.toJson());

      expect(restored.solution, game.solution);
      expect(restored.guessedGraphemes, game.guessedGraphemes);
      expect(restored.hintedGraphemes, game.hintedGraphemes);
      expect(restored.incorrectGuesses, 1);
      expect(restored.status, WordQuestStatus.playing);
      expect(
        () => WordQuestGame.restore(const {
          'schemaVersion': 1,
          'solution': 'SEVA',
          'maximumTries': 7,
          'guessedGraphemes': ['S'],
          'hintedGraphemes': ['X'],
        }),
        throwsFormatException,
      );
    });
  });
}
