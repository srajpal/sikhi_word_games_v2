import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/word_pool.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_vocabulary.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';
import 'package:sikhi_word_games_v2/features/word_search/domain/word_search_puzzle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('both decoding paths identify a malformed native record', () async {
    const documents = ['{"words":[{"word":"broken_record"}]}'];
    final failure = isA<FormatException>().having(
      (e) => e.message,
      'record identity',
      contains('broken_record'),
    );
    expect(() => decodeVocabularyDocuments(documents), throwsA(failure));
    await expectLater(
      decodeVocabularyCooperatively(documents),
      throwsA(failure),
    );
  });
  test('web decoding yields before work and matches native decoding', () async {
    var completed = false;
    const documents = ['{"words":[]}', '{"words":[]}', '{"words":[]}'];
    final result = decodeVocabularyCooperatively(documents).then((entries) {
      completed = true;
      return entries;
    });
    await Future<void>.value();
    expect(completed, isFalse);
    expect(await result, decodeVocabularyDocuments(documents));
  });

  test(
    'every approved word belongs to its own script and stays eligible',
    () async {
      final repository = AssetVocabularyRepository();
      final entries = await repository.load();
      expect(await repository.load(), same(entries));
      expect(entries, hasLength(20601));
      expect(
        entries.every(
          (e) =>
              e.isOwnerApproved &&
              e.acceptedGuess &&
              e.solutionEligible &&
              e.hasDistributableDefinition,
        ),
        isTrue,
      );
      final pool = WordPool(entries);
      final quest = WordQuestVocabulary(entries);
      final bridges = WordBridgesContent(entries);
      const counts = {
        LanguageMode.english: {4: 2346, 5: 4144, 6: 6692},
        LanguageMode.romanizedPanjabi: {4: 658, 5: 1354, 6: 979},
        LanguageMode.gurmukhi: {
          2: 1515,
          3: 1865,
          4: 787,
          5: 220,
          6: 33,
          7: 7,
          8: 1,
        },
      };
      for (final mode in LanguageMode.values) {
        final total = counts[mode]!.values.reduce((a, b) => a + b);
        expect(
          entries.where((e) => e.supportsScript(mode.script)),
          hasLength(total),
        );
        expect(bridges.pairsFor(mode), hasLength(total));
        expect(
          quest.words(mode: mode, preferKidManageable: false),
          hasLength(total),
        );
        for (final bucket in counts[mode]!.entries) {
          final solutions = pool.solutions(mode: mode, wordLength: bucket.key);
          expect(
            solutions,
            hasLength(bucket.value),
            reason: '${mode.name}/${bucket.key}',
          );
          expect(
            pool.acceptedGuesses(mode: mode, wordLength: bucket.key),
            hasLength(bucket.value),
          );
          expect(
            quest
                .words(mode: mode, preferKidManageable: false)
                .where((w) => w.graphemeLength == bucket.key),
            hasLength(bucket.value),
          );
        }
      }
      expect(pool.charactersFor(LanguageMode.romanizedPanjabi), hasLength(53));
      expect(
        pool.entryForGuess(mode: LanguageMode.english, guess: 'HOME'),
        isNotNull,
      );
      expect(entries.any((e) => e.id.startsWith('en_v2_')), isFalse);
      expect(() => entries.clear(), throwsUnsupportedError);
    },
  );

  test(
    'joined Gurmukhi letters survive Bujho, Quest, Khoj and restoration',
    () async {
      final entries = await AssetVocabularyRepository().load();
      final pool = WordPool(entries);
      final entry = pool.entryForGuess(
        mode: LanguageMode.gurmukhi,
        guess: 'ਉਪਗ੍ਰਹਿ',
      )!;
      expect(entry.gurmukhiLength, 4);
      final guess = GuessGame(
        solution: entry.gurmukhi!,
        acceptedGuesses: pool.acceptedGuesses(
          mode: LanguageMode.gurmukhi,
          wordLength: 4,
        ),
      );
      expect(guess.submit(entry.gurmukhi!).isAccepted, isTrue);
      expect(guess.turns.single.evaluation, hasLength(4));
      expect(
        GuessGame.restore(
          json: guess.toJson(),
          acceptedGuesses: guess.acceptedGuesses,
        ).status,
        GuessGameStatus.won,
      );
      final quest = WordQuestGame(solution: entry.gurmukhi!);
      expect(quest.maximumTries, 3);
      for (final unit in wordUnits(entry.gurmukhi!)) {
        quest.guess(unit);
      }
      expect(quest.status, WordQuestStatus.won);
      final puzzle = WordSearchGenerator(random: Random(41)).generate(
        candidates: [entry.gurmukhi!, 'ਅਪ੍ਰੈਲ', 'ਅੰਨ੍ਹਾ'],
        fillerCharacters: ['ਕ', 'ਪ੍ਰੈ', 'ਗ੍ਰ'],
        size: 6,
        targetWordCount: 3,
      );
      expect(puzzle.words, hasLength(3));
      expect(
        WordSearchPuzzle.fromJson(
          jsonDecode(jsonEncode(puzzle.toJson())) as Map<String, Object?>,
        ).toJson(),
        puzzle.toJson(),
      );
      expect(
        puzzle.cells
            .expand((row) => row)
            .every((cell) => wordUnitCount(cell) == 1),
        isTrue,
      );
    },
  );

  test(
    'Romanized accents distinguish approved words and equivalent input matches',
    () async {
      final pool = WordPool(await AssetVocabularyRepository().load());
      final a = pool.entryForGuess(
        mode: LanguageMode.romanizedPanjabi,
        guess: 'āsān',
      )!;
      final b = pool.entryForGuess(
        mode: LanguageMode.romanizedPanjabi,
        guess: 'asān',
      )!;
      expect(a.id, isNot(b.id));
      expect(
        pool
            .entryForGuess(
              mode: LanguageMode.romanizedPanjabi,
              guess: 'a\u0304sa\u0304n',
            )
            ?.id,
        a.id,
      );
      final game = GuessGame(solution: a.latin, acceptedGuesses: {a.latin});
      expect(game.submit('a\u0304sa\u0304n').isAccepted, isTrue);
      expect(game.status, GuessGameStatus.won);
    },
  );
}
