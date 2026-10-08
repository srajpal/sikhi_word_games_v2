import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';
import 'package:sikhi_word_games_v2/core/widgets/victory_celebration.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'NotoSans',
    )..addFont(rootBundle.load('assets/fonts/noto_sans/NotoSans.ttf'))).load();
    await (FontLoader('NotoSansGurmukhi')..addFont(
          rootBundle.load(
            'assets/fonts/noto_sans_gurmukhi/NotoSansGurmukhi.ttf',
          ),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final theme in AppThemeChoice.values) {
    testWidgets('victory burst on phone in ${theme.name}', (tester) async {
      await _captureVictory(tester, theme: theme);
    }, tags: 'golden');
  }

  testWidgets('victory banner fits narrow phone with double text', (
    tester,
  ) async {
    await _captureVictory(
      tester,
      theme: AppThemeChoice.sikhi,
      size: const Size(320, 640),
      textScale: 2,
      suffix: '_large_text',
    );
  }, tags: 'golden');
}

Future<void> _captureVictory(
  WidgetTester tester, {
  required AppThemeChoice theme,
  Size size = const Size(360, 800),
  double textScale = 1,
  String suffix = '',
}) async {
  final oldDisableShadows = debugDisableShadows;
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = oldDisableShadows);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('victory-golden'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.forChoice(theme),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: VictoryCelebration(
          game: GameKind.wordBridges,
          settings: AppSettings(theme: theme),
          onSettingsChanged: (_) {},
          playSound: () async {},
          child: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Jodo')),
              body: GameBackdrop(
                child: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 156, 16, 24),
                    children: [
                      GamePanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'All four pairs matched!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '4 pairs matched · 4 attempts',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  VictoryCelebration.celebrate(context),
                              child: const Text(
                                'Celebrate',
                                style: TextStyle(fontFamily: 'NotoSans'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Celebrate'));
  await tester.tap(find.text('Celebrate'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byKey(const ValueKey('victory-particles')), findsOneWidget);
  expect(find.text('You did it!'), findsOneWidget);
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byKey(const ValueKey('victory-golden')),
    matchesGoldenFile('images/victory_${theme.name}$suffix.png'),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('victory-particles')), findsNothing);
  debugDisableShadows = oldDisableShadows;
  await tester.pumpWidget(const SizedBox.shrink());
  expect(tester.takeException(), isNull);
}
