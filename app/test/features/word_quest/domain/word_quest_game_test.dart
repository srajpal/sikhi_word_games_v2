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
      expect(game.triesRemaining, 4);
      expect(game.guess('X').result, WordQuestGuessResult.repeated);
      expect(game.triesRemaining, 4);
      expect(game.guess('s').result, WordQuestGuessResult.correct);
      expect(game.guess('S').result, WordQuestGuessResult.repeated);
      expect(game.triesRemaining, 4);
    });

    test('uses an adaptive try budget and ends a learning round', () {
      final game = WordQuestGame(solution: 'SEVA');

      expect(game.maximumTries, 5);
      for (final letter in const ['B', 'C', 'D', 'F', 'G']) {
        game.guess(letter);
      }

      expect(game.incorrectGuesses, 5);
      expect(game.triesRemaining, 0);
      expect(game.status, WordQuestStatus.lost);
      expect(game.guess('S').result, WordQuestGuessResult.gameOver);
    });

    test('rejects multi-grapheme inputs without consuming a try', () {
      final game = WordQuestGame(solution: 'SEVA');

      expect(game.guess('SE').result, WordQuestGuessResult.invalid);
      expect(game.guess(' ').result, WordQuestGuessResult.invalid);
      expect(game.triesRemaining, 5);
    });

    test(
      'hint deterministically reveals an unguessed grapheme and tracks it',
      () {
        final game = WordQuestGame(solution: 'PLANET');

        final hint = game.useHint();

        expect(hint.result, WordQuestHintResult.revealed);
        expect(hint.revealedGrapheme, 'P');
        expect(game.hintsUsed, 1);
        expect(game.hintedGraphemes, {'P'});
        expect(game.hintsRemaining, 1);
        game.guess('L');
        game.guess('A');
        game.guess('N');
        expect(game.useHint().revealedGrapheme, 'E');
        expect(game.hintsRemaining, 0);
        game.guess('T');
        expect(game.status, WordQuestStatus.won);
        expect(game.useHint().result, WordQuestHintResult.gameOver);
      },
    );

    test('scales hints with the visible word length', () {
      expect(WordQuestGame(solution: 'SEVA').maximumHints, 0);
      expect(WordQuestGame(solution: 'APPLE').maximumHints, 1);
      expect(WordQuestGame(solution: 'PLANET').maximumHints, 2);

      final fourLetters = WordQuestGame(solution: 'SEVA');
      expect(fourLetters.useHint().result, WordQuestHintResult.unavailable);
      expect(fourLetters.hintsUsed, 0);
    });

    test('assigns 5, 6, and 7 tries to 4-, 5-, and 6-grapheme words', () {
      expect(WordQuestGame(solution: 'SEVA').maximumTries, 5);
      expect(WordQuestGame(solution: 'APPLE').maximumTries, 6);
      expect(WordQuestGame(solution: 'PLANET').maximumTries, 7);
      expect(WordQuestGame(solution: 'ਕੀਰਤਨ').maximumTries, 5);
    });

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
      expect(
        () => WordQuestGame.restore(const {
          'schemaVersion': 2,
          'solution': 'SEVA',
          'maximumTries': 5,
          'guessedGraphemes': ['S'],
          'hintedGraphemes': ['S'],
        }),
        throwsFormatException,
      );
    });
  });
}
