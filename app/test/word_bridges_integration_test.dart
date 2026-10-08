import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/game_guide_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/game_library/data/game_launch_preferences_repository.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';

void main() {
  testWidgets(
    'Word Bridges library launch, guide, continue and global totals',
    (tester) async {
      final store = MemoryKeyValueStore();
      final repository = WordBridgesRepository(store);
      final guides = GameGuideRepository(store);
      final preferences = GameLaunchPreferencesRepository(store);
      final vocabulary = AssetVocabularyRepository();
      final content = await tester.runAsync(
        () => WordBridgesContent.load(vocabulary),
      );
      await preferences.save(
        GameKind.wordBridges,
        const GameLaunchOptions(language: LanguageMode.english),
      );
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: AppSettingsRepository(store),
          vocabularyRepository: vocabulary,
          wordBridgesContentFuture: Future.value(content!),
          wordBridgesRepository: repository,
          guideRepository: guides,
          launchPreferencesRepository: preferences,
        ),
      );
      await tester.pumpAndSettle();
      final launch = find.byKey(const ValueKey('new-game-wordBridges'));
      await tester.scrollUntilVisible(launch, 300);
      await tester.pumpAndSettle();
      await tester.tap(launch);
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(guides.hasSeen(GameKind.wordBridges), isTrue);
      final game = repository.restore()!.game;
      final first = game.wordOrder.first;
      final word = find.byKey(ValueKey('bridge-word-${first.id}'));
      await tester.ensureVisible(word);
      await tester.tap(word);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Continue'), 300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3'), findsNothing);
      expect(repository.restore()!.game.roundId, game.roundId);
      expect(repository.restore()!.game.selectedWordId, first.id);
      for (final pair in game.wordOrder) {
        if (pair.id != first.id) {
          final item = find.byKey(ValueKey('bridge-word-${pair.id}'));
          await tester.ensureVisible(item);
          await tester.tap(item);
          await tester.pumpAndSettle();
        }
        final meaning = find.byKey(ValueKey('bridge-meaning-${pair.id}'));
        await tester.ensureVisible(meaning);
        await tester.tap(meaning);
        await tester.pumpAndSettle();
      }
      expect(repository.total.finishedSets, 1);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsNothing);
      await tester.tap(find.byTooltip('App settings'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Your statistics'));
      await tester.tap(find.text('Your statistics'));
      await tester.pumpAndSettle();
      expect(find.text('1 rounds finished'), findsOneWidget);
      expect(find.text('4 words solved'), findsOneWidget);
      expect(find.text('1 sets finished, 4 pairs matched'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(launch, -250);
      await tester.pumpAndSettle();
      await tester.tap(launch);
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3'), findsNothing);
      expect(repository.restore()!.game.roundId, isNot(game.roundId));
      expect(repository.total.finishedSets, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
