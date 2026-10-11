import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/achievements/presentation/achievement_feedback.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/data/learn_letters_repository.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/domain/learn_letters_game.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/presentation/learn_letters_page.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

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

  void surface(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> mountLetters(
    WidgetTester tester,
    AppThemeChoice theme, {
    bool badge = false,
    bool large = false,
  }) async {
    surface(tester, large ? const Size(320, 800) : const Size(390, 844));
    final repo = LearnLettersRepository(MemoryKeyValueStore());
    await repo.save(
      LearnLettersGame.newRound(
        random: Random(7),
        practiceMode: LetterPracticeMode.listening,
      ),
    );
    final facts = <String, int>{};
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.forChoice(theme),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(large ? 2 : 1),
            accessibleNavigation: large,
          ),
          child: child!,
        ),
        home: AchievementFeedback(
          game: GameKind.learnLetters,
          facts: () => facts,
          reducedMotion: true,
          child: LearnLettersPage(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (badge) {
      facts['learnLetters:won'] = 1;
      AchievementFeedback.check(tester.element(find.byType(LearnLettersPage)));
      await tester.pumpAndSettle();
      if (large) {
        await tester.pump(const Duration(seconds: 20));
        expect(find.text('First page'), findsOneWidget);
      }
    }
    expect(tester.takeException(), isNull);
  }

  for (final theme in AppThemeChoice.values) {
    testWidgets('listening choices in ${theme.name}', (tester) async {
      await mountLetters(tester, theme);
      await expectLater(
        find.byType(AchievementFeedback),
        matchesGoldenFile('images/letters_listening_${theme.name}.png'),
      );
    }, tags: 'golden');
    testWidgets('named badge banner in ${theme.name}', (tester) async {
      await mountLetters(tester, theme, badge: true);
      await expectLater(
        find.byType(AchievementFeedback),
        matchesGoldenFile('images/badge_banner_${theme.name}.png'),
      );
      await tester.pumpWidget(const SizedBox());
    }, tags: 'golden');
  }
  testWidgets('badge banner stays readable with large accessible text', (
    tester,
  ) async {
    await mountLetters(tester, AppThemeChoice.sikhi, badge: true, large: true);
    await expectLater(
      find.byType(AchievementFeedback),
      matchesGoldenFile('images/badge_banner_large_text_sikhi.png'),
    );
    await tester.pumpWidget(const SizedBox());
  }, tags: 'golden');

  testWidgets('tablet Quest keeps its alphabet and lantern in view', (
    tester,
  ) async {
    surface(tester, const Size(1024, 768));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.forChoice(AppThemeChoice.sikhi),
        home: WordQuestPage(
          vocabularyRepository: MemoryVocabularyRepository([
            fixture('APPLE', LanguageMode.english),
          ]),
          sessionRepository: WordQuestSessionRepository(MemoryKeyValueStore()),
          startFresh: true,
          initialMode: LanguageMode.english,
          initialWordSize: 5,
          hapticLevel: HapticFeedbackLevel.off,
          reducedMotion: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('images/quest_tablet_full_alphabet_sikhi.png'),
    );
  }, tags: 'golden');
}
