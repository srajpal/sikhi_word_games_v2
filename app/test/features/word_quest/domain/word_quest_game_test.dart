import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';

void main() {
  group('WordQuestGame', () {
    test(
      'standalone Roman and non-vowel marks are invalid and cost no miss',
      () {
        final game = WordQuestGame(solution: 'ĀSĀN');
        for (final mark in ['\u0304', 'ੰ', '੍']) {
          expect(game.guess(mark).result, WordQuestGuessResult.invalid);
        }
        expect(game.incorrectGuesses, 0);
        expect(game.guessedGraphemes, isEmpty);
      },
    );
    test('lone Gurmukhi vowel signs are ignored without consuming a miss', () {
      final game = WordQuestGame(solution: 'ਕਿਤਾਬ');
      game.guess('ਸ');
      final misses = game.incorrectGuesses;
      final remaining = game.triesRemaining;
      for (final sign in ['ਾ', 'ਿ', 'ੀ', 'ੁ', 'ੂ', 'ੇ', 'ੈ', 'ੋ', 'ੌ']) {
        expect(game.guess(sign).result, WordQuestGuessResult.invalid);
        expect(game.incorrectGuesses, misses, reason: sign);
        expect(game.triesRemaining, remaining, reason: sign);
        expect(game.guessedGraphemes, {'ਸ'});
      }
      expect(WordQuestGame.restore(game.toJson()).incorrectGuesses, misses);
      expect(game.guess('ਤਾ').result, WordQuestGuessResult.correct);
    });
    test('rejects guesses recorded after the round would have ended', () {
      final snapshot = WordQuestGame(solution: 'SEVA').toJson();
      for (final guesses in [
        ['B', 'C', 'D', 'F', 'G', 'H'],
        ['B', 'C', 'D', 'F', 'G', 'S', 'E', 'V', 'A'],
      ]) {
        expect(
          () =>
              WordQuestGame.restore({...snapshot, 'guessedGraphemes': guesses}),
          throwsFormatException,
        );
      }
      final lost = WordQuestGame(solution: 'SEVA');
      for (final guess in ['B', 'C', 'D', 'F', 'G']) {
        lost.guess(guess);
      }
      expect(WordQuestGame.restore(lost.toJson()).status, WordQuestStatus.lost);
    });
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

    test('matches precomposed and decomposed Gurmukhi letter guesses', () {
      final game = WordQuestGame(solution: 'ਖ਼ਬਰ');

      expect(game.solutionGraphemes, const ['ਖ਼', 'ਬ', 'ਰ']);
      expect(game.guess('ਖ਼').result, WordQuestGuessResult.correct);
      expect(game.revealedGraphemes.first, 'ਖ਼');
      game.guess('ਬ');
      game.guess('ਰ');
      expect(game.status, WordQuestStatus.won);
    });

    test('repeated guesses are harmless', () {
      final game = WordQuestGame(solution: 'SEVA');

      expect(game.guess('x').result, WordQuestGuessResult.incorrect);
      expect(game.triesRemaining, 2);
      expect(game.guess('X').result, WordQuestGuessResult.repeated);
      expect(game.triesRemaining, 2);
      expect(game.guess('s').result, WordQuestGuessResult.correct);
      expect(game.guess('S').result, WordQuestGuessResult.repeated);
      expect(game.triesRemaining, 2);
    });

    test('uses an adaptive try budget and ends a learning round', () {
      final game = WordQuestGame(solution: 'SEVA');

      expect(game.maximumTries, 3);
      for (final letter in const ['B', 'C', 'D', 'F', 'G']) {
        game.guess(letter);
      }

      expect(game.incorrectGuesses, 3);
      expect(game.triesRemaining, 0);
      expect(game.status, WordQuestStatus.lost);
      expect(game.guess('S').result, WordQuestGuessResult.gameOver);
    });

    test('rejects multi-grapheme inputs without consuming a try', () {
      final game = WordQuestGame(solution: 'SEVA');

      expect(game.guess('SE').result, WordQuestGuessResult.invalid);
      expect(game.guess(' ').result, WordQuestGuessResult.invalid);
      expect(game.triesRemaining, 3);
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

    test('assigns 3, 4, and 5 misses to 4-, 5-, and 6-grapheme words', () {
      expect(WordQuestGame(solution: 'SEVA').maximumTries, 3);
      expect(WordQuestGame(solution: 'APPLE').maximumTries, 4);
      expect(WordQuestGame(solution: 'PLANET').maximumTries, 5);
      expect(WordQuestGame(solution: 'ਕੀਰਤਨ').maximumTries, 3);
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
