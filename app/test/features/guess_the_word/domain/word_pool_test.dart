import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/word_pool.dart';

void main() {
  final entries = [
    _entry('english_hero', VocabularyLanguage.english, 'HERO', solution: true),
    _entry(
      'panjabi_baag',
      VocabularyLanguage.panjabi,
      'BAAG',
      gurmukhi: 'ਬਾਗ',
      solution: true,
    ),
    _entry(
      'panjabi_juna',
      VocabularyLanguage.panjabi,
      'JUNA',
      gurmukhi: 'ਜੁਨਾ',
    ),
  ];

  test('keeps accepted guesses separate from curated solutions', () {
    final pool = WordPool(entries);
    expect(
      pool
          .solutions(mode: LanguageMode.romanizedPanjabi, wordLength: 4)
          .map((entry) => entry.latin),
      ['BAAG'],
    );
    expect(
      pool.acceptedGuesses(mode: LanguageMode.romanizedPanjabi, wordLength: 4),
      {'BAAG', 'JUNA'},
    );
  });

  test('Mixed Latin accepts both English and romanized Panjabi', () {
    expect(
      WordPool(entries)
          .acceptedGuesses(mode: LanguageMode.mixedLatin, wordLength: 4),
      {'HERO', 'BAAG', 'JUNA'},
    );
  });

  test('Gurmukhi filters on visible grapheme length', () {
    expect(
      WordPool(entries)
          .acceptedGuesses(mode: LanguageMode.gurmukhi, wordLength: 2),
      {'ਬਾਗ', 'ਜੁਨਾ'},
    );
  });

  test('finds definition entries using the active language mode', () {
    final pool = WordPool(entries);
    expect(
      pool.entryForGuess(mode: LanguageMode.english, guess: ' hero ')?.id,
      'english_hero',
    );
    expect(
      pool.entryForGuess(mode: LanguageMode.gurmukhi, guess: 'ਬਾਗ')?.id,
      'panjabi_baag',
    );
    expect(
      pool.entryForGuess(mode: LanguageMode.english, guess: 'BAAG'),
      isNull,
    );
  });

  test('seeded selector does not repeat until the pool is exhausted', () {
    final selector = NonRepeatingWordSelector(random: Random(7));
    final first = selector.select(entries);
    final second = selector.select(entries);
    final third = selector.select(entries);
    expect({first.id, second.id, third.id}, hasLength(3));
    expect(() => selector.select(const []), throwsStateError);
  });
}

VocabularyEntry _entry(
  String id,
  VocabularyLanguage language,
  String latin, {
  String? gurmukhi,
  bool solution = false,
}) => VocabularyEntry(
  id: id,
  language: language,
  latin: latin,
  gurmukhi: gurmukhi,
  englishDefinition: 'Definition',
  latinLength: latin.length,
  gurmukhiLength: gurmukhi == null ? null : 2,
  acceptedGuess: true,
  solutionEligible: solution,
  reviewStatus: ReviewStatus.unreviewed,
  source: 'test',
);
