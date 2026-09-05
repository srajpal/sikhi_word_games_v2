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
          _mode = restored.mode;
          _wordSize = restored.wordSize;
          _word = word;
          _game = restored.game;
          _letterBank = _buildLetterBank(restored.game);
          _loading = false;
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
        'Try another letter — your garden progress is safe.',
      WordQuestGuessResult.repeated => 'You already tried that letter.',
      _ => '',
    };
    setState(() {});
    if (feedback.isNotEmpty) _showFeedback(feedback);
    if (game.isComplete) {
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
    _showFeedback('Hint used — a letter is now showing.');
    if (game.isComplete) {
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
    showGameSnackBar(context, message);
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

  void _showHelp() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How to play'),
      content: const Text(
        'Choose letters to uncover the hidden word. Correct letters help your word garden grow. Shorter words have fewer hearts. Four-letter words have no hints, five-letter words have one, and six-letter words have two. If the word stays hidden, we reveal it so you can learn it.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final word = _word;
    final game = _game;
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    final scheme = Theme.of(context).colorScheme;
    final topColors = tokens.sikhiStyle
        ? const [_QuestPalette.navy, _QuestPalette.indigo]
        : [scheme.primary, scheme.secondary];
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: topColors),
            border: const Border(
              bottom: BorderSide(color: _QuestPalette.saffron, width: 3),
            ),
          ),
        ),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CHARDI KALA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                fontSize: 18,
              ),
            ),
            Text(
              'WORD QUEST',
              style: TextStyle(
                color: _QuestPalette.sunGold,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            key: const ValueKey('word-quest-menu'),
            onSelected: (value) {
              if (value == 'new') _startNewWord();
              if (value == 'settings') _showSettings();
              if (value == 'help') _showHelp();
              if (value == 'dictionary') context.push('/dictionary');
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'new', child: Text('New word')),
              PopupMenuItem(value: 'settings', child: Text('Game settings')),
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
              child: Center(
                child: CircularProgressIndicator(color: _QuestPalette.sunGold),
              ),
            )
          : word == null || game == null
          ? _QuestBackdrop(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          : _QuestBackdrop(
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
                              color: tokens.sikhiStyle
                                  ? _QuestPalette.parchment
                                  : scheme.surface,
                              shadowColor: tokens.sikhiStyle
                                  ? _QuestPalette.deepGold
                                  : scheme.primary.withValues(alpha: .45),
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
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome,
                                          color: _QuestPalette.saffron,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            'YOUR CLUE',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: scheme.onSurface,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.4,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
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
                              showRomanization: _mode == LanguageMode.gurmukhi,
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
    final hiddenColors = tokens.sikhiStyle
        ? const [Colors.white, _QuestPalette.parchment]
        : [scheme.surfaceContainerLowest, scheme.surfaceContainerHigh];
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
                          : [
                              tokens.correct.withValues(alpha: .75),
                              tokens.correct,
                            ],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: game.revealedGraphemes[i] == null
                            ? scheme.primary.withValues(alpha: .6)
                            : tokens.correct.withValues(alpha: .7),
                        offset: const Offset(0, 7),
                      ),
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 9),
                      ),
                    ],
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8BE3F0), _QuestPalette.turquoise],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white70, width: 2),
          boxShadow: const [
            BoxShadow(color: _QuestPalette.deepTeal, offset: Offset(0, 7)),
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GardenPainter(
                  progress: progress,
                  bloomColor: tokens.correct,
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
                            ? const LinearGradient(
                                colors: [
                                  _QuestPalette.sunGold,
                                  _QuestPalette.saffron,
                                ],
                              )
                            : const LinearGradient(
                                colors: [Colors.white70, Color(0xFFB5D9D2)],
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
  const _GardenPainter({required this.progress, required this.bloomColor});

  final int progress;
  final Color bloomColor;

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = _QuestPalette.sunGold;
    canvas.drawCircle(const Offset(24, 22), 10, sun);
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        const Offset(24, 22),
        Offset(24 + cos(angle) * 16, 22 + sin(angle) * 16),
        Paint()
          ..color = _QuestPalette.sunGold.withValues(alpha: .75)
          ..strokeWidth = 2,
      );
    }

    final backHill = Paint()
      ..color = const Color(0xFF56C88B).withValues(alpha: .8);
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
      Paint()..color = _QuestPalette.emerald.withValues(alpha: .72),
    );

    final stemPaint = Paint()
      ..color = const Color(0xFF176D43)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < progress; i++) {
      final x = 58 + i * ((size.width - 116) / 7);
      final y = size.height - 13 - (i.isEven ? 2 : 8);
      canvas.drawLine(Offset(x, y), Offset(x, y - 10), stemPaint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x - 3, y - 7), width: 7, height: 4),
        Paint()..color = const Color(0xFF76D76B),
      );
      canvas.drawCircle(Offset(x, y - 13), 4, Paint()..color = bloomColor);
      canvas.drawCircle(
        Offset(x, y - 13),
        1.5,
        Paint()..color = _QuestPalette.sunGold,
      );
    }

    final treeX = size.width - 23;
    canvas.drawRect(
      Rect.fromLTWH(treeX - 2, size.height - 35, 4, 24),
      Paint()..color = const Color(0xFF8A5A32),
    );
    canvas.drawCircle(
      Offset(treeX, size.height - 38),
      progress == 8 ? 15 : 12,
      Paint()..color = progress == 8 ? bloomColor : _QuestPalette.emerald,
    );
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.bloomColor != bloomColor;
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
    final keyColors = tokens.sikhiStyle
        ? const [Colors.white, _QuestPalette.keyCream]
        : [scheme.surfaceContainerLowest, scheme.primaryContainer];
    return Semantics(
      button: true,
      enabled: enabled,
      label: showRomanization
          ? 'Gurmukhi letter $letter, ${romanizeGurmukhiGrapheme(letter)}'
          : 'Letter $letter',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
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
                  : const [Color(0xFF7181A4), Color(0xFF465477)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? Colors.white : Colors.white24,
              width: 2,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: .75),
                      offset: const Offset(0, 6),
                    ),
                    const BoxShadow(
                      color: Colors.black38,
                      blurRadius: 7,
                      offset: Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: showRomanization
              ? GurmukhiKeyLabel(
                  grapheme: letter,
                  color: enabled ? scheme.onSurface : Colors.white70,
                )
              : Text(
                  letter,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: enabled ? scheme.onSurface : Colors.white70,
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
  });
  final WordQuestWord word;
  final WordQuestGame game;
  final bool showRomanization;
  final VoidCallback onNewWord;

  @override
  Widget build(BuildContext context) => _RaisedPanel(
    color: Theme.of(context).colorScheme.surface,
    shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: .5),
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
          _QuestActionButton(
            onPressed: onNewWord,
            icon: const Icon(Icons.refresh),
            label: 'NEW WORD',
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _StatusPill(
          icon: Icons.translate_rounded,
          label: '$language · $letters LETTERS',
        ),
      ),
      const SizedBox(width: 7),
      _StatusPill(
        icon: Icons.favorite_rounded,
        label: '$tries',
        accent: _QuestPalette.magenta,
      ),
      if (hintsRemaining > 0) ...[
        const SizedBox(width: 7),
        Semantics(
          button: true,
          enabled: onHint != null,
          label: 'Hint, $hintsRemaining left',
          child: Tooltip(
            message: 'Hint, $hintsRemaining left',
            child: InkWell(
              key: const ValueKey('word-quest-hint'),
              onTap: onHint,
              borderRadius: BorderRadius.circular(22),
              child: _StatusPill(
                icon: Icons.lightbulb_outline,
                label: '$hintsRemaining',
                accent: onHint == null
                    ? Theme.of(context).disabledColor
                    : _QuestPalette.saffron,
              ),
            ),
          ),
        ),
      ],
      const SizedBox(width: 7),
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: tooltip,
    child: Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 41,
          height: 41,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _QuestPalette.navy.withValues(alpha: .96),
                _QuestPalette.indigo.withValues(alpha: .92),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white38),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label, this.accent});
  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (accent ?? scheme.primary).withValues(alpha: .96),
            (accent ?? scheme.secondary).withValues(alpha: .92),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white38),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: .5,
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: definition, style: style),
        maxLines: 1,
        textDirection: Directionality.of(context),
      )..layout(maxWidth: constraints.maxWidth);
      final isLong = painter.didExceedMaxLines;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              definition,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: style,
            ),
          ),
          if (isLong) ...[
            const SizedBox(width: 2),
            Tooltip(
              message: 'Show full definition',
              child: IconButton(
                key: const ValueKey('word-quest-definition-more'),
                onPressed: () => _showFullDefinition(context),
                icon: const Icon(Icons.info_outline),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      );
    },
  );

  void _showFullDefinition(BuildContext context) {
    showGameSnackBar(context, definition);
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 118),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.primary),
    ),
    child: Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w800,
        fontSize: 9,
      ),
    ),
  );
}

class _RaisedPanel extends StatelessWidget {
  const _RaisedPanel({
    required this.child,
    required this.color,
    required this.shadowColor,
  });
  final Widget child;
  final Color color;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(color: shadowColor, offset: const Offset(0, 7)),
        const BoxShadow(
          color: Colors.black26,
          blurRadius: 12,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: onPressed == null
          ? null
          : const [
              BoxShadow(color: _QuestPalette.deepMagenta, offset: Offset(0, 6)),
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 8),
              ),
            ],
    ),
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _QuestPalette.magenta,
        foregroundColor: Colors.white,
        minimumSize: const Size(168, 46),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
  );
}

class _QuestBackdrop extends StatelessWidget {
  const _QuestBackdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    return GameBackdrop(
      child: tokens.sikhiStyle
          ? CustomPaint(painter: _SaffronGlowPainter(), child: child)
          : child,
    );
  }
}

class _SaffronGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [_QuestPalette.saffron, Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, 30),
              radius: size.width * .72,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract final class _QuestPalette {
  static const navy = Color(0xFF102B56);
  static const indigo = Color(0xFF263D91);
  static const saffron = Color(0xFFFF8A1F);
  static const sunGold = Color(0xFFFFD54A);
  static const deepGold = Color(0xFFC66612);
  static const parchment = Color(0xFFFFF2CF);
  static const keyCream = Color(0xFFFFDDB4);
  static const turquoise = Color(0xFF1BB9B2);
  static const deepTeal = Color(0xFF116A7A);
  static const emerald = Color(0xFF169B62);
  static const magenta = Color(0xFFE94191);
  static const deepMagenta = Color(0xFF9E1E63);
}
