import 'dart:convert';
import 'dart:io';

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
      for (final size in [4, 5, 6])
        for (final record in jsonDecode(
          File('assets/content/release/vocabulary_$size.json')
              .readAsStringSync(),
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
      expect(content.decksFor(LanguageMode.mixedLatin), isEmpty);
    },
  );

  test(
    'missing, held, and duplicate records omit the entire affected deck',
    () {
      final original = release.firstWhere((e) => e.id == 'english_book');
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
        e.id == 'panjabi_ghar' ? e.copyWith(gurmukhi: '') : e,
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
      expect(content.romanizedFor('english_book'), isNull);
    },
  );

  test(
    'romanization excludes omitted Gurmukhi decks and trims source text',
    () {
      final trimmed = WordBridgesContent([
        for (final entry in release)
          entry.id == 'panjabi_ghar'
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
      expect(trimmed.romanizedFor('panjabi_ghar'), 'GHAR');
      final missing = WordBridgesContent(
        release.where((entry) => entry.id != 'panjabi_ghar'),
      );
      expect(missing.romanizedFor('panjabi_ghar'), isNull);
      expect(missing.romanizedFor('panjabi_pani'), isNull);
      expect(missing.romanizedFor('panjabi_phull'), isNotNull);
    },
  );

  test('decks and pairs cannot be changed by callers', () {
    final content = WordBridgesContent(release);
    final decks = content.decksFor(LanguageMode.english);
    expect(() => decks.clear(), throwsUnsupportedError);
    expect(() => decks.first.pairs.clear(), throwsUnsupportedError);
    expect(() => content.availableModes.clear(), throwsUnsupportedError);
  });
}
