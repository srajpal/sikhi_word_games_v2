import '../../../core/statistics/game_statistics_dialog.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/widgets/victory_celebration.dart';
import '../../game_library/domain/game_launch_options.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../../core/language/gurmukhi_romanization.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/themes/game_ui.dart';
import '../../../core/widgets/gurmukhi_key_label.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../../guess_the_word/domain/word_pool.dart';
import '../domain/word_search_puzzle.dart';
import '../data/word_search_session_repository.dart';

enum _WordSearchAction {
  newPuzzle,
  language,
  help,
  statistics,
  dictionary,
  celebrations,
}

class WordSearchPage extends StatefulWidget {
  const WordSearchPage({
    required this.vocabularyRepository,
    required this.sessionRepository,
    this.initialMode,
    this.initialWordSize,
    this.startFresh = false,
    super.key,
  });

  final VocabularyRepository vocabularyRepository;
  final WordSearchSessionRepository sessionRepository;
  final LanguageMode? initialMode;
  final int? initialWordSize;
  final bool startFresh;

  @override
  State<WordSearchPage> createState() => _WordSearchPageState();
}

class _WordSearchPageState extends State<WordSearchPage> {
  final _generator = WordSearchGenerator();
  final _random = math.Random.secure();
  final _gridFocusNode = FocusNode(debugLabel: 'Word search grid');
  List<VocabularyEntry>? _entries;
  WordSearchPuzzle? _puzzle;
  LanguageMode _mode = LanguageMode.english;
  int? _wordSize;
  final Set<String> _foundWords = {};
  GridPoint? _dragStart;
  List<GridPoint> _selection = const [];
  String? _activeHintWord;
  String? _error;
  GridPoint _keyboardPoint = const GridPoint(0, 0);
  bool _keyboardSelecting = false;

  static const _latinFiller = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];
  static const _gurmukhiFiller = [
    'ਕ',
    'ਖ',
    'ਗ',
    'ਘ',
    'ਚ',
    'ਜ',
    'ਟ',
    'ਡ',
    'ਤ',
    'ਦ',
    'ਨ',
    'ਪ',
    'ਬ',
    'ਮ',
    'ਯ',
    'ਰ',
    'ਲ',
    'ਵ',
    'ਸ',
    'ਹ',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _gridFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _entries = await widget.vocabularyRepository.load();
      if (!mounted) return;
      if (!widget.startFresh) {
        final restored = widget.sessionRepository.restore();
        if (restored != null) {
          if (!_canRestore(restored)) {
            _mode = restored.mode;
            _wordSize = restored.wordSize;
            await widget.sessionRepository.clear();
            if (!mounted) return;
            _newPuzzle();
            return;
          }
          if (!mounted) return;
          setState(() {
            _mode = restored.mode;
            _wordSize = restored.wordSize;
            _puzzle = restored.puzzle;
            _foundWords
              ..clear()
              ..addAll(restored.foundWords);
            _activeHintWord = null;
            _error = null;
            _keyboardPoint = const GridPoint(0, 0);
            _keyboardSelecting = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ModalRoute.of(context)?.isCurrent != false) {
              _gridFocusNode.requestFocus();
            }
          });
          return;
        }
        await widget.sessionRepository.clear();
        if (!mounted) return;
      }
      _mode = widget.initialMode ?? _randomMode();
      _wordSize = widget.initialWordSize ?? _randomWordSize(_mode);
      _newPuzzle();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load the offline word list: $error');
    }
  }

  bool _canRestore(WordSearchSession restored) => restored.puzzle.words.every(
    (placed) => (_entries ?? const <VocabularyEntry>[]).any(
      (entry) =>
          entry.acceptedGuess &&
          entry.solutionEligible &&
          entry.hasDistributableDefinition &&
          _supportsMode(entry, restored.mode) &&
          WordPool.spelling(entry, restored.mode)?.trim().toUpperCase() ==
              placed.word.trim().toUpperCase(),
    ),
  );

  void _newPuzzle() {
    if (!mounted) return;
    VictoryCelebration.stop(context);
    final entries = _entries;
    if (entries == null) return;
    try {
      final candidates = <String>[];
      final seen = <String>{};
      for (final entry in entries) {
        if (!entry.acceptedGuess ||
            !entry.solutionEligible ||
            !entry.hasDistributableDefinition ||
            !_supportsMode(entry, _mode)) {
          continue;
        }
        final spelling = WordPool.spelling(entry, _mode);
        if (spelling == null || !seen.add(spelling.toUpperCase())) continue;
        candidates.add(spelling);
      }
      final selectedCandidates = _wordSize == null
          ? candidates
          : candidates
                .where((word) => word.characters.length == _wordSize)
                .toList(growable: false);
      final available = selectedCandidates.isEmpty
          ? candidates
          : selectedCandidates;
      final puzzle = _generator.generate(
        candidates: available,
        targetWordCount: math.min(6, available.length),
        fillerCharacters: _mode == LanguageMode.gurmukhi
            ? _gurmukhiFiller
            : _latinFiller,
      );
      if (!mounted) return;
      setState(() {
        _puzzle = puzzle;
        _foundWords.clear();
        _dragStart = null;
        _selection = const [];
        _activeHintWord = null;
        _error = null;
        _keyboardPoint = const GridPoint(0, 0);
        _keyboardSelecting = false;
      });
      _persist(
        widget.sessionRepository.save(
          mode: _mode,
          wordSize: _wordSize,
          puzzle: puzzle,
          foundWords: _foundWords,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent != false) {
          _gridFocusNode.requestFocus();
        }
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to make a puzzle: $error');
    }
  }

  LanguageMode _randomMode() {
    final values = LanguageMode.values;
    return values[_random.nextInt(values.length)];
  }

  int _randomWordSize(LanguageMode mode) {
    final entries = _entries ?? const <VocabularyEntry>[];
    final sizes = <int>{};
    for (final entry in entries) {
      if (!entry.acceptedGuess ||
          !entry.solutionEligible ||
          !entry.hasDistributableDefinition ||
          !_supportsMode(entry, mode)) {
        continue;
      }
      final spelling = WordPool.spelling(entry, mode);
      if (spelling != null &&
          const [4, 5, 6].contains(spelling.characters.length)) {
        sizes.add(spelling.characters.length);
      }
    }
    if (sizes.isEmpty) return 5;
    final values = sizes.toList()..sort();
    return values[_random.nextInt(values.length)];
  }

  bool _supportsMode(VocabularyEntry entry, LanguageMode mode) =>
      switch (mode) {
        LanguageMode.english => entry.language == VocabularyLanguage.english,
        LanguageMode.romanizedPanjabi ||
        LanguageMode.gurmukhi => entry.language == VocabularyLanguage.panjabi,
        LanguageMode.mixedLatin => true,
      };

  VocabularyEntry? _entryForWord(String word) {
    final entries = _entries;
    if (entries == null) return null;
    final normalized = word.toUpperCase();
    for (final entry in entries) {
      if (!_supportsMode(entry, _mode)) continue;
      final spelling = WordPool.spelling(entry, _mode);
      if (spelling != null && spelling.toUpperCase() == normalized) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _chooseLanguage() async {
    final mode = await showModalBottomSheet<LanguageMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            child: RadioGroup<LanguageMode>(
              groupValue: _mode,
              onChanged: (value) => Navigator.pop(context, value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(title: Text('Word-search language')),
                  for (final mode in LanguageMode.values)
                    RadioListTile<LanguageMode>(
                      value: mode,
                      title: Text(mode.label),
                      subtitle: Text(_languageDescription(mode)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || mode == null || mode == _mode) return;
    setState(() => _mode = mode);
    _newPuzzle();
  }

  String _languageDescription(LanguageMode mode) => switch (mode) {
    LanguageMode.english => 'English words from the offline dictionary',
    LanguageMode.romanizedPanjabi => 'Punjabi written with Latin letters',
    LanguageMode.mixedLatin => 'English and romanized Punjabi together',
    LanguageMode.gurmukhi => 'Punjabi written in Gurmukhi',
  };

  void _startSelection(GridPoint point) {
    setState(() {
      _keyboardSelecting = false;
      _keyboardPoint = point;
      _dragStart = point;
      _selection = [point];
    });
  }

  void _extendSelection(GridPoint point) {
    final start = _dragStart;
    if (start == null) return;
    final selection = WordSearchPuzzle.lineBetween(start, point);
    if (selection == null) return;
    setState(() {
      _keyboardPoint = point;
      _selection = selection;
    });
  }

  void _activateAccessibleCell(GridPoint point) {
    final puzzle = _puzzle;
    if (puzzle == null || _foundWords.length == puzzle.words.length) return;
    if (!_keyboardSelecting || _dragStart == null) {
      setState(() {
        _keyboardSelecting = true;
        _keyboardPoint = point;
        _dragStart = point;
        _selection = [point];
      });
      showGameSnackBar(
        context,
        'Start selected. Choose the last cell, or select this cell again to cancel.',
      );
      return;
    }
    if (_dragStart == point) {
      setState(() {
        _keyboardSelecting = false;
        _dragStart = null;
        _selection = const [];
      });
      showGameSnackBar(context, 'Selection cancelled.');
      return;
    }
    final line = WordSearchPuzzle.lineBetween(_dragStart!, point);
    if (line == null) {
      showGameSnackBar(context, 'Choose an end cell in a straight line.');
      return;
    }
    _keyboardPoint = point;
    _selection = line;
    _completeSelection();
  }

  void _completeSelection() {
    final puzzle = _puzzle;
    if (puzzle == null || _foundWords.length == puzzle.words.length) return;
    final word = puzzle.wordForSelection(_selection);
    setState(() {
      _keyboardSelecting = false;
      _dragStart = null;
      _selection = const [];
      if (word != null) _foundWords.add(word.word);
      if (word != null && _activeHintWord == word.word) {
        _activeHintWord = null;
      }
    });
    if (word == null) {
      showGameSnackBar(context, 'No target found. Try another selection.');
      return;
    }
    final complete = _foundWords.length == puzzle.words.length;
    if (complete) {
      VictoryCelebration.celebrate(context);
      _persist(
        widget.sessionRepository.clear(
          after: widget.sessionRepository.statistics.record(
            mode: _mode.name,
            size: _wordSize,
            won: true,
            wordsFound: puzzle.words.length,
          ),
        ),
      );
    } else {
      _persist(
        widget.sessionRepository.save(
          mode: _mode,
          wordSize: _wordSize,
          puzzle: puzzle,
          foundWords: _foundWords,
        ),
      );
    }
    HapticFeedback.selectionClick();
    showGameSnackBar(
      context,
      complete ? 'Puzzle complete. Great searching!' : 'Found ${word.word}',
    );
  }

  KeyEventResult _handleGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _puzzle == null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (!_keyboardSelecting && _selection.isEmpty) {
        return KeyEventResult.ignored;
      }
      setState(() {
        _keyboardSelecting = false;
        _dragStart = null;
        _selection = const [];
      });
      return KeyEventResult.handled;
    }
    final delta = switch (key) {
      LogicalKeyboardKey.arrowUp => const (-1, 0),
      LogicalKeyboardKey.arrowDown => const (1, 0),
      LogicalKeyboardKey.arrowLeft => const (0, -1),
      LogicalKeyboardKey.arrowRight => const (0, 1),
      _ => null,
    };
    if (delta != null) {
      final size = _puzzle!.size;
      final next = GridPoint(
        (_keyboardPoint.row + delta.$1).clamp(0, size - 1),
        (_keyboardPoint.column + delta.$2).clamp(0, size - 1),
      );
      setState(() {
        _keyboardPoint = next;
        if (_keyboardSelecting && _dragStart != null) {
          _selection =
              WordSearchPuzzle.lineBetween(_dragStart!, next) ?? [_dragStart!];
        }
      });
      return KeyEventResult.handled;
    }
    if (key != LogicalKeyboardKey.enter && key != LogicalKeyboardKey.space) {
      return KeyEventResult.ignored;
    }
    if (!_keyboardSelecting) {
      setState(() {
        _keyboardSelecting = true;
        _dragStart = _keyboardPoint;
        _selection = [_keyboardPoint];
      });
    } else {
      final line = WordSearchPuzzle.lineBetween(_dragStart!, _keyboardPoint);
      if (line == null) {
        showGameSnackBar(context, 'Choose an end cell in a straight line.');
        return KeyEventResult.handled;
      }
      _selection = line;
      _keyboardSelecting = false;
      _completeSelection();
    }
    return KeyEventResult.handled;
  }

  void _showDefinition(PlacedWord word) {
    final entry = _entryForWord(word.word);
    showGameSnackBar(
      context,
      entry == null
          ? 'Definition unavailable for ${word.word}'
          : '${word.word}: ${entry.displayDefinition}',
    );
  }

  void _activateHint(PlacedWord word) {
    if (_foundWords.contains(word.word)) return;
    setState(
      () => _activeHintWord = _activeHintWord == word.word ? null : word.word,
    );
  }

  void _showHelp() => showGameHelp(context, GameKind.wordSearch);

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
    final puzzle = _puzzle;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Khoj: Word Search',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<_WordSearchAction>(
            tooltip: 'Khoj: Word Search menu',
            onSelected: (action) => switch (action) {
              _WordSearchAction.newPuzzle => _newPuzzle(),
              _WordSearchAction.language => _chooseLanguage(),
              _WordSearchAction.help => _showHelp(),
              _WordSearchAction.celebrations => VictoryCelebration.showSettings(
                context,
              ),
              _WordSearchAction.statistics => showGameStatistics(
                context,
                title: 'Khoj',
                repository: widget.sessionRepository.statistics,
                mode: _mode.name,
                size: _wordSize,
                modeLabel: _mode.label,
              ),
              _WordSearchAction.dictionary => context.push('/dictionary'),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _WordSearchAction.newPuzzle,
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('New puzzle'),
                ),
              ),
              PopupMenuItem(
                value: _WordSearchAction.language,
                child: ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                ),
              ),
              PopupMenuItem(
                value: _WordSearchAction.statistics,
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Statistics'),
                ),
              ),
              PopupMenuItem(
                value: _WordSearchAction.celebrations,
                child: ListTile(
                  leading: Icon(Icons.celebration_outlined),
                  title: Text('Celebration settings'),
                ),
              ),
              PopupMenuItem(
                value: _WordSearchAction.help,
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('How to play'),
                ),
              ),
              PopupMenuItem(
                value: _WordSearchAction.dictionary,
                child: ListTile(
                  leading: Icon(Icons.menu_book_outlined),
                  title: Text('Dictionary'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: GameBackdrop(
        child: SafeArea(
          child: puzzle == null
              ? Center(
                  child: _error == null
                      ? const CircularProgressIndicator()
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                )
              : Focus(
                  key: const ValueKey('word-search-grid-focus'),
                  autofocus: true,
                  focusNode: _gridFocusNode,
                  onKeyEvent: _handleGridKey,
                  onFocusChange: (_) => setState(() {}),
                  child: _WordSearchBoard(
                    puzzle: puzzle,
                    mode: _mode,
                    foundWords: _foundWords,
                    selection: _selection,
                    activeHintWord: _activeHintWord,
                    keyboardPoint: _keyboardPoint,
                    showKeyboardFocus: _gridFocusNode.hasFocus,
                    keyboardSelecting: _keyboardSelecting,
                    entryForWord: _entryForWord,
                    onActivateCell: _activateAccessibleCell,
                    onStartSelection: _startSelection,
                    onExtendSelection: _extendSelection,
                    onCompleteSelection: _completeSelection,
                    onActivateHint: _activateHint,
                    onWordTap: _showDefinition,
                    onNewPuzzle: _newPuzzle,
                  ),
                ),
        ),
      ),
    );
  }
}

class _WordSearchBoard extends StatelessWidget {
  const _WordSearchBoard({
    required this.puzzle,
    required this.mode,
    required this.foundWords,
    required this.selection,
    required this.activeHintWord,
    required this.keyboardPoint,
    required this.showKeyboardFocus,
    required this.keyboardSelecting,
    required this.entryForWord,
    required this.onActivateCell,
    required this.onStartSelection,
    required this.onExtendSelection,
    required this.onCompleteSelection,
    required this.onActivateHint,
    required this.onWordTap,
    required this.onNewPuzzle,
  });

  final WordSearchPuzzle puzzle;
  final LanguageMode mode;
  final Set<String> foundWords;
  final List<GridPoint> selection;
  final String? activeHintWord;
  final GridPoint keyboardPoint;
  final bool showKeyboardFocus;
  final bool keyboardSelecting;
  final VocabularyEntry? Function(String word) entryForWord;
  final ValueChanged<GridPoint> onActivateCell;
  final ValueChanged<GridPoint> onStartSelection;
  final ValueChanged<GridPoint> onExtendSelection;
  final VoidCallback onCompleteSelection;
  final ValueChanged<PlacedWord> onActivateHint;
  final ValueChanged<PlacedWord> onWordTap;
  final VoidCallback onNewPuzzle;

  static const _targetGap = 8.0;
  static const _minimumTargetWidth = 148.0;

  GridPoint _pointFor(Offset position, Size size) {
    final row = (position.dy * puzzle.size ~/ size.height)
        .clamp(0, puzzle.size - 1)
        .toInt();
    final column = (position.dx * puzzle.size ~/ size.width)
        .clamp(0, puzzle.size - 1)
        .toInt();
    return GridPoint(row, column);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final foundCells = <GridPoint>{
      for (final word in puzzle.words)
        if (foundWords.contains(word.word)) ...puzzle.cellsFor(word),
    };
    final activeCells = selection.toSet();
    final hintedCells = activeHintWord == null
        ? const <GridPoint>{}
        : puzzle.cellsWithGrapheme(activeHintWord!.characters.first);
    final complete = foundWords.length == puzzle.words.length;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final targetCardHeight =
        (mode == LanguageMode.gurmukhi ? 64.0 : 56.0) +
        (textScale - 1).clamp(0, 1) * (mode == LanguageMode.gurmukhi ? 30 : 20);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: LayoutBuilder(
            builder: (context, contentConstraints) {
              final cardsPerRow = math
                  .max(
                    1,
                    ((contentConstraints.maxWidth + _targetGap) /
                            (_minimumTargetWidth + _targetGap))
                        .floor(),
                  )
                  .toInt();
              final targetRowCount =
                  (puzzle.words.length + cardsPerRow - 1) ~/ cardsPerRow;
              final targetWordsHeight =
                  targetRowCount * targetCardHeight +
                  (targetRowCount - 1) * _targetGap;
              final completionHeight = complete ? 62.0 : 0.0;
              final fittedBoardDimension = math
                  .max(
                    0.0,
                    math.min(
                      620.0,
                      math.min(
                        contentConstraints.maxWidth - 24,
                        contentConstraints.maxHeight -
                            targetWordsHeight -
                            10 -
                            completionHeight -
                            26,
                      ),
                    ),
                  )
                  .toDouble();
              final minimumBoardDimension = math
                  .min(280.0, contentConstraints.maxWidth - 24)
                  .clamp(0.0, double.infinity)
                  .toDouble();
              final boardDimension = math.max(
                fittedBoardDimension,
                minimumBoardDimension,
              );
              return SingleChildScrollView(
                key: const ValueKey('word-search-board-scroll'),
                child: Column(
                  children: [
                    GamePanel(
                      padding: const EdgeInsets.all(12),
                      child: Semantics(
                        key: const ValueKey('word-search-grid-semantics'),
                        label: keyboardSelecting
                            ? 'Word search grid. Start cell chosen. Use arrow keys, then press Enter or Space to choose the end cell.'
                            : 'Word search grid. Use arrow keys to move. Press Enter or Space to choose a start cell.',
                        child: SizedBox.square(
                          dimension: boardDimension,
                          child: GestureDetector(
                            onPanStart: (details) => onStartSelection(
                              _pointFor(
                                details.localPosition,
                                Size.square(boardDimension),
                              ),
                            ),
                            onPanUpdate: (details) => onExtendSelection(
                              _pointFor(
                                details.localPosition,
                                Size.square(boardDimension),
                              ),
                            ),
                            onPanEnd: (_) => onCompleteSelection(),
                            onPanCancel: onCompleteSelection,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: puzzle.size,
                                    mainAxisSpacing: 3,
                                    crossAxisSpacing: 3,
                                  ),
                              itemCount: puzzle.size * puzzle.size,
                              itemBuilder: (context, index) {
                                final point = GridPoint(
                                  index ~/ puzzle.size,
                                  index % puzzle.size,
                                );
                                final grapheme =
                                    puzzle.cells[point.row][point.column];
                                final found = foundCells.contains(point);
                                final selected = activeCells.contains(point);
                                final hinted = hintedCells.contains(point);
                                final keyboardFocused =
                                    showKeyboardFocus && point == keyboardPoint;
                                final textColor = found || hinted
                                    ? Colors.white
                                    : selected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface;
                                return Semantics(
                                  key: ValueKey(
                                    'word-search-cell-action-${point.row}-${point.column}',
                                  ),
                                  button: true,
                                  enabled: !complete,
                                  selected: selected,
                                  excludeSemantics: true,
                                  onTap: complete
                                      ? null
                                      : () => onActivateCell(point),
                                  hint: keyboardSelecting
                                      ? 'Choose the end cell. Choose the start again to cancel.'
                                      : 'Choose the start cell.',
                                  label:
                                      'Row ${point.row + 1}, column ${point.column + 1}: '
                                      '$grapheme${mode == LanguageMode.gurmukhi ? ', ${romanizeGurmukhiGrapheme(grapheme)}' : ''}'
                                      '${keyboardFocused ? ', keyboard focus' : ''}'
                                      '${hinted ? ', hint highlighted' : ''}'
                                      '${found ? ', found' : ''}',
                                  child: DecoratedBox(
                                    key: ValueKey(
                                      'word-search-cell-${point.row}-${point.column}',
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: found
                                            ? [tokens.correct, tokens.correct]
                                            : selected
                                            ? [
                                                theme.colorScheme.primary,
                                                theme.colorScheme.primary,
                                              ]
                                            : hinted
                                            ? [tokens.present, tokens.present]
                                            : tokens.panelGradient.colors,
                                      ),
                                      border: Border.all(
                                        color: keyboardFocused
                                            ? selected && !found && !hinted
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.primary
                                            : found || hinted
                                            ? (found
                                                  ? tokens.correct
                                                  : tokens.present)
                                            : tokens.tileBorder,
                                        width: keyboardFocused
                                            ? 3
                                            : tokens.tileBorderWidth,
                                      ),
                                      borderRadius: tokens.tileRadius,
                                      boxShadow: tokens.tileShadow,
                                    ),
                                    child: Center(
                                      child: mode == LanguageMode.gurmukhi
                                          ? GurmukhiKeyLabel(
                                              grapheme: grapheme,
                                              color: textColor,
                                              gurmukhiFontSize: 18,
                                              romanizationFontSize: 8,
                                            )
                                          : FittedBox(
                                              child: Text(
                                                grapheme,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: textColor,
                                                    ),
                                              ),
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
                    const SizedBox(height: 10),
                    Semantics(
                      container: true,
                      label: 'Target words',
                      child: SizedBox(
                        height: targetWordsHeight,
                        child: _TargetWords(
                          words: puzzle.words,
                          contentWidth: contentConstraints.maxWidth,
                          cardHeight: targetCardHeight,
                          cardsPerRow: cardsPerRow,
                          entryForWord: entryForWord,
                          mode: mode,
                          foundWords: foundWords,
                          activeHintWord: activeHintWord,
                          onActivateHint: onActivateHint,
                          onWordTap: onWordTap,
                        ),
                      ),
                    ),
                    if (complete) ...[
                      const SizedBox(height: 10),
                      GameGradientButton(
                        label: 'Play another puzzle',
                        icon: const Icon(Icons.refresh),
                        onPressed: onNewPuzzle,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TargetWords extends StatelessWidget {
  const _TargetWords({
    required this.words,
    required this.contentWidth,
    required this.cardHeight,
    required this.cardsPerRow,
    required this.entryForWord,
    required this.mode,
    required this.foundWords,
    required this.activeHintWord,
    required this.onActivateHint,
    required this.onWordTap,
  });

  final List<PlacedWord> words;
  final double contentWidth;
  final double cardHeight;
  final int cardsPerRow;
  final VocabularyEntry? Function(String word) entryForWord;
  final LanguageMode mode;
  final Set<String> foundWords;
  final String? activeHintWord;
  final ValueChanged<PlacedWord> onActivateHint;
  final ValueChanged<PlacedWord> onWordTap;

  @override
  Widget build(BuildContext context) {
    final cardWidth =
        (contentWidth - _WordSearchBoard._targetGap * (cardsPerRow - 1)) /
        cardsPerRow;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: _WordSearchBoard._targetGap,
      runSpacing: _WordSearchBoard._targetGap,
      children: [
        for (final word in words)
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _WordTargetCard(
              key: ValueKey('word-search-target-${word.word}'),
              word: word,
              entry: entryForWord(word.word),
              mode: mode,
              found: foundWords.contains(word.word),
              hintActive: activeHintWord == word.word,
              onHint: () => onActivateHint(word),
              onTap: () => onWordTap(word),
            ),
          ),
      ],
    );
  }
}

class _WordTargetCard extends StatelessWidget {
  const _WordTargetCard({
    required this.word,
    required this.entry,
    required this.mode,
    required this.found,
    required this.hintActive,
    required this.onHint,
    required this.onTap,
    super.key,
  });

  final PlacedWord word;
  final VocabularyEntry? entry;
  final LanguageMode mode;
  final bool found;
  final bool hintActive;
  final VoidCallback onHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final firstGrapheme = word.firstGrapheme;
    final wordColor = theme.colorScheme.onSurface;
    final romanized = mode == LanguageMode.gurmukhi ? entry?.latin : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: found
            ? tokens.correct.withValues(alpha: .14)
            : theme.colorScheme.surface,
        borderRadius: tokens.tileRadius,
        border: Border.all(
          color: hintActive
              ? tokens.present
              : theme.colorScheme.outline.withValues(alpha: .35),
          width: hintActive ? 2 : 1,
        ),
        boxShadow: tokens.tileShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: found
                  ? '${word.word}, found. Show definition.'
                  : '${word.word}. Show definition.',
              child: InkWell(
                key: ValueKey('word-search-definition-${word.word}'),
                borderRadius: tokens.tileRadius,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word.word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: wordColor,
                          fontWeight: FontWeight.w900,
                          decoration: found ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (romanized != null)
                        Text(
                          romanized,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            enabled: !found,
            label: found
                ? 'Hint already solved for ${word.word}'
                : hintActive
                ? 'Turn off hint for ${word.word}'
                : 'Hint: Highlight every $firstGrapheme in ${word.word}',
            child: Tooltip(
              message: found
                  ? 'Hint already solved'
                  : 'Hint: highlight every $firstGrapheme',
              child: InkResponse(
                key: ValueKey('word-search-hint-${word.word}'),
                onTap: found ? null : onHint,
                radius: 26,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: hintActive
                          ? tokens.present
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      width: 42,
                      height: (46 + (textScale - 1).clamp(0, 1) * 28)
                          .toDouble(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: hintActive
                                ? Colors.white
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 1),
                          mode == LanguageMode.gurmukhi
                              ? GurmukhiKeyLabel(
                                  grapheme: firstGrapheme,
                                  color: hintActive
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  gurmukhiFontSize: 13,
                                  romanizationFontSize: 6,
                                )
                              : Text(
                                  firstGrapheme,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: hintActive
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
