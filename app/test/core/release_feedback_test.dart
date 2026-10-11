import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/release_feedback.dart';

void main() {
  testWidgets('feedback retains a selectable email when clipboard is blocked', (
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
    await tester.tap(find.text('Copy email address'));
    await tester.pumpAndSettle();
    expect(find.text('Copy the email address manually'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SelectableText, feedbackEmail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final outcome in ['opened', 'unavailable', 'error']) {
    testWidgets('feedback email handles $outcome mail app', (tester) async {
      Uri? requested;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showReleaseFeedback(
                  context,
                  openEmail: (uri) async {
                    requested = uri;
                    if (outcome == 'error') throw StateError('No mail handler');
                    return outcome == 'opened';
                  },
                ),
                child: const Text('Feedback'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Feedback'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Email feedback'));
      await tester.pumpAndSettle();
      expect(requested!.scheme, 'mailto');
      expect(requested!.path, 'khalsagamestudio.apps@gmail.com');
      expect(
        requested!.queryParameters['subject'],
        contains('Sikhi Word Games'),
      );
      expect(requested!.queryParameters['body'], contains('Device/browser:'));
      expect(requested!.query, contains('%20'));
      if (outcome == 'opened') {
        expect(find.byType(AlertDialog), findsNothing);
      } else {
        expect(find.text('Email app unavailable'), findsOneWidget);
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(SelectableText, feedbackEmail),
          findsOneWidget,
        );
        expect(find.text('Copy email address'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('copy feedback uses the plain developer email', (tester) async {
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
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
    await tester.tap(find.text('Copy email address'));
    await tester.pumpAndSettle();
    expect(copied, 'khalsagamestudio.apps@gmail.com');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Email address copied.'), findsOneWidget);
  });
}
