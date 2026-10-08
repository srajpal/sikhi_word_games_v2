import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/achievements/domain/player_progress.dart';
import 'package:sikhi_word_games_v2/features/achievements/presentation/achievements_page.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_statistics.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/settings/presentation/settings_page.dart';

import 'paper_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadPaperAssets();
    for (final (name, path) in [
      ('NotoSerif', 'assets/fonts/noto_serif/NotoSerif.ttf'),
      ('NotoSans', 'assets/fonts/noto_sans/NotoSans.ttf'),
      (
        'NotoSansGurmukhi',
        'assets/fonts/noto_sans_gurmukhi/NotoSansGurmukhi.ttf',
      ),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(name)..addFont(rootBundle.load(path))).load();
    }
  });
  for (final theme in AppThemeChoice.values) {
    testWidgets('achievement badges in ${theme.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final book = const GuessStatisticsBook().record(
        mode: LanguageMode.gurmukhi,
        wordLength: 4,
        won: true,
        attempts: 2,
      );
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.forChoice(theme),
          home: AchievementsPage(
            progress: PlayerProgress(bujho: book, khoj: {}, quest: {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('images/achievements_${theme.name}.png'),
      );
    }, tags: 'golden');
  }
  testWidgets('settings phone uses paper sections', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemes.forChoice(AppThemeChoice.modern),
        home: SettingsPage(
          settings: const AppSettings(theme: AppThemeChoice.modern),
          onSave: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('images/settings_phone_modern.png'),
    );
  }, tags: 'golden');
}
