import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/game_guide_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/data/word_scramble_repository.dart';

import 'word_scramble_page_test.dart' show fixture;

void main() {
  testWidgets(
    'sixth library game launches, continues, guides and updates Progress',
    (tester) async {
      final store = MemoryKeyValueStore(),
          guides = GameGuideRepository(MemoryKeyValueStore());
      final repo = WordScrambleRepository(store);
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(store),
          guideRepository: guides,
          wordScrambleRepository: repo,
          vocabularyRepository: MemoryVocabularyRepository([
            fixture('APPLE', LanguageMode.english),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('new-game-wordScramble'));
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(guides.hasSeen(GameKind.wordScramble), isTrue);
      await tester.tap(find.byKey(const ValueKey('scramble-tile-0')));
      await tester.pumpAndSettle();
      final round = repo.restore()!.game.roundId;
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(repo.restore()!.game.roundId, round);
      expect(repo.restore()!.game.slots[0], 0);
      expect(find.text('Step 1 of 3'), findsNothing);
      for (var i = 1; i < 5; i++) {
        await tester.tap(find.byKey(ValueKey('scramble-tile-$i')));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Check word'));
      await tester.tap(find.text('Check word'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.text('1 rounds finished'), findsOneWidget);
      expect(find.text('1 words solved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
