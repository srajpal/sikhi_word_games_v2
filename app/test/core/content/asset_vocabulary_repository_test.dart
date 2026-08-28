import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/word_pool.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads the full offline vocabulary and curated starter solutions',
    () async {
      final entries = await AssetVocabularyRepository().load();
      final pool = WordPool(entries);

      expect(entries, hasLength(38510));
      expect(
        pool.solutions(mode: LanguageMode.english, wordLength: 4),
        hasLength(greaterThanOrEqualTo(20)),
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
        pool
            .entryForGuess(mode: LanguageMode.english, guess: 'HOME')
            ?.englishDefinition,
        'The place where a person lives.',
      );
    },
  );
}
