import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('persists app preferences and restores an interrupted game', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final settings = AppSettingsRepository(store);
    final games = GuessGameRepository(store);

    Future<void> launch() => tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: settings,
        gameRepository: games,
        vocabularyRepository: _vocabulary,
      ),
    );

    await launch();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app-theme-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sikhi'));
    await tester.pumpAndSettle();
    expect(find.text('ੴ'), findsOneWidget);

    await tester.tap(find.byTooltip('Feedback settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medium').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(settings.load().hapticLevel, HapticFeedbackLevel.off);

    await tester.tap(find.text('Play prototype'));
    await tester.pumpAndSettle();
    for (final letter in 'GRAPE'.characters) {
      await tester.tap(find.byKey(ValueKey('key-$letter')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('key-enter')));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await launch();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play prototype'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tile-0-0')),
        matching: find.text('G'),
      ),
      findsOneWidget,
    );
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
    source: 'integration-test',
  ),
  VocabularyEntry(
    id: 'english_grape',
    language: VocabularyLanguage.english,
    latin: 'GRAPE',
    gurmukhi: null,
    englishDefinition: 'A small fruit that grows in bunches',
    latinLength: 5,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: false,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'integration-test',
  ),
]);
