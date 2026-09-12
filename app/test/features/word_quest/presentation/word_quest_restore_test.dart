import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';

void main() {
  testWidgets('restores an unfinished quest into the playable screen', (
    tester,
  ) async {
    final repository = WordQuestSessionRepository(MemoryKeyValueStore());
    final game = WordQuestGame(solution: 'APPLE')..guess('A');
    await repository.save(mode: LanguageMode.english, wordSize: 5, game: game);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.sikhi),
        home: WordQuestPage(
          vocabularyRepository: _vocabulary,
          hapticLevel: HapticFeedbackLevel.off,
          reducedMotion: true,
          sessionRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('A round fruit'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-quest-key-A')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('word-quest-answer-tile-0')),
        matching: find.text('A'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

const _vocabulary = MemoryVocabularyRepository([
  VocabularyEntry(
    id: 'english_apple',
    language: VocabularyLanguage.english,
    latin: 'APPLE',
    gurmukhi: null,
    englishDefinition: 'A round fruit',
    latinLength: 5,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
]);
