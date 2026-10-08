import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/core/themes/game_heading.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final font in [
      ('NotoSans', 'noto_sans/NotoSans.ttf'),
      ('NotoSerif', 'noto_serif/NotoSerif.ttf'),
    ]) {
      await (FontLoader(
        font.$1,
      )..addFont(rootBundle.load('assets/fonts/${font.$2}'))).load();
    }
  });

  for (final theme in AppThemeChoice.values) {
    for (final width in [320.0, 800.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '${theme.name} game headings at $width px and ${scale}x text',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            for (final game in GameKind.values) {
              final identity = GameIdentity.forGame(game);
              await tester.pumpWidget(
                MaterialApp(
                  theme: AppThemes.forChoice(theme),
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 800),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Builder(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          toolbarHeight: gameToolbarHeight(context),
                          leading: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.arrow_back),
                          ),
                          actions: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert),
                            ),
                          ],
                          title: GameHeading(identity: identity, compact: true),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final english = find.text(identity.englishTitle);
              final punjabi = find.text(identity.punjabiName);
              expect(
                tester.getBottomLeft(english).dy,
                lessThanOrEqualTo(tester.getTopLeft(punjabi).dy),
              );
              expect(
                tester.widget<Text>(english).style!.fontSize,
                lessThan(tester.widget<Text>(punjabi).style!.fontSize!),
              );
              final heading = tester.getRect(find.byType(GameHeading));
              final bar = tester.getRect(find.byType(AppBar));
              expect(heading.top, greaterThanOrEqualTo(bar.top));
              expect(heading.bottom, lessThanOrEqualTo(bar.bottom));
              expect(tester.takeException(), isNull, reason: identity.fullName);
            }
          },
        );
      }
    }
  }
}
