import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/game_guide_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/learn_letters/data/learn_letters_repository.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  testWidgets(
    'library launch, first guide, continue and global letter totals',
    (tester) async {
      final store = MemoryKeyValueStore();
      final repository = LearnLettersRepository(store);
      final settings = AppSettingsRepository(store);
      await settings.save(
        const AppSettings(victorySound: false, victoryParticles: false),
      );
      await tester.pumpWidget(
        SikhiWordGamesApp(
          settingsRepository: settings,
          guideRepository: GameGuideRepository(store),
          learnLettersRepository: repository,
          vocabularyRepository: const MemoryVocabularyRepository([]),
        ),
      );
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('new-game-learnLetters'));
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(
        find.text('Welcome to Akhar Pachhaan: Learn Letters'),
        findsOneWidget,
      );
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(GameGuideRepository(store).hasSeen(GameKind.learnLetters), isTrue);
      final answer = find.byKey(
        ValueKey('letter-choice-${repository.restore()!.currentLetter.id}'),
      );
      await tester.ensureVisible(answer);
      await tester.pumpAndSettle();
      await tester.tap(answer);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      final resume = find.byKey(const ValueKey('continue-game-learnLetters'));
      await tester.ensureVisible(resume);
      await tester.pumpAndSettle();
      await tester.tap(resume);
      await tester.pumpAndSettle();
      expect(repository.restore()!.answered, isTrue);
      for (var index = 1; index < 5; index++) {
        await tester.ensureVisible(find.text('Next letter'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next letter'));
        await tester.pumpAndSettle();
        final choice = find.byKey(
          ValueKey('letter-choice-${repository.restore()!.currentLetter.id}'),
        );
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        await tester.tap(choice);
        await tester.pumpAndSettle();
      }
      expect(repository.statistics.roundsCompleted, 1);
      expect(repository.statistics.firstTryCorrect, 5);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('App settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Your statistics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Your statistics'));
      await tester.pumpAndSettle();
      expect(find.text('1 rounds finished'), findsOneWidget);
      expect(find.text('0 words solved'), findsOneWidget);
      expect(
        find.textContaining('1 rounds finished, 5 first-try answers.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
