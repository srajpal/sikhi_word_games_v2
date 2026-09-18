import 'package:flutter/material.dart';

import '../../features/game_library/domain/game_launch_options.dart';
import '../persistence/game_guide_repository.dart';

class GameGuide extends StatefulWidget {
  const GameGuide({
    super.key,
    required this.game,
    required this.repository,
    required this.child,
  });

  final GameKind game;
  final GameGuideRepository? repository;
  final Widget child;

  @override
  State<GameGuide> createState() => _GameGuideState();
}

class _GameGuideState extends State<GameGuide> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repository = widget.repository;
      if (!mounted || repository == null || repository.hasSeen(widget.game)) {
        return;
      }
      final game = widget.game;
      await showGameWalkthrough(context, game);
      // Dismissing with Back also counts as skipping the introduction.
      try {
        await repository.markSeen(game);
      } on Object catch (_) {
        // Unavailable storage must never prevent playing.
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

typedef _GuideStep = ({String title, String body});

String _gameName(GameKind game) => switch (game) {
  GameKind.guessTheWord => 'Bujho',
  GameKind.wordSearch => 'Khoj',
  GameKind.wordQuest => 'Word Quest',
  GameKind.wordBridges => 'Jodo: Word Bridges',
  GameKind.learnLetters => 'Akhar Pachhaan: Learn Letters',
};

List<_GuideStep> _steps(GameKind game) => switch (game) {
  GameKind.learnLetters => const [
    (
      title: 'Learn letter names',
      body: 'Look at one Gurmukhi letter and choose its name from three Romanized choices. This game teaches the names of the 35 basic letters, not the sounds they make in words. There is no timer.',
    ),
    (
      title: 'Practice five letters',
      body: 'A wrong choice stays marked so you can try another. After a correct answer, read the name and choose Next letter. Finish five letters to complete a round. Getting a letter right on your first try counts toward mastery when you finish the round.',
    ),
    (
      title: 'Build your collection',
      body: 'A letter is marked Practiced after three first-try answers in finished rounds. New rounds favor letters that need more practice. Open Letter progress to review your collection. Dots below Romanized letters help distinguish different Gurmukhi letters; spellings are approximate.',
    ),
  ],
  GameKind.wordBridges => const [
    (
      title: 'Connect words and meanings',
      body: 'Choose a word, then its English meaning. You can choose the meaning first instead. Match all four pairs to finish the set. There is no timer.',
    ),
    (
      title: 'Try a connection',
      body: 'Each word-and-meaning choice counts as one attempt. An incorrect match clears your selection so you can try again. Correct matches stay marked with a check. Choose a selected card again to cancel, or another card on the same side to change your choice.',
    ),
    (
      title: 'Play your way',
      body: 'Tap cards or use Tab and Enter or Space on a keyboard. With a screen reader, focus and activate each card. No dragging is needed. Use New set or Language above the cards. Open the game menu for Statistics or these instructions.',
    ),
  ],
  GameKind.guessTheWord => const [
    (
      title: 'Guess the hidden word',
      body: 'Use the on-screen letters or a physical keyboard to enter a complete word, then press Enter. You have six accepted guesses. A word that is not accepted does not use a guess.',
    ),
    (
      title: 'Read the tile clues',
      body: 'Check mark means Correct: the letter is in the right place. Two arrows mean Present: it belongs in another place. Cross means Absent: there are no copies left to match. If you repeat a letter, only as many copies as the answer contains can be Correct or Present.',
    ),
    (
      title: 'Use the clues',
      body: 'Keep Correct letters in place and try new places for Present letters. Backspace removes the last visible letter group. After the round, read the answer and definition. Open the game menu for How to play or Statistics.',
    ),
  ],
  GameKind.wordSearch => const [
    (
      title: 'Find every listed word',
      body: 'Find the words below the grid. Words follow a straight line across, down, or diagonally, in either direction.',
    ),
    (
      title: 'Select a word',
      body: 'Drag from its first letter to its last. With a screen reader, focus and double-tap the first cell, then the last cell. Double-tap the start again to cancel. With a keyboard, use arrow keys to move, then Enter or Space to choose the first and last cells. Escape cancels a selection.',
    ),
    (
      title: 'Get a clue',
      body: 'Use a word\'s hint button to highlight every grid cell matching its first letter. Select the word in the list to read its definition. Find all the words to finish. Open the game menu to read these instructions again.',
    ),
  ],
  GameKind.wordQuest => const [
    (
      title: 'Reveal the hidden word',
      body: 'Read the definition clue and choose one letter at a time using the on-screen letters or a physical keyboard. A correct letter reveals every place it appears and helps your garden grow.',
    ),
    (
      title: 'Keep your hearts',
      body: 'A wrong letter costs one heart. Choosing a letter again costs nothing. Four-letter words start with five hearts, five-letter words with six, and six-letter words with seven. Reveal the word before your hearts run out.',
    ),
    (
      title: 'Use a hint',
      body: 'A hint reveals a hidden letter without costing a heart. Four-letter words have no hints, five-letter words have one, and six-letter words have two. The answer is shown when the round ends. Open the game menu to read these instructions again.',
    ),
  ],
};

Future<void> showGameHelp(BuildContext context, GameKind game) async {
  final replay = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('How to play ${_gameName(game)}'),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final step in _steps(game)) ...[
              Semantics(
                header: true,
                child: Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Text(step.body),
              const SizedBox(height: 16),
            ],
            if (game == GameKind.wordQuest) ...[
              Semantics(
                header: true,
                child: Text(
                  'Letters and retries',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The simple letter bank includes the answer letters and some extra choices. Use Show all letters for the full bank, or Show simple letters to switch back. After a missed word, Try again starts the same word with fresh hearts and hints. Each finished attempt counts in Statistics, including retries.',
              ),
              const SizedBox(height: 16),
            ],
            if (game == GameKind.learnLetters)
              const Text(
                'Choose with touch, Tab and Enter, or a screen reader. Pronunciation clips are generated previews for review, not verified recordings. Hear each name after answering or in your letter collection. The installed app and its bundled clips work offline. Web offline reload requires the first download and caching to finish.',
              )
            else if (game == GameKind.wordBridges)
              const Text(
                'Choose English, Romanized Punjabi, or Gurmukhi words. Meanings are in English. Each fixed set includes different word lengths. Sets may repeat. The installed app works offline. On the web, offline reload requires a completed first download and browser caching support.',
              )
            else
              const Text(
                'English uses English words. Romanized Punjabi uses Punjabi words in Latin letters. Mixed accepts both. Gurmukhi uses Punjabi script; each visible letter group counts as one tile. The installed app works offline. On the web, the first visit needs a connection; offline reload is available only after caching finishes and the browser allows it.',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Replay walkthrough'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
  if (replay == true && context.mounted) {
    await showGameWalkthrough(context, game);
  }
}

Future<void> showGameWalkthrough(BuildContext context, GameKind game) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _Walkthrough(game: game),
    );

class _Walkthrough extends StatefulWidget {
  const _Walkthrough({required this.game});
  final GameKind game;

  @override
  State<_Walkthrough> createState() => _WalkthroughState();
}

class _WalkthroughState extends State<_Walkthrough> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final steps = _steps(widget.game);
    final step = steps[_index];
    return AlertDialog(
      scrollable: true,
      title: Text('Welcome to ${_gameName(widget.game)}'),
      content: SizedBox(
        width: 440,
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Step ${_index + 1} of ${steps.length}'),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Text(step.body),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        if (_index > 0)
          TextButton(
            onPressed: () => setState(() => _index--),
            child: const Text('Back'),
          ),
        FilledButton(
          onPressed: () {
            if (_index == steps.length - 1) {
              Navigator.pop(context);
            } else {
              setState(() => _index++);
            }
          },
          child: Text(_index == steps.length - 1 ? 'Start playing' : 'Next'),
        ),
      ],
    );
  }
}
