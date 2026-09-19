import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  testWidgets('Khoj semantic endpoints finish and record exactly one puzzle', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final repository = WordSearchSessionRepository(MemoryKeyValueStore());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.sikhi),
          home: WordSearchPage(
            vocabularyRepository: _vocabulary,
            sessionRepository: repository,
            initialMode: LanguageMode.english,
            initialWordSize: 5,
            startFresh: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final puzzle = repository.restore()!.puzzle;
      expect(repository.statistics.total.played, 0);
      for (final word in puzzle.words) {
        for (final point in [word.cells().first, word.cells().last]) {
          final node = tester.getSemantics(
            find.byKey(
              ValueKey('word-search-cell-action-${point.row}-${point.column}'),
            ),
          );
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
            node.id,
            SemanticsAction.tap,
          );
          await tester.pump();
        }
      }
      expect(repository.statistics.total.played, 1);
      expect(repository.statistics.total.won, 1);
      expect(repository.statistics.total.wordsFound, puzzle.words.length);
      expect(repository.hasActiveGame, isFalse);
      final end = puzzle.words.last.cells().last;
      final completed = tester.getSemantics(
        find.byKey(
          ValueKey('word-search-cell-action-${end.row}-${end.column}'),
        ),
      );
      expect(
        completed.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        completed.id,
        SemanticsAction.tap,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(repository.statistics.total.played, 1);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'Quest lost attempt then successful retry records twice, with repeated input ignored',
    (tester) async {
      final repository = WordQuestSessionRepository(MemoryKeyValueStore());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.sikhi),
          home: WordQuestPage(
            vocabularyRepository: _vocabulary,
            sessionRepository: repository,
            initialMode: LanguageMode.english,
            initialWordSize: 5,
            startFresh: true,
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.statistics.total.played, 0);
      for (final entry in [
        (LogicalKeyboardKey.keyB, 'b'),
        (LogicalKeyboardKey.keyC, 'c'),
        (LogicalKeyboardKey.keyD, 'd'),
        (LogicalKeyboardKey.keyF, 'f'),
        (LogicalKeyboardKey.keyG, 'g'),
        (LogicalKeyboardKey.keyH, 'h'),
      ]) {
        await tester.sendKeyEvent(entry.$1, character: entry.$2);
        await tester.pump();
      }
      expect(find.text('The word is ready to discover'), findsOneWidget);
      expect(repository.statistics.total.played, 1);
      expect(repository.statistics.total.won, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH, character: 'h');
      await tester.pump();
      expect(repository.statistics.total.played, 1);
      await tester.ensureVisible(find.text('Try this word again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try this word again'));
      await tester.pumpAndSettle();
      expect(repository.statistics.total.played, 1);
      for (final letter in ['A', 'P', 'L', 'E']) {
        await tester.ensureVisible(
          find.byKey(ValueKey('word-quest-key-$letter')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('word-quest-key-$letter')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('word-quest-key-$letter')));
        await tester.pump();
      }
      expect(repository.statistics.total.played, 2);
      expect(repository.statistics.total.won, 1);
      expect(repository.statistics.forMode('english', 5).played, 2);
      expect(repository.hasActiveGame, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: 'e');
      await tester.pump();
      expect(repository.statistics.total.played, 2);
      expect(tester.takeException(), isNull);
    },
  );
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
