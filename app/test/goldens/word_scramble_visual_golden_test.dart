import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/data/word_scramble_repository.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/domain/word_scramble_game.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/presentation/word_scramble_page.dart';

import '../word_scramble_page_test.dart' show fixture;
import 'paper_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadPaperAssets();
    for (final font in {
      'NotoSerif': 'assets/fonts/noto_serif/NotoSerif.ttf',
      'NotoSans': 'assets/fonts/noto_sans/NotoSans.ttf',
      'NotoSansGurmukhi':
          'assets/fonts/noto_sans_gurmukhi/NotoSansGurmukhi.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  Future<void> mount(
    WidgetTester tester,
    AppThemeChoice theme, {
    bool gurmukhi = false,
    bool largeText = false,
  }) async {
    tester.view.physicalSize = largeText
        ? const Size(320, 800)
        : const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mode = gurmukhi ? LanguageMode.gurmukhi : LanguageMode.english;
    final entry = fixture(gurmukhi ? 'ਅਪ੍ਰੈਲ' : 'APPLE', mode);
    final repository = WordScrambleRepository(MemoryKeyValueStore());
    final game = WordScrambleGame(
      wordId: entry.id,
      spelling: gurmukhi ? entry.gurmukhi! : entry.latin,
      definition: entry.displayDefinition,
      random: Random(7),
      roundId: 'golden',
    );
    game.place(0);
    await repository.save(mode: mode, game: game);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.forChoice(theme),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
          child: child!,
        ),
        home: WordScramblePage(
          repository: repository,
          vocabularyRepository: MemoryVocabularyRepository([entry]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final theme in AppThemeChoice.values) {
    testWidgets('Shabad Banao phone in ${theme.name}', (tester) async {
      await mount(tester, theme);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('images/scramble_${theme.name}.png'),
      );
    }, tags: 'golden');
  }
  testWidgets('Shabad Banao Gurmukhi conjunct', (tester) async {
    await mount(tester, AppThemeChoice.sikhi, gurmukhi: true);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('images/scramble_gurmukhi_sikhi.png'),
    );
  }, tags: 'golden');
  testWidgets('Shabad Banao meaning appears only after Hint', (tester) async {
    await mount(tester, AppThemeChoice.sikhi);
    expect(find.text('A test clue'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scramble-hint')));
    await tester.pumpAndSettle();
    expect(find.text('A test clue'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('images/scramble_meaning_hint_sikhi.png'),
    );
  }, tags: 'golden');
  testWidgets('Shabad Banao narrow large-text header and tiles', (
    tester,
  ) async {
    await mount(tester, AppThemeChoice.sikhi, gurmukhi: true, largeText: true);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('images/scramble_large_text_sikhi.png'),
    );
  }, tags: 'golden');
}
