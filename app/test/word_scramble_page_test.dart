import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/paper_letter_tile.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/data/word_scramble_repository.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/presentation/word_scramble_page.dart';

import 'word_scramble_game_test.dart' show scramble;

VocabularyEntry fixture(String spelling, LanguageMode mode) => VocabularyEntry(
  id: 'fixture-$spelling',
  language: mode == LanguageMode.english
      ? VocabularyLanguage.english
      : VocabularyLanguage.panjabi,
  latin: mode == LanguageMode.gurmukhi ? 'APRAIL' : spelling,
  gurmukhi: mode == LanguageMode.gurmukhi ? spelling : null,
  englishDefinition: 'A test clue',
  latinLength: wordUnitCount(spelling),
  gurmukhiLength: mode == LanguageMode.gurmukhi
      ? wordUnitCount(spelling)
      : null,
  acceptedGuess: true,
  solutionEligible: true,
  reviewStatus: ReviewStatus.editorApproved,
  script: mode.script,
  source: 'Project editorial definition; original text for Sikhi Word Games',
);
Widget scramblePage(
  WordScrambleRepository repo, {
  String spelling = 'APPLE',
  LanguageMode mode = LanguageMode.english,
  AppThemeChoice theme = AppThemeChoice.sikhi,
  double scale = 1,
  bool simple = false,
}) => MaterialApp(
  theme: AppThemes.forChoice(theme),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: WordScramblePage(
    repository: repo,
    vocabularyRepository: MemoryVocabularyRepository([fixture(spelling, mode)]),
    initialMode: mode,
    simpleRomanized: simple,
  ),
);
void main() {
  for (final theme in AppThemeChoice.values) {
    testWidgets(
      'phone board fits and semantic tile play completes once in ${theme.name}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final repo = WordScrambleRepository(MemoryKeyValueStore());
        await tester.pumpWidget(scramblePage(repo, theme: theme));
        await tester.pumpAndSettle();
        expect(find.text('English · 5 letters'), findsOneWidget);
        expect(
          tester
              .widgetList<PaperLetterTile>(find.byType(PaperLetterTile))
              .every((tile) => tile.romanization == null),
          isTrue,
        );
        expect(find.text('Check word').hitTestable(), findsOneWidget);
        final game = repo.restore()!.game;
        for (var i = 0; i < 5; i++) {
          final target = find.byKey(ValueKey('scramble-tile-$i'));
          final node = tester.getSemantics(target);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
            node.id,
            SemanticsAction.tap,
          );
          await tester.pumpAndSettle();
        }
        expect(game.units.join(), 'APPLE');
        await tester.tap(find.text('Check word'));
        await tester.pumpAndSettle();
        expect(repo.total.solved, 1);
        expect(find.text('Next word'), findsOneWidget);
        expect(repo.hasActiveGame, isFalse);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
  testWidgets(
    'return, shuffle, hint and wrong checks recover without a toast',
    (tester) async {
      final repo = WordScrambleRepository(MemoryKeyValueStore());
      await tester.pumpWidget(scramblePage(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scramble-tile-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scramble-slot-0')));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.slots.every((id) => id == null), isTrue);
      await tester.tap(find.text('Shuffle'));
      await tester.pumpAndSettle();
      for (final id in [1, 0, 2, 3, 4]) {
        await tester.tap(find.byKey(ValueKey('scramble-tile-$id')));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Check word'));
      await tester.tap(find.text('Check word'));
      await tester.pumpAndSettle();
      expect(
        find.text('Not quite. Tap a tile to try a different order.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      await tester.tap(find.text('Hint · 1 left'));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.usedHint, isTrue);
      expect(repo.restore()!.game.slots[0], 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'large Gurmukhi written units wrap without splitting or overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = WordScrambleRepository(MemoryKeyValueStore());
      await tester.pumpWidget(
        scramblePage(
          repo,
          spelling: 'ਅਪ੍ਰੈਲ',
          mode: LanguageMode.gurmukhi,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.units, ['ਅ', 'ਪ੍ਰੈ', 'ਲ']);
      expect(find.text('ਪ੍ਰੈ'), findsOneWidget);
      expect(find.text('Prai'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Check word'));
      expect(tester.takeException(), isNull);
    },
  );
  for (final theme in AppThemeChoice.values) {
    testWidgets(
      'Gurmukhi tile labels survive placement, hints and completion in ${theme.name}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final repo = WordScrambleRepository(MemoryKeyValueStore());
        await tester.pumpWidget(
          scramblePage(
            repo,
            spelling: 'ਅਪ੍ਰੈਲ',
            mode: LanguageMode.gurmukhi,
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();
        void expectLabels() {
          for (final label in ['A', 'Prai', 'La']) {
            expect(find.text(label), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        }

        expectLabels();
        expect(
          tester
              .getSemantics(find.byKey(const ValueKey('scramble-tile-1')))
              .label,
          contains('Prai'),
        );
        await tester.tap(find.byKey(const ValueKey('scramble-tile-0')));
        await tester.pumpAndSettle();
        expectLabels();
        await tester.ensureVisible(find.text('Hint · 1 left'));
        await tester.tap(find.text('Hint · 1 left'));
        await tester.pumpAndSettle();
        final hinted = tester.widget<PaperLetterTile>(
          find.byKey(const ValueKey('scramble-slot-1')),
        );
        expect(hinted.locked, isTrue);
        expect(hinted.romanization, 'Prai');
        expectLabels();
        await tester.ensureVisible(
          find.byKey(const ValueKey('scramble-tile-2')),
        );
        await tester.tap(find.byKey(const ValueKey('scramble-tile-2')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Check word'));
        await tester.tap(find.text('Check word'));
        await tester.pumpAndSettle();
        expectLabels();
        expect(repo.total.solved, 1);
        expect(
          tester
              .widget<PaperLetterTile>(
                find.byKey(const ValueKey('scramble-slot-1')),
              )
              .correct,
          isTrue,
        );
        semantics.dispose();
      },
    );
  }
  testWidgets(
    'Continue keeps the original accented spelling after Simple changes',
    (tester) async {
      final repo = WordScrambleRepository(MemoryKeyValueStore()),
          game = scramble('ĀSĀN');
      game.place(1);
      await repo.save(mode: LanguageMode.romanizedPanjabi, game: game);
      await tester.pumpWidget(
        scramblePage(
          repo,
          spelling: 'ĀSĀN',
          mode: LanguageMode.romanizedPanjabi,
          simple: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.spelling, 'ĀSĀN');
      expect(repo.restore()!.game.slots[0], 1);
      await tester.tap(find.byTooltip('Shabad Banao menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New word'));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.spelling, 'ASAN');
      expect(repo.restore()!.simpleRomanized, isTrue);
    },
  );
}
