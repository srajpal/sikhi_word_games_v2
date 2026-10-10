import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/romanized_vocabulary_views.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/game_guide_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/word_pool.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_vocabulary.dart';
import 'package:sikhi_word_games_v2/features/word_scramble/domain/word_scramble_vocabulary.dart';

// Uses bundled content and isolated in-memory saves. It never reads or resets
// the player's Android preferences. Timing is reported, not a flaky CI limit.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('reports real vocabulary preparation and first game frame', (
    tester,
  ) async {
    final repository = AssetVocabularyRepository();
    final entries = (await tester.runAsync(repository.load))!;
    void measure(String name, void Function() work) {
      final watch = Stopwatch()..start();
      work();
      watch.stop();
      debugPrint('LAUNCH_PERF $name ${watch.elapsedMilliseconds}ms');
    }

    measure('plain Romanized view', () {
      RomanizedVocabularyViews(entries).entries(simple: true);
    });
    for (final mode in LanguageMode.values) {
      measure('Bujho pools ${mode.name}', () {
        final pool = WordPool(entries);
        for (final length in [4, 5, 6]) {
          pool.solutions(mode: mode, wordLength: length);
        }
        pool.acceptedGuesses(mode: mode, wordLength: 5);
      });
      measure('Quest pool ${mode.name}', () {
        WordQuestVocabulary(entries).words(mode: mode);
      });
    }
    measure('Bridges all pools', () => WordBridgesContent(entries));
    measure('Scramble all pools', () {
      WordScrambleVocabulary(entries).availableModes;
    });

    final store = MemoryKeyValueStore();
    final guides = GameGuideRepository(store);
    for (final kind in GameKind.values) {
      store.values['gameGuide.v1.${kind.name}'] = 'seen';
    }
    // Give the route check its own freshly decoded identities so the benchmark
    // above cannot prewarm eligibility decisions for the navigation sample.
    final launchRepository = AssetVocabularyRepository();
    await tester.runAsync(launchRepository.load);
    debugPrint('LAUNCH_PERF home begin');
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(store),
        guideRepository: guides,
        vocabularyRepository: launchRepository,
      ),
    );
    await tester.pumpAndSettle();
    debugPrint('LAUNCH_PERF home ready');
    for (final kind in GameKind.values) {
      final button = find.byKey(ValueKey('new-game-${kind.name}'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      final watch = Stopwatch()..start();
      await tester.tap(button);
      await tester.pump();
      debugPrint(
        'LAUNCH_PERF ${kind.name} route '
        '${tester.widget<Navigator>(find.byType(Navigator).last).pages.last.runtimeType}',
      );
      debugPrint(
        'LAUNCH_PERF ${kind.name} first pump ${watch.elapsedMilliseconds}ms',
      );
      await tester.pumpAndSettle();
      watch.stop();
      debugPrint(
        'LAUNCH_PERF ${kind.name} settled ${watch.elapsedMilliseconds}ms',
      );
      expect(find.byTooltip('Back'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}
