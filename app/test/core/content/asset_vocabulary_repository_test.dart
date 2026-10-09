import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/word_pool.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_vocabulary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('both decoding paths identify a malformed record', () async {
    const documents = ['[{"id":"broken_record"}]'];
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
    final result = decodeVocabularyCooperatively(['[]', '[]']).then((entries) {
      completed = true;
      return entries;
    });
    await Future<void>.value();
    expect(completed, isFalse);
    expect(await result, decodeVocabularyDocuments(['[]', '[]']));
  });

  test('loads the replacement offline dictionary and varied game pools', () async {
    final entries = await AssetVocabularyRepository().load();
    final pool = WordPool(entries);
    final quest = WordQuestVocabulary(entries);
    expect(entries.length, inInclusiveRange(6000, 10000));
    expect(
      entries.every(
        (e) => e.id.startsWith('en_v2_') || e.id.startsWith('panjabi_v2_'),
      ),
      isTrue,
    );
    expect(entries.every((e) => e.hasDistributableDefinition), isTrue);
    expect(
      entries.every((e) => e.reviewStatus.name == 'machineChecked'),
      isTrue,
    );
    for (final mode in LanguageMode.values) {
      for (final length in [4, 5, 6]) {
        final answers = pool.solutions(mode: mode, wordLength: length);
        final clues = quest
            .words(mode: mode)
            .where((w) => w.graphemeLength == length);
        expect(
          answers.length,
          greaterThanOrEqualTo(5),
          reason: '${mode.name}/$length',
        );
        expect(
          clues.length,
          greaterThanOrEqualTo(5),
          reason: 'Quest ${mode.name}/$length',
        );
      }
    }
    for (final word in ['VOTARY', 'BATHOS', 'ECLAT', 'LUST', 'STUD', 'TWAT']) {
      expect(
        pool.entryForGuess(mode: LanguageMode.english, guess: word),
        isNull,
      );
    }
    for (final word in ['BUTTERFLY', 'ELEPHANT', 'MOUNTAIN']) {
      final entry = entries.singleWhere(
        (e) => e.latin == word && e.id.startsWith('en_v2_'),
      );
      expect(entry.solutionEligible, isTrue);
      expect(entry.latinLength, greaterThan(6));
    }
    expect(
      pool
          .entryForGuess(mode: LanguageMode.english, guess: 'HOME')
          ?.englishDefinition,
      'Where a person lives.',
    );
    expect(
      pool
          .entryForGuess(mode: LanguageMode.english, guess: 'APPLE')
          ?.englishDefinition,
      'A sweet, red, yellow or green fruit.',
    );
    expect(
      entries.any((e) => e.id == 'english_home'),
      isFalse,
      reason:
          'Old English target IDs must not silently restore with a new meaning',
    );
  });

  test(
    'random answers favor everyday child vocabulary while lookup stays broader',
    () async {
      final entries = await AssetVocabularyRepository().load();
      final english = {
        for (final entry in entries.where((e) => e.id.startsWith('en_v2_')))
          entry.latin: entry,
      };
      for (final word in [
        'CORPORATION',
        'FINANCE',
        'RESEARCH',
        'SECONDARY',
        'SOCIETY',
        'COMMENT',
        'CURRENT',
        'DON',
        'FRANK',
      ]) {
        final entry = english[word]!;
        expect(entry.acceptedGuess, isTrue, reason: word);
        expect(entry.hasDistributableDefinition, isTrue, reason: word);
        expect(entry.solutionEligible, isFalse, reason: word);
        expect(entry.reviewStatus.name, 'machineChecked', reason: word);
      }
      for (final word in [
        'HAPPY',
        'SHARE',
        'LEARN',
        'PRACTICE',
        'USEFUL',
        'TREE',
        'LAKE',
        'BUTTERFLY',
      ]) {
        expect(english[word]!.solutionEligible, isTrue, reason: word);
      }
      // The pinned RULE source was vandalized, so it must not enter lookup either.
      expect(english.containsKey('RULE'), isFalse);
      expect(
        entries.any(
          (e) => e.englishDefinition.toLowerCase().contains('master bait'),
        ),
        isFalse,
      );
    },
  );
}
