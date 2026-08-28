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

  testWidgets('plays a complete game with the on-screen keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    await tester.tap(find.text('Play prototype'));
    await tester.pumpAndSettle();
    for (final letter in ['A', 'P', 'P', 'L', 'E']) {
      await _tapVisible(tester, find.byKey(ValueKey('key-$letter')));
    }
    await _tapVisible(tester, find.byKey(const ValueKey('key-enter')));
    await tester.pump();
    expect(find.text('You found it!'), findsOneWidget);
    expect(find.text('A round fruit'), findsOneWidget);
  });

  testWidgets('Gurmukhi keyboard composes and deletes visible graphemes', (
    tester,
  ) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    await tester.tap(find.text('Play prototype'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gurmukhi').last);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const ValueKey('key-ਕ')));
    await _tapVisible(tester, find.byKey(const ValueKey('key-ੀ')));
    var field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'ਕੀ');
    await _tapVisible(tester, find.byKey(const ValueKey('key-backspace')));
    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);

    for (final character in ['ਕ', 'ੀ', 'ਰ', 'ਤ', 'ਨ']) {
      await _tapVisible(tester, find.byKey(ValueKey('key-$character')));
    }
    await _tapVisible(tester, find.byKey(const ValueKey('key-enter')));
    await tester.pump();
    expect(find.text('You found it!'), findsOneWidget);
    expect(find.text('Sikh devotional music'), findsOneWidget);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
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
  VocabularyEntry(
    id: 'panjabi_kirtan',
    language: VocabularyLanguage.panjabi,
    latin: 'KIRTAN',
    gurmukhi: 'ਕੀਰਤਨ',
    englishDefinition: 'Sikh devotional music',
    latinLength: 6,
    gurmukhiLength: 4,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'test',
  ),
]);
