import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';

void main() {
  testWidgets(
    'short content keeps the themed backdrop over the whole viewport',
    (tester) async {
      for (final choice in AppThemeChoice.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.forChoice(choice),
            home: const Scaffold(
              body: GameBackdrop(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 120,
                    child: Text('Short matching set'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.getSize(find.byType(GameBackdrop)),
          tester.getSize(find.byType(Scaffold)),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
