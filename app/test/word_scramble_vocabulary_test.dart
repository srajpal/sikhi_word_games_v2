import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/content/answer_eligibility.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/domain/word_scramble_vocabulary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'approved masters feed isolated pools, with source units and mixed lengths',
    () async {
      final entries = await AssetVocabularyRepository().load();
      final vocabulary = WordScrambleVocabulary(entries);
      final byId = {for (final entry in entries) entry.id: entry};
      for (final mode in LanguageMode.values) {
        expect(vocabulary.words(mode), isNotEmpty);
        for (final word in vocabulary.words(mode)) {
          final entry = byId[word.id]!;
          expect(entry.supportsScript(mode.script), isTrue);
          expect(word.definition, entry.displayDefinition);
        }
      }
      expect(
        vocabulary
            .words(LanguageMode.english)
            .any((word) => word.spelling == 'MICE'),
        isTrue,
      );
      expect(
        vocabulary
            .words(LanguageMode.gurmukhi)
            .any((word) => word.spelling == 'ਅਪ੍ਰੈਲ'),
        isTrue,
      );
      expect(
        vocabulary.simpleRomanized
            .words(LanguageMode.romanizedPanjabi)
            .any((word) => word.spelling == 'ASAN'),
        isTrue,
      );
      expect(
        vocabulary
            .words(LanguageMode.romanizedPanjabi)
            .any((word) => word.spelling == 'ĀSĀN'),
        isTrue,
      );
      final gurEntries = entries.where(
        (entry) => entry.script == VocabularyScript.gurmukhi,
      );
      expect(
        gurEntries.any((entry) => (entry.gurmukhiLength ?? 0) > 6),
        isTrue,
      );
    },
  );
  test(
    'a pool is exhausted before repeats, then avoids the previous word',
    () async {
      final entries = (await AssetVocabularyRepository().load())
          .where(
            (e) =>
                e.script == VocabularyScript.english &&
                AnswerEligibility.allows(e, VocabularyScript.english),
          )
          .take(4);
      final vocabulary = WordScrambleVocabulary(entries), seen = <String>{};
      String? previous;
      for (var i = 0; i < 4; i++) {
        final word = vocabulary.choose(
          LanguageMode.english,
          random: Random(i),
          seen: seen,
          previous: previous,
        )!;
        expect(seen.add(word.id), isTrue);
        previous = word.id;
      }
      expect(
        vocabulary
            .choose(
              LanguageMode.english,
              random: Random(9),
              seen: seen,
              previous: previous,
            )!
            .id,
        isNot(previous),
      );
    },
  );
}
