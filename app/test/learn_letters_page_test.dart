import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/data/learn_letters_repository.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/presentation/learn_letters_page.dart';

void main() {
  Widget page(LearnLettersRepository repository, {double scale = 1}) =>
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: LearnLettersPage(repository: repository),
      );

  testWidgets('wrong answer allows retry and correct answer waits for Next', (
    tester,
  ) async {
    final repository = LearnLettersRepository(MemoryKeyValueStore());
    await tester.pumpWidget(page(repository));
    await tester.pumpAndSettle();
    final initial = repository.restore()!;
    final right = initial.currentLetter.id;
    final wrong = initial.choices.firstWhere((choice) => choice.id != right).id;
    await tester.ensureVisible(find.byKey(ValueKey('letter-choice-$wrong')));
    await tester.tap(find.byKey(ValueKey('letter-choice-$wrong')));
    await tester.pumpAndSettle();
    expect(find.text('Not quite. Try another name.'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(ValueKey('letter-choice-$wrong')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byKey(ValueKey('letter-choice-$right')));
    await tester.tap(find.byKey(ValueKey('letter-choice-$right')));
    await tester.pumpAndSettle();
    expect(repository.restore()!.index, 0);
    expect(find.text('Next letter'), findsOneWidget);
    await tester.ensureVisible(find.text('Next letter'));
    await tester.tap(find.text('Next letter'));
    await tester.pumpAndSettle();
    expect(repository.restore()!.index, 1);
    expect(find.text('Next letter'), findsNothing);
  });

  testWidgets('five answers complete once and fresh round keeps statistics', (
    tester,
  ) async {
    final repository = LearnLettersRepository(MemoryKeyValueStore());
    await tester.pumpWidget(page(repository));
    await tester.pumpAndSettle();
    for (var index = 0; index < 5; index++) {
      final id = repository.restore()!.currentLetter.id;
      final answer = find.byKey(ValueKey('letter-choice-$id'));
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pumpAndSettle();
      if (index < 4) {
        await tester.ensureVisible(find.text('Next letter'));
        await tester.tap(find.text('Next letter'));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('Five letters practiced!'), findsOneWidget);
    expect(repository.statistics.roundsCompleted, 1);
    expect(repository.statistics.firstTryCorrect, 5);
    await tester.ensureVisible(find.text('Play another round'));
    await tester.tap(find.text('Play another round'));
    await tester.pumpAndSettle();
    expect(repository.restore()!.index, 0);
    expect(repository.statistics.roundsCompleted, 1);
  });

  testWidgets('narrow screen and doubled text keep choices accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = LearnLettersRepository(MemoryKeyValueStore());
    await tester.pumpWidget(page(repository, scale: 2));
    await tester.pumpAndSettle();
    final right = repository.restore()!.currentLetter.id;
    final choice = find.byKey(ValueKey('letter-choice-$right'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next letter'));
    expect(tester.takeException(), isNull);
  });
}
