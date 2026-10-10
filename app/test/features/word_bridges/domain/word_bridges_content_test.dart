import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/answer_eligibility.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_game.dart';

void main() {
  late List<VocabularyEntry> release;
  late WordBridgesContent content;

  setUpAll(() {
    release = decodeVocabularyDocuments([
      for (final path in AssetVocabularyRepository.assetPaths)
        File(path).readAsStringSync(),
    ]);
    content = WordBridgesContent(release);
  });

  test(
    'eligible mode answers retain their original meanings and provenance',
    () async {
      final loaded = await WordBridgesContent.load(
        MemoryVocabularyRepository(release),
      );
      expect(loaded.availableModes, LanguageMode.values);
      const counts = {
        LanguageMode.english: 13182,
        LanguageMode.romanizedPanjabi: 2991,
        LanguageMode.gurmukhi: 4428,
      };
      final byId = {for (final entry in release) entry.id: entry};
      for (final mode in LanguageMode.values) {
        final expected = release.where(
          (entry) =>
              entry.script == mode.script &&
              AnswerEligibility.allows(entry, mode.script),
        );
        final pairs = loaded.pairsFor(mode);
        expect(
          release.where((entry) => entry.script == mode.script),
          hasLength(counts[mode]!),
        );
        expect(pairs, hasLength(expected.length));
        expect(
          pairs.map((pair) => pair.id).toSet(),
          expected.map((e) => e.id).toSet(),
        );
        expect(
          pairs.map((pair) => pair.word).toSet(),
          hasLength(expected.length),
        );
        for (final pair in pairs) {
          final entry = byId[pair.id]!;
          expect(entry.isOwnerApproved, isTrue);
          expect(entry.acceptedGuess && entry.solutionEligible, isTrue);
          expect(entry.hasDistributableDefinition, isTrue);
          expect(pair.meaning, entry.displayDefinition);
          expect(
            pair.word,
            mode == LanguageMode.gurmukhi ? entry.gurmukhi : entry.latin,
          );
        }
      }
    },
  );

  test(
    'preview decks expose four pairs without a fixed legacy starter list',
    () {
      for (final mode in LanguageMode.values) {
        final decks = content.decksFor(mode);
        expect(decks, hasLength(1));
        expect(decks.single.id, '${mode.name}_preview');
        expect(decks.single.pairs, hasLength(4));
        for (final pair in decks.single.pairs) {
          expect(content.containsPair(mode, pair), isTrue);
          for (final other in decks.single.pairs.where(
            (p) => p.id != pair.id,
          )) {
            expect(WordBridgesContent.ambiguous(pair, other), isFalse);
          }
        }
      }
      expect(WordBridgesContent([]).availableModes, isEmpty);
      expect(
        WordBridgesContent([])
            .chooseSet(LanguageMode.english, random: Random(1)),
        isNull,
      );
    },
  );

  test(
    'counterpart metadata never introduces membership in another script',
    () {
      final native = release.firstWhere(
        (entry) => entry.script == VocabularyScript.gurmukhi,
      );
      final roman = release.firstWhere(
        (entry) => entry.script == VocabularyScript.romanizedPunjabi,
      );
      expect(native.latin, isNotEmpty);
      expect(roman.gurmukhi, isNotEmpty);
      final nativeOnly = WordBridgesContent([native]);
      final romanOnly = WordBridgesContent([roman]);
      expect(nativeOnly.pairsFor(LanguageMode.gurmukhi).single.id, native.id);
      expect(nativeOnly.pairsFor(LanguageMode.romanizedPanjabi), isEmpty);
      expect(
        romanOnly.pairsFor(LanguageMode.romanizedPanjabi).single.id,
        roman.id,
      );
      expect(romanOnly.pairsFor(LanguageMode.gurmukhi), isEmpty);
      expect(nativeOnly.pairsFor(LanguageMode.english), isEmpty);
      expect(romanOnly.pairsFor(LanguageMode.english), isEmpty);
      expect(romanOnly.romanizedFor(roman.id), isNull);
    },
  );

  test(
    'missing, ineligible, unlicensed and duplicate IDs cannot restore a pair',
    () {
      final entries = release
          .where(
            (entry) =>
                entry.script == VocabularyScript.english &&
                AnswerEligibility.allows(entry, VocabularyScript.english),
          )
          .take(5)
          .toList();
      final original = entries.first;
      final saved = WordBridgesContent(entries)
          .pairsFor(LanguageMode.english)
          .first;
      for (final changed in [
        entries.skip(1).toList(),
        [original.copyWith(solutionEligible: false), ...entries.skip(1)],
        [original.copyWith(acceptedGuess: false), ...entries.skip(1)],
        [original.copyWith(source: 'Unclear source'), ...entries.skip(1)],
        [...entries, original],
      ]) {
        final changedContent = WordBridgesContent(changed);
        expect(
          changedContent.containsPair(LanguageMode.english, saved),
          isFalse,
        );
        expect(changedContent.pairsFor(LanguageMode.english), hasLength(4));
        expect(changedContent.availableModes, [LanguageMode.english]);
        expect(
          changedContent
              .pairsFor(LanguageMode.english)
              .any((pair) => pair.id == original.id),
          isFalse,
        );
      }
      expect(content.containsPair(LanguageMode.english, saved), isTrue);
      expect(content.containsPair(LanguageMode.gurmukhi, saved), isFalse);
      expect(
        content.containsPair(
          LanguageMode.english,
          BridgePair(
            id: saved.id,
            word: saved.word,
            meaning: 'Changed meaning',
          ),
        ),
        isFalse,
      );
      expect(
        content.containsPair(
          LanguageMode.english,
          BridgePair(id: saved.id, word: 'OTHER', meaning: saved.meaning),
        ),
        isFalse,
      );
    },
  );

  test('an absent native spelling removes only its own script pair', () {
    final native = release.firstWhere(
      (entry) => entry.script == VocabularyScript.gurmukhi,
    );
    final changed = WordBridgesContent([
      for (final entry in release)
        entry.id == native.id ? entry.copyWith(gurmukhi: '') : entry,
    ]);
    expect(
      changed.pairsFor(LanguageMode.gurmukhi),
      hasLength(content.pairsFor(LanguageMode.gurmukhi).length - 1),
    );
    expect(
      changed.pairsFor(LanguageMode.romanizedPanjabi),
      hasLength(content.pairsFor(LanguageMode.romanizedPanjabi).length),
    );
    expect(
      changed.pairsFor(LanguageMode.english),
      hasLength(content.pairsFor(LanguageMode.english).length),
    );
    expect(changed.romanizedFor(native.id), isNull);
  });

  test(
    'restored native pairs resolve unchanged scholarly Romanization',
    () async {
      final byId = {for (final entry in release) entry.id: entry};
      final pairs = content.chooseSet(
        LanguageMode.gurmukhi,
        random: Random(17),
      )!;
      final repository = WordBridgesRepository(MemoryKeyValueStore());
      await repository.save(
        mode: LanguageMode.gurmukhi,
        game: WordBridgesGame(pairs: pairs),
      );
      final restored = repository.restore()!;
      expect(restored.mode, LanguageMode.gurmukhi);
      for (final pair in restored.game.wordOrder) {
        expect(content.containsPair(restored.mode, pair), isTrue);
        expect(content.romanizedFor(pair.id), byId[pair.id]!.latin.trim());
        expect(pair.toJson().containsKey('romanized'), isFalse);
      }
      final scholarly = release.firstWhere(
        (entry) =>
            entry.script == VocabularyScript.gurmukhi &&
            RegExp(r'[^A-Z]').hasMatch(entry.latin),
      );
      expect(content.romanizedFor(scholarly.id), scholarly.latin);
      expect(content.romanizedFor('unknown'), isNull);
      expect(
        content.romanizedFor(
          release.firstWhere((e) => e.script == VocabularyScript.english).id,
        ),
        isNull,
      );
    },
  );

  test('native Romanization is trimmed without deriving another spelling', () {
    final native = release.firstWhere(
      (entry) => entry.script == VocabularyScript.gurmukhi,
    );
    final modified = VocabularyEntry(
      id: native.id,
      language: native.language,
      latin: '  ${native.latin}  ',
      gurmukhi: native.gurmukhi,
      englishDefinition: native.englishDefinition,
      latinLength: native.latinLength,
      gurmukhiLength: native.gurmukhiLength,
      acceptedGuess: native.acceptedGuess,
      solutionEligible: native.solutionEligible,
      reviewStatus: native.reviewStatus,
      source: native.source,
      script: native.script,
    );
    final trimmed = WordBridgesContent([modified]);
    expect(trimmed.romanizedFor(native.id), native.latin);
    expect(trimmed.pairsFor(LanguageMode.romanizedPanjabi), isEmpty);
    expect(WordBridgesContent([]).romanizedFor(native.id), isNull);
  });

  test('short and long approved definitions remain globally eligible', () {
    final short = release.firstWhere(
      (entry) =>
          entry.script == VocabularyScript.english &&
          entry.englishDefinition.trim().length < 4,
    );
    final long = release.firstWhere(
      (entry) =>
          entry.script == VocabularyScript.english &&
          entry.englishDefinition.length > 180,
    );
    final pairs = content.pairsFor(LanguageMode.english);
    expect(
      pairs.firstWhere((pair) => pair.id == short.id).meaning,
      short.displayDefinition,
    );
    expect(
      pairs.firstWhere((pair) => pair.id == long.id).meaning,
      long.displayDefinition,
    );
  });

  test('conflicting clues are avoided only within a board', () {
    final entries = release
        .where((entry) => entry.script == VocabularyScript.english)
        .take(5)
        .toList();
    final clues = [
      'A striped animal.',
      'A striped animal.',
      'A glass vessel for keeping flowers.',
      'An instrument that points north.',
      'A spinning device for making yarn.',
    ];
    final matching = WordBridgesContent([
      for (var i = 0; i < entries.length; i++)
        entries[i].copyWith(englishDefinition: clues[i]),
    ]);
    expect(matching.pairsFor(LanguageMode.english), hasLength(5));
    expect(
      WordBridgesContent.ambiguous(
        matching.pairsFor(LanguageMode.english)[0],
        matching.pairsFor(LanguageMode.english)[1],
      ),
      isTrue,
    );
    for (var seed = 0; seed < 10; seed++) {
      final pairs = matching.chooseSet(
        LanguageMode.english,
        random: Random(seed),
      )!;
      expect(pairs, hasLength(4));
      for (final pair in pairs) {
        for (final other in pairs.where((other) => pair.id != other.id)) {
          expect(WordBridgesContent.ambiguous(pair, other), isFalse);
        }
      }
    }
  });

  test('preview, pool and selected pairs cannot be changed by callers', () {
    final decks = content.decksFor(LanguageMode.english);
    final selected = content.chooseSet(
      LanguageMode.english,
      random: Random(1),
    )!;
    expect(() => decks.clear(), throwsUnsupportedError);
    expect(() => decks.first.pairs.clear(), throwsUnsupportedError);
    expect(
      () => content.pairsFor(LanguageMode.english).clear(),
      throwsUnsupportedError,
    );
    expect(() => selected.clear(), throwsUnsupportedError);
    expect(() => content.availableModes.clear(), throwsUnsupportedError);
  });

  test('random sets vary lengths and avoid used and previous mode words', () {
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
        final ids = pairs.map((pair) => pair.id).toSet();
        expect(pairs, hasLength(4));
        expect(ids, hasLength(4));
        expect(ids.intersection(previous), isEmpty);
        expect(ids.intersection(used), isEmpty);
        for (final pair in pairs) {
          final entry = eligible[pair.id]!;
          expect(entry.script, mode.script);
          expect(content.containsPair(mode, pair), isTrue);
          lengths.add(
            mode == LanguageMode.gurmukhi
                ? entry.gurmukhiLength!
                : entry.latinLength,
          );
          for (final other in pairs.where((other) => pair.id != other.id)) {
            expect(WordBridgesContent.ambiguous(pair, other), isFalse);
          }
        }
        used.addAll(ids);
        previous = ids;
      }
      expect(used, hasLength(80));
      expect(lengths.length, greaterThan(1));
    }
  });
}
