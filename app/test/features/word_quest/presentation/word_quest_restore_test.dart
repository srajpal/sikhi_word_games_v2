import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/quest_lantern.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';

void main() {
  for (final mode in LanguageMode.values) {
    testWidgets(
      '${mode.name} starts with full alphabet and retains its miss limit',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = WordQuestSessionRepository(MemoryKeyValueStore());
        final vocabulary = switch (mode) {
          LanguageMode.english => _vocabulary,
          LanguageMode.romanizedPanjabi => _romanizedVocabulary,
          LanguageMode.gurmukhi => _gurmukhiVocabulary,
        };
        Widget page({bool fresh = false}) => MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.sikhi),
          home: WordQuestPage(
            vocabularyRepository: vocabulary,
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
            sessionRepository: repo,
            initialMode: mode,
            initialWordSize: mode == LanguageMode.english ? 5 : 4,
            startFresh: fresh,
          ),
        );
        await tester.pumpWidget(page(fresh: true));
        await tester.pumpAndSettle();
        expect(repo.restore()!.fullKeyboard, isTrue);
        expect(find.byType(QuestLantern), findsOneWidget);
        if (mode == LanguageMode.gurmukhi) {
          for (final letter in ['ਕ', 'ਖ', 'ਗ', 'ਪ', 'ੳ', 'ਤਿ']) {
            expect(
              find.byKey(ValueKey('word-quest-key-$letter')),
              findsOneWidget,
            );
          }
        } else {
          for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
            expect(
              find.byKey(ValueKey('word-quest-key-$letter')),
              findsOneWidget,
            );
          }
          if (mode == LanguageMode.romanizedPanjabi) {
            expect(
              find.byKey(const ValueKey('word-quest-key-Ā')),
              findsOneWidget,
            );
          }
        }
        final budget = repo.restore()!.game.maximumTries;
        expect(budget, mode == LanguageMode.english ? 4 : 3);
        await tester.sendKeyEvent(
          LogicalKeyboardKey.keyZ,
          character: mode == LanguageMode.gurmukhi ? 'ਖ' : 'z',
        );
        await tester.pumpAndSettle();
        expect(repo.restore()!.game.triesRemaining, budget - 1);
        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        final before = repo.restore()!.game.toJson();
        await tester.ensureVisible(find.byTooltip('Use easier letter bank'));
        await tester.tap(find.byTooltip('Use easier letter bank'));
        await tester.pumpAndSettle();
        expect(repo.restore()!.fullKeyboard, isFalse);
        expect(repo.restore()!.game.toJson(), before);
        expect(find.byType(QuestLantern), findsOneWidget);
        final correct = switch (mode) {
          LanguageMode.gurmukhi => 'ਸ',
          LanguageMode.romanizedPanjabi => 'Ā',
          LanguageMode.english => 'A',
        };
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: correct);
        await tester.pumpAndSettle();
        expect(repo.restore()!.fullKeyboard, isFalse);
        expect(repo.restore()!.game.triesRemaining, budget - 1);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        expect(find.byTooltip('Use full alphabet'), findsOneWidget);
        expect(repo.restore()!.game.guessedGraphemes, contains(correct));
        await tester.tap(find.byTooltip('Use full alphabet'));
        await tester.pumpAndSettle();
        expect(repo.restore()!.fullKeyboard, isTrue);
        expect(repo.restore()!.game.triesRemaining, budget - 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Gurmukhi hardware accepts a single letter and ignores lone vowel signs',
    (tester) async {
      final repository = WordQuestSessionRepository(MemoryKeyValueStore());
      await repository.save(
        mode: LanguageMode.gurmukhi,
        wordSize: 4,
        game: WordQuestGame(solution: 'ਸਤਿਗੁਰ'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.modern),
          home: WordQuestPage(
            vocabularyRepository: _gurmukhiVocabulary,
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
            sessionRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final value in ['੨', '1', 'ੴ', 'ਕਾ', 'ਸਤਿ', 'ਖ਼', '੍', 'ੰ', '🙂']) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: value);
        await tester.pumpAndSettle();
        expect(
          repository.restore()!.game.guessedGraphemes,
          isEmpty,
          reason: value,
        );
        expect(repository.restore()!.game.incorrectGuesses, 0, reason: value);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'ਸ');
      await tester.pumpAndSettle();
      expect(repository.restore()!.game.guessedGraphemes, contains('ਸ'));
      expect(repository.restore()!.game.incorrectGuesses, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'ਿ');
      await tester.pumpAndSettle();
      expect(repository.restore()!.game.guessedGraphemes, {'ਸ'});
      expect(repository.restore()!.game.incorrectGuesses, 0);
      expect(tester.takeException(), isNull);
    },
  );
  for (final gurmukhi in [false, true]) {
    testWidgets(
      '${gurmukhi ? 'Gurmukhi' : 'Latin'} letter key activates with keyboard Space',
      (tester) async {
        final repository = WordQuestSessionRepository(MemoryKeyValueStore());
        await repository.save(
          mode: gurmukhi ? LanguageMode.gurmukhi : LanguageMode.english,
          wordSize: gurmukhi ? 4 : 5,
          game: WordQuestGame(solution: gurmukhi ? 'ਸਤਿਗੁਰ' : 'APPLE'),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.forChoice(AppThemeChoice.modern),
            home: WordQuestPage(
              vocabularyRepository: gurmukhi
                  ? _gurmukhiVocabulary
                  : _vocabulary,
              hapticLevel: HapticFeedbackLevel.off,
              reducedMotion: true,
              sessionRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final letter = gurmukhi ? 'ਤਿ' : 'P';
        final key = find.byKey(ValueKey('word-quest-key-$letter'));
        final center = find
            .descendant(of: key, matching: find.byType(Center))
            .last;
        Focus.of(tester.element(center)).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space, character: ' ');
        await tester.pumpAndSettle();
        expect(repository.restore()?.game.guessedGraphemes, contains(letter));
        expect(repository.restore()?.game.incorrectGuesses, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
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
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.byKey(const ValueKey('word-quest-key-P')));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
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

const _romanizedVocabulary = MemoryVocabularyRepository([
  VocabularyEntry(
    id: 'punjabi_asan',
    language: VocabularyLanguage.panjabi,
    script: VocabularyScript.romanizedPunjabi,
    latin: 'ĀSĀN',
    gurmukhi: null,
    englishDefinition: 'A task that needs little effort',
    latinLength: 4,
    gurmukhiLength: null,
    acceptedGuess: true,
    solutionEligible: true,
    reviewStatus: ReviewStatus.editorApproved,
    source: 'Project editorial definition; original text for Sikhi Word Games',
  ),
]);
