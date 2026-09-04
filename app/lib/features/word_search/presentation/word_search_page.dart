import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/themes/game_ui.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../../guess_the_word/domain/word_pool.dart';
import '../domain/word_search_puzzle.dart';

enum _WordSearchAction { newPuzzle, language, help }

class WordSearchPage extends StatefulWidget {
  const WordSearchPage({required this.vocabularyRepository, super.key});

  final VocabularyRepository vocabularyRepository;

  @override
  State<WordSearchPage> createState() => _WordSearchPageState();
}

class _WordSearchPageState extends State<WordSearchPage> {
  final _generator = WordSearchGenerator();
  List<VocabularyEntry>? _entries;
  WordSearchPuzzle? _puzzle;
  LanguageMode _mode = LanguageMode.english;
  final Set<String> _foundWords = {};
  GridPoint? _dragStart;
  List<GridPoint> _selection = const [];
  String? _error;

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

  Future<void> _load() async {
    try {
      _entries = await widget.vocabularyRepository.load();
      _newPuzzle();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load the offline word list: $error');
    }
  }

  void _newPuzzle() {
    final entries = _entries;
    if (entries == null) return;
    try {
      final candidates = <String>[];
      final seen = <String>{};
      for (final entry in entries) {
        if (!entry.acceptedGuess || !_supportsMode(entry, _mode)) continue;
        final spelling = WordPool.spelling(entry, _mode);
        if (spelling == null || !seen.add(spelling.toUpperCase())) continue;
        candidates.add(spelling);
      }
      final puzzle = _generator.generate(
        candidates: candidates,
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
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to make a puzzle: $error');
    }
  }

  bool _supportsMode(VocabularyEntry entry, LanguageMode mode) =>
      switch (mode) {
        LanguageMode.english => entry.language == VocabularyLanguage.english,
        LanguageMode.romanizedPanjabi ||
        LanguageMode.gurmukhi => entry.language == VocabularyLanguage.panjabi,
        LanguageMode.mixedLatin => true,
      };

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
    if (mode == null || mode == _mode) return;
    setState(() => _mode = mode);
    _newPuzzle();
  }

  String _languageDescription(LanguageMode mode) => switch (mode) {
    LanguageMode.english => 'English words from the offline dictionary',
    LanguageMode.romanizedPanjabi => 'Panjabi written with Latin letters',
    LanguageMode.mixedLatin => 'English and romanized Panjabi together',
    LanguageMode.gurmukhi => 'Panjabi written in Gurmukhi',
  };

  void _startSelection(GridPoint point) {
    setState(() {
      _dragStart = point;
      _selection = [point];
    });
  }

  void _extendSelection(GridPoint point) {
    final start = _dragStart;
    if (start == null) return;
    final selection = WordSearchPuzzle.lineBetween(start, point);
    if (selection == null) return;
    setState(() => _selection = selection);
  }

  void _completeSelection() {
    final puzzle = _puzzle;
    if (puzzle == null) return;
    final word = puzzle.wordForSelection(_selection);
    setState(() {
      _dragStart = null;
      _selection = const [];
      if (word != null) _foundWords.add(word.word);
    });
    if (word == null) return;
    HapticFeedback.selectionClick();
    final complete = _foundWords.length == puzzle.words.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: complete ? 2600 : 1200),
        content: Text(
          complete
              ? 'Puzzle complete — great searching!'
              : 'Found ${word.word}',
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to play'),
        content: const Text(
          'Find every word below the grid. Drag across letters horizontally, '
          'vertically, or diagonally. Words may run forward or backward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
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
        title: const Text('Word Search'),
        actions: [
          PopupMenuButton<_WordSearchAction>(
            tooltip: 'Word Search menu',
            onSelected: (action) => switch (action) {
              _WordSearchAction.newPuzzle => _newPuzzle(),
              _WordSearchAction.language => _chooseLanguage(),
              _WordSearchAction.help => _showHelp(),
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
                value: _WordSearchAction.help,
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('How to play'),
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
              : _WordSearchBoard(
                  puzzle: puzzle,
                  mode: _mode,
                  foundWords: _foundWords,
                  selection: _selection,
                  onStartSelection: _startSelection,
                  onExtendSelection: _extendSelection,
                  onCompleteSelection: _completeSelection,
                  onNewPuzzle: _newPuzzle,
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
    required this.onStartSelection,
    required this.onExtendSelection,
    required this.onCompleteSelection,
    required this.onNewPuzzle,
  });

  final WordSearchPuzzle puzzle;
  final LanguageMode mode;
  final Set<String> foundWords;
  final List<GridPoint> selection;
  final ValueChanged<GridPoint> onStartSelection;
  final ValueChanged<GridPoint> onExtendSelection;
  final VoidCallback onCompleteSelection;
  final VoidCallback onNewPuzzle;

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
    final complete = foundWords.length == puzzle.words.length;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: .28,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      mode.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '${foundWords.length}/${puzzle.words.length} found',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: GamePanel(
                  padding: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: LayoutBuilder(
                      builder: (context, boardConstraints) {
                        final dimension = math.min(
                          boardConstraints.maxWidth,
                          boardConstraints.maxHeight,
                        );
                        return SizedBox.square(
                          dimension: dimension,
                          child: GestureDetector(
                            onPanStart: (details) => onStartSelection(
                              _pointFor(
                                details.localPosition,
                                Size.square(dimension),
                              ),
                            ),
                            onPanUpdate: (details) => onExtendSelection(
                              _pointFor(
                                details.localPosition,
                                Size.square(dimension),
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
                                final found = foundCells.contains(point);
                                final selected = activeCells.contains(point);
                                return Semantics(
                                  label:
                                      'Row ${point.row + 1}, column ${point.column + 1}: '
                                      '${puzzle.cells[point.row][point.column]}',
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: found
                                            ? [
                                                tokens.correct,
                                                tokens.correct.withValues(
                                                  alpha: .72,
                                                ),
                                              ]
                                            : selected
                                            ? [
                                                theme.colorScheme.primary,
                                                theme.colorScheme.secondary,
                                              ]
                                            : [
                                                theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                theme.colorScheme.surface,
                                              ],
                                      ),
                                      border: Border.all(
                                        color: found
                                            ? tokens.correct
                                            : tokens.tileBorder,
                                        width: tokens.tileBorderWidth,
                                      ),
                                      borderRadius: tokens.tileRadius,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: found || selected
                                                ? .30
                                                : .14,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: FittedBox(
                                        child: Text(
                                          puzzle.cells[point.row][point.column],
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: found || selected
                                                    ? Colors.white
                                                    : theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final word in puzzle.words)
                      Chip(
                        elevation: 3,
                        shadowColor: Colors.black45,
                        backgroundColor: foundWords.contains(word.word)
                            ? tokens.correct.withValues(alpha: .18)
                            : theme.colorScheme.surface,
                        avatar: Icon(
                          foundWords.contains(word.word)
                              ? Icons.check_circle
                              : Icons.search,
                          size: 18,
                        ),
                        label: Text(
                          word.word,
                          style: TextStyle(
                            decoration: foundWords.contains(word.word)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                if (complete) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onNewPuzzle,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Play another puzzle'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
