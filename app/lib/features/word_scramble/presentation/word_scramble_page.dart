import '../../achievements/presentation/achievement_feedback.dart';
import '../../../core/widgets/game_menu.dart';

import 'dart:math';

import '../../../core/language/player_text.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/interaction_sounds.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../../core/language/gurmukhi_romanization.dart';
import '../../../core/themes/game_heading.dart';
import '../../../core/themes/game_ui.dart';
import '../../../core/themes/paper_letter_tile.dart';
import '../../../core/themes/paper_page.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/widgets/victory_celebration.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../data/word_scramble_repository.dart';
import '../domain/word_scramble_game.dart';
import '../domain/word_scramble_vocabulary.dart';

class WordScramblePage extends StatefulWidget {
  const WordScramblePage({
    required this.vocabularyRepository,
    required this.repository,
    this.initialMode,
    this.startFresh = false,
    this.simpleRomanized = false,
    super.key,
  });
  final VocabularyRepository vocabularyRepository;
  final WordScrambleRepository repository;
  final LanguageMode? initialMode;
  final bool startFresh, simpleRomanized;
  @override
  State<WordScramblePage> createState() => _WordScramblePageState();
}

class _WordScramblePageState extends State<WordScramblePage> {
  final _random = Random();
  WordScrambleVocabulary? _original;
  WordScrambleGame? _game;
  LanguageMode _mode = LanguageMode.english;
  bool _simple = false;
  String? _error, _saveError;
  String _message = 'Take your time. There is no timer.';
  int _pending = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final words = WordScrambleVocabulary(
        await widget.vocabularyRepository.load(),
      );
      if (!mounted) return;
      _original = words;
      final saved = widget.startFresh ? null : widget.repository.restore();
      final view = saved?.simpleRomanized == true
          ? words.simpleRomanized
          : words;
      if (saved != null &&
          view.contains(
            saved.mode,
            id: saved.game.wordId,
            spelling: saved.game.spelling,
            definition: saved.game.definition,
          )) {
        setState(() {
          _mode = saved.mode;
          _simple = saved.simpleRomanized;
          _game = saved.game;
          _message = 'Your tiles are saved. Pick up where you left off.';
        });
        return;
      }
      final modes = words.availableModes;
      if (modes.isEmpty) {
        setState(
          () => _error = 'No words are available in the offline word list.',
        );
        return;
      }
      final requested =
          widget.initialMode ??
          (widget.startFresh
              ? modes[_random.nextInt(modes.length)]
              : saved?.mode ?? LanguageMode.english);
      await _newWord(mode: modes.contains(requested) ? requested : modes.first);
      if (mounted && saved != null) {
        setState(
          () => _message = 'Your saved word changed, so a fresh word is ready.',
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _error = 'Unable to load Shabad Banao. Please try again.',
        );
      }
    }
  }

  Future<void> _newWord({LanguageMode? mode}) async {
    if (!mounted || _pending > 0 || _original == null) return;
    final simple = widget.simpleRomanized;
    final view = simple ? _original!.simpleRomanized : _original!;
    final next = mode ?? _mode;
    final seen = widget.repository.seen(next);
    final pool = view.words(next);
    final reset =
        pool.isNotEmpty && pool.every((word) => seen.contains(word.id));
    final word = view.choose(
      next,
      random: _random,
      seen: seen,
      previous: _game?.wordId ?? widget.repository.previous(next),
    );
    if (word == null) {
      if (_game == null) {
        setState(
          () => _error = 'No scrambled words are available for this language.',
        );
      } else {
        showGameSnackBar(
          context,
          'No scrambled words are available for this language.',
        );
      }
      return;
    }
    VictoryCelebration.stop(context);
    setState(() {
      _mode = next;
      _simple = simple;
      _error = null;
      _game = WordScrambleGame(
        wordId: word.id,
        spelling: word.spelling,
        definition: word.definition,
        random: _random,
      );
      _message = 'Take your time. There is no timer.';
    });
    await _save(resetHistory: reset);
  }

  Future<void> _save({bool resetHistory = false}) async {
    if (!mounted || _game == null) return;
    final game = _game!, mode = _mode, simple = _simple;
    final completed = game.isComplete;
    setState(() => _pending++);
    try {
      await widget.repository.save(
        mode: mode,
        game: game,
        simpleRomanized: simple,
        resetHistory: resetHistory,
      );
      if (mounted) {
        setState(() => _saveError = null);
        if (completed) AchievementFeedback.check(context);
      }
    } on Object {
      if (mounted) {
        setState(
          () => _saveError = 'Progress could not be saved on this device. You can keep playing.',
        );
      }
    } finally {
      if (mounted) setState(() => _pending--);
    }
  }

  void _place(int id) {
    if (!_game!.place(id)) return;
    setState(
      () => _message = _game!.canCheck
          ? 'Ready? Check your word.'
          : 'Keep going!',
    );
    _save();
  }

  void _remove(int slot) {
    if (!_game!.remove(slot)) return;
    setState(() => _message = 'Try another arrangement.');
    _save();
  }

  void _move(int id, int slot) {
    if (!_game!.moveTo(id, slot)) return;
    InteractionSounds.letter(context);
    setState(
      () => _message = _game!.canCheck
          ? 'Ready? Check your word.'
          : 'Keep going!',
    );
    _save();
  }

  void _recall() {
    if (!_game!.recall()) return;
    setState(() => _message = 'Tiles returned. Try a fresh arrangement.');
    _save();
  }

  Widget _draggable(int id, Widget tile) => Draggable<(String, int)>(
    data: (_game!.roundId, id),
    maxSimultaneousDrags:
        _game!.isComplete ||
            _game!.locked.any((slot) => _game!.slots[slot] == id)
        ? 0
        : 1,
    feedback: Material(
      type: MaterialType.transparency,
      child: IgnorePointer(child: tile),
    ),
    childWhenDragging: Opacity(opacity: .3, child: tile),
    child: tile,
  );

  Widget _dropSpace(int slot, Widget tile) => DragTarget<(String, int)>(
    onWillAcceptWithDetails: (details) =>
        details.data.$1 == _game!.roundId &&
        _game!.canMoveTo(details.data.$2, slot),
    onAcceptWithDetails: (details) {
      if (details.data.$1 == _game!.roundId) _move(details.data.$2, slot);
    },
    builder: (context, candidates, rejected) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: candidates.isEmpty
            ? null
            : Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
      ),
      child: tile,
    ),
  );

  void _shuffle() {
    if (!_game!.shuffle(_random)) return;
    setState(() => _message = 'A fresh view of the same letters.');
    _save();
  }

  void _hint() {
    if (!_game!.hint()) {
      return;
    }
    setState(
      () => _message = 'Meaning revealed. Your tiles stay where they are.',
    );
    _save();
  }

  void _check() {
    final result = _game!.check();
    if (result == ScrambleCheck.ignored) return;
    setState(
      () => _message = result == ScrambleCheck.solved
          ? 'Lovely! ${_game!.spelling} is the word.'
          : 'Not quite. Tap a tile to try a different order.',
    );
    if (result == ScrambleCheck.solved) VictoryCelebration.celebrate(context);
    _save();
  }

  Future<void> _settings() async {
    var draft = _mode;
    final mode = await showModalBottomSheet<LanguageMode>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text('Game settings'),
                  subtitle: Text(
                    'A different language starts a new word when you apply. Cancel keeps your current word. Word lengths vary.',
                  ),
                ),
                for (final mode in _original!.availableModes)
                  ListTile(
                    key: ValueKey('scramble-language-${mode.name}'),
                    title: Text(mode.label),
                    selected: mode == draft,
                    leading: Icon(
                      mode == draft
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    onTap: InteractionSounds.buttonAction(
                      context,
                      () => setSheetState(() => draft = mode),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: InteractionSounds.buttonAction(
                            context,
                            () => Navigator.pop(context),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('scramble-settings-apply'),
                          onPressed: InteractionSounds.buttonAction(
                            context,
                            () => Navigator.pop(context, draft),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mode != null && mounted && mode != _mode) await _newWord(mode: mode);
  }

  void _statistics() {
    final total = widget.repository.total;
    showPaperDetails(
      context,
      title: 'Shabad Banao statistics',
      introduction: 'Every finished word is a discovery.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(wordsSolvedLabel(total.solved)),
          Text('${total.unhinted} without a hint'),
          Text('${total.firstCheck} on the first check'),
          const SizedBox(height: 16),
          for (final mode in LanguageMode.values)
            Text(
              '${mode.label}: ${widget.repository.forMode(mode).solved} solved',
            ),
          const SizedBox(height: 16),
          const Text(
            'Only finished words count. Leaving a word does not create a loss. Saved only on this device or browser.',
          ),
        ],
      ),
    );
  }

  Widget _board() {
    final game = _game!,
        theme = Theme.of(context),
        scale = MediaQuery.textScalerOf(context);
    // Account for the panel's padding and border as well as the page padding.
    final trayWidth = min(640.0, MediaQuery.sizeOf(context).width) - 67;
    final fitted =
        (trayWidth - (game.units.length - 1) * 10) / game.units.length;
    var tileSize = max(44.0 + scale.scale(30) - 30, min(60.0, fitted));
    final romanizations = [
      for (final unit in game.units)
        _mode == LanguageMode.gurmukhi ? romanizeGurmukhiGrapheme(unit) : null,
    ];
    for (final unit in game.units) {
      final painter = TextPainter(
        text: TextSpan(
          text: unit,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: scale,
      )..layout();
      tileSize = max(tileSize, painter.width + 12);
      painter.dispose();
    }
    for (final romanization in romanizations.whereType<String>()) {
      final painter = TextPainter(
        text: TextSpan(
          text: romanization,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: scale,
      )..layout();
      tileSize = max(tileSize, painter.width + 12);
      painter.dispose();
    }
    final tileHeight = PaperLetterTile.heightFor(
      context,
      tileSize,
      withRomanization: _mode == LanguageMode.gurmukhi,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (game.clueRevealed || game.isComplete) ...[
          Semantics(
            liveRegion: true,
            child: PaperLabel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.isComplete ? 'THE MEANING' : 'YOUR HINT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.definition,
                    key: const ValueKey('scramble-clue'),
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'BUILD THE WORD',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 12,
          children: [
            for (var i = 0; i < game.units.length; i++)
              Builder(
                builder: (context) {
                  final tile = PaperLetterTile(
                    key: ValueKey('scramble-slot-$i'),
                    size: tileSize,
                    height: tileHeight,
                    text: game.slots[i] == null
                        ? null
                        : game.units[game.slots[i]!],
                    romanization: game.slots[i] == null
                        ? null
                        : romanizations[game.slots[i]!],
                    correct: game.isComplete,
                    locked: game.locked.contains(i),
                    label: game.slots[i] == null
                        ? 'Empty space ${i + 1}'
                        : '${game.units[game.slots[i]!]} in space ${i + 1}${game.locked.contains(i)
                              ? ', hint tile'
                              : game.isComplete
                              ? ', correct'
                              : ', tap to return'}',
                    onPressed:
                        game.isComplete ||
                            game.locked.contains(i) ||
                            game.slots[i] == null
                        ? null
                        : () => _remove(i),
                  );
                  return _dropSpace(
                    i,
                    game.slots[i] == null
                        ? tile
                        : _draggable(game.slots[i]!, tile),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          game.isComplete
              ? 'All the pieces found their place.'
              : 'Tap or drag tiles to place or return them.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (!game.isComplete) ...[
          DragTarget<(String, int)>(
            onWillAcceptWithDetails: (details) =>
                details.data.$1 == game.roundId &&
                game.slots.contains(details.data.$2) &&
                !game.locked.contains(game.slots.indexOf(details.data.$2)),
            onAcceptWithDetails: (details) {
              if (details.data.$1 != game.roundId || game.isComplete) return;
              InteractionSounds.letter(context);
              _remove(game.slots.indexOf(details.data.$2));
            },
            builder: (context, candidates, rejected) => GamePanel(
              color: candidates.isEmpty
                  ? null
                  : theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: LayoutBuilder(
                builder: (context, box) {
                  final perRow = ((box.maxWidth + 10) / (tileSize + 10))
                      .floor()
                      .clamp(1, game.units.length);
                  final rows = (game.units.length / perRow).ceil();
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: rows * tileHeight + (rows - 1) * 12,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        if (game.tray.isEmpty)
                          const Text('Drop tiles here to return them'),
                        for (final id in game.tray)
                          Transform.rotate(
                            angle: id.isEven ? -.035 : .035,
                            child: _draggable(
                              id,
                              PaperLetterTile(
                                key: ValueKey('scramble-tile-$id'),
                                text: game.units[id],
                                romanization: romanizations[id],
                                size: tileSize,
                                height: tileHeight,
                                label: 'Place ${game.units[id]} tile ${id + 1}',
                                onPressed: () => _place(id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 12,
            children: [
              GameGradientButton(
                label: 'Shuffle',
                icon: const Icon(Icons.shuffle, size: 18),
                compact: true,
                prominent: false,
                onPressed: game.canShuffle ? _shuffle : null,
              ),
              GameGradientButton(
                key: const ValueKey('scramble-recall'),
                label: 'Recall tiles',
                icon: const Icon(Icons.undo_rounded, size: 18),
                compact: true,
                prominent: false,
                onPressed: game.canRecall ? _recall : null,
              ),
              GameGradientButton(
                key: const ValueKey('scramble-hint'),
                label: game.usedHint
                    ? 'Meaning revealed'
                    : 'Hint: show meaning',
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                compact: true,
                prominent: false,
                onPressed: game.hintsRemaining > 0 ? _hint : null,
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            _message,
            textAlign: TextAlign.center,
            key: const ValueKey('scramble-feedback'),
          ),
        ),
        const SizedBox(height: 12),
        GameGradientButton(
          key: const ValueKey('scramble-check'),
          label: game.isComplete ? 'Next word' : 'Check word',
          icon: const Icon(Icons.arrow_forward),
          iconTrailing: true,
          onPressed: game.isComplete
              ? (_pending == 0 ? () => _newWord() : null)
              : game.canCheck
              ? _check
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          wordsSolvedLabel(widget.repository.total.solved),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        if (_saveError != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(_saveError!)),
          TextButton(
            onPressed: InteractionSounds.buttonAction(context, () => _save()),
            child: const Text('Retry saving'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: gameBackButton(context),
      flexibleSpace: const PaperTexture(),
      toolbarHeight: gameToolbarHeight(
        context,
        identity: GameIdentity.scramble,
        subtitleText: GameLanguageHeader(
          mode: _game == null ? widget.initialMode : _mode,
          wordLength: _game?.units.length,
        ).label,
      ),
      title: GameHeading(
        identity: GameIdentity.scramble,
        compact: true,
        subtitle: GameLanguageHeader(
          mode: _game == null ? widget.initialMode : _mode,
          wordLength: _game?.units.length,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Shabad Banao menu',
          enabled: _game != null && _pending == 0,
          onOpened: () => InteractionSounds.button(context),
          onSelected: (action) {
            InteractionSounds.button(context);
            switch (action) {
              case 'new':
                _newWord();
              case 'settings':
                _settings();
              case 'help':
                showGameHelp(context, GameKind.wordScramble);
              case 'statistics':
                _statistics();
              case 'dictionary':
                context.push('/dictionary');
              case 'celebrations':
                VictoryCelebration.showSettings(context);
            }
          },
          itemBuilder: (_) => gameMenuItems(
            newGame: 'new',
            settings: 'settings',
            help: 'help',
            statistics: 'statistics',
            dictionary: 'dictionary',
            celebrations: 'celebrations',
          ),
        ),
      ],
    ),
    body: GameBackdrop(
      child: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      GameGradientButton(label: 'Try again', onPressed: _load),
                    ],
                  ),
                ),
              )
            : _game == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: _board(),
                  ),
                ),
              ),
      ),
    ),
  );
}
