import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/themes/app_theme.dart';
import '../domain/guess_evaluator.dart';
import '../domain/language_mode.dart';

class GuessTheWordPage extends StatefulWidget {
  const GuessTheWordPage({
    required this.themeChoice,
    required this.onThemeChanged,
    super.key,
  });

  final AppThemeChoice themeChoice;
  final ValueChanged<AppThemeChoice> onThemeChanged;

  @override
  State<GuessTheWordPage> createState() => _GuessTheWordPageState();
}

class _GuessTheWordPageState extends State<GuessTheWordPage> {
  static const _solution = 'APPLE';
  static const _accepted = {
    'APPLE',
    'ALLEY',
    'AMPLE',
    'HELLO',
    'LEVEL',
    'PAPAL',
  };
  final _controller = TextEditingController();
  final _rows = <List<EvaluatedLetter>>[];
  LanguageMode _mode = LanguageMode.english;
  String? _message;
  bool _gameOver = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final guess = _controller.text.trim().toUpperCase();
    if (GuessEvaluator.visibleLength(guess) != 5) {
      setState(() => _message = 'Enter exactly five letters.');
      return;
    }
    if (!_accepted.contains(guess)) {
      setState(() => _message = 'Not in the temporary accepted-guess list.');
      return;
    }
    setState(() {
      _rows.add(GuessEvaluator.evaluate(solution: _solution, guess: guess));
      _controller.clear();
      if (guess == _solution) {
        _message = 'You found it — APPLE: a round fruit.';
        _gameOver = true;
      } else if (_rows.length == 6) {
        _message = 'The word was APPLE: a round fruit.';
        _gameOver = true;
      } else {
        _message = null;
      }
    });
  }

  void _newGame() => setState(() {
    _rows.clear();
    _controller.clear();
    _message = null;
    _gameOver = false;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sikhi Word Games V2'),
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
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Guess the Word',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                DropdownButton<LanguageMode>(
                  value: _mode,
                  onChanged: (value) {
                    if (value != null) setState(() => _mode = value);
                  },
                  items: [
                    for (final mode in LanguageMode.values)
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: _Board(rows: _rows)),
                if (_message != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_message!, textAlign: TextAlign.center),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_gameOver,
                        maxLength: 5,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Five-letter guess',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _gameOver ? _newGame : _submit,
                      child: Text(_gameOver ? 'New game' : 'Enter'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Foundation prototype — temporary English content',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Board extends StatelessWidget {
  const _Board({required this.rows});
  final List<List<EvaluatedLetter>> rows;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = ((constraints.maxWidth - 32) / 5).clamp(38.0, 68.0);
      return SingleChildScrollView(
        child: Column(
          children: [
            for (var row = 0; row < 6; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var column = 0; column < 5; column++) ...[
                      _Tile(
                        size: size,
                        letter: row < rows.length ? rows[row][column] : null,
                      ),
                      if (column < 4) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
          ],
        ),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: letter == null ? null : Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
