import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/word_pool.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_vocabulary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads the full offline vocabulary and curated starter solutions',
    () async {
      final entries = await AssetVocabularyRepository().load();
      final pool = WordPool(entries);
      final quest = WordQuestVocabulary(entries);
      expect(
        entries.where((entry) => entry.solutionEligible),
        everyElement(
          isA<dynamic>().having(
            (entry) => entry.hasDistributableDefinition,
            'distributable definition',
            isTrue,
          ),
        ),
      );
      for (final mode in LanguageMode.values) {
        for (final length in [4, 5, 6]) {
          final answers = pool.solutions(mode: mode, wordLength: length);
          final questAnswers = quest
              .words(mode: mode)
              .where((word) => word.graphemeLength == length);
          expect(
            answers.length,
            greaterThanOrEqualTo(6),
            reason: '${mode.name}/$length must support a full Khoj puzzle',
          );
          expect(
            questAnswers,
            isNotEmpty,
            reason: '${mode.name}/$length must support Word Quest',
          );
        }
      }

      expect(entries, hasLength(46995));
      expect(
        pool.solutions(mode: LanguageMode.english, wordLength: 4),
        hasLength(greaterThanOrEqualTo(1200)),
      );
      expect(
        pool.solutions(mode: LanguageMode.english, wordLength: 5),
        isNotEmpty,
      );
      expect(
        pool.solutions(mode: LanguageMode.romanizedPanjabi, wordLength: 6),
        isNotEmpty,
      );
      expect(
        pool.solutions(mode: LanguageMode.gurmukhi, wordLength: 4),
        isNotEmpty,
      );
      expect(
        pool.solutions(mode: LanguageMode.gurmukhi, wordLength: 5),
        isNotEmpty,
      );
      expect(
        pool.solutions(mode: LanguageMode.gurmukhi, wordLength: 6),
        isNotEmpty,
      );
      expect(
        pool
            .entryForGuess(mode: LanguageMode.english, guess: 'HOME')
            ?.englishDefinition,
        'where you live at a particular time',
      );
      expect(
        pool
            .entryForGuess(mode: LanguageMode.english, guess: 'WORD')
            ?.englishDefinition,
        'a unit of language that native speakers can identify',
      );
      const excludedIds = {
        'english_bozo',
        'english_dork',
        'english_goof',
        'english_goon',
        'english_lech',
        'english_pimp',
        'english_putz',
        'english_twat',
        'gurmukhi_mahan_kosh_1-108-4',
        'gurmukhi_mahan_kosh_1-194-20',
        'gurmukhi_mahan_kosh_1-235-7',
        'gurmukhi_mahan_kosh_1-272-18',
        'gurmukhi_mahan_kosh_1-304-34',
        'gurmukhi_mahan_kosh_1-341-17',
        'gurmukhi_mahan_kosh_1-373-3',
        'gurmukhi_mahan_kosh_1-397-8',
        'gurmukhi_mahan_kosh_1-405-8',
        'gurmukhi_mahan_kosh_1-543-15',
        'gurmukhi_mahan_kosh_1-543-16',
        'gurmukhi_mahan_kosh_1-551-18',
      };
      for (final id in excludedIds) {
        final entry = entries.singleWhere((entry) => entry.id == id);
        expect(entry.acceptedGuess, isTrue, reason: id);
        expect(entry.solutionEligible, isFalse, reason: id);
      }
      final lust = entries.singleWhere((entry) => entry.id == 'english_lust');
      final stud = entries.singleWhere((entry) => entry.id == 'english_stud');
      expect(lust.solutionEligible, isFalse);
      expect(stud.solutionEligible, isFalse);
      expect(stud.englishDefinition, 'an upright in house framing');
      expect(
        entries
            .singleWhere((entry) => entry.id == 'english_give')
            .englishDefinition,
        'transfer possession of something concrete or abstract to somebody',
      );
      final legacyGuess = entries.singleWhere(
        (entry) => entry.id == 'panjabi_item',
      );
      expect(legacyGuess.acceptedGuess, isTrue);
      expect(legacyGuess.solutionEligible, isFalse);
      expect(
        legacyGuess.displayDefinition,
        'Definition unavailable for this word.',
      );
    },
  );
}
