import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/domain/word_search_puzzle.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  testWidgets('keyboard finds a word forward and backward', (tester) async {
    for (final reverse in [false, true]) {
      final store = MemoryKeyValueStore();
      final repository = WordSearchSessionRepository(store);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(reverse),
          theme: AppThemes.forChoice(AppThemeChoice.sikhi),
          home: WordSearchPage(
            vocabularyRepository: _vocabulary,
            sessionRepository: repository,
            initialMode: LanguageMode.english,
            initialWordSize: 4,
            startFresh: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final placed = repository.restore()!.puzzle.words.first;
      final cells = placed.cells();
      final start = reverse ? cells.last : cells.first;
      final end = reverse ? cells.first : cells.last;
      await _move(tester, const GridPoint(0, 0), start);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _move(tester, start, end);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(find.text('Found ${placed.word}'), findsOneWidget);
      expect(repository.hasActiveGame, isTrue);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Escape cancels keyboard selection and help explains controls', (
    tester,
  ) async {
    final repository = WordSearchSessionRepository(MemoryKeyValueStore());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.sikhi),
        home: WordSearchPage(
          vocabularyRepository: _vocabulary,
          sessionRepository: repository,
          initialMode: LanguageMode.english,
          initialWordSize: 4,
          startFresh: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<Focus>(find.byKey(const ValueKey('word-search-grid-focus')))
        .focusNode!
        .requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final grid = find.byKey(const ValueKey('word-search-grid-semantics'));
    expect(tester.getSemantics(grid).label, contains('Start cell chosen'));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(
      tester.getSemantics(grid).label,
      isNot(contains('Start cell chosen')),
    );

    await tester.tap(find.byTooltip('Khoj: Word Search menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter or Space to choose'), findsOneWidget);
    expect(find.textContaining('Escape cancels a selection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pointer drag replaces an unfinished keyboard selection', (
    tester,
  ) async {
    final repository = WordSearchSessionRepository(MemoryKeyValueStore());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.sikhi),
        home: WordSearchPage(
          vocabularyRepository: _vocabulary,
          sessionRepository: repository,
          initialMode: LanguageMode.english,
          initialWordSize: 4,
          startFresh: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final gridFocus = tester.widget<Focus>(
      find.byKey(const ValueKey('word-search-grid-focus')),
    );
    gridFocus.focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    final word = repository.restore()!.puzzle.words.first;
    final start = word.cells().first;
    final end = word.cells().last;
    final startCenter = tester.getCenter(
      find.byKey(ValueKey('word-search-cell-${start.row}-${start.column}')),
    );
    final endCenter = tester.getCenter(
      find.byKey(ValueKey('word-search-cell-${end.row}-${end.column}')),
    );
    final gesture = await tester.startGesture(startCenter);
    await gesture.moveTo(endCenter);
    await gesture.up();
    await tester.pump();

    expect(find.text('Found ${word.word}'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('word-search-grid-semantics')),
          )
          .label,
      contains('Start cell chosen'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrow keys stay in bounds and Space selects a cell', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.sikhi),
        home: WordSearchPage(
          vocabularyRepository: _vocabulary,
          sessionRepository: WordSearchSessionRepository(MemoryKeyValueStore()),
          initialMode: LanguageMode.english,
          initialWordSize: 4,
          startFresh: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final focus = tester.widget<Focus>(
      find.byKey(const ValueKey('word-search-grid-focus')),
    );
    focus.focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('word-search-cell-0-0')))
          .label,
      contains('keyboard focus'),
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('word-search-grid-semantics')),
          )
          .label,
      contains('Start cell chosen'),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _move(WidgetTester tester, GridPoint from, GridPoint to) async {
  final verticalKey = to.row >= from.row
      ? LogicalKeyboardKey.arrowDown
      : LogicalKeyboardKey.arrowUp;
  final horizontalKey = to.column >= from.column
      ? LogicalKeyboardKey.arrowRight
      : LogicalKeyboardKey.arrowLeft;
  for (var count = 0; count < (to.row - from.row).abs(); count++) {
    await tester.sendKeyEvent(verticalKey);
  }
  for (var count = 0; count < (to.column - from.column).abs(); count++) {
    await tester.sendKeyEvent(horizontalKey);
  }
}

const _vocabulary = MemoryVocabularyRepository([
  VocabularyEntry(
    id: 'english_test',
    language: VocabularyLanguage.english,
    latin: 'TEST',
    gurmukhi: null,
    englishDefinition: 'A check of how something works',
    latinLength: 4,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'english_play',
    language: VocabularyLanguage.english,
    latin: 'PLAY',
    gurmukhi: null,
    englishDefinition: 'To take part in a game',
    latinLength: 4,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
]);
