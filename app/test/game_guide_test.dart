import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/game_guide_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/widgets/game_guide.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';

void main() {
  test(
    'seen markers are independent, durable and tolerate invalid values',
    () async {
      final store = MemoryKeyValueStore();
      final repository = GameGuideRepository(store);
      await repository.markSeen(GameKind.guessTheWord);
      expect(GameGuideRepository(store).hasSeen(GameKind.guessTheWord), isTrue);
      expect(repository.hasSeen(GameKind.wordQuest), isFalse);
      store.values['gameGuide.v1.wordSearch'] = 'invalid';
      expect(repository.hasSeen(GameKind.wordSearch), isFalse);
    },
  );

  testWidgets('skip persists first launch and help can replay later', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final repository = GameGuideRepository(store);
    Widget host() => MaterialApp(
      home: GameGuide(
        game: GameKind.guessTheWord,
        repository: repository,
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGameHelp(context, GameKind.guessTheWord),
              child: const Text('Help'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(repository.hasSeen(GameKind.guessTheWord), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsNothing);
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replay walkthrough'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  });

  testWidgets('all walkthrough steps fit a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final game in GameKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showGameWalkthrough(context, game),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      for (var step = 1; step <= 3; step++) {
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(step == 3 ? 'Start playing' : 'Next'));
        await tester.pumpAndSettle();
      }
      expect(find.byType(AlertDialog), findsNothing);
    }
  });
}
