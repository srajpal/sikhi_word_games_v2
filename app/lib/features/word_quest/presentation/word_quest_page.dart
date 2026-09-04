import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/content/vocabulary_repository.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/themes/game_ui.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../../settings/data/app_settings_repository.dart';
import '../domain/word_quest_game.dart';
import '../domain/word_quest_vocabulary.dart';

class WordQuestPage extends StatefulWidget {
  const WordQuestPage({
    required this.vocabularyRepository,
    required this.hapticLevel,
    required this.reducedMotion,
    super.key,
  });

  final VocabularyRepository vocabularyRepository;
  final HapticFeedbackLevel hapticLevel;
  final bool reducedMotion;

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
  String _message = 'Choose a letter to begin your quest.';
  bool _loading = true;
  bool _showAllLatin = false;
  int _hintsRemaining = 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vocabulary = await WordQuestVocabulary.load(
      widget.vocabularyRepository,
    );
    if (!mounted) return;
    _vocabulary = vocabulary;
    _startNewWord();
  }

  void _startNewWord() {
    final vocabulary = _vocabulary;
    if (vocabulary == null) return;
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
    final game = WordQuestGame(solution: word.spelling, maximumTries: 8);
    final bank = _buildLetterBank(game, candidates);
    setState(() {
      _word = word;
      _game = game;
      _letterBank = bank;
      _showAllLatin = false;
      _hintsRemaining = 2;
      _message = 'Choose a letter to begin your quest.';
      _loading = false;
    });
  }

  List<String> _buildLetterBank(WordQuestGame game, List<WordQuestWord> pool) {
    final answer = game.letterBankGraphemes.toSet();
    final choices = <String>{...answer};
    if (_mode == LanguageMode.gurmukhi) {
      final distractors =
          pool
              .expand((word) => word.spelling.characters)
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
    setState(() {
      _message = switch (result.result) {
        WordQuestGuessResult.correct =>
          'Nice find! That letter is in the word.',
        WordQuestGuessResult.incorrect =>
          'Try another letter — your garden progress is safe.',
        WordQuestGuessResult.repeated => 'You already tried that letter.',
        _ => _message,
      };
    });
    _haptic(correct: correct, complete: game.isComplete);
  }

  void _useHint() {
    final game = _game;
    if (game == null || game.isComplete || _hintsRemaining == 0) return;
    final hint = game.useHint();
    if (hint.result != WordQuestHintResult.revealed) return;
    setState(() {
      _hintsRemaining--;
      _message = 'Hint used — a letter is now showing.';
    });
    _haptic(correct: true);
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
        'Choose letters to uncover the hidden word. Correct letters help your word garden grow. You have eight tries and two friendly hints. If the word stays hidden, we reveal it so you can learn it.',
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
            onSelected: (value) {
              if (value == 'new') _startNewWord();
              if (value == 'settings') _showSettings();
              if (value == 'help') _showHelp();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'new', child: Text('New word')),
              PopupMenuItem(value: 'settings', child: Text('Game settings')),
              PopupMenuItem(value: 'help', child: Text('How to play')),
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
                                        Text(
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
                                        const Spacer(),
                                        _MiniBadge(label: word.categoryHint),
                                      ],
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      word.definitionHint,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
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
                            _WordTiles(game: game),
                            const SizedBox(height: 16),
                            _GardenPath(
                              game: game,
                              reducedMotion: widget.reducedMotion,
                            ),
                            const SizedBox(height: 10),
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: _QuestPalette.navy.withValues(
                                    alpha: .72,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  _message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (game.isComplete)
                              _ResultCard(
                                word: word,
                                game: game,
                                onNewWord: _startNewWord,
                              )
                            else ...[
                              _QuestActionButton(
                                onPressed: _hintsRemaining == 0
                                    ? null
                                    : _useHint,
                                icon: const Icon(Icons.lightbulb_outline),
                                label: 'HINT · $_hintsRemaining LEFT',
                              ),
                              const SizedBox(height: 10),
                              if (_mode != LanguageMode.gurmukhi &&
                                  !_showAllLatin)
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _showAllLatin = true),
                                  icon: const Icon(
                                    Icons.keyboard_alt_outlined,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'SHOW ALL LETTERS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              _LetterBank(
                                letters:
                                    _mode != LanguageMode.gurmukhi &&
                                        _showAllLatin
                                    ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.characters
                                          .toList()
                                    : _letterBank,
                                game: game,
                                onPressed: _guess,
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
  const _WordTiles({required this.game});
  final WordQuestGame game;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    final scheme = Theme.of(context).colorScheme;
    final hiddenColors = tokens.sikhiStyle
        ? const [Colors.white, _QuestPalette.parchment]
        : [scheme.surfaceContainerLowest, scheme.surfaceContainerHigh];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: [
        for (var i = 0; i < game.revealedGraphemes.length; i++)
          Semantics(
            label: game.revealedGraphemes[i] == null
                ? 'Letter ${i + 1}, hidden'
                : 'Letter ${i + 1}, ${game.revealedGraphemes[i]}, revealed',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 55,
              height: 61,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: game.revealedGraphemes[i] == null
                      ? hiddenColors
                      : [tokens.correct.withValues(alpha: .75), tokens.correct],
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
              child: Text(
                game.revealedGraphemes[i] ?? '?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: game.revealedGraphemes[i] == null
                      ? scheme.onSurface
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GardenPath extends StatelessWidget {
  const _GardenPath({required this.game, required this.reducedMotion});
  final WordQuestGame game;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final distinct = game.solutionGraphemes.toSet();
    final found = distinct.where(game.isGuessed).length;
    final progress = distinct.isEmpty
        ? 0
        : (found / distinct.length * 8).ceil();
    return Semantics(
      label: '$progress of 8 garden steps glowing',
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_QuestPalette.sky, _QuestPalette.turquoise],
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
            Positioned.fill(child: CustomPaint(painter: _GardenPainter())),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Icon(
                    Icons.wb_sunny_rounded,
                    color: _QuestPalette.sunGold,
                    size: 30,
                  ),
                  for (var i = 0; i < 8; i++)
                    AnimatedContainer(
                      duration: reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      width: 22,
                      height: 15,
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
                  Icon(
                    progress == 8 ? Icons.local_florist : Icons.park_rounded,
                    color: progress == 8
                        ? _QuestPalette.magenta
                        : _QuestPalette.emerald,
                    size: 31,
                  ),
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
  @override
  void paint(Canvas canvas, Size size) {
    final hill = Paint()..color = _QuestPalette.emerald.withValues(alpha: .42);
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * .22,
        size.height * .42,
        size.width * .48,
        size.height,
      )
      ..close();
    canvas.drawPath(path, hill);
    canvas.drawCircle(
      Offset(size.width * .88, 13),
      3,
      Paint()..color = Colors.white70,
    );
    canvas.drawCircle(
      Offset(size.width * .82, 24),
      2,
      Paint()..color = Colors.white54,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LetterBank extends StatelessWidget {
  const _LetterBank({
    required this.letters,
    required this.game,
    required this.onPressed,
  });
  final List<String> letters;
  final WordQuestGame game;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 9,
    runSpacing: 11,
    children: [
      for (final letter in letters)
        _QuestKey(
          letter: letter,
          enabled: !game.isGuessed(letter),
          onPressed: () => onPressed(letter),
        ),
    ],
  );
}

class _QuestKey extends StatelessWidget {
  const _QuestKey({
    required this.letter,
    required this.enabled,
    required this.onPressed,
  });
  final String letter;
  final bool enabled;
  final VoidCallback onPressed;

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
      label: 'Letter $letter',
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
          child: Text(
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
    required this.onNewWord,
  });
  final WordQuestWord word;
  final WordQuestGame game;
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
          const SizedBox(height: 6),
          Text(word.definitionHint, textAlign: TextAlign.center),
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
  });
  final String language;
  final int letters;
  final int tries;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _StatusPill(
          icon: Icons.translate_rounded,
          label: '$language · $letters LETTERS',
        ),
      ),
      const SizedBox(width: 10),
      _StatusPill(
        icon: Icons.favorite_rounded,
        label: '$tries',
        accent: _QuestPalette.magenta,
      ),
    ],
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.primary),
    ),
    child: Text(
      label.toUpperCase(),
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
  static const sky = Color(0xFF48D8EA);
  static const turquoise = Color(0xFF1BB9B2);
  static const deepTeal = Color(0xFF116A7A);
  static const emerald = Color(0xFF169B62);
  static const magenta = Color(0xFFE94191);
  static const deepMagenta = Color(0xFF9E1E63);
}
