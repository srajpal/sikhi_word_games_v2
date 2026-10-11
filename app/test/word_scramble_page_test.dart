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
  wordNetTagCount: mode == LanguageMode.english ? 3 : null,
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
  for (final mode in [LanguageMode.english, LanguageMode.gurmukhi]) {
    testWidgets('drag, swap, return and recall persist whole units in $mode', (
      tester,
    ) async {
      final repo = WordScrambleRepository(MemoryKeyValueStore());
      await tester.pumpWidget(
        scramblePage(
          repo,
          mode: mode,
          spelling: mode == LanguageMode.gurmukhi ? 'ਕਰੇਲਾ' : 'APPLE',
        ),
      );
      await tester.pumpAndSettle();
      Future<void> drag(Finder from, Finder to) async {
        await tester.drag(from, tester.getCenter(to) - tester.getCenter(from));
        await tester.pumpAndSettle();
      }

      await drag(
        find.byKey(const ValueKey('scramble-tile-1')),
        find.byKey(const ValueKey('scramble-slot-2')),
      );
      expect(repo.restore()!.game.slots[2], 1);
      await drag(
        find.byKey(const ValueKey('scramble-tile-0')),
        find.byKey(const ValueKey('scramble-slot-0')),
      );
      await drag(
        find.byKey(const ValueKey('scramble-slot-2')),
        find.byKey(const ValueKey('scramble-slot-0')),
      );
      expect(repo.restore()!.game.slots[0], 1);
      expect(repo.restore()!.game.slots[2], 0);
      await drag(
        find.byKey(const ValueKey('scramble-slot-0')),
        find.byKey(const ValueKey('scramble-tile-2')),
      );
      expect(repo.restore()!.game.tray, contains(1));
      await tester.tap(find.byKey(const ValueKey('scramble-recall')));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.slots.every((id) => id == null), isTrue);
      expect(
        repo.restore()!.game.tray.toSet().length,
        mode == LanguageMode.gurmukhi ? 3 : 5,
      );
      if (mode == LanguageMode.gurmukhi) {
        expect(find.text('ਰੇ'), findsOneWidget);
        expect(find.text('Re'), findsOneWidget);
      }
      for (final id in repo.restore()!.game.tray) {
        await tester.tap(find.byKey(ValueKey('scramble-tile-$id')));
        await tester.pumpAndSettle();
      }
      expect(repo.restore()!.game.tray, isEmpty);
      final returnedId = repo.restore()!.game.slots[0]!;
      await drag(
        find.byKey(const ValueKey('scramble-slot-0')),
        find.text('Drop tiles here to return them'),
      );
      expect(repo.restore()!.game.tray, [returnedId]);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'meaning is hidden, hint persists and the next word starts hidden',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = WordScrambleRepository(MemoryKeyValueStore());
      await tester.pumpWidget(scramblePage(repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scramble-clue')), findsNothing);
      expect(find.text('A test clue'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('A test clue')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('scramble-tile-1')));
      await tester.pumpAndSettle();
      final before = repo.restore()!.game;
      await tester.tap(find.byKey(const ValueKey('scramble-hint')));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.slots, before.slots);
      expect(repo.restore()!.game.tray, before.tray);
      expect(find.text('A test clue'), findsOneWidget);
      expect(repo.restore()!.game.usedHint, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(scramblePage(repo));
      await tester.pumpAndSettle();
      expect(find.text('A test clue'), findsOneWidget);
      expect(repo.restore()!.game.slots, before.slots);
      await tester.tap(find.byKey(const ValueKey('scramble-slot-0')));
      await tester.pumpAndSettle();
      for (var id = 0; id < 5; id++) {
        await tester.tap(find.byKey(ValueKey('scramble-tile-$id')));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Check word'));
      await tester.tap(find.text('Check word'));
      await tester.pumpAndSettle();
      expect(repo.total.solved, 1);
      expect(repo.total.unhinted, 0);
      expect(find.text('A test clue'), findsOneWidget);
      await tester.ensureVisible(find.text('Next word'));
      await tester.tap(find.text('Next word'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scramble-clue')), findsNothing);
      expect(repo.restore()!.game.usedHint, isFalse);
      semantics.dispose();
    },
  );
  testWidgets(
    'settings preserve the round until a different language is applied',
    (tester) async {
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = WordScrambleRepository(MemoryKeyValueStore());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.modern),
          home: WordScramblePage(
            repository: repo,
            vocabularyRepository: MemoryVocabularyRepository([
              fixture('APPLE', LanguageMode.english),
              fixture('ĀSĀN', LanguageMode.romanizedPanjabi),
              fixture('ਕਲਮਤ', LanguageMode.gurmukhi),
            ]),
            initialMode: LanguageMode.english,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('scramble-tile-0')));
      await tester.pumpAndSettle();
      final snapshot = repo.restore()!.game.toJson();
      Future<void> openSettings() async {
        await tester.tap(find.byTooltip('Shabad Banao menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Game settings'));
        await tester.pumpAndSettle();
      }

      await openSettings();
      await tester.tap(find.byKey(const ValueKey('scramble-language-english')));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.toJson(), snapshot);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.toJson(), snapshot);
      await openSettings();
      await tester.tap(
        find.byKey(const ValueKey('scramble-language-gurmukhi')),
      );
      await tester.pumpAndSettle();
      expect(repo.restore()!.mode, LanguageMode.english);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.toJson(), snapshot);
      await openSettings();
      await tester.tap(
        find.byKey(const ValueKey('scramble-language-gurmukhi')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      final changed = repo.restore()!;
      expect(changed.mode, LanguageMode.gurmukhi);
      expect(changed.game.roundId, isNot(snapshot['roundId']));
      expect(changed.game.slots.every((id) => id == null), isTrue);
      expect(repo.total.solved, 0);
      expect(tester.takeException(), isNull);
    },
  );
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
        expect(repo.total.unhinted, 1);
        expect(find.text('A test clue'), findsOneWidget);
        expect(find.text('1 word solved'), findsOneWidget);
        expect(find.text('1 words solved'), findsNothing);
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
      final before = repo.restore()!.game.slots;
      await tester.tap(find.byKey(const ValueKey('scramble-hint')));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.usedHint, isTrue);
      expect(repo.restore()!.game.slots, before);
      expect(repo.restore()!.game.locked, isEmpty);
      expect(find.text('A test clue'), findsOneWidget);
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
        await tester.ensureVisible(find.byKey(const ValueKey('scramble-hint')));
        await tester.tap(find.byKey(const ValueKey('scramble-hint')));
        await tester.pumpAndSettle();
        expect(repo.restore()!.game.locked, isEmpty);
        expect(find.text('A test clue'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('scramble-tile-1')));
        await tester.pumpAndSettle();
        final hinted = tester.widget<PaperLetterTile>(
          find.byKey(const ValueKey('scramble-slot-1')),
        );
        expect(hinted.locked, isFalse);
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
      await tester.tap(find.text('New game'));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.spelling, 'ASAN');
      expect(repo.restore()!.simpleRomanized, isTrue);
    },
  );
}
