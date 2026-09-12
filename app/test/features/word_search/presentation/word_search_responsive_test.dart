import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  testWidgets('short scaled Gurmukhi layout scrolls with a usable grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final sessions = WordSearchSessionRepository(MemoryKeyValueStore());
    final theme = AppThemes.forChoice(AppThemeChoice.dark);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: WordSearchPage(
          vocabularyRepository: _gurmukhiVocabulary,
          sessionRepository: sessions,
          initialMode: LanguageMode.gurmukhi,
          initialWordSize: 4,
          startFresh: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(sessions.restore()!.puzzle.words, hasLength(6));
    final scrollView = find.byKey(const ValueKey('word-search-board-scroll'));
    final scrollable = find.descendant(
      of: scrollView,
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable.first).position.maxScrollExtent,
      greaterThan(0),
    );
    final gridSize = tester.getSize(
      find.byKey(const ValueKey('word-search-grid-semantics')),
    );
    expect(gridSize.shortestSide, greaterThanOrEqualTo(260));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final selectedCell = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('word-search-cell-0-0')),
    );
    final decoration = selectedCell.decoration as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, theme.colorScheme.onPrimary);
    expect(tester.takeException(), isNull);
  });
}

const _gurmukhiVocabulary = MemoryVocabularyRepository([
  VocabularyEntry(
    id: 'panjabi_one',
    language: VocabularyLanguage.panjabi,
    latin: 'KAGA',
    gurmukhi: 'ਕਖਗਘ',
    englishDefinition: 'First test word',
    latinLength: 4,
    gurmukhiLength: 4,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'panjabi_two',
    language: VocabularyLanguage.panjabi,
    latin: 'CHAJ',
    gurmukhi: 'ਚਛਜਝ',
    englishDefinition: 'Second test word',
    latinLength: 4,
    gurmukhiLength: 4,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'panjabi_three',
    language: VocabularyLanguage.panjabi,
    latin: 'TADA',
    gurmukhi: 'ਟਠਡਢ',
    englishDefinition: 'Third test word',
    latinLength: 4,
    gurmukhiLength: 4,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'panjabi_four',
    language: VocabularyLanguage.panjabi,
    latin: 'TADA2',
    gurmukhi: 'ਤਥਦਧ',
    englishDefinition: 'Fourth test word',
    latinLength: 5,
    gurmukhiLength: 4,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'panjabi_five',
    language: VocabularyLanguage.panjabi,
    latin: 'PABA',
    gurmukhi: 'ਪਫਬਭ',
    englishDefinition: 'Fifth test word',
    latinLength: 4,
    gurmukhiLength: 4,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'panjabi_six',
    language: VocabularyLanguage.panjabi,
    latin: 'MAYA',
    gurmukhi: 'ਮਯਰਲ',
    englishDefinition: 'Sixth test word',
    latinLength: 4,
    gurmukhiLength: 4,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
]);
