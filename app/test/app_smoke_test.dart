import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  testWidgets('opens Guess the Word from the game library', (tester) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    expect(find.text('Choose a game'), findsOneWidget);
    await tester.tap(find.text('Play prototype'));
    await tester.pumpAndSettle();
    expect(find.text('Guess the Word'), findsOneWidget);
  });

  testWidgets('game library fits a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose a game'), findsOneWidget);
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
    source: 'test',
  ),
]);
