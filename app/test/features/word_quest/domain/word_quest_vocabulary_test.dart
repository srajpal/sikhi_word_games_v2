import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_vocabulary.dart';

void main() {
  final entries = <VocabularyEntry>[
    _entry('english_sun', VocabularyLanguage.english, 'SUN', 'bright star'),
    _entry(
      'english_garden',
      VocabularyLanguage.english,
      'GARDEN',
      'place to grow flowers',
    ),
    _entry(
      'english_long',
      VocabularyLanguage.english,
      'ELEPHANTS',
      'large animals',
    ),
    _entry('english_blank', VocabularyLanguage.english, 'BLANK', '   '),
    _entry(
      'panjabi_baag',
      VocabularyLanguage.panjabi,
      'BAAG',
      'orchard',
      gurmukhi: 'ਬਾਗ',
    ),
    _entry(
      'panjabi_mahan',
      VocabularyLanguage.panjabi,
      'GURMAT',
      'the Guru’s teaching',
      gurmukhi: 'ਗੁਰਮਤਿ',
      source: 'Mahan Kosh multilingual dataset',
    ),
    _entry(
      'panjabi_no_gurmukhi',
      VocabularyLanguage.panjabi,
      'SABAD',
      'sacred hymn',
    ),
    _entry(
      'duplicate_low',
      VocabularyLanguage.english,
      'SUN',
      'old definition',
    ),
    _entry(
      'duplicate_best',
      VocabularyLanguage.english,
      ' sun ',
      'a bright star',
      reviewStatus: ReviewStatus.editorApproved,
      solutionEligible: true,
    ),
    _entry(
      'not_accepted',
      VocabularyLanguage.english,
      'MOON',
      'earth satellite',
      acceptedGuess: false,
    ),
    _entry(
      'guess_only',
      VocabularyLanguage.english,
      'GINN',
      'a small horse or pony',
      solutionEligible: false,
    ),
  ];

  test('loads curated solution spellings with standalone clues', () async {
    final vocabulary = await WordQuestVocabulary.load(
      MemoryVocabularyRepository(entries),
    );

    expect(
      vocabulary.words(mode: LanguageMode.english).map((word) => word.id),
      containsAll(['duplicate_best', 'english_garden']),
    );
    expect(
      vocabulary.words(mode: LanguageMode.english).map((word) => word.id),
      isNot(contains('english_blank')),
    );
    expect(
      vocabulary.words(mode: LanguageMode.english).map((word) => word.id),
      isNot(contains('guess_only')),
    );
  });

  test('uses each language mode’s active spelling', () {
    final vocabulary = WordQuestVocabulary(entries);

    expect(
      vocabulary.words(mode: LanguageMode.english).map((word) => word.spelling),
      isNot(contains('BAAG')),
    );
    expect(
      vocabulary
          .words(mode: LanguageMode.romanizedPanjabi)
          .map((word) => word.spelling),
      containsAll(['BAAG', 'GURMAT', 'SABAD']),
    );
    expect(
      vocabulary
          .words(mode: LanguageMode.gurmukhi)
          .map((word) => word.spelling),
      containsAll(['ਬਾਗ', 'ਗੁਰਮਤਿ']),
    );
    expect(
      vocabulary
          .words(mode: LanguageMode.gurmukhi)
          .map((word) => word.spelling),
      isNot(contains('SABAD')),
    );
    expect(
      vocabulary
          .words(mode: LanguageMode.mixedLatin)
          .map((word) => word.spelling),
      containsAll(['SUN', 'BAAG']),
    );
  });

  test('prefers 3–7 grapheme words but falls back when needed', () {
    final vocabulary = WordQuestVocabulary(entries);

    expect(
      vocabulary.words(mode: LanguageMode.english).map((word) => word.spelling),
      isNot(contains('ELEPHANTS')),
    );
    expect(
      vocabulary
          .words(mode: LanguageMode.english, preferKidManageable: false)
          .map((word) => word.spelling),
      contains('ELEPHANTS'),
    );

    final fallback = WordQuestVocabulary([
      _entry('long', VocabularyLanguage.english, 'ELEPHANTS', 'large animals'),
    ]);
    expect(
      fallback.words(mode: LanguageMode.english).single.spelling,
      'ELEPHANTS',
    );
  });

  test('deduplicates active spellings using the highest-quality entry', () {
    final vocabulary = WordQuestVocabulary(entries);
    final sun = vocabulary.wordForSpelling(
      mode: LanguageMode.english,
      spelling: ' SUN ',
    );

    expect(sun?.id, 'duplicate_best');
    expect(sun?.definitionHint, 'a bright star');
  });

  test('exposes definition and source-derived category hints', () {
    final vocabulary = WordQuestVocabulary(entries);
    final word = vocabulary.wordForSpelling(
      mode: LanguageMode.romanizedPanjabi,
      spelling: 'GURMAT',
    );

    expect(word?.definitionHint, 'the Guru’s teaching');
    expect(word?.categoryHint, 'Sikhi vocabulary');
    expect(word?.source, contains('Mahan Kosh'));
  });

  test('selector is injectable, non-repeating, and rejects empty input', () {
    final selector = WordQuestWordSelector(random: Random(4));
    final candidates = WordQuestVocabulary(entries)
        .words(mode: LanguageMode.romanizedPanjabi);

    final first = selector.select(candidates);
    final second = selector.select(candidates);
    final third = selector.select(candidates);

    expect({first.id, second.id, third.id}, hasLength(3));
    expect(() => selector.select(const []), throwsStateError);
  });
}

VocabularyEntry _entry(
  String id,
  VocabularyLanguage language,
  String latin,
  String definition, {
  String? gurmukhi,
  bool acceptedGuess = true,
  bool solutionEligible = true,
  ReviewStatus reviewStatus = ReviewStatus.unreviewed,
  String source = 'test source',
}) => VocabularyEntry(
  id: id,
  language: language,
  latin: latin,
  gurmukhi: gurmukhi,
  englishDefinition: definition,
  latinLength: latin.length,
  gurmukhiLength: gurmukhi?.length,
  acceptedGuess: acceptedGuess,
  solutionEligible: solutionEligible,
  reviewStatus: reviewStatus,
  source: source,
);
