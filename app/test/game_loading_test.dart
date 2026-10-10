import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/game_ui.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

import 'word_scramble_page_test.dart' show fixture;

class _WarmVocabulary extends MemoryVocabularyRepository {
  _WarmVocabulary()
    : super([
        for (final word in ['APPLE', 'GRAPE', 'PEACH', 'PLUMS'])
          fixture(word, LanguageMode.english),
      ]);
  int loads = 0;
  @override
  Future<List<VocabularyEntry>> load() {
    loads++;
    return super.load();
  }
}

void main() {
  for (final game in GameKind.values.where(
    (game) => game != GameKind.learnLetters,
  )) {
    testWidgets('$game paints its loading screen before warm vocabulary work', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _WarmVocabulary();
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(MemoryKeyValueStore()),
          vocabularyRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(ValueKey('new-game-${game.name}'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      // GoRouter installs the destination on the next scheduled frame.
      await tester.pump();
      // The first destination frame acknowledges the tap even for cached data.
      expect(find.byType(GameLanguageHeader), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(GameLanguageHeader),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(repository.loads, 0);
      await tester.pumpAndSettle();
      expect(repository.loads, greaterThan(0));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
