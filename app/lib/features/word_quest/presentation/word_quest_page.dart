import '../../../core/statistics/game_statistics_dialog.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/widgets/victory_celebration.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../../../core/themes/game_artwork.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/content/vocabulary_repository.dart';
import '../../../core/language/gurmukhi_romanization.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/themes/game_ui.dart';
import '../../../core/widgets/gurmukhi_key_label.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../../settings/data/app_settings_repository.dart';
import '../domain/word_quest_game.dart';
import '../domain/word_quest_vocabulary.dart';
import '../data/word_quest_session_repository.dart';

const _gurmukhiAlphabet = <String>[
  'ੳ',
  'ਅ',
  'ੲ',
  'ਸ',
  'ਹ',
  'ਕ',
  'ਖ',
  'ਗ',
  'ਘ',
  'ਙ',
  'ਚ',
  'ਛ',
  'ਜ',
  'ਝ',
  'ਞ',
  'ਟ',
  'ਠ',
  'ਡ',
  'ਢ',
  'ਣ',
  'ਤ',
  'ਥ',
  'ਦ',
  'ਧ',
  'ਨ',
  'ਪ',
  'ਫ',
  'ਬ',
  'ਭ',
  'ਮ',
  'ਯ',
  'ਰ',
  'ਲ',
  'ਵ',
  'ੜ',
  'ਸ਼',
  'ਖ਼',
  'ਗ਼',
  'ਜ਼',
  'ਫ਼',
];

class WordQuestPage extends StatefulWidget {
  const WordQuestPage({
    required this.vocabularyRepository,
    required this.hapticLevel,
    required this.reducedMotion,
    required this.sessionRepository,
    this.vocabularyFuture,
    this.initialMode,
    this.initialWordSize,
    this.startFresh = false,
    super.key,
  });

  final VocabularyRepository vocabularyRepository;
  final HapticFeedbackLevel hapticLevel;
  final bool reducedMotion;
  final WordQuestSessionRepository sessionRepository;
  final Future<WordQuestVocabulary>? vocabularyFuture;
  final LanguageMode? initialMode;
  final int? initialWordSize;
  final bool startFresh;

  @override
  State<WordQuestPage> createState() => _WordQuestPageState();
}

class _WordQuestPageState extends State<WordQuestPage> {
  final _keyboardFocusNode = FocusNode(debugLabel: 'Word Quest keyboard');
  final _selector = WordQuestWordSelector();
  final _random = Random();
  WordQuestVocabulary? _vocabulary;
  WordQuestWord? _word;
  WordQuestGame? _game;
  LanguageMode _mode = LanguageMode.english;
  int _wordSize = 4;
  List<String> _letterBank = const [];
  String _message = '';
  bool _loading = true;
  bool _showFullKeyboard = false;
  int _startRequest = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleHardwareKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _game?.isComplete != false) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final character = event.character;
    if (character == null || character.isEmpty) return KeyEventResult.ignored;
    if (_mode != LanguageMode.gurmukhi &&
        !RegExp(r'^[A-Za-z]$').hasMatch(character)) {
      return KeyEventResult.ignored;
    }
    _guess(character);
    return KeyEventResult.handled;
  }

  Future<void> _load() async {
    try {
      await _loadContents();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Unable to load the offline word list: $error';
      });
    }
  }

  Future<void> _loadContents() async {
    final vocabulary =
        await (widget.vocabularyFuture ??
            WordQuestVocabulary.load(widget.vocabularyRepository));
    if (!mounted) return;
    _vocabulary = vocabulary;
    if (!widget.startFresh) {
      final restored = widget.sessionRepository.restore();
      if (restored != null) {
        final word = vocabulary.wordForSpelling(
          mode: restored.mode,
          spelling: restored.game.solution,
        );
        if (word != null) {
          final bank = _buildLetterBank(restored.game);
          setState(() {
            _mode = restored.mode;
            _wordSize = restored.wordSize;
            _word = word;
            _game = restored.game;
            _letterBank = bank;
            _loading = false;
          });
          return;
        }
      }
      await widget.sessionRepository.clear();
    }
    _mode = widget.initialMode ?? _randomMode();
    _wordSize = widget.initialWordSize ?? _randomWordSize(_mode);
    await _startNewWord();
  }

  LanguageMode _randomMode() {
    final values = LanguageMode.values;
    return values[_random.nextInt(values.length)];
  }

  int _randomWordSize(LanguageMode mode) {
    final values = [
      for (final size in const [4, 5, 6])
        if (_vocabulary!
            .words(mode: mode)
            .any((word) => word.graphemeLength == size))
          size,
    ];
    return values.isEmpty ? 4 : values[_random.nextInt(values.length)];
  }

  Future<void> _startNewWord() async {
    VictoryCelebration.stop(context);
    final vocabulary = _vocabulary;
    if (vocabulary == null || !mounted) return;
    final request = ++_startRequest;
    final shouldYieldForLoading = !_loading;
    if (shouldYieldForLoading) {
      setState(() => _loading = true);
      // Let a player-initiated new-round loading state paint before a mode's
      // first vocabulary index and Gurmukhi grapheme bank are derived.
      await Future<void>.delayed(Duration.zero);
    }
    if (!mounted || request != _startRequest) return;
    var candidates = vocabulary
        .words(mode: _mode)
        .where((word) => word.graphemeLength == _wordSize)
        .toList();
    if (candidates.isEmpty) candidates = vocabulary.words(mode: _mode);
    if (candidates.isEmpty) {
      setState(() {
        _loading = false;
        _word = null;
        _game = null;
        _message = 'No words are available for these settings yet.';
      });
      return;
    }
    final word = _selector.select(candidates);
    final game = WordQuestGame(solution: word.spelling);
    final bank = _buildLetterBank(game);
    setState(() {
      _word = word;
      _game = game;
      _letterBank = bank;
      _showFullKeyboard = false;
      _message = '';
      _loading = false;
    });
    await widget.sessionRepository.save(
      mode: _mode,
      wordSize: _wordSize,
      game: game,
    );
  }

  void _retryWord() {
    final word = _word;
    if (word == null) return;
    final game = WordQuestGame(solution: word.spelling);
    setState(() {
      _game = game;
      _letterBank = _buildLetterBank(game);
      _showFullKeyboard = false;
      _message = '';
    });
    widget.sessionRepository.save(mode: _mode, wordSize: _wordSize, game: game);
  }

  List<String> _buildLetterBank(WordQuestGame game) {
    final answer = game.letterBankGraphemes.toSet();
    final choices = <String>{...answer};
    if (_mode == LanguageMode.gurmukhi) {
      final distractors =
          _vocabulary!
              .graphemes(mode: _mode)
              .where((letter) => !answer.contains(letter))
              .toSet()
              .toList()
            ..shuffle(_random);
      choices.addAll(distractors.take(6));
    } else {
      final distractors =
          'ETAOINSHRDLUCMFPGWYBVKXJQZ'.characters
              .where((letter) => !answer.contains(letter))
              .toList()
            ..shuffle(_random);
      choices.addAll(distractors.take(6));
    }
    final result = choices.toList()..shuffle(_random);
    return result;
  }

  List<String> _fullLetterBank(WordQuestGame game) {
    if (_mode != LanguageMode.gurmukhi) {
      return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.characters.toList(growable: false);
    }
    return <String>{
      ...game.letterBankGraphemes,
      ..._gurmukhiAlphabet,
    }.toList(growable: false);
  }

  Future<void> _haptic({required bool correct, bool complete = false}) async {
    switch (widget.hapticLevel) {
      case HapticFeedbackLevel.off:
        return;
      case HapticFeedbackLevel.light:
        await HapticFeedback.selectionClick();
      case HapticFeedbackLevel.medium:
        if (correct || complete) {
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.selectionClick();
        }
      case HapticFeedbackLevel.strong:
        if (complete) {
          await HapticFeedback.heavyImpact();
        } else if (correct) {
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.vibrate();
        }
    }
  }

  void _guess(String letter) {
    final game = _game;
    if (game == null || game.isComplete) return;
    final result = game.guess(letter);
    final correct = result.result == WordQuestGuessResult.correct;
    final feedback = switch (result.result) {
      WordQuestGuessResult.correct => 'Nice find! That letter is in the word.',
      WordQuestGuessResult.incorrect =>
        'Try another letter. Your garden progress is safe.',
      WordQuestGuessResult.repeated => 'You already tried that letter.',
      _ => '',
    };
    setState(() {});
    if (feedback.isNotEmpty) _showFeedback(feedback);
    if (game.isComplete) {
      if (game.status == WordQuestStatus.won) {
        VictoryCelebration.celebrate(context);
      }
      widget.sessionRepository.statistics.record(
        mode: _mode.name,
        size: game.solutionGraphemes.length,
        won: game.status == WordQuestStatus.won,
        hintsUsed: game.hintsUsed,
      );
      widget.sessionRepository.clear();
    } else {
      widget.sessionRepository.save(
        mode: _mode,
        wordSize: _wordSize,
        game: game,
      );
    }
    _haptic(correct: correct, complete: game.isComplete);
  }

  void _useHint() {
    final game = _game;
    if (game == null || game.isComplete || game.hintsRemaining == 0) return;
    final hint = game.useHint();
    if (hint.result != WordQuestHintResult.revealed) return;
    setState(() {});
    _showFeedback('Hint used. A letter is now showing.');
    if (game.isComplete) {
      if (game.status == WordQuestStatus.won) {
        VictoryCelebration.celebrate(context);
      }
      widget.sessionRepository.statistics.record(
        mode: _mode.name,
        size: game.solutionGraphemes.length,
        won: game.status == WordQuestStatus.won,
        hintsUsed: game.hintsUsed,
      );
      widget.sessionRepository.clear();
    } else {
      widget.sessionRepository.save(
        mode: _mode,
        wordSize: _wordSize,
        game: game,
      );
    }
    _haptic(correct: true);
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    setState(() => _message = message);
  }

  Future<void> _showSettings() async {
    var mode = _mode;
    var size = _wordSize;
    final result = await showModalBottomSheet<(LanguageMode, int)>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Game settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LanguageMode>(
                  initialValue: mode,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: [
                    for (final value in LanguageMode.values)
                      DropdownMenuItem(value: value, child: Text(value.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => mode = value);
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 4, label: Text('4 letters')),
                    ButtonSegment(value: 5, label: Text('5')),
                    ButtonSegment(value: 6, label: Text('6')),
                  ],
                  selected: {size},
                  onSelectionChanged: (values) =>
                      setSheetState(() => size = values.first),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context, (mode, size)),
                  child: const Text('Apply and start a new word'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      _mode = result.$1;
      _wordSize = result.$2;
      _startNewWord();
    }
  }

  void _showHelp() => showGameHelp(context, GameKind.wordQuest);

  @override
  Widget build(BuildContext context) {
    final word = _word;
    final game = _game;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chardi Kala',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                  fontSize: 18,
                ),
              ),
              Text(
                'Word Quest',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            key: const ValueKey('word-quest-menu'),
            onSelected: (value) {
              if (value == 'new') _startNewWord();
              if (value == 'settings') _showSettings();
              if (value == 'help') _showHelp();
              if (value == 'celebrations') {
                VictoryCelebration.showSettings(context);
              }
              if (value == 'statistics') {
                showGameStatistics(
                  context,
                  title: 'Word Quest',
                  repository: widget.sessionRepository.statistics,
                  mode: _mode.name,
                  size: _game?.solutionGraphemes.length ?? _wordSize,
                  modeLabel: _mode.label,
                  isQuest: true,
                );
              }
              if (value == 'dictionary') context.push('/dictionary');
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'new', child: Text('New word')),
              PopupMenuItem(value: 'settings', child: Text('Game settings')),
              PopupMenuItem(value: 'statistics', child: Text('Statistics')),
              PopupMenuItem(
                value: 'celebrations',
                child: Text('Celebration settings'),
              ),
              PopupMenuItem(value: 'help', child: Text('How to play')),
              PopupMenuItem(
                value: 'dictionary',
                child: ListTile(
                  leading: Icon(Icons.menu_book_outlined),
                  title: Text('Dictionary'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const _QuestBackdrop(
              child: Center(child: CircularProgressIndicator()),
            )
          : word == null || game == null
          ? _QuestBackdrop(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _message,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ),
              ),
            )
          : Focus(
              autofocus: true,
              focusNode: _keyboardFocusNode,
              onKeyEvent: _handleHardwareKey,
              child: _QuestBackdrop(
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          padding: EdgeInsets.all(
                            constraints.maxWidth < 360 ? 12 : 16,
                          ),
                          child: Column(
                            children: [
                              _QuestStatusBar(
                                language: _mode.label,
                                letters: word.graphemeLength,
                                tries: game.triesRemaining,
                                hintsRemaining: game.hintsRemaining,
                                onHint:
                                    game.isComplete || game.hintsRemaining == 0
                                    ? null
                                    : _useHint,
                                showFullKeyboard: _showFullKeyboard,
                                onToggleKeyboard: game.isComplete
                                    ? null
                                    : () => setState(
                                        () => _showFullKeyboard =
                                            !_showFullKeyboard,
                                      ),
                              ),
                              const SizedBox(height: 14),
                              _RaisedPanel(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lightbulb_outline,
                                                color: scheme.secondary,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 7),
                                              Text(
                                                'Your clue',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color: scheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          _MiniBadge(label: word.categoryHint),
                                        ],
                                      ),
                                      const SizedBox(height: 9),
                                      _DefinitionPreview(
                                        definition: word.definitionHint,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: scheme.onSurface,
                                              fontWeight: FontWeight.w700,
                                              height: 1.25,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _WordTiles(
                                game: game,
                                showRomanization:
                                    _mode == LanguageMode.gurmukhi,
                              ),
                              const SizedBox(height: 16),
                              if (_showFullKeyboard) ...[
                                const SizedBox(height: 4),
                                Divider(
                                  color: scheme.onSurface.withValues(alpha: .2),
                                  height: 1,
                                ),
                                const SizedBox(height: 10),
                              ] else ...[
                                _GardenPath(
                                  game: game,
                                  reducedMotion: widget.reducedMotion,
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (game.isComplete)
                                _ResultCard(
                                  word: word,
                                  game: game,
                                  showRomanization:
                                      _mode == LanguageMode.gurmukhi,
                                  onNewWord: _startNewWord,
                                  onTryAgain:
                                      game.status == WordQuestStatus.lost
                                      ? _retryWord
                                      : null,
                                )
                              else ...[
                                _LetterBank(
                                  letters: _showFullKeyboard
                                      ? _fullLetterBank(game)
                                      : _letterBank,
                                  game: game,
                                  onPressed: _guess,
                                  showRomanization:
                                      _mode == LanguageMode.gurmukhi,
                                ),
                                const SizedBox(height: 12),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _message.isEmpty
                                        ? 'Choose a letter to grow your garden.'
                                        : _message,
                                    key: const ValueKey('word-quest-feedback'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _WordTiles extends StatelessWidget {
  const _WordTiles({required this.game, required this.showRomanization});
  final WordQuestGame game;
  final bool showRomanization;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    final scheme = Theme.of(context).colorScheme;
    final hiddenColors = tokens.panelGradient.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 7.0;
        final count = game.revealedGraphemes.length;
        final available = constraints.maxWidth - spacing * (count - 1);
        final tileWidth = (available / count).clamp(40.0, 55.0);
        final tileHeight = showRomanization ? 66.0 : 61.0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: spacing),
              Semantics(
                label: game.revealedGraphemes[i] == null
                    ? 'Letter ${i + 1}, hidden'
                    : 'Letter ${i + 1}, ${game.revealedGraphemes[i]}, '
                          '${showRomanization ? romanizeGurmukhiGrapheme(game.revealedGraphemes[i]!) : ''} revealed',
                child: Container(
                  key: ValueKey('word-quest-answer-tile-$i'),
                  width: tileWidth,
                  height: tileHeight,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: game.revealedGraphemes[i] == null
                          ? hiddenColors
                          : [tokens.correct, tokens.correct],
                    ),
                    border: Border.all(
                      color: tokens.tileBorder,
                      width: tokens.tileBorderWidth,
                    ),
                    borderRadius: tokens.tileRadius,
                    boxShadow: tokens.tileShadow,
                  ),
                  child: game.revealedGraphemes[i] == null
                      ? Text(
                          '?',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                        )
                      : showRomanization
                      ? GurmukhiKeyLabel(
                          grapheme: game.revealedGraphemes[i]!,
                          color: Colors.white,
                          gurmukhiFontSize: 24,
                          romanizationFontSize: 10,
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            game.revealedGraphemes[i]!,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GardenPath extends StatelessWidget {
  const _GardenPath({required this.game, required this.reducedMotion});
  final WordQuestGame game;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    final scene = GameSceneColors(Theme.of(context));
    final distinct = game.solutionGraphemes.toSet();
    final found = distinct.where(game.isGuessed).length;
    final progress = distinct.isEmpty
        ? 0
        : (found / distinct.length * 8).ceil();
    return Semantics(
      label: '$progress of 8 garden blooms growing',
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scene.sky, scene.horizon],
          ),
          borderRadius: tokens.panelRadius,
          border: Border.all(color: tokens.tileBorder.withValues(alpha: .4)),
          boxShadow: tokens.tileShadow,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GardenPainter(
                  progress: progress,
                  bloomColor: scene.sun,
                  scene: scene,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 26),
                  for (var i = 0; i < 8; i++)
                    AnimatedContainer(
                      duration: reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      width: 20,
                      height: 13,
                      decoration: BoxDecoration(
                        gradient: i < progress
                            ? LinearGradient(colors: [scene.sun, scene.leaf])
                            : LinearGradient(
                                colors: [scene.horizon, scene.hill],
                              ),
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(22, 15),
                        ),
                        border: Border.all(color: Colors.white70),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 26),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenPainter extends CustomPainter {
  const _GardenPainter({
    required this.progress,
    required this.bloomColor,
    required this.scene,
  });

  final GameSceneColors scene;

  final int progress;
  final Color bloomColor;

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = scene.sun;
    canvas.drawCircle(const Offset(24, 22), 10, sun);
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        const Offset(24, 22),
        Offset(24 + cos(angle) * 16, 22 + sin(angle) * 16),
        Paint()
          ..color = scene.sun.withValues(alpha: .75)
          ..strokeWidth = 2,
      );
    }

    final backHill = Paint()..color = scene.hill.withValues(alpha: .8);
    final backPath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .30,
        size.width * .62,
        size.height,
      )
      ..close();
    canvas.drawPath(backPath, backHill);

    final frontHill = Path()
      ..moveTo(size.width * .38, size.height)
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .40,
        size.width,
        size.height * .68,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      frontHill,
      Paint()..color = scene.leaf.withValues(alpha: .72),
    );

    final stemPaint = Paint()
      ..color = scene.stem
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < progress; i++) {
      final x = 58 + i * ((size.width - 116) / 7);
      final y = size.height - 13 - (i.isEven ? 2 : 8);
      canvas.drawLine(Offset(x, y), Offset(x, y - 10), stemPaint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x - 3, y - 7), width: 7, height: 4),
        Paint()..color = scene.leaf,
      );
      canvas.drawCircle(Offset(x, y - 13), 4, Paint()..color = bloomColor);
      canvas.drawCircle(Offset(x, y - 13), 1.5, Paint()..color = scene.sun);
    }

    final treeX = size.width - 23;
    canvas.drawRect(
      Rect.fromLTWH(treeX - 2, size.height - 35, 4, 24),
      Paint()..color = scene.stem,
    );
    canvas.drawCircle(
      Offset(treeX, size.height - 38),
      progress == 8 ? 15 : 12,
      Paint()..color = progress == 8 ? bloomColor : scene.leaf,
    );
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.bloomColor != bloomColor ||
      oldDelegate.scene.sky != scene.sky;
}

class _LetterBank extends StatelessWidget {
  const _LetterBank({
    required this.letters,
    required this.game,
    required this.onPressed,
    required this.showRomanization,
  });
  final List<String> letters;
  final WordQuestGame game;
  final ValueChanged<String> onPressed;
  final bool showRomanization;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 9,
    runSpacing: 11,
    children: [
      for (final letter in letters)
        _QuestKey(
          key: ValueKey('word-quest-key-$letter'),
          letter: letter,
          enabled: !game.isGuessed(letter),
          onPressed: () => onPressed(letter),
          showRomanization: showRomanization,
        ),
    ],
  );
}

class _QuestKey extends StatelessWidget {
  const _QuestKey({
    required this.letter,
    required this.enabled,
    required this.onPressed,
    required this.showRomanization,
    super.key,
  });
  final String letter;
  final bool enabled;
  final VoidCallback onPressed;
  final bool showRomanization;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    final scheme = Theme.of(context).colorScheme;
    final keyColors = tokens.panelGradient.colors;
    return Semantics(
      button: true,
      enabled: enabled,
      label: showRomanization
          ? 'Gurmukhi letter $letter, ${romanizeGurmukhiGrapheme(letter)}'
          : 'Letter $letter',
      excludeSemantics: true,
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 120),
        width: 49,
        height: 48,
        margin: EdgeInsets.only(bottom: enabled ? 6 : 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? keyColors
                : [
                    scheme.surfaceContainerHighest,
                    scheme.surfaceContainerHighest,
                  ],
          ),
          borderRadius: tokens.controlRadius,
          border: Border.all(
            color: enabled ? tokens.tileBorder : scheme.outlineVariant,
            width: 2,
          ),
          boxShadow: enabled ? tokens.tileShadow : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: tokens.controlRadius,
            focusColor: scheme.primary.withValues(alpha: .3),
            child: Center(
              child: showRomanization
                  ? GurmukhiKeyLabel(
                      grapheme: letter,
                      color: enabled
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    )
                  : Text(
                      letter,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: enabled
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.word,
    required this.game,
    required this.showRomanization,
    required this.onNewWord,
    required this.onTryAgain,
  });
  final WordQuestWord word;
  final WordQuestGame game;
  final bool showRomanization;
  final VoidCallback onNewWord;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) => _RaisedPanel(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            game.status == WordQuestStatus.won
                ? 'You found the word!'
                : 'The word is ready to discover',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word.spelling,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (showRomanization &&
              word.romanizedSpelling?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Semantics(
              label: 'Romanized spelling ${word.romanizedSpelling}',
              child: Text(
                word.romanizedSpelling!.trim(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          _DefinitionPreview(
            definition: word.definitionHint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (onTryAgain != null) ...[
            _QuestActionButton(
              onPressed: onTryAgain!,
              icon: const Icon(Icons.replay),
              label: 'Try this word again',
            ),
            const SizedBox(height: 10),
          ],
          _QuestActionButton(
            onPressed: onNewWord,
            icon: const Icon(Icons.refresh),
            label: 'New word',
          ),
        ],
      ),
    ),
  );
}

class _QuestStatusBar extends StatelessWidget {
  const _QuestStatusBar({
    required this.language,
    required this.letters,
    required this.tries,
    required this.hintsRemaining,
    required this.onHint,
    required this.showFullKeyboard,
    required this.onToggleKeyboard,
  });
  final String language;
  final int letters;
  final int tries;
  final int hintsRemaining;
  final VoidCallback? onHint;
  final bool showFullKeyboard;
  final VoidCallback? onToggleKeyboard;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      _StatusPill(
        icon: Icons.translate_rounded,
        label: '$language · $letters letters',
      ),
      _StatusPill(
        icon: Icons.favorite_rounded,
        label: '$tries ${tries == 1 ? 'try' : 'tries'}',
        accent: Theme.of(context).colorScheme.tertiaryContainer,
        foreground: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
      if (hintsRemaining > 0)
        Semantics(
          button: true,
          enabled: onHint != null,
          label: 'Hint, $hintsRemaining left',
          excludeSemantics: true,
          onTap: onHint,
          child: Tooltip(
            message: 'Hint, $hintsRemaining left',
            child: InkWell(
              key: const ValueKey('word-quest-hint'),
              onTap: onHint,
              borderRadius: Theme.of(context)
                  .extension<GameThemeTokens>()!
                  .controlRadius,
              child: _StatusPill(
                icon: Icons.lightbulb_outline,
                label:
                    '$hintsRemaining ${hintsRemaining == 1 ? 'hint' : 'hints'}',
                accent: Theme.of(context).colorScheme.secondaryContainer,
                foreground: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      _StatusIconButton(
        key: const ValueKey('word-quest-keyboard-toggle'),
        icon: showFullKeyboard
            ? Icons.keyboard_hide_outlined
            : Icons.keyboard_alt_outlined,
        tooltip: showFullKeyboard ? 'Show simple letters' : 'Show all letters',
        onPressed: onToggleKeyboard,
      ),
    ],
  );
}

class _StatusIconButton extends StatelessWidget {
  const _StatusIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: 20),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    this.accent,
    this.foreground,
  });
  final IconData icon;
  final String label;
  final Color? accent;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: accent ?? scheme.surfaceContainerHigh,
        borderRadius: Theme.of(context)
            .extension<GameThemeTokens>()!
            .controlRadius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground ?? scheme.onSurface, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground ?? scheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefinitionPreview extends StatelessWidget {
  const _DefinitionPreview({
    required this.definition,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  final String definition;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Text(
    definition,
    key: const ValueKey('word-quest-full-definition'),
    textAlign: textAlign,
    style: style,
    softWrap: true,
  );
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: Theme.of(context)
          .extension<GameThemeTokens>()!
          .controlRadius,
      border: Border.all(color: Theme.of(context).colorScheme.primary),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    ),
  );
}

class _RaisedPanel extends StatelessWidget {
  const _RaisedPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      GamePanel(padding: EdgeInsets.zero, child: child);
}

class _QuestActionButton extends StatelessWidget {
  const _QuestActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) =>
      GameGradientButton(onPressed: onPressed, icon: icon, label: label);
}

class _QuestBackdrop extends StatelessWidget {
  const _QuestBackdrop({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => GameBackdrop(child: child);
}
