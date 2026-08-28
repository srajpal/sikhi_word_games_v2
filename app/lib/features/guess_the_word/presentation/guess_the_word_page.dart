import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../../core/themes/app_theme.dart';
import '../domain/guess_evaluator.dart';
import '../domain/guess_game.dart';
import '../domain/language_mode.dart';
import '../domain/word_pool.dart';
import 'game_keyboard.dart';

class GuessTheWordPage extends StatefulWidget {
  const GuessTheWordPage({
    required this.themeChoice,
    required this.onThemeChanged,
    required this.vocabularyRepository,
    super.key,
  });

  final AppThemeChoice themeChoice;
  final ValueChanged<AppThemeChoice> onThemeChanged;
  final VocabularyRepository vocabularyRepository;

  @override
  State<GuessTheWordPage> createState() => _GuessTheWordPageState();
}

class _GuessTheWordPageState extends State<GuessTheWordPage> {
  final _controller = TextEditingController();
  final _selector = NonRepeatingWordSelector();
  WordPool? _pool;
  GuessGame? _game;
  VocabularyEntry? _solutionEntry;
  LanguageMode _mode = LanguageMode.english;
  int _wordLength = 5;
  String? _message;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
  }

  void _submit() {
    final game = _game;
    if (game == null) return;
    final result = game.submit(_controller.text);
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
      _controller.clear();
      _message = switch (game.status) {
        GuessGameStatus.won => 'You found it!',
        GuessGameStatus.lost => 'No guesses remain.',
        GuessGameStatus.playing => null,
      };
    });
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
  }

  void _backspace() {
    if (_controller.text.isEmpty) return;
    final shortened = _controller.text.characters.skipLast(1).toString();
    _controller.value = TextEditingValue(
      text: shortened,
      selection: TextSelection.collapsed(offset: shortened.length),
    );
    setState(() => _message = null);
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final isComplete = game?.status != GuessGameStatus.playing;
    final inputFormatters = _mode == LanguageMode.gurmukhi
        ? <TextInputFormatter>[]
        : <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess the Word'),
        actions: [
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
                  : SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                                  if (value != null) _startGame(length: value);
                                },
                                items: [
                                  for (final length in _availableLengths(_mode))
                                    DropdownMenuItem(
                                      value: length,
                                      child: Text('$length letters'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (game != null)
                            _Board(
                              turns: game.turns,
                              wordLength: game.wordLength,
                              maximumAttempts: game.maximumAttempts,
                            ),
                          if (_message != null)
                            Semantics(
                              liveRegion: true,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  _message!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                            ),
                          if (game != null && isComplete) ...[
                            Text(
                              game.solution,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _solutionEntry!.englishDefinition,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (game != null)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    enabled: !isComplete,
                                    maxLength: game.wordLength,
                                    autofocus: true,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    inputFormatters: inputFormatters,
                                    decoration: InputDecoration(
                                      labelText: _mode == LanguageMode.gurmukhi
                                          ? 'Gurmukhi guess'
                                          : 'Your guess',
                                      counterText: '',
                                      border: const OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) => _submit(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: isComplete
                                      ? () => _startGame()
                                      : _submit,
                                  child: Text(
                                    isComplete ? 'New game' : 'Enter',
                                  ),
                                ),
                              ],
                            ),
                          if (game != null) ...[
                            const SizedBox(height: 10),
                            GameKeyboard(
                              mode: _mode,
                              enabled: !isComplete,
                              onCharacter: _appendCharacter,
                              onBackspace: _backspace,
                              onEnter: _submit,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Offline starter solution set — editorial review pending',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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
      final spacing = wordLength == 6 ? 5.0 : 8.0;
      final available = constraints.maxWidth - ((wordLength - 1) * spacing);
      final size = (available / wordLength).clamp(34.0, 68.0);
      return Column(
        children: [
          for (var row = 0; row < maximumAttempts; row++)
            Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var column = 0; column < wordLength; column++) ...[
                    _Tile(
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
  const _Tile({required this.size, this.letter});

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
    return Semantics(
      label: letter == null ? 'Blank tile' : '${letter!.grapheme}, $status',
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
        child: Text(
          letter?.grapheme ?? '',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: letter == null ? null : Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
