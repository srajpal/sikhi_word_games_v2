import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';

void main() {
  late List<VocabularyEntry> release;

  setUpAll(() {
    release = [
      for (final language in ['english', 'punjabi'])
        for (final record in jsonDecode(
          File('assets/content/release/${language}_v2.json').readAsStringSync(),
        ) as List)
          VocabularyEntry.fromJson(Map<String, Object?>.from(record as Map)),
    ];
  });

  test(
    'all starter decks resolve to distinct eligible release records',
    () async {
      final content = await WordBridgesContent.load(
        MemoryVocabularyRepository(release),
      );
      final byId = {for (final entry in release) entry.id: entry};
      expect(content.availableModes, [
        LanguageMode.english,
        LanguageMode.romanizedPanjabi,
        LanguageMode.gurmukhi,
      ]);
      for (final mode in content.availableModes) {
        final decks = content.decksFor(mode);
        expect(decks, hasLength(2));
        for (final deck in decks) {
          expect(deck.pairs, hasLength(4));
          expect(deck.pairs.map((p) => p.id).toSet(), hasLength(4));
          expect(deck.pairs.map((p) => p.word).toSet(), hasLength(4));
          expect(deck.pairs.map((p) => p.meaning).toSet(), hasLength(4));
          for (final pair in deck.pairs) {
            final entry = byId[pair.id]!;
            expect(entry.acceptedGuess, isTrue);
            expect(entry.solutionEligible, isTrue);
            expect(entry.hasDistributableDefinition, isTrue);
            expect(pair.meaning, entry.displayDefinition);
            expect(
              pair.word,
              mode == LanguageMode.gurmukhi ? entry.gurmukhi : entry.latin,
            );
          }
        }
      }
    },
  );

  test(
    'missing, held, and duplicate records omit the entire affected deck',
    () {
      final original = release.firstWhere((e) => e.id == 'en_v2_book');
      for (final entries in [
        release.where((e) => e.id != original.id).toList(),
        [
          for (final e in release)
            e.id == original.id ? e.copyWith(solutionEligible: false) : e,
        ],
        [
          for (final e in release)
            e.id == original.id ? e.copyWith(acceptedGuess: false) : e,
        ],
        [
          for (final e in release)
            e.id == original.id ? e.copyWith(source: 'Unclear source') : e,
        ],
        [...release, original],
      ]) {
        final decks = WordBridgesContent(entries)
            .decksFor(LanguageMode.english);
        expect(decks, hasLength(1));
        expect(decks.single.id, 'english_outdoors_and_food');
      }
    },
  );

  test('missing script disables only that deck in Gurmukhi', () {
    final changed = [
      for (final e in release)
        e.id == 'panjabi_v2_a15_a3f_a24_a3e_a2c' ? e.copyWith(gurmukhi: '') : e,
    ];
    final content = WordBridgesContent(changed);
    expect(content.decksFor(LanguageMode.gurmukhi), hasLength(1));
    expect(content.decksFor(LanguageMode.romanizedPanjabi), hasLength(2));
    expect(WordBridgesContent([]).availableModes, isEmpty);
  });

  test(
    'Gurmukhi pairs resolve source romanization after session restore',
    () async {
      final content = WordBridgesContent(release);
      final byId = {for (final entry in release) entry.id: entry};
      final repository = WordBridgesRepository(MemoryKeyValueStore());
      for (final deck in content.decksFor(LanguageMode.gurmukhi)) {
        await repository.save(
          mode: LanguageMode.gurmukhi,
          game: WordBridgesGame(pairs: deck.pairs),
        );
        final restored = repository.restore()!;
        for (final pair in restored.game.wordOrder) {
          final sourceSpelling = byId[pair.id]!.latin.trim();
          expect(sourceSpelling, isNotEmpty);
          expect(content.romanizedFor(pair.id), sourceSpelling);
          expect(pair.toJson().containsKey('romanized'), isFalse);
        }
      }
      expect(content.romanizedFor('unknown'), isNull);
      expect(content.romanizedFor('en_v2_book'), isNull);
    },
  );

  test('romanization excludes missing words and trims source text', () {
    final trimmed = WordBridgesContent([
      for (final entry in release)
        entry.id == 'panjabi_v2_a15_a3f_a24_a3e_a2c'
            ? VocabularyEntry(
                id: entry.id,
                language: entry.language,
                latin: '  GHAR  ',
                gurmukhi: entry.gurmukhi,
                englishDefinition: entry.englishDefinition,
                latinLength: entry.latinLength,
                gurmukhiLength: entry.gurmukhiLength,
                acceptedGuess: entry.acceptedGuess,
                solutionEligible: entry.solutionEligible,
                reviewStatus: entry.reviewStatus,
                source: entry.source,
              )
            : entry,
    ]);
    expect(trimmed.romanizedFor('panjabi_v2_a15_a3f_a24_a3e_a2c'), 'GHAR');
    final missing = WordBridgesContent(
      release.where((entry) => entry.id != 'panjabi_v2_a15_a3f_a24_a3e_a2c'),
    );
    expect(missing.romanizedFor('panjabi_v2_a15_a3f_a24_a3e_a2c'), isNull);
    expect(missing.romanizedFor('panjabi_v2_a2a_a3e_a23_a40'), 'PANI');
    expect(missing.romanizedFor('panjabi_v2_a2b_a41_a71_a32'), isNotNull);
  });

  test('decks and pairs cannot be changed by callers', () {
    final content = WordBridgesContent(release);
    final decks = content.decksFor(LanguageMode.english);
    expect(() => decks.clear(), throwsUnsupportedError);
    expect(() => decks.first.pairs.clear(), throwsUnsupportedError);
    expect(() => content.availableModes.clear(), throwsUnsupportedError);
  });

  test('new sets use a broad eligible pool, varying lengths and avoiding recent words', () {
    final content = WordBridgesContent(release);
    final eligible = {for (final entry in release) entry.id: entry};
    for (final mode in LanguageMode.values) {
      final used = <String>{};
      var previous = <String>{};
      final random = Random(92);
      final lengths = <int>{};
      for (var i = 0; i < 20; i++) {
        final pairs = content.chooseSet(
          mode,
          random: random,
          usedIds: used,
          previousIds: previous,
        )!;
        final ids = pairs.map((p) => p.id).toSet();
        expect(ids.intersection(previous), isEmpty);
        for (final pair in pairs) {
          final entry = eligible[pair.id]!;
          expect(
            entry.solutionEligible && entry.hasDistributableDefinition,
            isTrue,
          );
          lengths.add(
            mode == LanguageMode.gurmukhi
                ? entry.gurmukhiLength!
                : entry.latinLength,
          );
          for (final other in pairs.where((p) => p.id != pair.id)) {
            expect(WordBridgesContent.ambiguous(pair, other), isFalse);
          }
        }
        used.addAll(ids);
        previous = ids;
      }
      expect(used.length, greaterThan(60));
      expect(lengths.length, greaterThan(1));
    }
  });
}
