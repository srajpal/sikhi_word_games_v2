import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/audio/interaction_sounds.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/widgets/game_guide.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/settings/presentation/settings_page.dart';

void main() {
  Widget harness({
    AppSettings settings = const AppSettings(),
    required Future<void> Function(InteractionSound) play,
    VoidCallback? button,
  }) => MaterialApp(
    builder: (context, child) =>
        InteractionSounds(settings: settings, playSound: play, child: child!),
    home: Scaffold(
      body: Builder(
        builder: (context) => ListView(
          children: [
            TextButton(
              onPressed: InteractionSounds.letterAction(context, () {}),
              child: const Text('Letter'),
            ),
            TextButton(
              onPressed: InteractionSounds.buttonAction(
                context,
                button ?? () {},
              ),
              child: const Text('Button'),
            ),
            TextButton(
              onPressed: InteractionSounds.buttonAction(context, null),
              child: const Text('Disabled'),
            ),
            Container(height: 1600, color: Colors.white),
          ],
        ),
      ),
    ),
  );

  testWidgets(
    'actions distinguish letters, buttons, disabled and raw gestures',
    (tester) async {
      final sounds = <InteractionSound>[];
      await tester.pumpWidget(
        harness(
          play: (sound) async {
            sounds.add(sound);
          },
        ),
      );
      await tester.tap(find.text('Letter'));
      await tester.tap(find.text('Button'));
      await tester.tap(find.text('Disabled'));
      await tester.tapAt(const Offset(300, 350));
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(sounds, [InteractionSound.letter, InteractionSound.button]);
    },
  );

  testWidgets(
    'keyboard activation sounds once and respects updated independent preferences',
    (tester) async {
      final sounds = <InteractionSound>[];
      Future<void> play(InteractionSound sound) async {
        sounds.add(sound);
      }

      await tester.pumpWidget(harness(play: play));
      final letterButton = tester.element(find.text('Letter'));
      Focus.of(letterButton).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sounds, [InteractionSound.letter]);
      await tester.pumpWidget(
        harness(settings: const AppSettings(letterClicks: false), play: play),
      );
      await tester.tap(find.text('Letter'));
      await tester.tap(find.text('Button'));
      await tester.pumpWidget(
        harness(settings: const AppSettings(buttonClicks: false), play: play),
      );
      await tester.tap(find.text('Letter'));
      await tester.tap(find.text('Button'));
      expect(sounds, [
        InteractionSound.letter,
        InteractionSound.button,
        InteractionSound.letter,
      ]);
    },
  );

  testWidgets(
    'playback failure does not block actions and background is silent',
    (tester) async {
      var actions = 0;
      var requests = 0;
      await tester.pumpWidget(
        harness(
          play: (_) async {
            requests++;
            throw StateError('audio unavailable');
          },
          button: () {
            actions++;
          },
        ),
      );
      await tester.tap(find.text('Button'));
      await tester.pump();
      expect(actions, 1);
      expect(requests, 1);
      expect(tester.takeException(), isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.tap(find.text('Button'));
      expect(actions, 2);
      expect(requests, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(find.text('Button'));
      await tester.pump();
      expect(requests, 2);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings apply click choices immediately and independently', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppSettings? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: SettingsPage(
          settings: const AppSettings(),
          onChanged: (value) async {
            saved = value;
          },
        ),
      ),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('letter-clicks')));
    await tester.tap(find.byKey(const ValueKey('letter-clicks')));
    await tester.pump();
    expect(saved!.letterClicks, isFalse);
    final letter = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('letter-clicks')),
    );
    final button = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('button-clicks')),
    );
    expect(letter.value, isFalse);
    expect(button.value, isTrue);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(saved!.letterClicks, isFalse);
    expect(saved!.buttonClicks, isTrue);
    expect(saved!.victorySound, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog actions inherit the app sound scope and play once', (
    tester,
  ) async {
    final sounds = <InteractionSound>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => InteractionSounds(
          settings: const AppSettings(),
          playSound: (sound) async {
            sounds.add(sound);
          },
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGameHelp(context, GameKind.guessTheWord),
              child: const Text('Open guide'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(sounds, [InteractionSound.button]);
    expect(find.text('Got it'), findsNothing);
  });

  test('bundled original click WAVs are brief, distinct and unclipped', () {
    final files = [
      File('assets/audio/letter_click.wav'),
      File('assets/audio/button_click.wav'),
    ];
    final waves = files.map((file) => file.readAsBytesSync()).toList();
    expect(waves[0], isNot(equals(waves[1])));
    for (final wave in waves) {
      final data = ByteData.sublistView(wave);
      expect(String.fromCharCodes(wave.take(4)), 'RIFF');
      expect(data.getUint16(22, Endian.little), 1);
      expect(data.getUint16(34, Endian.little), 16);
      final rate = data.getUint32(24, Endian.little);
      final count = data.getUint32(40, Endian.little) ~/ 2;
      expect(count / rate, inExclusiveRange(.03, .1));
      var peak = 0;
      for (var i = 0; i < count; i++) {
        final amplitude = data.getInt16(44 + i * 2, Endian.little).abs();
        if (amplitude > peak) peak = amplitude;
      }
      expect(peak, inExclusiveRange(100, 16000));
    }
  });
}
