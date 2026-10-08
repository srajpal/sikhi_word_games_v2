import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/widgets/letter_pronunciation_button.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/data/learn_letters_repository.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/domain/learn_letters_game.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/presentation/learn_letters_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'NotoSans',
    )..addFont(rootBundle.load('assets/fonts/noto_sans/NotoSans.ttf'))).load();
    await (FontLoader('NotoSansGurmukhi')..addFont(
          rootBundle.load(
            'assets/fonts/noto_sans_gurmukhi/NotoSansGurmukhi.ttf',
          ),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> mount(
    WidgetTester tester,
    AppThemeChoice choice, {
    bool answered = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = answered
        ? const Size(320, 640)
        : const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = LearnLettersRepository(MemoryKeyValueStore());
    final game = LearnLettersGame.newRound(random: Random(7));
    if (answered) {
      game.answer(
        game.choices
            .firstWhere((letter) => letter.id != game.currentLetter.id)
            .id,
      );
      game.answer(game.currentLetter.id);
    }
    await repository.save(game);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.forChoice(choice),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(answered ? 2 : 1)),
          child: child!,
        ),
        home: LearnLettersPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    if (answered) {
      await tester.ensureVisible(find.byType(LetterPronunciationButton));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  }

  for (final theme in AppThemeChoice.values) {
    testWidgets('Learn Letters phone question in ${theme.name}', (
      tester,
    ) async {
      await mount(tester, theme);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('images/learn_letters_question_${theme.name}.png'),
      );
    }, tags: 'golden');
  }

  testWidgets('Learn Letters answered after retry on narrow large-text phone', (
    tester,
  ) async {
    await mount(tester, AppThemeChoice.sikhi, answered: true);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('images/learn_letters_answered_large_text_sikhi.png'),
    );
  }, tags: 'golden');
}
