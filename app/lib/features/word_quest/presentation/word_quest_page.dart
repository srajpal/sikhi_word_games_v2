import '../../../core/themes/game_heading.dart';
import '../../../core/audio/interaction_sounds.dart';
import '../../../core/statistics/game_statistics_dialog.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/widgets/victory_celebration.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../../../core/themes/quest_lantern.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/content/vocabulary_repository.dart';
import '../../../core/language/gurmukhi_romanization.dart';
import '../../../core/language/word_units.dart';
import '../../../core/language/hardware_input.dart';
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
  'ਆ',
  'ਇ',
  'ਈ',
  'ਉ',
  'ਊ',
  'ਏ',
  'ਐ',
  'ਓ',
  'ਔ',
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
    this.simpleRomanized = false,
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
  final bool simpleRomanized;

  @override
  State<WordQuestPage> createState() => _WordQuestPageState();
}

class _WordQuestPageState extends State<WordQuestPage> {
  final _keyboardFocusNode = FocusNode(debugLabel: 'Word Quest keyboard');
  final _selector = WordQuestWordSelector();
  final _random = Random();
  WordQuestVocabulary? _vocabulary;
  WordQuestVocabulary? _originalVocabulary;
  WordQuestWord? _word;
  WordQuestGame? _game;
  bool _simpleRomanized = false;
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
    final hardware = HardwareKeyboard.instance;
    if (hardware.isMetaPressed ||
        (hardware.isControlPressed != hardware.isAltPressed)) {
      return KeyEventResult.ignored;
    }
    final character = event.character;
    if (character == null || character.isEmpty) return KeyEventResult.ignored;
    final normalized = _mode == LanguageMode.romanizedPanjabi
        ? normalizeRomanizedInput(character)
        : character;
    // Hardware Gurmukhi input is one letter or vowel sign. Whole marked tiles
    // remain available through the on-screen keys and their accessible actions.
    final isLetter = HardwareInput.acceptsQuestCharacter(
      _mode.script,
      normalized,
    );
    if (!isLetter) {
      return KeyEventResult.ignored;
    }
    _guess(normalized);
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
    _originalVocabulary = vocabulary;
    _vocabulary = vocabulary;
    if (!widget.startFresh) {
      final restored = widget.sessionRepository.restore();
      if (restored != null) {
        _simpleRomanized = restored.simpleRomanized;
        _vocabulary = _simpleRomanized
            ? vocabulary.simpleRomanized
            : vocabulary;
        final word = _vocabulary!.wordForSpelling(
          mode: restored.mode,
          spelling: restored.game.solution,
        );
        if (word != null) {
          // Set the mode before building the bank so distractors come from
          // the restored language rather than the default.
          _mode = restored.mode;
          _wordSize = restored.wordSize;
          final bank = _buildLetterBank(restored.game);
          setState(() {
            _word = word;
            _game = restored.game;
            _letterBank = bank;
            _loading = false;
          });
          return;
        }
      }
      await _persist(widget.sessionRepository.clear());
      if (!mounted) return;
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
    _simpleRomanized = widget.simpleRomanized;
    _vocabulary = _simpleRomanized
        ? _originalVocabulary?.simpleRomanized
        : _originalVocabulary;
    if (!mounted) return;
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
    await _persist(
      widget.sessionRepository.save(
        simpleRomanized: _simpleRomanized,
        mode: _mode,
        wordSize: _wordSize,
        game: game,
      ),
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
    _persist(
      widget.sessionRepository.save(
        simpleRomanized: _simpleRomanized,
        mode: _mode,
        wordSize: _wordSize,
        game: game,
      ),
    );
  }

  List<String> _buildLetterBank(WordQuestGame game) {
    final answer = game.letterBankGraphemes.toSet();
    final choices = <String>{...answer};
    if (_mode != LanguageMode.english) {
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
    if (_mode == LanguageMode.english) {
      return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.characters.toList(growable: false);
    }
    if (_mode == LanguageMode.romanizedPanjabi) {
      return <String>{
        ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.characters,
        ...game.letterBankGraphemes,
        ..._vocabulary!.graphemes(mode: _mode),
      }.toList(growable: false);
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
    if (_mode == LanguageMode.romanizedPanjabi && _simpleRomanized) {
      letter = simplifyRomanizedPunjabi(letter);
    }
    final game = _game;
    if (game == null || game.isComplete) return;
    final result = game.guess(letter);
    if (result.result != WordQuestGuessResult.repeated) {
      InteractionSounds.letter(context);
    }
    final correct = result.result == WordQuestGuessResult.correct;
    final feedback = switch (result.result) {
      WordQuestGuessResult.correct => 'Nice find! That letter is in the word.',
      WordQuestGuessResult.incorrect =>
        'Try another letter. You can still find the word.',
      WordQuestGuessResult.repeated => 'You already tried that letter.',
      _ => '',
    };
    setState(() {});
    if (feedback.isNotEmpty) _showFeedback(feedback);
    if (game.isComplete) {
      if (game.status == WordQuestStatus.won) {
        VictoryCelebration.celebrate(context);
      }
      _persist(
        widget.sessionRepository.clear(
          after: widget.sessionRepository.statistics.record(
            mode: _mode.name,
            size: game.solutionGraphemes.length,
            won: game.status == WordQuestStatus.won,
            hintsUsed: game.hintsUsed,
          ),
        ),
      );
    } else {
      _persist(
        widget.sessionRepository.save(
          simpleRomanized: _simpleRomanized,
          mode: _mode,
          wordSize: _wordSize,
          game: game,
        ),
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
      _persist(
        widget.sessionRepository.clear(
          after: widget.sessionRepository.statistics.record(
            mode: _mode.name,
            size: game.solutionGraphemes.length,
            won: game.status == WordQuestStatus.won,
            hintsUsed: game.hintsUsed,
          ),
        ),
      );
    } else {
      _persist(
        widget.sessionRepository.save(
          simpleRomanized: _simpleRomanized,
          mode: _mode,
          wordSize: _wordSize,
          game: game,
        ),
      );
    }
    _haptic(correct: true);
  }

  void _showFeedback(String message) => showGameSnackBar(context, message);

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
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: [
                    for (final value in LanguageMode.values)
                      DropdownMenuItem(value: value, child: Text(value.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      InteractionSounds.button(context);
                      setSheetState(() => mode = value);
                    }
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
                  onSelectionChanged: (values) {
                    InteractionSounds.button(context);
                    setSheetState(() => size = values.first);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: InteractionSounds.buttonAction(
                    context,
                    () => Navigator.pop(context, (mode, size)),
                  ),
                  child: const Text('Apply and start a new word'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && result != null) {
      _mode = result.$1;
      _wordSize = result.$2;
      _startNewWord();
    }
  }

  void _showHelp() => showGameHelp(context, GameKind.wordQuest);

  Future<void> _persist(Future<void> write) async {
    try {
      await write;
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
    final word = _word;
    final game = _game;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: gameBackButton(context),
        flexibleSpace: const PaperTexture(),
        centerTitle: true,
        toolbarHeight: gameToolbarHeight(context),
        title: GameHeading(
          identity: GameIdentity.quest,
          compact: true,
          subtitle: GameLanguageHeader(
            mode: _mode,
            wordLength: _word?.graphemeLength,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onOpened: () => InteractionSounds.button(context),
            key: const ValueKey('word-quest-menu'),
            onSelected: (value) {
              InteractionSounds.button(context);
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
                        builder: (context, constraints) =>
                            SingleChildScrollView(
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
                                        game.isComplete ||
                                            game.hintsRemaining == 0
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
                                                          color:
                                                              scheme.onSurface,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              _MiniBadge(
                                                label: word.categoryHint,
                                              ),
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
                                      color: scheme.onSurface.withValues(
                                        alpha: .2,
                                      ),
                                      height: 1,
                                    ),
                                    const SizedBox(height: 10),
                                  ] else ...[
                                    QuestLantern(
                                      missesLeft: game.triesRemaining,
                                      maximumMisses: game.maximumTries,
                                      won: game.status == WordQuestStatus.won,
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
                          color: tokens.foregroundFor(tokens.correct),
                          gurmukhiFontSize: 24,
                          romanizationFontSize: 10,
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            game.revealedGraphemes[i]!,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: tokens.foregroundFor(tokens.correct),
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
        icon: Icons.light_mode_outlined,
        label: '$tries ${tries == 1 ? 'miss' : 'misses'} left',
        accent: Theme.of(context).colorScheme.tertiaryContainer,
        foreground: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
      if (hintsRemaining > 0)
        Semantics(
          button: true,
          enabled: onHint != null,
          label: 'Hint, $hintsRemaining left',
          excludeSemantics: true,
          onTap: InteractionSounds.buttonAction(context, onHint),
          child: Tooltip(
            message: 'Hint, $hintsRemaining left',
            child: InkWell(
              key: const ValueKey('word-quest-hint'),
              onTap: InteractionSounds.buttonAction(context, onHint),
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
    onPressed: InteractionSounds.buttonAction(context, onPressed),
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
