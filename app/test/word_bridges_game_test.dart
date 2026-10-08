import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_game.dart';

void main() {
  final pairs = List.generate(
    4,
    (i) => BridgePair(id: '$i', word: 'word$i', meaning: 'meaning$i'),
  );
  WordBridgesGame game() => WordBridgesGame(pairs: pairs, random: Random(12));
  void finish(WordBridgesGame game) {
    for (final pair in pairs) {
      game.selectWord(pair.id);
      game.selectMeaning(pair.id);
    }
  }

  test('either side first, toggle and replacement do not count attempts', () {
    final g = game();
    expect(g.selectMeaning('0'), BridgeSelectionResult.selected);
    expect(g.selectMeaning('1'), BridgeSelectionResult.selected);
    expect(g.selectMeaning('1'), BridgeSelectionResult.cleared);
    expect(g.attempts, 0);
    g.selectMeaning('0');
    expect(g.selectWord('0'), BridgeSelectionResult.matched);
    expect(g.matchedIds, {'0'});
    expect(g.attempts, 1);
    expect(g.selectMeaning('0'), BridgeSelectionResult.ignored);
    expect(g.selectWord('unknown'), BridgeSelectionResult.ignored);
  });

  test('mismatch clears both; completed sets cannot change', () {
    final g = game();
    g.selectWord('0');
    expect(g.selectMeaning('1'), BridgeSelectionResult.mismatched);
    expect(g.selectedWordId, isNull);
    expect(g.selectedMeaningId, isNull);
    finish(g);
    expect(g.isComplete, isTrue);
    expect(g.attempts, 5);
    expect(g.selectWord('1'), BridgeSelectionResult.ignored);
    expect(() => g.matchedIds.clear(), throwsUnsupportedError);
    expect(() => g.wordOrder.clear(), throwsUnsupportedError);
  });

  test('round trip preserves independent orders and partial selection', () {
    final g = game();
    g.selectWord('0');
    g.selectMeaning('0');
    g.selectMeaning('2');
    expect(WordBridgesGame.fromJson(g.toJson()).toJson(), g.toJson());
  });

  test('reject ambiguous pairs and malformed progress', () {
    expect(
      () => WordBridgesGame(pairs: [...pairs.take(3), pairs.first]),
      throwsArgumentError,
    );
    for (final mutation in <void Function(Map<String, Object?>)>[
      (j) => j['attempts'] = -1,
      (j) => j['attempts'] = 1.5,
      (j) => j['wordOrder'] = ['0', '0', '2', '3'],
      (j) => j['meaningOrder'] = ['0', '1', '2', 'bad'],
      (j) => j['matchedIds'] = ['0', '0'],
      (j) => j['matchedIds'] = ['0'],
      (j) => j['selectedWordId'] = 'unknown',
      (j) {
        j['selectedWordId'] = '0';
        j['selectedMeaningId'] = '1';
      },
      (j) => j['roundId'] = '',
    ]) {
      final json = game().toJson();
      mutation(json);
      expect(() => WordBridgesGame.fromJson(json), throwsFormatException);
    }
  });

  test(
    'save snapshots progress and completion is atomic and idempotent',
    () async {
      final store = MemoryKeyValueStore();
      final repo = WordBridgesRepository(store);
      final g = game();
      g.selectWord('0');
      final saved = repo.save(mode: LanguageMode.gurmukhi, game: g);
      g.selectMeaning('0');
      await saved;
      expect(repo.restore()!.game.matchedIds, isEmpty);
      expect(repo.restore()!.game.selectedWordId, '0');
      finish(g);
      await Future.wait([
        repo.recordCompletion(mode: LanguageMode.gurmukhi, game: g),
        repo.recordCompletion(mode: LanguageMode.gurmukhi, game: g),
      ]);
      expect(repo.hasActiveGame, isFalse);
      expect(repo.total.finishedSets, 1);
      expect(repo.total.pairsMatched, 4);
      expect(repo.forMode(LanguageMode.english).finishedSets, 0);
      final reopened = WordBridgesRepository(store);
      await reopened.recordCompletion(mode: LanguageMode.gurmukhi, game: g);
      expect(reopened.total.finishedSets, 1);
      expect(store.values.length, 1);
    },
  );

  test(
    'clearing active game preserves statistics; broken saves fail closed',
    () async {
      final store = MemoryKeyValueStore();
      final repo = WordBridgesRepository(store);
      final g = game();
      finish(g);
      await repo.save(mode: LanguageMode.english, game: g);
      await repo.save(mode: LanguageMode.english, game: game());
      await repo.clear();
      expect(repo.total.finishedSets, 1);
      expect(repo.restore(), isNull);
      store.values[WordBridgesRepository.storageKey] = '{bad json';
      expect(repo.restore(), isNull);
      expect(repo.total.finishedSets, 0);
    },
  );

  test(
    'late completion cannot clear a newer round or revive a finished round',
    () async {
      final repo = WordBridgesRepository(MemoryKeyValueStore());
      final old = game();
      final stale = WordBridgesGame.fromJson(old.toJson());
      finish(old);
      final next = game();
      await repo.save(mode: LanguageMode.english, game: next);
      await repo.recordCompletion(mode: LanguageMode.english, game: old);
      expect(repo.restore()!.game.roundId, next.roundId);
      await repo.save(mode: LanguageMode.english, game: stale);
      expect(repo.restore()!.game.roundId, next.roundId);
      expect(repo.total.finishedSets, 1);
    },
  );
}
