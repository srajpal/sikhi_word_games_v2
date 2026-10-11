import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/presentation/guess_the_word_page.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  testWidgets(
    'grid edits the pending row, retains rejected input and advances only on Enter',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        expect(find.byType(InputDecorator), findsNothing);
        expect(find.text('Your guess'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('key-A')));
        await tester.pump();
        expect(_row(tester, 0), 'A');
        expect(_row(tester, 1), '');
        final node = tester.getSemantics(
          find.bySemanticsLabel('Current guess, attempt 1, A'),
        );
        expect(node.label, 'Current guess, attempt 1, A');
        expect(find.byType(TextField), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('tile-0-0')),
            matching: find.byIcon(Icons.check),
          ),
          findsNothing,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pump();
        expect(_row(tester, 0), '');
        await _type(tester, 'ZZZZZ');
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'A');
        await tester.pump();
        expect(_row(tester, 0), 'ZZZZZ');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Not in the accepted-guess list.'), findsOneWidget);
        expect(_row(tester, 0), 'ZZZZZ');
        expect(_row(tester, 1), '');
        for (var i = 0; i < 5; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        }
        await tester.pump();
        await _type(tester, 'GRAPE');
        await tester.tap(find.byKey(const ValueKey('key-enter')));
        await tester.pumpAndSettle();
        expect(_row(tester, 0), 'GRAPE');
        expect(_row(tester, 1), '');
        expect(
          find.bySemanticsLabel('Current guess, attempt 2, blank'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('guess-active-row')));
        await _type(tester, 'APPLE');
        expect(_row(tester, 0), 'GRAPE');
        expect(_row(tester, 1), 'APPLE');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('You found it!'), findsOneWidget);
        expect(find.byKey(const ValueKey('guess-active-row')), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    testWidgets('direct grid fits $size with larger reachable English keys', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final key = find.byKey(const ValueKey('key-A'));
      expect(key.hitTestable(), findsOneWidget);
      expect(tester.getSize(key).height, greaterThanOrEqualTo(44));
      final letter = tester.widget<Text>(
        find.descendant(of: key, matching: find.text('A')),
      );
      expect(letter.style!.fontSize, greaterThanOrEqualTo(20));
      expect(
        find.byKey(const ValueKey('key-enter')).hitTestable(),
        findsOneWidget,
      );
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scroll.position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _type(WidgetTester tester, String value) async {
  for (final character in value.split('')) {
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: character);
    await tester.pump();
  }
}

String _row(WidgetTester tester, int row) => [
  for (var column = 0; column < 5; column++)
    ...tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(ValueKey('tile-$row-$column')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data ?? ''),
].join();

Widget _app() {
  final store = MemoryKeyValueStore();
  return MaterialApp(
    theme: AppThemes.forChoice(AppThemeChoice.modern),
    home: GuessTheWordPage(
      vocabularyRepository: MemoryVocabularyRepository([
        for (final word in ['APPLE', 'GRAPE'])
          VocabularyEntry(
            id: word,
            language: VocabularyLanguage.english,
            wordNetTagCount: 3,
            latin: word,
            gurmukhi: null,
            englishDefinition: 'A sweet fruit.',
            latinLength: 5,
            gurmukhiLength: null,
            acceptedGuess: true,
            solutionEligible: word == 'APPLE',
            reviewStatus: ReviewStatus.editorApproved,
            source: 'Project editorial definition; original text for Sikhi Word Games',
          ),
      ]),
      statisticsRepository: GuessStatisticsRepository(store),
      gameRepository: GuessGameRepository(store),
      solutionHistoryRepository: SolutionHistoryRepository(store),
      hapticLevel: HapticFeedbackLevel.off,
      reducedMotion: true,
      initialMode: LanguageMode.english,
      initialWordLength: 5,
      startFresh: true,
    ),
  );
}
