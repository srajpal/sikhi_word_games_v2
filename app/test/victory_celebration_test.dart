import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/widgets/victory_celebration.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  Widget harness({
    AppSettings settings = const AppSettings(),
    bool deviceReducedMotion = false,
    Future<void> Function()? sound,
    ValueChanged<AppSettings>? onSave,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: deviceReducedMotion),
      child: VictoryCelebration(
        game: GameKind.wordBridges,
        settings: settings,
        onSettingsChanged: onSave ?? (_) {},
        playSound: sound ?? () async {},
        child: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => VictoryCelebration.celebrate(context),
                  child: const Text('Win'),
                ),
                TextButton(
                  onPressed: () => VictoryCelebration.showSettings(context),
                  child: const Text('Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('new win plays sound and temporary nonblocking particles', (
    tester,
  ) async {
    var sounds = 0;
    await tester.pumpWidget(
      harness(
        sound: () async {
          sounds++;
        },
      ),
    );
    expect(sounds, 0);
    await tester.tap(find.text('Win'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(sounds, 1);
    expect(find.byKey(const ValueKey('victory-particles')), findsOneWidget);
    expect(find.text('Win').hitTestable(), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('victory-particles')), findsNothing);
    await tester.pump();
    expect(sounds, 1);
  });

  testWidgets('global and per-game opt-outs silence both effects', (
    tester,
  ) async {
    var sounds = 0;
    for (final settings in [
      const AppSettings(victorySound: false, victoryParticles: false),
      const AppSettings().withGameVictory(
        GameKind.wordBridges,
        sound: false,
        particles: false,
      ),
    ]) {
      await tester.pumpWidget(
        harness(
          settings: settings,
          sound: () async {
            sounds++;
          },
        ),
      );
      await tester.tap(find.text('Win'));
      await tester.pump();
      expect(find.byKey(const ValueKey('victory-particles')), findsNothing);
    }
    expect(sounds, 0);
  });

  testWidgets(
    'app and system reduced motion suppress particles but retain sound',
    (tester) async {
      var sounds = 0;
      for (final system in [false, true]) {
        await tester.pumpWidget(
          harness(
            settings: AppSettings(reducedMotion: !system),
            deviceReducedMotion: system,
            sound: () async {
              sounds++;
            },
          ),
        );
        await tester.tap(find.text('Win'));
        await tester.pump();
        expect(find.byKey(const ValueKey('victory-particles')), findsNothing);
      }
      expect(sounds, 2);
    },
  );

  testWidgets('audio failure does not interrupt visual feedback or disposal', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        sound: () async {
          throw StateError('no audio');
        },
      ),
    );
    await tester.tap(find.text('Win'));
    await tester.pump();
    expect(find.byKey(const ValueKey('victory-particles')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('game settings cancel discards and save preserves other games', (
    tester,
  ) async {
    AppSettings? saved;
    await tester.pumpWidget(harness(onSave: (value) => saved = value));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Victory sound'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Victory sound'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved!.victorySoundFor(GameKind.wordBridges), isFalse);
    expect(saved!.victorySoundFor(GameKind.guessTheWord), isTrue);
    expect(saved!.victoryParticlesFor(GameKind.wordBridges), isTrue);
  });
}
