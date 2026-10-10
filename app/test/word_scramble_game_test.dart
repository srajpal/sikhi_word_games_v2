import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/domain/word_scramble_game.dart';

WordScrambleGame scramble([String spelling = 'APPLE']) => WordScrambleGame(
  wordId: 'fixture-$spelling',
  spelling: spelling,
  definition: 'A test clue',
  random: Random(7),
  roundId: 'fixture-$spelling',
);
void solve(WordScrambleGame game) {
  for (var i = 0; i < game.units.length; i++) {
    game.remove(i);
  }
  for (var i = 0; i < game.units.length; i++) {
    if (game.slots[i] != null) continue;
    game.place(game.tray.firstWhere((id) => game.units[id] == game.units[i]));
  }
  expect(game.check(), ScrambleCheck.solved);
}

void main() {
  test(
    'duplicate letters are independent and a solved round cannot change',
    () {
      final game = scramble();
      expect(game.tray.toSet(), {0, 1, 2, 3, 4});
      expect(game.tray.map((id) => game.units[id]).join(), isNot('APPLE'));
      expect(game.place(1), isTrue);
      expect(game.place(1), isFalse);
      expect(game.place(2), isTrue);
      expect(game.remove(0), isTrue);
      solve(game);
      expect(game.check(), ScrambleCheck.ignored);
      expect(game.checks, 1);
      expect(game.hint(), isFalse);
      expect(game.remove(0), isFalse);
      expect(game.shuffle(Random(1)), isFalse);
    },
  );
  test(
    'incomplete checks cost nothing and wrong checks allow unlimited retries',
    () {
      final game = scramble();
      expect(game.check(), ScrambleCheck.ignored);
      expect(game.checks, 0);
      for (final id in game.tray) {
        game.place(id);
      }
      expect(game.check(), ScrambleCheck.tryAgain);
      expect(game.isComplete, isFalse);
      solve(game);
      expect(game.checks, 2);
    },
  );
  test('meaning hint preserves misplaced tiles and does not lock them', () {
    final game = scramble();
    for (final id in [1, 0, 2, 4, 3]) {
      game.place(id);
    }
    final slots = game.slots;
    final tray = game.tray;
    expect(game.clueRevealed, isFalse);
    expect(game.hint(), isTrue);
    expect(game.clueRevealed, isTrue);
    expect(game.slots, slots);
    expect(game.tray, tray);
    expect(game.locked, isEmpty);
    expect(game.remove(0), isTrue);
    expect(game.hint(), isFalse);
    expect(game.hintsRemaining, 0);
    solve(game);
  });
  test('meaning can be requested before checking a ready word', () {
    final game = scramble();
    for (var i = 0; i < 5; i++) {
      game.place(i);
    }
    expect(game.hint(), isTrue);
    expect(game.slots, [0, 1, 2, 3, 4]);
    expect(game.hintsRemaining, 0);
  });
  test('meaning hint leaves duplicate-letter arrangements unchanged', () {
    final game = scramble();
    for (final id in [0, 1, 3, 2, 4]) {
      game.place(id);
    }
    expect(game.hint(), isTrue);
    expect(game.slots[1], 1);
    expect(game.slots[2], 3);
    expect(game.slots[3], 2);
    expect(game.tray, isEmpty);
    solve(game);
  });
  test(
    'Gurmukhi marks and conjuncts remain attached in play and restoration',
    () {
      final game = scramble('ਅਪ੍ਰੈਲ');
      expect(game.units, ['ਅ', 'ਪ੍ਰੈ', 'ਲ']);
      game.place(1);
      game.hint();
      final restored = WordScrambleGame.fromJson(game.toJson());
      expect(restored.units, game.units);
      expect(restored.slots, game.slots);
      expect(restored.locked, game.locked);
      expect(restored.clueRevealed, isTrue);
      solve(restored);
    },
  );
  test('seeded moves preserve every tile and valid snapshots', () {
    for (var seed = 0; seed < 150; seed++) {
      final game = scramble(seed.isEven ? 'BANANA' : 'ਪਾਣੀ');
      final rng = Random(seed);
      for (var move = 0; move < 30; move++) {
        switch (rng.nextInt(4)) {
          case 0:
            if (game.tray.isNotEmpty) {
              game.place(game.tray[rng.nextInt(game.tray.length)]);
            }
          case 1:
            game.remove(rng.nextInt(game.units.length));
          case 2:
            game.shuffle(rng);
          case 3:
            game.hint();
        }
        final ids = [...game.slots.whereType<int>(), ...game.tray];
        expect(ids.toSet().length, game.units.length);
        expect(ids.length, game.units.length);
        expect(WordScrambleGame.fromJson(game.toJson()).slots, game.slots);
      }
      solve(game);
    }
  });
  test(
    'corrupt tile IDs, hint locks and impossible completion fail closed',
    () {
      final json = scramble().toJson();
      for (final patch in [
        {
          'tray': [0, 0, 2, 3, 4],
        },
        {
          'tray': [-1, 1, 2, 3, 4],
        },
        {
          'locked': [0],
        },
        {'checks': -1},
        {'clueRevealed': 'true'},
        {'complete': true},
        {
          'slots': [0, 1, 2, 3, 4],
          'tray': <int>[],
          'complete': true,
          'checks': 0,
        },
      ]) {
        expect(
          () => WordScrambleGame.fromJson({...json, ...patch}),
          throwsFormatException,
        );
      }
      expect(() => scramble('AAAA'), throwsArgumentError);
    },
  );
  test(
    'older unhinted and tile-hinted rounds restore without losing progress',
    () {
      final unhinted = scramble()..place(1);
      final old = unhinted.toJson()..remove('clueRevealed');
      final restored = WordScrambleGame.fromJson(old);
      expect(restored.slots, unhinted.slots);
      expect(restored.usedHint, isFalse);
      expect(restored.clueRevealed, isFalse);
      final hinted = scramble()..place(0);
      final legacy = hinted.toJson()
        ..remove('clueRevealed')
        ..['locked'] = [0];
      final resumed = WordScrambleGame.fromJson(legacy);
      expect(resumed.clueRevealed, isTrue);
      expect(resumed.usedHint, isTrue);
      expect(resumed.remove(0), isFalse);
      solve(resumed);
    },
  );
  test('Gurmukhi vowel signs stay attached through the anagram and hint', () {
    final game = scramble('ਕਰੇਲਾ');
    expect(game.units, ['ਕ', 'ਰੇ', 'ਲਾ']);
    final tray = game.tray;
    game.hint();
    expect(game.tray, tray);
    expect(game.locked, isEmpty);
    solve(game);
  });
}
