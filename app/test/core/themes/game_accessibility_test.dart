import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/presentation/game_keyboard.dart';

void main() {
  testWidgets('screen-reader keyboard activation types, deletes and submits', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final actions = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.forChoice(AppThemeChoice.modern),
          home: Scaffold(
            body: GameKeyboard(
              mode: LanguageMode.english,
              onCharacter: actions.add,
              onBackspace: () => actions.add('delete'),
              onEnter: () => actions.add('submit'),
              enabled: true,
              disabledCharacters: const {'Q'},
            ),
          ),
        ),
      );
      for (final label in ['A', 'Delete last letter', 'Submit guess']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.tap,
        );
      }
      expect(actions, ['A', 'delete', 'submit']);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Q, not in the word'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('large-text action labels wrap without shrinking', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                child: GameGradientButton(
                  label: 'Start a new puzzle',
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsNothing);
    expect(
      tester.getSize(find.byType(GameGradientButton)).height,
      greaterThan(48),
    );
  });

  testWidgets('accessible feedback stays until dismissed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showGameSnackBar(context, 'Letter found'),
                child: const Text('Show feedback'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show feedback'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Letter found'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Letter found'), findsNothing);
  });
}
