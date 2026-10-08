import 'package:flutter/material.dart';

import '../../../core/themes/game_ui.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/widgets/letter_pronunciation_button.dart';
import '../../../core/widgets/victory_celebration.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../data/learn_letters_repository.dart';
import '../domain/learn_letters_game.dart';

class LearnLettersPage extends StatefulWidget {
  const LearnLettersPage({
    required this.repository,
    this.startFresh = false,
    super.key,
  });

  final LearnLettersRepository repository;
  final bool startFresh;

  @override
  State<LearnLettersPage> createState() => _LearnLettersPageState();
}

class _LearnLettersPageState extends State<LearnLettersPage> {
  late LearnLettersGame _game;
  String? _saveError;
  String _feedback = 'Take your time. There is no timer.';

  @override
  void initState() {
    super.initState();
    _game =
        (widget.startFresh ? null : widget.repository.restore()) ??
        widget.repository.newGame();
    if (_game.answered) {
      _feedback = 'Correct! This letter is ${_game.currentLetter.name}.';
    }
    _save();
  }

  Future<void> _save() async {
    try {
      await widget.repository.save(_game);
      if (mounted) setState(() => _saveError = null);
    } on Object {
      if (mounted) {
        setState(
          () => _saveError = 'Progress could not be saved on this device. You can keep playing.',
        );
      }
    }
  }

  void _newRound() {
    VictoryCelebration.stop(context);
    setState(() {
      _game = widget.repository.newGame();
      _feedback = 'Take your time. There is no timer.';
    });
    _save();
  }

  void _answer(String id) {
    if (_game.answered ||
        _game.isComplete ||
        _game.wrongChoiceIds.contains(id)) {
      return;
    }
    final correct = _game.answer(id);
    setState(
      () => _feedback = correct
          ? 'Correct! This letter is ${_game.currentLetter.name}.'
          : 'Not quite. Try another name.',
    );
    if (correct && _game.isComplete) VictoryCelebration.celebrate(context);
    _save();
  }

  void _next() {
    setState(() {
      _game.next();
      _feedback = 'Choose the name that matches this letter.';
    });
    _save();
  }

  void _statistics() {
    final statistics = widget.repository.statistics;
    final mastery = widget.repository.mastery;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Letter progress'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${statistics.roundsCompleted} rounds completed'),
            Text('${statistics.firstTryCorrect} first-try answers'),
            const SizedBox(height: 12),
            const Text(
              'Mark a letter Practiced by naming it correctly on your first try in three completed rounds.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Computer-generated pronunciation preview. Please check the audio.',
            ),
            for (final letter in learnLetters)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${letter.gurmukhi}  ${letter.name}\n${(mastery[letter.id] ?? 0) >= 3 ? 'Practiced' : '${mastery[letter.id] ?? 0} of 3 first-try answers'}',
                    ),
                    LetterPronunciationButton(
                      letterId: letter.id,
                      label: 'Hear ${letter.name}',
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akhar Pachhaan'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Akhar Pachhaan menu',
            onSelected: (action) {
              switch (action) {
                case 'new':
                  _newRound();
                case 'help':
                  showGameHelp(context, GameKind.learnLetters);
                case 'statistics':
                  _statistics();
                case 'celebration':
                  VictoryCelebration.showSettings(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('New round')),
              PopupMenuItem(value: 'help', child: Text('Help')),
              PopupMenuItem(
                value: 'statistics',
                child: Text('Letter progress'),
              ),
              PopupMenuItem(
                value: 'celebration',
                child: Text('Celebration settings'),
              ),
            ],
          ),
        ],
      ),
      body: GameBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Akhar Pachhaan: Learn Letters',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (_game.isComplete) ...[
                      GamePanel(
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 56,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Five letters practiced!',
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_game.firstTryCorrect} of 5 named on your first try.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Computer-generated pronunciation preview. Please check the audio.',
                              textAlign: TextAlign.center,
                            ),
                            for (final id in _game.questionIds)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${learnLetters.firstWhere((letter) => letter.id == id).gurmukhi}  ${learnLetters.firstWhere((letter) => letter.id == id).name}',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    LetterPronunciationButton(
                                      letterId: id,
                                      label:
                                          'Hear ${learnLettersById[id]!.name}',
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _newRound,
                        child: const Text('Play another round'),
                      ),
                      TextButton(
                        onPressed: _statistics,
                        child: const Text('See letter progress'),
                      ),
                    ] else ...[
                      Text(
                        'Letter ${_game.index + 1} of 5',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_game.index + (_game.answered ? 1 : 0)) / 5,
                        semanticsLabel: 'Letters answered',
                      ),
                      const SizedBox(height: 16),
                      GamePanel(
                        child: Column(
                          children: [
                            const Text(
                              'Choose this letter’s name',
                              textAlign: TextAlign.center,
                            ),
                            Semantics(
                              label:
                                  'Gurmukhi letter ${_game.currentLetter.gurmukhi}',
                              excludeSemantics: true,
                              child: Text(
                                _game.currentLetter.gurmukhi,
                                key: const ValueKey('letter-target'),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: 88,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (_game.answered) ...[
                              Text(
                                _game.currentLetter.name,
                                style: theme.textTheme.titleLarge,
                              ),
                              LetterPronunciationButton(
                                letterId: _game.currentLetter.id,
                                label: 'Hear ${_game.currentLetter.name}',
                              ),
                              const Text(
                                'Computer-generated pronunciation preview. Please check the audio.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final choice in _game.choices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton(
                            key: ValueKey('letter-choice-${choice.id}'),
                            onPressed:
                                _game.answered ||
                                    _game.wrongChoiceIds.contains(choice.id)
                                ? null
                                : () => _answer(choice.id),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              padding: const EdgeInsets.all(14),
                            ),
                            child: Text(
                              choice.name,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      Semantics(
                        liveRegion: true,
                        child: Text(_feedback, textAlign: TextAlign.center),
                      ),
                      if (_game.answered) ...[
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _next,
                          child: const Text('Next letter'),
                        ),
                      ],
                    ],
                    if (_saveError != null) ...[
                      const SizedBox(height: 16),
                      Semantics(liveRegion: true, child: Text(_saveError!)),
                      TextButton(
                        onPressed: _save,
                        child: const Text('Retry saving'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
