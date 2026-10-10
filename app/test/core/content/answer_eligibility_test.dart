import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/answer_eligibility.dart';
import 'package:sikhi_word_games_v2/core/content/romanized_vocabulary_views.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/word_pool.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_vocabulary.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/domain/word_scramble_vocabulary.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  test(
    'whole-word leaks respect Unicode, punctuation, case and attached marks',
    () {
      for (final (word, clue) in [
        ('abaca', 'hemp from the ABACA plant'),
        ('bhajan', 'devotional song, bhajan, hymn'),
        ('ĀSĀN', 'another spelling of a\u0304sa\u0304n'),
        ('ਨਿਸ਼ਾਨ', 'A ਨਿਸ਼ਾਨ.'),
      ]) {
        expect(AnswerEligibility.containsWholeWord(clue, word), isTrue);
      }
      for (final (word, clue) in [
        ('far', 'farther away'),
        ('sex', 'a sextant'),
        ('sus', 'Sussex'),
        ('ਸ', 'ਸਾ'),
        ('a', 'ā'),
        ('cat', 'cat_name'),
      ]) {
        expect(AnswerEligibility.containsWholeWord(clue, word), isFalse);
      }
    },
  );
  test(
    'Roman numeral answers are excluded without rejecting CIVIC or MILD',
    () {
      for (final word in ['XLIV', 'LXXXVI', 'cxlv', 'ILXX', 'ILXXX']) {
        expect(
          AnswerEligibility.allows(
            _entry(word, 'a number'),
            VocabularyScript.english,
          ),
          isFalse,
        );
      }
      for (final word in ['CIVIC', 'MILD', 'MILL', 'VIVID']) {
        expect(
          AnswerEligibility.allows(
            _entry(word, 'an ordinary word'),
            VocabularyScript.english,
          ),
          isTrue,
        );
      }
    },
  );
  test('the documented sacred terms and marked/plain aliases are excluded', () {
    for (final word in AnswerEligibility.sacredGurmukhi) {
      expect(
        AnswerEligibility.allows(
          _entry(
            'alias',
            'meaning',
            script: VocabularyScript.gurmukhi,
            native: word,
          ),
          VocabularyScript.gurmukhi,
        ),
        isFalse,
      );
    }
    for (final word in [
      ...AnswerEligibility.sacredRomanized,
      'GURŪ',
      'KHAṆḌĀ',
      'NIŚĀN',
    ]) {
      expect(
        AnswerEligibility.allows(
          _entry(word, 'meaning', script: VocabularyScript.romanizedPunjabi),
          VocabularyScript.romanizedPunjabi,
        ),
        isFalse,
      );
    }
    expect(
      AnswerEligibility.allows(
        _entry('GARDEN', 'a place for plants'),
        VocabularyScript.english,
      ),
      isTrue,
    );
  });
  test(
    'all domain pools exclude answers while dictionary and guesses retain them',
    () {
      final entries = [
        _entry('ABACA', 'hemp from abaca'),
        _entry('XLIV', 'being four more than forty'),
        _entry('GURU', 'spiritual teacher'),
        _entry('APPLE', 'a round fruit'),
      ];
      final pool = WordPool(entries);
      final quest = WordQuestVocabulary(entries);
      final bridges = WordBridgesContent(entries);
      final scramble = WordScrambleVocabulary(entries);
      expect(
        pool
            .solutions(mode: LanguageMode.english, wordLength: 5)
            .map((e) => e.latin),
        ['APPLE'],
      );
      expect(
        pool.solutions(mode: LanguageMode.english, wordLength: 4),
        isEmpty,
      );
      expect(quest.words(mode: LanguageMode.english).map((e) => e.spelling), [
        'APPLE',
      ]);
      expect(bridges.pairsFor(LanguageMode.english).map((e) => e.word), [
        'APPLE',
      ]);
      expect(scramble.words(LanguageMode.english).map((e) => e.spelling), [
        'APPLE',
      ]);
      for (final word in ['ABACA', 'XLIV', 'GURU']) {
        expect(
          pool.entryForGuess(mode: LanguageMode.english, guess: word),
          isNotNull,
        );
        expect(
          pool
              .search(mode: LanguageMode.english, query: word)
              .single
              .englishDefinition,
          entries.firstWhere((e) => e.latin == word).englishDefinition,
        );
        expect(
          pool.acceptedGuesses(
            mode: LanguageMode.english,
            wordLength: word.length,
          ),
          contains(word),
        );
      }
    },
  );
  test(
    'Simple Punjabi retains source leak exclusions and dictionary membership',
    () {
      final original = _entry(
        'ĀSĀN',
        'another spelling of āsān',
        script: VocabularyScript.romanizedPunjabi,
      );
      final entries = RomanizedVocabularyViews([original])
          .entries(simple: true);
      expect(entries.single.latin, 'ASAN');
      expect(entries.single.englishDefinition, original.englishDefinition);
      expect(
        WordScrambleVocabulary(entries).words(LanguageMode.romanizedPanjabi),
        isEmpty,
      );
      expect(
        WordPool(entries)
            .search(mode: LanguageMode.romanizedPanjabi, query: 'ASAN'),
        hasLength(1),
      );
    },
  );
  testWidgets(
    'Khoj selects only eligible answers from the complete dictionary',
    (tester) async {
      final repository = WordSearchSessionRepository(MemoryKeyValueStore());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.modern),
          home: WordSearchPage(
            vocabularyRepository: MemoryVocabularyRepository([
              _entry('ABACA', 'hemp from abaca'),
              _entry('XLIV', 'being four more than forty'),
              _entry('GURU', 'spiritual teacher'),
              _entry('APPLE', 'a round fruit'),
              _entry('BREAD', 'food baked from flour'),
            ]),
            sessionRepository: repository,
            initialMode: LanguageMode.english,
            startFresh: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.restore()!.puzzle.words.map((e) => e.word).toSet(), {
        'APPLE',
        'BREAD',
      });
      expect(tester.takeException(), isNull);
    },
  );
}

VocabularyEntry _entry(
  String word,
  String clue, {
  VocabularyScript script = VocabularyScript.english,
  String? native,
}) => VocabularyEntry(
  id: word,
  language: script == VocabularyScript.english
      ? VocabularyLanguage.english
      : VocabularyLanguage.panjabi,
  script: script,
  latin: word,
  gurmukhi: native,
  englishDefinition: clue,
  latinLength: wordUnitCount(word),
  gurmukhiLength: native == null ? null : wordUnitCount(native),
  acceptedGuess: true,
  solutionEligible: true,
  reviewStatus: ReviewStatus.editorApproved,
  source: 'Project editorial definition; original text for Sikhi Word Games',
);
