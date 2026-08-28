import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../../core/themes/app_theme.dart';
import '../domain/guess_evaluator.dart';
import '../domain/guess_game.dart';
import '../domain/language_mode.dart';
import '../domain/word_pool.dart';
import '../domain/guess_statistics.dart';
import '../domain/guess_share.dart';
import '../domain/keyboard_feedback.dart';
import '../data/guess_statistics_repository.dart';
import 'game_keyboard.dart';

enum _GameMenuAction { help, statistics, dictionary, copyResult }

class GuessTheWordPage extends StatefulWidget {
  const GuessTheWordPage({
    required this.themeChoice,
    required this.onThemeChanged,
    required this.vocabularyRepository,
    required this.statisticsRepository,
    super.key,
  });

  final AppThemeChoice themeChoice;
  final ValueChanged<AppThemeChoice> onThemeChanged;
  final VocabularyRepository vocabularyRepository;
  final GuessStatisticsRepository statisticsRepository;

  @override
  State<GuessTheWordPage> createState() => _GuessTheWordPageState();
}

class _GuessTheWordPageState extends State<GuessTheWordPage> {
  final _controller = TextEditingController();
  final _gameFocusNode = FocusNode(debugLabel: 'Guess game keyboard');
  final _selector = NonRepeatingWordSelector();
  WordPool? _pool;
  GuessGame? _game;
  VocabularyEntry? _solutionEntry;
  LanguageMode _mode = LanguageMode.english;
  int _wordLength = 5;
  String? _message;
  bool _loading = true;
  late GuessStatisticsBook _statistics;

  @override
  void initState() {
    super.initState();
    _statistics = widget.statisticsRepository.load();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _controller.dispose();
    _gameFocusNode.dispose();
    super.dispose();
  }

  void _focusInput() {
    if (!mounted || _game?.status != GuessGameStatus.playing) return;
    _gameFocusNode.requestFocus();
  }

  void _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent || _game?.status != GuessGameStatus.playing) {
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return;
    }
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return;
    }
    final character = event.character;
    if (character == null || character.isEmpty) return;
    if (_mode != LanguageMode.gurmukhi &&
        !RegExp(r'^[A-Za-z]$').hasMatch(character)) {
      return;
    }
    _appendCharacter(
      _mode == LanguageMode.gurmukhi ? character : character.toUpperCase(),
    );
  }

  Future<void> _loadVocabulary() async {
    try {
      final entries = await widget.vocabularyRepository.load();
      if (!mounted) return;
      _pool = WordPool(entries);
      _startGame();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Unable to load the offline vocabulary: $error';
      });
    }
  }

  List<int> _availableLengths(LanguageMode mode) {
    final pool = _pool;
    if (pool == null) return const [4, 5, 6];
    return [
      for (final length in const [4, 5, 6])
        if (pool.solutions(mode: mode, wordLength: length).isNotEmpty) length,
    ];
  }

  void _changeMode(LanguageMode mode) {
    final lengths = _availableLengths(mode);
    if (lengths.isEmpty) {
      setState(
        () => _message = 'No reviewed starter solutions for ${mode.label}.',
      );
      return;
    }
    _mode = mode;
    if (!lengths.contains(_wordLength)) _wordLength = lengths.first;
    _startGame();
  }

  void _startGame({int? length}) {
    final pool = _pool;
    if (pool == null) return;
    _wordLength = length ?? _wordLength;
    final solutions = pool.solutions(mode: _mode, wordLength: _wordLength);
    if (solutions.isEmpty) {
      setState(() {
        _loading = false;
        _game = null;
        _message = 'No reviewed starter solutions for this mode and length.';
      });
      return;
    }
    final entry = _selector.select(solutions);
    final spelling = WordPool.spelling(entry, _mode)!;
    final accepted = pool.acceptedGuesses(mode: _mode, wordLength: _wordLength);
    setState(() {
      _solutionEntry = entry;
      _game = GuessGame(solution: spelling, acceptedGuesses: accepted);
      _controller.clear();
      _message = null;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusInput());
  }

  void _submit() {
    final game = _game;
    if (game == null) return;
    final guess = _controller.text;
    final result = game.submit(guess);
    setState(() {
      if (!result.isAccepted) {
        _message = switch (result.rejection!) {
          GuessRejection.wrongLength =>
            'Enter exactly ${game.wordLength} visible letters.',
          GuessRejection.notAccepted => 'Not in the accepted-guess list.',
          GuessRejection.gameOver => 'This game is already complete.',
        };
        return;
      }
      if (game.status != GuessGameStatus.playing) {
        _statistics = _statistics.record(
          mode: _mode,
          wordLength: game.wordLength,
          won: game.status == GuessGameStatus.won,
          attempts: game.turns.length,
        );
        widget.statisticsRepository.save(_statistics);
      }
      _controller.clear();
      _message = switch (game.status) {
        GuessGameStatus.won => 'You found it!',
        GuessGameStatus.lost => 'No guesses remain.',
        GuessGameStatus.playing => null,
      };
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusInput());
  }

  void _appendCharacter(String character) {
    final current = _controller.text;
    final candidate = '$current$character';
    if (candidate.characters.length > _wordLength) return;
    _controller.value = TextEditingValue(
      text: candidate,
      selection: TextSelection.collapsed(offset: candidate.length),
    );
    setState(() => _message = null);
    _focusInput();
  }

  void _backspace() {
    if (_controller.text.isEmpty) return;
    final shortened = _controller.text.characters.skipLast(1).toString();
    _controller.value = TextEditingValue(
      text: shortened,
      selection: TextSelection.collapsed(offset: shortened.length),
    );
    setState(() => _message = null);
    _focusInput();
  }

  Future<void> _showHelp() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How to play'),
      content: const SingleChildScrollView(child: _GuessHelpContent()),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  Future<void> _showStatistics() {
    final statistics = _statistics.forGame(_mode, _wordLength);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_mode.label} · $_wordLength letters'),
        content: _StatisticsContent(statistics: statistics),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyResult() async {
    final game = _game;
    if (game == null || game.status == GuessGameStatus.playing) return;
    await Clipboard.setData(
      ClipboardData(
        text: buildSpoilerSafeResult(game: game, mode: _mode),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Spoiler-free result copied')));
  }

  void _handleMenuAction(_GameMenuAction action) {
    switch (action) {
      case _GameMenuAction.help:
        _showHelp();
      case _GameMenuAction.statistics:
        _showStatistics();
      case _GameMenuAction.dictionary:
        context.push('/dictionary');
      case _GameMenuAction.copyResult:
        _copyResult();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final isComplete = game?.status != GuessGameStatus.playing;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess the Word'),
        actions: [
          PopupMenuButton<_GameMenuAction>(
            key: const ValueKey('game-menu'),
            tooltip: 'Game menu',
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _GameMenuAction.help,
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('How to play'),
                ),
              ),
              const PopupMenuItem(
                value: _GameMenuAction.statistics,
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Statistics'),
                ),
              ),
              const PopupMenuItem(
                value: _GameMenuAction.dictionary,
                child: ListTile(
                  leading: Icon(Icons.menu_book_outlined),
                  title: Text('Dictionary'),
                ),
              ),
              PopupMenuItem(
                value: _GameMenuAction.copyResult,
                enabled: isComplete && game != null,
                child: const ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy result'),
                ),
              ),
            ],
          ),
          DropdownButton<AppThemeChoice>(
            value: widget.themeChoice,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            underline: const SizedBox.shrink(),
            onChanged: (value) {
              if (value != null) widget.onThemeChanged(value);
            },
            items: const [
              DropdownMenuItem(
                value: AppThemeChoice.modern,
                child: Text('Modern'),
              ),
              DropdownMenuItem(
                value: AppThemeChoice.sketch,
                child: Text('Sketch'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 650;
                        return KeyboardListener(
                          focusNode: _gameFocusNode,
                          autofocus: true,
                          onKeyEvent: _handleHardwareKey,
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  DropdownButton<LanguageMode>(
                                    value: _mode,
                                    onChanged: (value) {
                                      if (value != null) _changeMode(value);
                                    },
                                    items: [
                                      for (final mode in LanguageMode.values)
                                        DropdownMenuItem(
                                          value: mode,
                                          child: Text(mode.label),
                                        ),
                                    ],
                                  ),
                                  DropdownButton<int>(
                                    value: _wordLength,
                                    onChanged: (value) {
                                      if (value != null) {
                                        _startGame(length: value);
                                      }
                                    },
                                    items: [
                                      for (final length in _availableLengths(
                                        _mode,
                                      ))
                                        DropdownMenuItem(
                                          value: length,
                                          child: Text('$length letters'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: compact ? 4 : 10),
                              if (game != null)
                                Expanded(
                                  child: _Board(
                                    turns: game.turns,
                                    wordLength: game.wordLength,
                                    maximumAttempts: game.maximumAttempts,
                                  ),
                                ),
                              SizedBox(height: compact ? 6 : 12),
                              if (_message != null)
                                Semantics(
                                  liveRegion: true,
                                  child: SizedBox(
                                    height: compact ? 34 : 44,
                                    child: Text(
                                      _message!,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                ),
                              if (game != null && isComplete) ...[
                                Text(
                                  game.solution,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  _solutionEntry!.englishDefinition,
                                  textAlign: TextAlign.center,
                                  maxLines: compact ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (game != null && !isComplete)
                                Semantics(
                                  textField: true,
                                  readOnly: true,
                                  label: _mode == LanguageMode.gurmukhi
                                      ? 'Gurmukhi guess'
                                      : 'Your guess',
                                  value: _controller.text,
                                  child: GestureDetector(
                                    key: const ValueKey('guess-display'),
                                    onTap: _focusInput,
                                    child: InputDecorator(
                                      isFocused: _gameFocusNode.hasFocus,
                                      decoration: InputDecoration(
                                        labelText:
                                            _mode == LanguageMode.gurmukhi
                                            ? 'Gurmukhi guess'
                                            : 'Your guess',
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      child: Text(
                                        _controller.text.isEmpty
                                            ? ' '
                                            : _controller.text,
                                        key: const ValueKey('guess-value'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              if (game != null && !isComplete) ...[
                                SizedBox(height: compact ? 4 : 8),
                                GameKeyboard(
                                  mode: _mode,
                                  enabled: true,
                                  disabledCharacters:
                                      unavailableKeyboardCharacters(game.turns),
                                  compact: compact,
                                  onCharacter: _appendCharacter,
                                  onBackspace: _backspace,
                                  onEnter: _submit,
                                ),
                              ],
                              if (game != null && isComplete)
                                FilledButton(
                                  onPressed: () => _startGame(),
                                  child: const Text('New game'),
                                ),
                              if (!compact) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Works completely offline',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuessHelpContent extends StatelessWidget {
  const _GuessHelpContent();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 460),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Find the hidden word in six accepted guesses. Choose a four-, '
          'five-, or six-letter game when that length is available.',
        ),
        const SizedBox(height: 16),
        Text('Tile clues', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const _HelpRow(
          icon: Icons.check,
          label: 'Correct',
          description: 'The letter is in the correct position.',
        ),
        const _HelpRow(
          icon: Icons.swap_horiz,
          label: 'Present',
          description: 'The letter belongs somewhere else in the word.',
        ),
        const _HelpRow(
          icon: Icons.close,
          label: 'Absent',
          description: 'The letter is not used in the answer.',
        ),
        const SizedBox(height: 16),
        Text('Language modes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'English uses English words. Romanized Panjabi uses Panjabi words '
          'written with Latin letters. Mixed Latin accepts both. Gurmukhi '
          'uses Panjabi words and the custom Gurmukhi keyboard.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Gurmukhi length counts visible letter groups, so a consonant and '
          'its vowel sign count together. Backspace removes one visible group.',
        ),
        const SizedBox(height: 12),
        const Text(
          'The answer and its definition appear when the game ends. Games '
          'and vocabulary work completely offline.',
        ),
      ],
    ),
  );
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, semanticLabel: label),
        const SizedBox(width: 10),
        Expanded(child: Text('$label — $description')),
      ],
    ),
  );
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.statistics});

  final GuessStatistics statistics;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16,
            runSpacing: 12,
            children: [
              _StatisticValue(value: statistics.gamesPlayed, label: 'Played'),
              _StatisticValue(value: statistics.winPercentage, label: 'Win %'),
              _StatisticValue(value: statistics.currentStreak, label: 'Streak'),
              _StatisticValue(value: statistics.bestStreak, label: 'Best'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Guess distribution',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var attempt = 1; attempt <= 6; attempt++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(width: 24, child: Text('$attempt')),
                  Expanded(
                    child: Semantics(
                      label:
                          '$attempt guesses, '
                          '${statistics.winDistribution[attempt] ?? 0} wins',
                      child: ExcludeSemantics(
                        child: LinearProgressIndicator(
                          minHeight: 18,
                          value: statistics.gamesWon == 0
                              ? 0
                              : (statistics.winDistribution[attempt] ?? 0) /
                                    statistics.gamesWon,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${statistics.winDistribution[attempt] ?? 0}',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _StatisticValue extends StatelessWidget {
  const _StatisticValue({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    child: Column(
      children: [
        Text(
          '$value',
          key: ValueKey('stat-$label'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _Board extends StatelessWidget {
  const _Board({
    required this.turns,
    required this.wordLength,
    required this.maximumAttempts,
  });

  final List<GuessTurn> turns;
  final int wordLength;
  final int maximumAttempts;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final spacing = constraints.maxHeight < 240
          ? 3.0
          : wordLength == 6
          ? 5.0
          : 8.0;
      final availableWidth =
          constraints.maxWidth - ((wordLength - 1) * spacing);
      final availableHeight =
          constraints.maxHeight - ((maximumAttempts - 1) * spacing);
      final size = math.min(
        (availableWidth / wordLength).clamp(12.0, 68.0),
        (availableHeight / maximumAttempts).clamp(12.0, 68.0),
      );
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var row = 0; row < maximumAttempts; row++)
            Padding(
              padding: EdgeInsets.only(
                bottom: row < maximumAttempts - 1 ? spacing : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var column = 0; column < wordLength; column++) ...[
                    _Tile(
                      key: ValueKey('tile-$row-$column'),
                      size: size,
                      letter: row < turns.length
                          ? turns[row].evaluation[column]
                          : null,
                    ),
                    if (column < wordLength - 1) SizedBox(width: spacing),
                  ],
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.size, this.letter, super.key});

  final double size;
  final EvaluatedLetter? letter;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    final color = switch (letter?.result) {
      LetterResult.correct => tokens.correct,
      LetterResult.present => tokens.present,
      LetterResult.absent => tokens.absent,
      null => Theme.of(context).colorScheme.surface,
    };
    final status = switch (letter?.result) {
      LetterResult.correct => 'correct position',
      LetterResult.present => 'present in another position',
      LetterResult.absent => 'not in the word',
      null => 'blank',
    };
    final statusIcon = switch (letter?.result) {
      LetterResult.correct => Icons.check,
      LetterResult.present => Icons.swap_horiz,
      LetterResult.absent => Icons.close,
      null => null,
    };
    return Semantics(
      label: letter == null ? 'Blank tile' : '${letter!.grapheme}, $status',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: tokens.tileRadius,
          border: Border.all(
            color: letter == null ? tokens.tileBorder : color,
            width: tokens.tileBorderWidth,
          ),
        ),
        child: statusIcon == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        letter!.grapheme,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 17,
                    child: Center(
                      child: Icon(statusIcon, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
