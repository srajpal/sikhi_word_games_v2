import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/game_artwork.dart';
import '../../../core/themes/game_heading.dart';
import '../../../core/themes/game_ui.dart';
import '../../../core/themes/paper_page.dart';
import '../../../core/themes/studio_navigation.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/domain/player_progress.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../domain/game_launch_options.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({required this.progress, super.key});
  final PlayerProgress progress;
  @override
  Widget build(BuildContext context) {
    final facts = progress.facts;
    final finished = GameKind.values.fold(
      0,
      (sum, game) => sum + (facts['${game.name}:played'] ?? 0),
    );
    final words =
        (facts['guessTheWord:won'] ?? 0) +
        (facts['wordQuest:won'] ?? 0) +
        (facts['wordSearch:words'] ?? 0) +
        (facts['wordBridges:words'] ?? 0);
    final earned = achievements.where((badge) => badge.earned(facts)).length;
    return PaperPage(
      destination: StudioDestination.progress,
      title: 'Progress',
      icon: Icons.insights,
      introduction: 'Your discoveries, one word at a time.',
      children: [
        GamePanel(
          child: Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              Text(
                '$finished rounds finished',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '$words words solved',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GameGradientButton(
          label: 'View achievements · $earned / ${achievements.length}',
          icon: const Icon(Icons.workspace_premium),
          onPressed: () => context.push('/achievements'),
        ),
        const SizedBox(height: 20),
        for (final game in GameKind.values) ...[
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GameArtwork(
                      kind: switch (game) {
                        GameKind.guessTheWord => GameArtworkKind.deduction,
                        GameKind.wordSearch => GameArtworkKind.search,
                        GameKind.wordQuest => GameArtworkKind.garden,
                        GameKind.wordBridges => GameArtworkKind.bridges,
                        GameKind.learnLetters => GameArtworkKind.letters,
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GameHeading(identity: GameIdentity.forGame(game)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(switch (game) {
                  GameKind.guessTheWord =>
                    '${facts['guessTheWord:played'] ?? 0} finished, ${facts['guessTheWord:won'] ?? 0} won',
                  GameKind.wordSearch =>
                    '${facts['wordSearch:played'] ?? 0} puzzles finished, ${facts['wordSearch:words'] ?? 0} words found',
                  GameKind.wordQuest =>
                    '${facts['wordQuest:played'] ?? 0} finished, ${facts['wordQuest:won'] ?? 0} won',
                  GameKind.wordBridges =>
                    '${facts['wordBridges:won'] ?? 0} sets finished, ${facts['wordBridges:words'] ?? 0} pairs matched',
                  GameKind.learnLetters =>
                    '${facts['learnLetters:won'] ?? 0} rounds finished, ${facts['learnLetters:firstTry'] ?? 0} first-try answers',
                }, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (game == GameKind.learnLetters)
                  Text(
                    '${facts['learnLetters:practiced'] ?? 0} of 35 letters Practiced. Three first-try answers in finished rounds mark a letter Practiced.',
                  )
                else
                  for (final mode in LanguageMode.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${mode.label}: ${facts['${game.name}:${mode.name}'] ?? 0} solved',
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Finished attempts count, including repeat words and retries. Unfinished rounds are not counted. Letters are counted separately from words. Saved only on this device or browser; earlier results are kept.',
        ),
      ],
    );
  }
}
