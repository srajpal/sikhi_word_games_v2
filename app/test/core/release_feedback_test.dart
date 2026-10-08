import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/release_feedback.dart';

void main() {
  testWidgets('feedback retains a selectable link when clipboard is blocked', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'denied');
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showReleaseFeedback(context),
              child: const Text('Feedback'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy feedback link'));
    await tester.pumpAndSettle();
    expect(find.text('Copy the link manually'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SelectableText, feedbackUrl), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
