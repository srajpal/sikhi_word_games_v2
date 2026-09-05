import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';

void main() {
  testWidgets('shows unified new-game actions and random launch options', (
    tester,
  ) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    await tester.pumpAndSettle();

    for (final title in [
      'Bujho: Guess the Word',
      'Khoj: Word Search',
      'Chardi Kala: Word Quest',
    ]) {
      final titleFinder = find.text(title);
      await tester.ensureVisible(titleFinder);
      await tester.pumpAndSettle();
      final card = find.ancestor(
        of: titleFinder,
        matching: find.byType(GamePanel),
      );
      expect(
        find.descendant(of: card, matching: find.text('New game')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('New game options')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Continue game')),
        findsNothing,
      );
    }

    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await _openNewGameOptions(tester);
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('5 letters'), findsOneWidget);

    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Random language'), findsOneWidget);
    await tester.tap(find.text('Random language').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 letters').last);
    await tester.pumpAndSettle();
    expect(find.text('Random size'), findsOneWidget);
    await tester.tap(find.text('Random size').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start new game'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Continue game'), findsOneWidget);

    await _openNewGameOptions(tester);
    expect(find.text('Random language'), findsOneWidget);
    expect(find.text('Random size'), findsOneWidget);
  });

  testWidgets('opens Bujho: Guess the Word from the game library', (
    tester,
  ) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    expect(find.text('Choose a game'), findsOneWidget);
    await _startNewGame(tester);
    await tester.pumpAndSettle();
    expect(find.text('Bujho: Guess the Word'), findsOneWidget);
  });

  testWidgets('opens Khoj: Word Search and changes its language', (
    tester,
  ) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );

    await _startNewGame(tester, cardIndex: 1);
    await tester.pumpAndSettle();
    expect(find.text('Khoj: Word Search'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.byTooltip('Khoj: Word Search menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    final gurmukhi = find.text('Gurmukhi').last;
    await tester.ensureVisible(gurmukhi);
    await tester.tap(gurmukhi);
    await tester.pumpAndSettle();

    expect(find.text('Gurmukhi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the child-friendly Word Quest mode', (tester) async {
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

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await _startNewGame(tester, cardIndex: 2);

    expect(find.text('CHARDI KALA'), findsOneWidget);
    expect(find.text('WORD QUEST'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-quest-hint')), findsOneWidget);
    final keyboardToggle = find.byKey(
      const ValueKey('word-quest-keyboard-toggle'),
    );
    expect(find.text('Choose a letter to begin your quest.'), findsNothing);
    expect(find.byIcon(Icons.keyboard_alt_outlined), findsOneWidget);
    await tester.tap(keyboardToggle);
    await tester.pump();
    expect(find.byIcon(Icons.keyboard_hide_outlined), findsOneWidget);
    await tester.tap(keyboardToggle);
    await tester.pump();
    expect(find.byIcon(Icons.keyboard_alt_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('word-quest-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dictionary').last);
    await tester.pumpAndSettle();
    expect(find.text('Dictionary'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Word Quest keeps six answer tiles on one row at 320 px', (
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
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await _openNewGameOptions(tester, cardIndex: 2);
    await tester.tap(find.text('5 letters').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('6 letters').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new game'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();

    final centers = [
      for (var i = 0; i < 6; i++)
        tester.getCenter(find.byKey(ValueKey('word-quest-answer-tile-$i'))),
    ];
    expect(centers.map((center) => center.dy).toSet(), hasLength(1));
    expect(centers.first.dx, greaterThan(0));
    expect(centers.last.dx, lessThan(320));
    expect(find.text('7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Word Quest shows Gurmukhi sounds and keyboard choices', (
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
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await _openNewGameOptions(tester, cardIndex: 2);
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gurmukhi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 letters').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('4 letters').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new game'));
    await tester.pumpAndSettle();

    expect(find.text('Kee'), findsWidgets);
    final keyboardToggle = find.byKey(
      const ValueKey('word-quest-keyboard-toggle'),
    );
    await tester.tap(keyboardToggle);
    await tester.pump();
    expect(find.byIcon(Icons.keyboard_hide_outlined), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('garden blooms')), findsNothing);
    expect(find.byKey(const ValueKey('word-quest-key-ਅ')), findsOneWidget);
    await tester.tap(keyboardToggle);
    await tester.pump();
    expect(find.byIcon(Icons.keyboard_alt_outlined), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('garden blooms')), findsOneWidget);

    for (final grapheme in ['ਕੀ', 'ਰ', 'ਤ', 'ਨ']) {
      await _tapVisible(
        tester,
        find.byKey(ValueKey('word-quest-key-$grapheme')),
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('KIRTAN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Word Quest previews long clues and shows the full definition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.sikhi),
        home: WordQuestPage(
          vocabularyRepository: _vocabulary,
          hapticLevel: HapticFeedbackLevel.off,
          reducedMotion: true,
          sessionRepository: WordQuestSessionRepository(MemoryKeyValueStore()),
          initialMode: LanguageMode.english,
          initialWordSize: 6,
          startFresh: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final more = find.byKey(const ValueKey('word-quest-definition-more'));
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('A world that travels around a star'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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

  testWidgets('changes the app-wide theme from the game library', (
    tester,
  ) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('app-theme-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sikhi'));
    await tester.pumpAndSettle();

    expect(find.text('ੴ'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Choose a game'))).brightness,
      Brightness.light,
    );
  });

  testWidgets('explains gameplay and every language mode', (tester) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    await _startNewGame(tester);
    await tester.pumpAndSettle();
    await _chooseGameMenu(tester, 'How to play');

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Tile clues'), findsOneWidget);
    expect(find.text('Language modes'), findsOneWidget);
    expect(
      find.textContaining('Mixed English/Punjabi accepts both'),
      findsOneWidget,
    );
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
      find.descendant(of: find.byType(ListTile), matching: find.text('APPLE')),
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
      await _startNewGame(tester);
      await tester.pumpAndSettle();
      await _applyGameSettings(
        tester,
        language: 'Gurmukhi',
        length: '4 letters',
      );

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byKey(const ValueKey('key-enter')), findsOneWidget);
      expect(
        tester.getCenter(find.byKey(const ValueKey('key-backspace'))).dx,
        greaterThan(tester.getCenter(find.byKey(const ValueKey('key-ੱ'))).dx),
      );
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
    await _startNewGame(tester);
    await tester.pumpAndSettle();
    await _applyGameSettings(tester, length: '4 letters');

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
    await _startNewGame(tester);
    await tester.pumpAndSettle();

    await _typeHardwareWord(tester, 'APPLE');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('You found it!'), findsOneWidget);
  });

  testWidgets('menu starts a fresh game with the current settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
        vocabularyRepository: _vocabulary,
      ),
    );
    await _startNewGame(tester);
    await tester.pumpAndSettle();
    for (final letter in 'GRAPE'.characters) {
      await tester.tap(find.byKey(ValueKey('key-$letter')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('key-enter')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tile-0-0')),
        matching: find.text('G'),
      ),
      findsOneWidget,
    );

    await _chooseGameMenu(tester, 'New game');

    expect(find.text('English · 5 letters'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tile-0-0')),
        matching: find.text('G'),
      ),
      findsNothing,
    );
  });

  testWidgets('restores an interrupted game from offline storage', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final settings = AppSettingsRepository(store);
    final games = GuessGameRepository(store);

    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: settings,
        gameRepository: games,
        vocabularyRepository: _vocabulary,
      ),
    );
    await _startNewGame(tester);
    await tester.pumpAndSettle();
    for (final letter in 'GRAPE'.characters) {
      await tester.tap(find.byKey(ValueKey('key-$letter')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('key-enter')));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: settings,
        gameRepository: games,
        vocabularyRepository: _vocabulary,
      ),
    );
    await tester.tap(find.text('Continue game'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tile-0-0')),
        matching: find.text('G'),
      ),
      findsOneWidget,
    );
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
    await _startNewGame(tester);
    await tester.pumpAndSettle();
    final boardBeforeNotice = tester.getRect(
      find.byKey(const ValueKey('tile-5-0')),
    );
    await _tapVisible(tester, find.byKey(const ValueKey('key-enter')));
    expect(find.text('Enter exactly 5 visible letters.'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('tile-5-0'))),
      boardBeforeNotice,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('key-backspace'))).dx,
      greaterThan(tester.getCenter(find.byKey(const ValueKey('key-M'))).dx),
    );
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

    await tester.tap(find.byKey(const ValueKey('game-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy result').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Spoiler-free result copied'), findsOneWidget);
    expect(clipboardText, contains('English · 5 letters · 2/6'));
    expect(clipboardText, isNot(contains('APPLE')));

    await _chooseGameMenu(tester, 'Statistics');
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('English · 5 letters'),
      ),
      findsOneWidget,
    );
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
    await _startNewGame(tester);
    await tester.pumpAndSettle();
    await _applyGameSettings(tester, language: 'Gurmukhi', length: '4 letters');

    expect(find.text('Ka'), findsWidgets);
    expect(find.text('Ee'), findsWidgets);
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

Future<void> _startNewGame(WidgetTester tester, {int cardIndex = 0}) async {
  await _openNewGameOptions(tester, cardIndex: cardIndex);
  await tester.tap(find.text('Start new game'));
  await tester.pumpAndSettle();
}

Future<void> _openNewGameOptions(
  WidgetTester tester, {
  int cardIndex = 0,
}) async {
  const titles = [
    'Bujho: Guess the Word',
    'Khoj: Word Search',
    'Chardi Kala: Word Quest',
  ];
  final titleFinder = find.text(titles[cardIndex]);
  await tester.ensureVisible(titleFinder);
  await tester.pumpAndSettle();
  final card = find.ancestor(of: titleFinder, matching: find.byType(GamePanel));
  final optionsButton = find.descendant(
    of: card,
    matching: find.text('New game options'),
  );
  await tester.tap(optionsButton);
  await tester.pumpAndSettle();
}

Future<void> _chooseGameMenu(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(const ValueKey('game-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<void> _applyGameSettings(
  WidgetTester tester, {
  String? language,
  String? length,
}) async {
  await _chooseGameMenu(tester, 'Game settings');
  if (language != null) {
    await tester.tap(find.byKey(const ValueKey('settings-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(language).last);
    await tester.pumpAndSettle();
  }
  if (length != null) {
    final lengthField = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<int> &&
          widget.key.toString().contains('settings-length'),
    );
    await tester.tap(lengthField);
    await tester.pumpAndSettle();
    await tester.tap(find.text(length).last);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Apply'));
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
    id: 'english_planet',
    language: VocabularyLanguage.english,
    latin: 'PLANET',
    gurmukhi: null,
    englishDefinition: 'A world that travels around a star',
    latinLength: 6,
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
