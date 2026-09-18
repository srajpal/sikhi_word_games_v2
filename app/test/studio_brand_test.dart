import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/studio_brand.dart';

void main() {
  for (final opens in [true, false]) {
    testWidgets(
      'studio link opens the studio or retains a usable address: $opens',
      (tester) async {
        Uri? requested;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudioWebsiteLink(
                openUrl: (uri) async {
                  requested = uri;
                  return opens;
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text(studioDomain));
        await tester.pumpAndSettle();
        expect(requested, Uri.parse('https://khalsagamestudio.com'));
        expect(find.byType(AlertDialog), opens ? findsNothing : findsOneWidget);
        if (!opens) {
          expect(
            tester.widget<SelectableText>(find.byType(SelectableText)).data,
            'https://khalsagamestudio.com',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
