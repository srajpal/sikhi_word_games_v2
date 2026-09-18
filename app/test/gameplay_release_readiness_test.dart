import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  testWidgets('all playable games remain usable at 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (var gameIndex = 0; gameIndex < 3; gameIndex++) {
      await tester.pumpWidget(
        SikhiWordGamesApp(
          key: ValueKey(gameIndex),
          settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
          vocabularyRepository: _vocabulary,
        ),
      );
      await tester.pumpAndSettle();
      final title = find.text(_gameTitles[gameIndex]);
      await tester.scrollUntilVisible(
        title,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final card = find.ancestor(of: title, matching: find.byType(GamePanel));
      await _startEnglishGame(tester, card);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();

      expect(find.text(_pageTitles[gameIndex]), findsWidgets);
      final exception = tester.takeException();
      if (exception is FlutterError) {
        fail('${_pageTitles[gameIndex]}: ${exception.toStringDeep()}');
      }
      expect(exception, isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    }
  });

  testWidgets('Word Quest learning finish can retry the same word', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryKeyValueStore();
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(store),
        vocabularyRepository: _vocabulary,
      ),
    );
    await tester.pumpAndSettle();
    final title = find.text('Chardi Kala: Word Quest');
    await tester.scrollUntilVisible(title, 200);
    final card = find.ancestor(of: title, matching: find.byType(GamePanel));
    await _startEnglishGame(tester, card);

    await tester.tap(find.byKey(const ValueKey('word-quest-keyboard-toggle')));
    await tester.pump();
    for (final letter in ['B', 'C', 'D', 'F', 'G', 'H']) {
      await tester.ensureVisible(
        find.byKey(ValueKey('word-quest-key-$letter')),
      );
      await tester.tap(find.byKey(ValueKey('word-quest-key-$letter')));
      await tester.pump();
    }

    expect(find.text('The word is ready to discover'), findsOneWidget);
    expect(find.text('APPLE'), findsOneWidget);
    await tester.ensureVisible(find.text('Try this word again'));
    await tester.tap(find.text('Try this word again'));
    await tester.pump();

    expect(find.text('The word is ready to discover'), findsNothing);
    expect(find.text('6 tries'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
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

Future<void> _startEnglishGame(WidgetTester tester, Finder card) async {
  final options = find.descendant(
    of: card,
    matching: find.byTooltip('New game options'),
  );
  await tester.ensureVisible(options);
  await tester.pumpAndSettle();
  await tester.tap(options);
  await tester.pumpAndSettle();
  final start = find.text('Start new game');
  await tester.ensureVisible(start);
  await tester.pumpAndSettle();
  await tester.tap(start);
  await tester.pumpAndSettle();
}

const _gameTitles = [
  'Bujho: Guess the Word',
  'Khoj: Word Search',
  'Chardi Kala: Word Quest',
];

const _pageTitles = [
  'Bujho: Guess the Word',
  'Khoj: Word Search',
  'Chardi Kala',
];

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
