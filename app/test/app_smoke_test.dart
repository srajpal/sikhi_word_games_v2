import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('explains gameplay and every language mode', (tester) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    await tester.tap(find.text('Play prototype'));
    await tester.pumpAndSettle();
    await _chooseGameMenu(tester, 'How to play');

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Tile clues'), findsOneWidget);
    expect(find.text('Language modes'), findsOneWidget);
    expect(find.textContaining('Mixed Latin accepts both'), findsOneWidget);
    expect(find.textContaining('work completely offline'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('How to play'), findsNothing);

    await _chooseGameMenu(tester, 'Dictionary');
    expect(find.text('Dictionary'), findsOneWidget);
    for (final letter in 'APPLE'.characters) {
      await tester.tap(find.byKey(ValueKey('key-$letter')));
      await tester.pump();
    }
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('APPLE'),
      ),
      findsOneWidget,
    );
    expect(find.text('English'), findsWidgets);
    expect(find.text('A round fruit'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'gameplay fits a phone without a system text field or scrolling',
    (tester) async {
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
      await tester.tap(find.text('Play prototype'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gurmukhi').last);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byKey(const ValueKey('key-enter')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('four-letter board leaves space above the guess display', (
    tester,
  ) async {
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
    await tester.tap(find.text('Play prototype'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 letters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4 letters').last);
    await tester.pumpAndSettle();

    final lastTile = tester.getRect(find.byKey(const ValueKey('tile-5-0')));
    final guessDisplay = tester.getRect(
      find.byKey(const ValueKey('guess-display')),
    );
    expect(guessDisplay.top - lastTile.bottom, greaterThanOrEqualTo(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('submits a physical keyboard or IME guess with Enter', (
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

    await _typeHardwareWord(tester, 'APPLE');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('You found it!'), findsOneWidget);
  });

  testWidgets('plays a complete game with the on-screen keyboard', (
    tester,
  ) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    await tester.tap(find.text('Play prototype'));
    await tester.pumpAndSettle();
    for (final letter in 'GRAPE'.characters) {
      await _tapVisible(tester, find.byKey(ValueKey('key-$letter')));
    }
    await _tapVisible(tester, find.byKey(const ValueKey('key-enter')));
    expect(find.textContaining('A small fruit that grows'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const ValueKey('key-G')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const ValueKey('key-A')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );

    for (final letter in ['A', 'P', 'P', 'L', 'E']) {
      await _tapVisible(tester, find.byKey(ValueKey('key-$letter')));
    }
    await _tapVisible(tester, find.byKey(const ValueKey('key-enter')));
    await tester.pump();
    expect(find.text('You found it!'), findsOneWidget);
    expect(find.text('A round fruit'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(6));
    expect(find.byIcon(Icons.swap_horiz), findsNWidgets(2));
    expect(find.byIcon(Icons.close), findsNWidgets(2));

    await _chooseGameMenu(tester, 'Copy result');
    expect(find.text('Spoiler-free result copied'), findsOneWidget);
    expect(clipboardText, contains('English · 5 letters · 2/6'));
    expect(clipboardText, isNot(contains('APPLE')));

    await _chooseGameMenu(tester, 'Statistics');
    expect(find.text('English · 5 letters'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('stat-Played'))).data,
      '1',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('stat-Win %'))).data,
      '100',
    );
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
    var value = tester.widget<Text>(find.byKey(const ValueKey('guess-value')));
    expect(value.data, 'ਕੀ');
    await _tapVisible(tester, find.byKey(const ValueKey('key-backspace')));
    value = tester.widget<Text>(find.byKey(const ValueKey('guess-value')));
    expect(value.data, ' ');

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

Future<void> _chooseGameMenu(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(const ValueKey('game-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<void> _typeHardwareWord(WidgetTester tester, String word) async {
  for (final character in word.characters) {
    final key = switch (character) {
      'A' => LogicalKeyboardKey.keyA,
      'E' => LogicalKeyboardKey.keyE,
      'L' => LogicalKeyboardKey.keyL,
      'P' => LogicalKeyboardKey.keyP,
      _ => throw ArgumentError.value(character, 'word'),
    };
    await tester.sendKeyDownEvent(key, character: character);
    await tester.sendKeyUpEvent(key);
  }
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
    id: 'english_jump',
    language: VocabularyLanguage.english,
    latin: 'JUMP',
    gurmukhi: null,
    englishDefinition: 'A quick movement off the ground',
    latinLength: 4,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'test',
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
