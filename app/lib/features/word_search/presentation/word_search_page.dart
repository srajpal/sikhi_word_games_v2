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

enum _WordSearchAction { newPuzzle, language, help, dictionary }

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
  List<VocabularyEntry>? _entries;
  WordSearchPuzzle? _puzzle;
  LanguageMode _mode = LanguageMode.english;
  int? _wordSize;
  final Set<String> _foundWords = {};
  GridPoint? _dragStart;
  List<GridPoint> _selection = const [];
  String? _activeHintWord;
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
      if (!widget.startFresh) {
        final restored = widget.sessionRepository.restore();
        if (restored != null) {
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
          });
          return;
        }
        await widget.sessionRepository.clear();
      }
      _mode = widget.initialMode ?? _randomMode();
      _wordSize = widget.initialWordSize ?? _randomWordSize(_mode);
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
      final selectedCandidates = _wordSize == null
          ? candidates
          : candidates
                .where((word) => word.characters.length == _wordSize)
                .toList(growable: false);
      final puzzle = _generator.generate(
        candidates: selectedCandidates.isEmpty
            ? candidates
            : selectedCandidates,
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
      });
      widget.sessionRepository.save(
        mode: _mode,
        wordSize: _wordSize,
        puzzle: puzzle,
        foundWords: _foundWords,
      );
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
      if (!entry.acceptedGuess || !_supportsMode(entry, mode)) continue;
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
    if (mode == null || mode == _mode) return;
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
      if (word != null && _activeHintWord == word.word) {
        _activeHintWord = null;
      }
    });
    if (word == null) return;
    final complete = _foundWords.length == puzzle.words.length;
    if (complete) {
      widget.sessionRepository.clear();
    } else {
      widget.sessionRepository.save(
        mode: _mode,
        wordSize: _wordSize,
        puzzle: puzzle,
        foundWords: _foundWords,
      );
    }
    HapticFeedback.selectionClick();
    showGameSnackBar(
      context,
      complete ? 'Puzzle complete — great searching!' : 'Found ${word.word}',
    );
  }

  void _showDefinition(PlacedWord word) {
    final entry = _entryForWord(word.word);
    showGameSnackBar(
      context,
      entry == null
          ? 'Definition unavailable for ${word.word}'
          : '${word.word}: ${entry.englishDefinition}',
    );
  }

  void _activateHint(PlacedWord word) {
    if (_foundWords.contains(word.word)) return;
    setState(
      () => _activeHintWord = _activeHintWord == word.word ? null : word.word,
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
        title: const Text('Khoj: Word Search'),
        actions: [
          PopupMenuButton<_WordSearchAction>(
            tooltip: 'Khoj: Word Search menu',
            onSelected: (action) => switch (action) {
              _WordSearchAction.newPuzzle => _newPuzzle(),
              _WordSearchAction.language => _chooseLanguage(),
              _WordSearchAction.help => _showHelp(),
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
              : _WordSearchBoard(
                  puzzle: puzzle,
                  mode: _mode,
                  foundWords: _foundWords,
                  selection: _selection,
                  activeHintWord: _activeHintWord,
                  entryForWord: _entryForWord,
                  onStartSelection: _startSelection,
                  onExtendSelection: _extendSelection,
                  onCompleteSelection: _completeSelection,
                  onActivateHint: _activateHint,
                  onWordTap: _showDefinition,
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
    required this.activeHintWord,
    required this.entryForWord,
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
  final VocabularyEntry? Function(String word) entryForWord;
  final ValueChanged<GridPoint> onStartSelection;
  final ValueChanged<GridPoint> onExtendSelection;
  final VoidCallback onCompleteSelection;
  final ValueChanged<PlacedWord> onActivateHint;
  final ValueChanged<PlacedWord> onWordTap;
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
    final hintedCells = activeHintWord == null
        ? const <GridPoint>{}
        : puzzle.cellsWithGrapheme(activeHintWord!.characters.first);
    final complete = foundWords.length == puzzle.words.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _KhojHeader(
                mode: mode,
                foundCount: foundWords.length,
                totalCount: puzzle.words.length,
              ),
              const SizedBox(height: 14),
              GamePanel(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, boardConstraints) {
                    final dimension = math.min(
                      boardConstraints.maxWidth,
                      620.0,
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
                            final grapheme =
                                puzzle.cells[point.row][point.column];
                            final found = foundCells.contains(point);
                            final selected = activeCells.contains(point);
                            final hinted = hintedCells.contains(point);
                            final emphasized = found || selected || hinted;
                            final textColor = emphasized
                                ? Colors.white
                                : theme.colorScheme.onSurface;
                            return Semantics(
                              label:
                                  'Row ${point.row + 1}, column ${point.column + 1}: '
                                  '$grapheme${mode == LanguageMode.gurmukhi ? ', ${romanizeGurmukhiGrapheme(grapheme)}' : ''}',
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
                                        : hinted
                                        ? [
                                            tokens.present,
                                            theme.colorScheme.tertiary,
                                          ]
                                        : [
                                            theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            theme.colorScheme.surface,
                                          ],
                                  ),
                                  border: Border.all(
                                    color: found || hinted
                                        ? (found
                                              ? tokens.correct
                                              : tokens.present)
                                        : tokens.tileBorder,
                                    width: tokens.tileBorderWidth,
                                  ),
                                  borderRadius: tokens.tileRadius,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: emphasized ? .30 : .14,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
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
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TARGET WORDS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final word in puzzle.words)
                    _WordTargetCard(
                      key: ValueKey('word-search-target-${word.word}'),
                      word: word,
                      entry: entryForWord(word.word),
                      mode: mode,
                      found: foundWords.contains(word.word),
                      hintActive: activeHintWord == word.word,
                      onHint: () => onActivateHint(word),
                      onTap: () => onWordTap(word),
                    ),
                ],
              ),
              if (complete) ...[
                const SizedBox(height: 16),
                GameGradientButton(
                  label: 'Play another puzzle',
                  icon: const Icon(Icons.refresh),
                  onPressed: onNewPuzzle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KhojHeader extends StatelessWidget {
  const _KhojHeader({
    required this.mode,
    required this.foundCount,
    required this.totalCount,
  });

  final LanguageMode mode;
  final int foundCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    return GamePanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
              ),
              shape: BoxShape.circle,
              boxShadow: tokens.elevationShadow,
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.explore_outlined, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KHOJ',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  mode.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'follow the compass',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GameStatusPill(
            icon: Icons.flag_outlined,
            child: Text('$foundCount/$totalCount'),
          ),
        ],
      ),
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
    final firstGrapheme = word.firstGrapheme;
    final wordColor = found ? tokens.correct : theme.colorScheme.onSurface;
    final romanized = mode == LanguageMode.gurmukhi ? entry?.latin : null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 145, maxWidth: 260),
      child: DecoratedBox(
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
          boxShadow: tokens.elevationShadow,
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
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              found ? Icons.check_circle_outline : Icons.search,
                              size: 18,
                              color: wordColor,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                word.word,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: wordColor,
                                  fontWeight: FontWeight.w900,
                                  decoration: found
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (romanized != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 25, top: 2),
                            child: Text(
                              romanized,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
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
                  : 'Highlight every $firstGrapheme in ${word.word}',
              child: InkResponse(
                key: ValueKey('word-search-hint-${word.word}'),
                onTap: found ? null : onHint,
                radius: 26,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: hintActive
                          ? tokens.present
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                        child: mode == LanguageMode.gurmukhi
                            ? GurmukhiKeyLabel(
                                grapheme: firstGrapheme,
                                color: hintActive
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                gurmukhiFontSize: 15,
                                romanizationFontSize: 7,
                              )
                            : Text(
                                firstGrapheme,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: hintActive
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
