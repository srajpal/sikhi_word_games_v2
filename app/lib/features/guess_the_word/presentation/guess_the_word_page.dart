import '../../../core/widgets/game_loading.dart';
import '../../achievements/presentation/achievement_feedback.dart';
import '../../../core/widgets/game_menu.dart';
import '../../../core/language/hardware_input.dart';
import '../../../core/content/romanized_vocabulary_views.dart';
import '../../../core/themes/paper_page.dart';
import '../../../core/themes/game_heading.dart';
import '../../../core/audio/interaction_sounds.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../../core/language/gurmukhi_normalization.dart';
import '../../../core/language/word_units.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/themes/game_ui.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/widgets/victory_celebration.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../domain/guess_evaluator.dart';
import '../domain/guess_game.dart';
import '../domain/language_mode.dart';
import '../domain/word_pool.dart';
import '../domain/guess_statistics.dart';
import '../domain/guess_share.dart';
import '../domain/keyboard_feedback.dart';
import '../data/guess_statistics_repository.dart';
import '../data/guess_game_repository.dart';
import '../data/solution_history_repository.dart';
import '../../settings/data/app_settings_repository.dart';
import 'game_keyboard.dart';

enum _GameMenuAction {
  newGame,
  settings,
  help,
  statistics,
  dictionary,
  copyResult,
  celebrations,
}

class GuessTheWordPage extends StatefulWidget {
  const GuessTheWordPage({
    required this.vocabularyRepository,
    required this.statisticsRepository,
    required this.gameRepository,
    required this.solutionHistoryRepository,
    required this.hapticLevel,
    required this.reducedMotion,
    this.initialMode,
    this.initialWordLength,
    this.startFresh = false,
    this.simpleRomanized = false,
    super.key,
  });

  final VocabularyRepository vocabularyRepository;
  final GuessStatisticsRepository statisticsRepository;
  final GuessGameRepository gameRepository;
  final SolutionHistoryRepository solutionHistoryRepository;
  final HapticFeedbackLevel hapticLevel;
  final bool reducedMotion;
  final LanguageMode? initialMode;
  final int? initialWordLength;
  final bool startFresh;
  final bool simpleRomanized;

  @override
  State<GuessTheWordPage> createState() => _GuessTheWordPageState();
}

class _GuessTheWordPageState extends State<GuessTheWordPage> {
  String _pendingGuess = '';
  final _gameFocusNode = FocusNode(debugLabel: 'Guess game keyboard');
  final _random = math.Random.secure();
  late final NonRepeatingWordSelector _selector;
  WordPool? _pool;
  RomanizedVocabularyViews? _views;
  GuessGame? _game;
  VocabularyEntry? _solutionEntry;
  bool _simpleRomanized = false;
  LanguageMode _mode = LanguageMode.english;
  int _wordLength = 5;
  String? _message;
  bool _loading = true;
  late GuessStatisticsBook _statistics;

  @override
  void initState() {
    super.initState();
    _statistics = widget.statisticsRepository.load();
    final history = widget.solutionHistoryRepository.load();
    _selector = NonRepeatingWordSelector(
      usedIds: history.usedIds,
      lastSelectedId: history.lastSelectedId,
    );
    _loadVocabulary();
  }

  @override
  void dispose() {
    _gameFocusNode.dispose();
    super.dispose();
  }

  void _focusInput() {
    if (!mounted ||
        _game?.status != GuessGameStatus.playing ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
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
    final hardware = HardwareKeyboard.instance;
    // Ctrl+Alt is the printable AltGr combination on some keyboards.
    if (hardware.isMetaPressed ||
        (hardware.isControlPressed != hardware.isAltPressed)) {
      return;
    }
    final character = event.character;
    if (character == null || character.isEmpty) return;
    if (!HardwareInput.acceptsCharacter(_mode.script, character)) {
      return;
    }
    InteractionSounds.letter(context);
    _appendCharacter(
      _mode == LanguageMode.gurmukhi ? character : character.toUpperCase(),
    );
  }

  Future<void> _loadVocabulary() async {
    try {
      await showGameLoadingFrame();
      if (!mounted) return;
      final entries = await widget.vocabularyRepository.load();
      if (!mounted) return;
      _views = RomanizedVocabularyViews(entries);
      _useSpelling(widget.gameRepository.usesSimpleRomanized);
      if (widget.startFresh) {
        _mode = widget.initialMode ?? _randomMode();
        _wordLength = widget.initialWordLength ?? _randomWordLength(_mode);
        _startGame();
        return;
      }
      final restored = widget.gameRepository.restore(
        (mode, length) =>
            _pool!.acceptedGuesses(mode: mode, wordLength: length),
      );
      if (restored == null) {
        _startGame();
        return;
      }
      final solutionEntry = _entryForPlayableSolution(
        restored.mode,
        restored.game.wordLength,
        restored.game.solution,
      );
      if (solutionEntry == null) {
        await _persist(widget.gameRepository.clear());
        if (!mounted) return;
        _mode = restored.mode;
        _wordLength = restored.game.wordLength;
        _startGame();
        return;
      }
      _selector.markUsed(solutionEntry.id);
      _saveSolutionHistory();
      setState(() {
        _mode = restored.mode;
        _wordLength = restored.game.wordLength;
        _solutionEntry = solutionEntry;
        _game = restored.game;
        _pendingGuess = '';
        _message = null;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusInput());
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Unable to load the offline vocabulary: $error';
      });
    }
  }

  LanguageMode _randomMode() {
    final values = LanguageMode.values;
    return values[_random.nextInt(values.length)];
  }

  int _randomWordLength(LanguageMode mode) {
    final lengths = _availableLengths(mode);
    if (lengths.isEmpty) return 5;
    return lengths[_random.nextInt(lengths.length)];
  }

  List<int> _availableLengths(LanguageMode mode) {
    final pool = _pool;
    if (pool == null) return const [4, 5, 6];
    return [
      for (final length in const [4, 5, 6])
        if (_playableSolutions(mode, length).isNotEmpty) length,
    ];
  }

  List<VocabularyEntry> _playableSolutions(LanguageMode mode, int length) =>
      _pool!
          .solutions(mode: mode, wordLength: length)
          .where((entry) => entry.hasDistributableDefinition)
          .toList(growable: false);

  VocabularyEntry? _entryForPlayableSolution(
    LanguageMode mode,
    int length,
    String solution,
  ) {
    final wanted = normalizeGurmukhi(solution.trim().toUpperCase());
    for (final entry in _playableSolutions(mode, length)) {
      final spelling = WordPool.spelling(entry, mode);
      if (spelling != null &&
          normalizeGurmukhi(spelling.trim().toUpperCase()) == wanted) {
        return entry;
      }
    }
    return null;
  }

  void _useSpelling(bool simple) {
    if (_pool != null && _simpleRomanized == simple) return;
    _simpleRomanized = simple;
    _pool = WordPool(_views!.entries(simple: simple));
  }

  void _startGame({int? length}) {
    if (_views == null) return;
    _useSpelling(widget.simpleRomanized);
    VictoryCelebration.stop(context);
    final pool = _pool;
    if (pool == null) return;
    _wordLength = length ?? _wordLength;
    final solutions = _playableSolutions(_mode, _wordLength);
    if (solutions.isEmpty) {
      setState(() {
        _loading = false;
        _game = null;
        _message = 'No reviewed starter solutions for this mode and length.';
      });
      return;
    }
    final entry = _selector.select(solutions);
    _saveSolutionHistory();
    final spelling = WordPool.spelling(entry, _mode)!;
    final accepted = pool.acceptedGuesses(mode: _mode, wordLength: _wordLength);
    setState(() {
      _solutionEntry = entry;
      _game = GuessGame(solution: spelling, acceptedGuesses: accepted);
      _pendingGuess = '';
      _message = null;
      _loading = false;
    });
    _persist(
      widget.gameRepository.save(
        game: _game!,
        mode: _mode,
        simpleRomanized: _simpleRomanized,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusInput());
  }

  void _saveSolutionHistory() {
    _persist(
      widget.solutionHistoryRepository.save(
        SolutionHistory(
          usedIds: _selector.usedIds,
          lastSelectedId: _selector.lastSelectedId,
        ),
      ),
    );
  }

  void _submit() {
    final game = _game;
    if (game == null) return;
    final guess = _pendingGuess;
    final result = game.submit(guess);
    if (!result.isAccepted) {
      _performHaptic(isError: true);
      final notice = switch (result.rejection!) {
        GuessRejection.wrongLength =>
          'Enter exactly ${game.wordLength} visible letters.',
        GuessRejection.notAccepted => 'Not in the accepted-guess list.',
        GuessRejection.gameOver => 'This game is already complete.',
      };
      _showNotice(notice);
      _focusInput();
      return;
    }
    setState(() {
      if (game.status != GuessGameStatus.playing) {
        _statistics = _statistics.record(
          mode: _mode,
          wordLength: game.wordLength,
          won: game.status == GuessGameStatus.won,
          attempts: game.turns.length,
        );
        _persist(
          widget.gameRepository.clear(
            after: widget.statisticsRepository.save(_statistics),
          ),
          checkAchievements: true,
        );
      } else {
        _persist(
          widget.gameRepository.save(
            game: game,
            mode: _mode,
            simpleRomanized: _simpleRomanized,
          ),
        );
      }
      _pendingGuess = '';
      _message = null;
    });
    _performHaptic();
    if (game.status == GuessGameStatus.won) {
      _showNotice('You found it!');
      VictoryCelebration.celebrate(context);
    } else if (game.status == GuessGameStatus.lost) {
      _showNotice('No guesses remain.');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusInput());
  }

  void _appendCharacter(String character) {
    final current = _pendingGuess;
    final appended = '$current$character';
    final candidate = _mode == LanguageMode.romanizedPanjabi
        ? (_simpleRomanized
              ? simplifyRomanizedPunjabi(appended)
              : normalizeRomanizedInput(appended))
        : normalizeGurmukhi(appended);
    if (wordUnitCount(candidate) > _wordLength) return;
    setState(() {
      _pendingGuess = candidate;
      _message = null;
    });
    _performHaptic(isKey: true);
    _focusInput();
  }

  void _backspace() {
    if (_pendingGuess.isEmpty) return;
    setState(() {
      _pendingGuess = withoutLastWordUnit(_pendingGuess);
      _message = null;
    });
    _performHaptic(isKey: true);
    _focusInput();
  }

  Future<void> _showHelp() => showGameHelp(context, GameKind.guessTheWord);

  void _performHaptic({bool isKey = false, bool isError = false}) {
    switch (widget.hapticLevel) {
      case HapticFeedbackLevel.off:
        return;
      case HapticFeedbackLevel.light:
        HapticFeedback.selectionClick();
        return;
      case HapticFeedbackLevel.medium:
        if (isKey) {
          HapticFeedback.selectionClick();
        } else {
          HapticFeedback.mediumImpact();
        }
        return;
      case HapticFeedbackLevel.strong:
        if (isError) {
          HapticFeedback.vibrate();
        } else {
          HapticFeedback.heavyImpact();
        }
        return;
    }
  }

  void _showNotice(String message) {
    showGameSnackBar(context, message);
  }

  Future<void> _showGameSettings() async {
    var selectedMode = _mode;
    var selectedLength = _wordLength;
    final applied = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final lengths = _availableLengths(selectedMode);
          if (!lengths.contains(selectedLength) && lengths.isNotEmpty) {
            selectedLength = lengths.first;
          }
          return AlertDialog(
            title: const Text('Game settings'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<LanguageMode>(
                    key: const ValueKey('settings-language'),
                    initialValue: selectedMode,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: [
                      for (final mode in LanguageMode.values)
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      InteractionSounds.button(context);
                      setDialogState(() => selectedMode = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey('settings-length-$selectedMode'),
                    initialValue: selectedLength,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Word size'),
                    items: [
                      for (final length in lengths)
                        DropdownMenuItem(
                          value: length,
                          child: Text('$length letters'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        InteractionSounds.button(context);
                        setDialogState(() => selectedLength = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: InteractionSounds.buttonAction(
                  context,
                  () => Navigator.of(context).pop(false),
                ),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: lengths.isEmpty
                    ? null
                    : InteractionSounds.buttonAction(
                        context,
                        () => Navigator.of(context).pop(true),
                      ),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
    if (applied != true || !mounted) return;
    if (selectedMode != _mode || selectedLength != _wordLength) {
      _mode = selectedMode;
      _startGame(length: selectedLength);
    } else {
      _focusInput();
    }
  }

  Future<void> _showStatistics() {
    final statistics = _statistics.forGame(_mode, _wordLength);
    return showPaperDetails(
      context,
      title: 'Bujho statistics',
      introduction: '${_mode.label} · $_wordLength letters',
      child: _StatisticsContent(statistics: statistics),
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
    _showNotice('Spoiler-free result copied');
  }

  void _handleMenuAction(_GameMenuAction action) {
    InteractionSounds.button(context);
    switch (action) {
      case _GameMenuAction.newGame:
        _startGame();
      case _GameMenuAction.settings:
        _showGameSettings();
      case _GameMenuAction.celebrations:
        VictoryCelebration.showSettings(context);
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

  Future<void> _persist(
    Future<void> write, {
    bool checkAchievements = false,
  }) async {
    try {
      await write;
      if (mounted && checkAchievements) AchievementFeedback.check(context);
    } on Object {
      if (!mounted) return;
      showGameSnackBar(
        context,
        'Progress could not be saved on this device. You can keep playing.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final isComplete = game?.status != GuessGameStatus.playing;
    return Scaffold(
      appBar: AppBar(
        leading: gameBackButton(context),
        flexibleSpace: const PaperTexture(),
        toolbarHeight: gameToolbarHeight(context),
        title: GameHeading(
          identity: GameIdentity.bujho,
          compact: true,
          subtitle: GameLanguageHeader(
            mode: _loading ? widget.initialMode : _mode,
            wordLength: game?.wordLength,
          ),
        ),
        actions: [
          PopupMenuButton<_GameMenuAction>(
            onOpened: () => InteractionSounds.button(context),
            key: const ValueKey('game-menu'),
            tooltip: 'Game menu',
            onSelected: _handleMenuAction,
            itemBuilder: (_) => gameMenuItems(
              newGame: _GameMenuAction.newGame,
              settings: _GameMenuAction.settings,
              help: _GameMenuAction.help,
              statistics: _GameMenuAction.statistics,
              dictionary: _GameMenuAction.dictionary,
              celebrations: _GameMenuAction.celebrations,
              extra: [
                gameMenuItem(
                  _GameMenuAction.copyResult,
                  'Copy result',
                  Icons.copy,
                  enabled: isComplete && game != null,
                ),
              ],
            ),
          ),
        ],
      ),
      body: GameBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : game == null
                    ? Center(
                        child: Text(
                          _message ?? 'No game is available.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxHeight < 650;
                          final extendedKeyboard =
                              _mode == LanguageMode.gurmukhi ||
                              (_mode == LanguageMode.romanizedPanjabi &&
                                  !_simpleRomanized);
                          final scale =
                              MediaQuery.textScalerOf(context).scale(14) / 14;
                          return SingleChildScrollView(
                            child: SizedBox(
                              height: math.max(
                                constraints.maxHeight,
                                (extendedKeyboard
                                        ? 700.0
                                        : scale > 1.5
                                        ? 500.0
                                        : 0.0) *
                                    scale,
                              ),
                              child: KeyboardListener(
                                focusNode: _gameFocusNode,
                                autofocus: true,
                                onKeyEvent: _handleHardwareKey,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: GamePanel(
                                        padding: const EdgeInsets.all(10),
                                        child: _Board(
                                          turns: game.turns,
                                          wordLength: game.wordLength,
                                          maximumAttempts: game.maximumAttempts,
                                          reducedMotion: widget.reducedMotion,
                                          pendingGuess: _pendingGuess,
                                          playing: !isComplete,
                                          onFocus: _focusInput,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: compact ? 6 : 12),
                                    if (isComplete) ...[
                                      Text(
                                        game.solution,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      Text(
                                        _solutionEntry!.displayDefinition,
                                        textAlign: TextAlign.center,
                                        maxLines: compact ? 1 : 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    if (!isComplete) ...[
                                      SizedBox(height: compact ? 4 : 8),
                                      GameKeyboard(
                                        largeKeys: true,
                                        simpleRomanized: _simpleRomanized,
                                        mode: _mode,
                                        additionalCharacters: _pool!
                                            .charactersFor(_mode),
                                        letterResults: keyboardLetterResults(
                                          game.turns,
                                        ),
                                        enabled: true,
                                        disabledCharacters:
                                            unavailableKeyboardCharacters(
                                              game.turns,
                                            ),
                                        compact: compact,
                                        onCharacter: _appendCharacter,
                                        onBackspace: _backspace,
                                        onEnter: _submit,
                                      ),
                                    ],
                                    if (isComplete)
                                      FilledButton(
                                        onPressed: () => _startGame(),
                                        child: const Text('New game'),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    required this.reducedMotion,
    required this.pendingGuess,
    required this.playing,
    required this.onFocus,
  });

  final List<GuessTurn> turns;
  final int wordLength;
  final int maximumAttempts;
  final bool reducedMotion;
  final String pendingGuess;
  final bool playing;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final pendingUnits = wordUnits(pendingGuess);
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
              child: Semantics(
                container: playing && row == turns.length,
                excludeSemantics: playing && row == turns.length,
                button: playing && row == turns.length,
                liveRegion: playing && row == turns.length,
                label: playing && row == turns.length
                    ? 'Current guess, attempt ${row + 1}, '
                          '${pendingGuess.isEmpty ? 'blank' : pendingGuess}'
                    : null,
                child: GestureDetector(
                  key: playing && row == turns.length
                      ? const ValueKey('guess-active-row')
                      : null,
                  onTap: playing && row == turns.length ? onFocus : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var column = 0; column < wordLength; column++) ...[
                        _Tile(
                          key: ValueKey('tile-$row-$column'),
                          size: size,
                          row: row,
                          column: column,
                          reducedMotion: reducedMotion,
                          letter: row < turns.length
                              ? turns[row].evaluation[column]
                              : null,
                          draftLetter:
                              playing &&
                                  row == turns.length &&
                                  column < pendingUnits.length
                              ? pendingUnits[column]
                              : null,
                          active:
                              playing &&
                              row == turns.length &&
                              column ==
                                  math.min(pendingUnits.length, wordLength - 1),
                        ),
                        if (column < wordLength - 1) SizedBox(width: spacing),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.size,
    required this.row,
    required this.column,
    required this.reducedMotion,
    this.letter,
    this.draftLetter,
    this.active = false,
    super.key,
  });

  final double size;
  final int row;
  final int column;
  final bool reducedMotion;
  final EvaluatedLetter? letter;
  final String? draftLetter;
  final bool active;

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
      LetterResult.absent => 'no unmatched copy in the word',
      null => 'blank',
    };
    final statusIcon = switch (letter?.result) {
      LetterResult.correct => Icons.check,
      LetterResult.present => Icons.swap_horiz,
      LetterResult.absent => Icons.close,
      null => null,
    };
    return Semantics(
      label: letter == null
          ? 'Attempt ${row + 1}, letter ${column + 1}, '
                '${draftLetter == null ? 'blank' : '$draftLetter, not submitted'}'
          : 'Attempt ${row + 1}, letter ${column + 1}, '
                '${letter!.grapheme}, $status',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedContainer(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: tokens.tileDecoration(
            color,
            border: active
                ? Theme.of(context).colorScheme.primary
                : letter == null
                ? tokens.tileBorder
                : color,
          ),
          child: statusIcon == null
              ? draftLetter == null
                    ? const SizedBox.shrink()
                    : Center(
                        child: Text(
                          draftLetter!,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      )
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          letter!.grapheme,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: tokens.foregroundFor(color),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 17,
                      child: Center(
                        child: Icon(
                          statusIcon,
                          size: 13,
                          color: tokens.foregroundFor(color),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
