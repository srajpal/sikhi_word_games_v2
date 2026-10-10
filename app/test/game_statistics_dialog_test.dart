import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/statistics/game_statistics_repository.dart';
import 'package:sikhi_word_games_v2/core/statistics/game_statistics_dialog.dart';

void main() {
  testWidgets('statistics remain scrollable at large text on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = GameStatisticsRepository(
      MemoryKeyValueStore(),
      'wordQuest',
    );
    await repository.record(mode: 'english', size: 4, won: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGameStatistics(
                context,
                title: 'Word Quest',
                repository: repository,
                mode: 'english',
                size: 4,
                modeLabel: 'English',
                isQuest: true,
              ),
              child: const Text('Open statistics'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Finished: 1'), findsOneWidget);
    expect(find.text('English · 4 letters'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Close'));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Word Quest statistics'), findsNothing);
  });
  testWidgets('mixed-length statistics show the language detail exactly once', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGameStatistics(
                context,
                title: 'Khoj',
                repository: GameStatisticsRepository(
                  MemoryKeyValueStore(),
                  'wordSearch',
                ),
                mode: 'english',
                size: null,
                modeLabel: 'English',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('English · Mixed lengths'), findsOneWidget);
    expect(find.textContaining('Varied lengths'), findsNothing);
  });
}
