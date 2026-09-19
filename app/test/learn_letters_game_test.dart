import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/data/learn_letters_repository.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/domain/learn_letters_game.dart';

void finish(LearnLettersGame game) {
  while (!game.isComplete) {
    game.answer(game.currentLetter.id);
    if (!game.isComplete) game.next();
  }
}

class DelayedLetterStore extends MemoryKeyValueStore {
  Completer<void>? gate;
  bool failNext = false;
  @override
  Future<void> setString(String key, String value) async {
    await gate?.future;
    if (failNext) {
      failNext = false;
      throw StateError('Simulated save failure');
    }
    await super.setString(key, value);
  }
}

void main() {
  test('basic alphabet has 35 unique letters and unambiguous answer names', () {
    expect(learnLetters, hasLength(35));
    expect(learnLetters.map((e) => e.id).toSet(), hasLength(35));
    expect(learnLetters.map((e) => e.gurmukhi).toSet(), hasLength(35));
    expect(learnLetters.map((e) => e.name).toSet(), hasLength(35));
    expect(learnLetters.every((e) => e.nativeName.isNotEmpty), isTrue);
    expect(learnLetters.take(3).map((e) => e.gurmukhi), ['ੳ', 'ਅ', 'ੲ']);
  });

  test(
    'selection prefers the five least familiar letters with unique choices',
    () {
      final mastery = {for (final letter in learnLetters) letter.id: 3};
      for (final letter in learnLetters.take(5)) {
        mastery[letter.id] = 0;
      }
      final game = LearnLettersGame.newRound(
        mastery: mastery,
        random: Random(1),
      );
      expect(
        game.questionIds.toSet(),
        learnLetters.take(5).map((e) => e.id).toSet(),
      );
      while (!game.isComplete) {
        expect(game.choices.map((e) => e.id).toSet(), hasLength(3));
        expect(game.choices.map((e) => e.id), contains(game.currentLetter.id));
        game.answer(game.currentLetter.id);
        game.next();
      }
    },
  );

  test(
    'wrong retries do not earn mastery, duplicate choices and skip are ignored',
    () {
      final game = LearnLettersGame.newRound(random: Random(2));
      game.next();
      expect(game.index, 0);
      expect(game.answer('unknown'), isFalse);
      final wrong = game.choices
          .firstWhere((e) => e.id != game.currentLetter.id)
          .id;
      final choices = game.choices.map((e) => e.id).toList();
      expect(game.answer(wrong), isFalse);
      expect(game.answer(wrong), isFalse);
      expect(game.attempts, 1);
      expect(game.choices.map((e) => e.id), choices);
      expect(game.answer(game.currentLetter.id), isTrue);
      expect(game.answer(game.currentLetter.id), isFalse);
      expect(game.firstTryCorrect, 0);
      game.next();
      expect(game.wrongChoiceIds, isEmpty);
      finish(game);
      expect(game.attempts, 6);
      expect(game.firstTryCorrect, 4);
      game.next();
      expect(game.index, 4);
    },
  );

  test('serialized partial game keeps choices, wrong attempts and current feedback', () {
    final game = LearnLettersGame.newRound(random: Random(3));
    game.answer(
      game.choices.firstWhere((e) => e.id != game.currentLetter.id).id,
    );
    game.answer(game.currentLetter.id);
    final restored = LearnLettersGame.fromJson(
      jsonDecode(jsonEncode(game.toJson())) as Map<String, Object?>,
    );
    expect(restored.toJson(), game.toJson());
    restored.next();
    expect(restored.firstTryCorrect, 0);
  });

  test(
    'restoration rejects unknown, duplicate, inconsistent and future state',
    () {
      final game = LearnLettersGame.newRound(random: Random(4));
      for (final edit in <void Function(Map<String, Object?>)>[
        (json) => json['index'] = 5,
        (json) => json['questionIds'] = List.filled(5, 'ka'),
        (json) => (json['questionIds'] as List)[0] = 'removed',
        (json) => (json['wrongCounts'] as List)[4] = 1,
        (json) => json['wrongChoiceIds'] = [game.currentLetter.id],
        (json) => (json['choiceIds'] as List)[0] = ['ka', 'ka', 'sa'],
      ]) {
        final json = game.toJson();
        edit(json);
        expect(() => LearnLettersGame.fromJson(json), throwsFormatException);
      }
    },
  );

  test(
    'completion is atomic and deduplicated across repository instances',
    () async {
      final store = MemoryKeyValueStore();
      final repo = LearnLettersRepository(store);
      final game = repo.newGame(random: Random(5));
      await repo.save(game);
      expect(repo.hasActiveGame, isTrue);
      finish(game);
      await Future.wait([
        repo.save(game),
        LearnLettersRepository(store).save(game),
      ]);
      expect(repo.statistics.roundsCompleted, 1);
      expect(repo.statistics.answers, 5);
      expect(repo.statistics.firstTryCorrect, 5);
      expect(repo.mastery.values, everyElement(1));
      expect(repo.mastery, hasLength(5));
      expect(repo.restore(), isNull);
      final replay = LearnLettersGame.fromJson(
        game.toJson()..['answered'] = false,
      );
      await repo.save(replay);
      expect(repo.hasActiveGame, isFalse);
    },
  );

  test(
    'mastery excludes wrong answers and ignores abandoned partial rounds',
    () async {
      final repo = LearnLettersRepository(MemoryKeyValueStore());
      final game = repo.newGame(random: Random(6));
      final missedId = game.currentLetter.id;
      game.answer(game.choices.firstWhere((e) => e.id != missedId).id);
      game.answer(missedId);
      await repo.save(game);
      expect(repo.mastery, isEmpty);
      finish(game);
      await repo.save(game);
      expect(repo.mastery[missedId], isNull);
      expect(repo.statistics.answers, 6);
      expect(repo.statistics.firstTryCorrect, 4);
    },
  );

  test(
    'queued save captures call-time game and reset waits for pending writes',
    () async {
      final store = DelayedLetterStore()..gate = Completer<void>();
      store.values['unrelated'] = 'keep';
      final repo = LearnLettersRepository(store);
      final game = repo.newGame(random: Random(7));
      final pending = repo.save(game);
      game.answer(game.currentLetter.id);
      store.gate!.complete();
      await pending;
      expect(repo.restore()!.answered, isFalse);
      store.gate = Completer<void>();
      final saving = repo.save(game);
      final reset = repo.resetAll();
      store.gate!.complete();
      await Future.wait([saving, reset]);
      expect(store.values, {'unrelated': 'keep'});
    },
  );

  test('failed completion can retry without duplicated statistics', () async {
    final store = DelayedLetterStore();
    final repo = LearnLettersRepository(store);
    final game = repo.newGame(random: Random(8));
    finish(game);
    store.failNext = true;
    await expectLater(repo.save(game), throwsStateError);
    expect(repo.statistics.roundsCompleted, 0);
    await repo.save(game);
    expect(repo.statistics.roundsCompleted, 1);
  });

  test('corrupt repository state falls back safely', () async {
    final store = MemoryKeyValueStore();
    final repo = LearnLettersRepository(store);
    for (final raw in [
      'broken',
      '{}',
      '{"schemaVersion":1,"mastery":{"unknown":7}}',
    ]) {
      store.values[LearnLettersRepository.storageKey] = raw;
      expect(repo.restore(), isNull);
      expect(repo.mastery, isEmpty);
      expect(repo.statistics.roundsCompleted, 0);
    }
    await repo.save(repo.newGame(random: Random(9)));
    expect(repo.hasActiveGame, isTrue);
  });

  test(
    'mastery reaches three only across three distinct completed rounds',
    () async {
      final repo = LearnLettersRepository(MemoryKeyValueStore());
      for (var round = 0; round < 21; round++) {
        final game = repo.newGame(random: Random(round));
        finish(game);
        await repo.save(game);
        await repo.save(game);
      }
      expect(repo.statistics.roundsCompleted, 21);
      expect(repo.mastery, hasLength(35));
      expect(repo.mastery.values, everyElement(3));
    },
  );
}
