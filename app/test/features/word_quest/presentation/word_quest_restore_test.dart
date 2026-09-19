import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';

void main() {
  testWidgets('feedback dismisses manually and after five seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: WordQuestPage(
          vocabularyRepository: _vocabulary,
          hapticLevel: HapticFeedbackLevel.off,
          reducedMotion: true,
          sessionRepository: WordQuestSessionRepository(MemoryKeyValueStore()),
          initialMode: LanguageMode.english,
          initialWordSize: 5,
          startFresh: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose a letter to grow your garden.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('word-quest-key-A')));
    await tester.pumpAndSettle();
    expect(find.text('Nice find! That letter is in the word.'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('word-quest-feedback')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('word-quest-key-P')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('word-quest-feedback')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('word-quest-feedback')), findsNothing);
  });
  testWidgets('restores an unfinished quest into the playable screen', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final repository = WordQuestSessionRepository(MemoryKeyValueStore());
      final game = WordQuestGame(solution: 'APPLE')..guess('A');
      await repository.save(
        mode: LanguageMode.english,
        wordSize: 5,
        game: game,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.sikhi),
          home: WordQuestPage(
            vocabularyRepository: _vocabulary,
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
            sessionRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('A round fruit'), findsOneWidget);
      expect(find.byKey(const ValueKey('word-quest-key-A')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('word-quest-answer-tile-0')),
          matching: find.text('A'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      final letterP = tester.getSemantics(find.bySemanticsLabel('Letter P'));
      expect(letterP.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        letterP.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('word-quest-answer-tile-1')),
          matching: find.text('P'),
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('restores a Gurmukhi quest with a Gurmukhi-only letter bank', (
    tester,
  ) async {
    final repository = WordQuestSessionRepository(MemoryKeyValueStore());
    final game = WordQuestGame(solution: 'ਸਤਿਗੁਰ')..guess('ਸ');
    await repository.save(mode: LanguageMode.gurmukhi, wordSize: 4, game: game);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.sikhi),
        home: WordQuestPage(
          vocabularyRepository: _gurmukhiVocabulary,
          hapticLevel: HapticFeedbackLevel.off,
          reducedMotion: true,
          sessionRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final bankKeys = tester
        .widgetList(
          find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'word-quest-key-',
                ),
          ),
        )
        .map((widget) => (widget.key! as ValueKey<String>).value.substring(15))
        .toList();
    expect(bankKeys, isNotEmpty);
    final gurmukhi = RegExp(r'^[਀-੿]+$');
    for (final letter in bankKeys) {
      expect(gurmukhi.hasMatch(letter), isTrue, reason: 'Latin key: $letter');
    }
    expect(tester.takeException(), isNull);
  });
}

const _gurmukhiVocabulary = MemoryVocabularyRepository([
  VocabularyEntry(
    id: 'punjabi_satgur',
    language: VocabularyLanguage.panjabi,
    latin: 'SATGUR',
    gurmukhi: 'ਸਤਿਗੁਰ',
    englishDefinition: 'The true Guru',
    latinLength: 6,
    gurmukhiLength: 4,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
  VocabularyEntry(
    id: 'punjabi_paani',
    language: VocabularyLanguage.panjabi,
    latin: 'PAANI',
    gurmukhi: 'ਪਾਣੀ',
    englishDefinition: 'Water',
    latinLength: 5,
    gurmukhiLength: 2,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.machineChecked,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
]);

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
