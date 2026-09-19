import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/content/vocabulary_repository.dart';
import '../../../core/themes/game_ui.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/themes/game_artwork.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/widgets/victory_celebration.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../data/word_bridges_repository.dart';
import '../domain/word_bridges_content.dart';
import '../domain/word_bridges_game.dart';

class WordBridgesPage extends StatefulWidget {
  const WordBridgesPage({
    required this.vocabularyRepository,
    required this.repository,
    this.contentFuture,
    this.initialMode,
    this.startFresh = false,
    super.key,
  });

  final VocabularyRepository vocabularyRepository;
  final WordBridgesRepository repository;
  final Future<WordBridgesContent>? contentFuture;
  final LanguageMode? initialMode;
  final bool startFresh;

  @override
  State<WordBridgesPage> createState() => _WordBridgesPageState();
}

class _WordBridgesPageState extends State<WordBridgesPage> {
  final _random = Random();
  WordBridgesContent? _content;
  WordBridgesGame? _game;
  LanguageMode _mode = LanguageMode.english;
  String _message = 'Choose a word and its meaning, in either order.';
  String? _error;
  String? _saveError;
  int _pendingSaves = 0;
  bool get _busy => _pendingSaves > 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final content =
          await (widget.contentFuture ??
              WordBridgesContent.load(widget.vocabularyRepository));
      if (!mounted) return;
      _content = content;
      if (content.availableModes.isEmpty) {
        setState(
          () => _error =
              'No matching sets are available in the offline word list.',
        );
        return;
      }
      final restored = widget.startFresh ? null : widget.repository.restore();
      if (restored != null && _canRestore(restored)) {
        setState(() {
          _mode = restored.mode;
          _game = restored.game;
          _message = restored.game.isComplete
              ? 'All four pairs matched! Choose New set to play again.'
              : 'Your set is saved. Choose a word and its meaning.';
        });
        await _save();
        return;
      }
      final requested =
          widget.initialMode ??
          restored?.mode ??
          (widget.startFresh
              ? content.availableModes[_random.nextInt(
                  content.availableModes.length,
                )]
              : LanguageMode.english);
      _mode = content.availableModes.contains(requested)
          ? requested
          : content.availableModes.first;
      await _newSet();
    } on Object {
      if (mounted) {
        setState(() => _error = 'Unable to load Jodo. Please try again.');
      }
    }
  }

  bool _canRestore(WordBridgesSession session) => _content!
      .decksFor(session.mode)
      .any(
        (deck) =>
            deck.pairs.length == session.game.wordOrder.length &&
            session.game.wordOrder.every(
              (saved) => deck.pairs.any(
                (pair) =>
                    pair.id == saved.id &&
                    pair.word == saved.word &&
                    pair.meaning == saved.meaning,
              ),
            ),
      );

  Future<void> _newSet({LanguageMode? mode}) async {
    if (_busy || !mounted) return;
    VictoryCelebration.stop(context);
    final nextMode = mode ?? _mode;
    final decks = _content!.decksFor(nextMode);
    if (decks.isEmpty) return;
    final previousIds = _game?.wordOrder.map((p) => p.id).toSet();
    final alternatives = decks
        .where(
          (deck) =>
              previousIds == null ||
              !deck.pairs.every((p) => previousIds.contains(p.id)),
        )
        .toList();
    final choices = alternatives.isEmpty ? decks : alternatives;
    setState(() {
      _mode = nextMode;
      _game = WordBridgesGame(
        pairs: choices[_random.nextInt(choices.length)].pairs,
      );
      _error = null;
      _message = 'Choose a word and its meaning, in either order.';
    });
    await _save();
  }

  Future<void> _save() async {
    final game = _game!;
    setState(() => _pendingSaves++);
    try {
      await widget.repository.save(mode: _mode, game: game);
      if (mounted) setState(() => _saveError = null);
    } on Object {
      if (mounted) {
        setState(
          () => _saveError = 'Progress could not be saved on this device. You can keep playing.',
        );
      }
    } finally {
      if (mounted) setState(() => _pendingSaves--);
    }
  }

  Future<void> _select(BridgePair pair, bool word) async {
    final game = _game!;
    final result = word
        ? game.selectWord(pair.id)
        : game.selectMeaning(pair.id);
    if (result == BridgeSelectionResult.ignored) return;
    setState(() {
      _message = switch (result) {
        BridgeSelectionResult.selected =>
          '${word ? pair.word : pair.meaning} selected. Choose ${word ? 'its meaning' : 'the matching word'}.',
        BridgeSelectionResult.cleared =>
          'Selection cleared. Choose a word or meaning.',
        BridgeSelectionResult.matched =>
          game.isComplete
              ? 'All four pairs matched in ${game.attempts} attempts! Choose New set to play again.'
              : 'Matched: ${pair.word} means ${pair.meaning}.',
        BridgeSelectionResult.mismatched =>
          'These do not match. Both selections cleared. Try another pair.',
        BridgeSelectionResult.ignored => _message,
      };
    });
    if (result == BridgeSelectionResult.matched && game.isComplete) {
      VictoryCelebration.celebrate(context);
    }
    await _save();
  }

  void _statistics() {
    final current = widget.repository.forMode(_mode);
    final total = widget.repository.total;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jodo statistics'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mode.label, style: Theme.of(context).textTheme.titleMedium),
            Text('Finished sets: ${current.finishedSets}'),
            Text('Pairs matched: ${current.pairsMatched}'),
            Text('Match attempts: ${current.attempts}'),
            const SizedBox(height: 16),
            Text(
              'All languages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Finished sets: ${total.finishedSets}'),
            Text('Pairs matched: ${total.pairsMatched}'),
            Text('Match attempts: ${total.attempts}'),
            const SizedBox(height: 12),
            const Text(
              'Only finished sets count. Each word and meaning you try together counts as one attempt. There is no timer or losing score. Saved on this device.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _card(BridgePair pair, bool word) {
    final game = _game!;
    final matched = game.matchedIds.contains(pair.id);
    final selected =
        (word ? game.selectedWordId : game.selectedMeaningId) == pair.id;
    final text = word ? pair.word : pair.meaning;
    final romanized = word && _mode == LanguageMode.gurmukhi
        ? _content!.romanizedFor(pair.id)
        : null;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = theme.extension<GameThemeTokens>()!;
    final background = matched
        ? Color.alphaBlend(
            tokens.correct.withValues(alpha: .15),
            colors.surface,
          )
        : selected
        ? colors.primaryContainer
        : colors.surface;
    final foreground = selected ? colors.onPrimaryContainer : colors.onSurface;
    final state = matched
        ? 'Matched'
        : selected
        ? 'Selected'
        : null;
    final label =
        '${word ? 'Word' : 'Meaning'}: $text${romanized == null ? '' : ', $romanized'}${state == null ? '' : ', $state'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        key: ValueKey('bridge-${word ? 'word' : 'meaning'}-${pair.id}'),
        label: label,
        button: true,
        selected: selected,
        enabled: !matched,
        onTap: matched ? null : () => _select(pair, word),
        excludeSemantics: true,
        child: OutlinedButton(
          onPressed: matched ? null : () => _select(pair, word),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 88),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: tokens.controlRadius),
            backgroundColor: background,
            disabledBackgroundColor: background,
            foregroundColor: foreground,
            side: BorderSide(
              color: matched
                  ? tokens.correct
                  : selected
                  ? colors.primary
                  : colors.outlineVariant,
              width: 2,
            ),
            disabledForegroundColor: foreground,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: word
                    ? theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      )
                    : theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        color: foreground,
                      ),
              ),
              if (romanized != null) ...[
                const SizedBox(height: 4),
                Text(
                  romanized,
                  key: ValueKey('bridge-romanized-${pair.id}'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              // Reserve the largest state label, so every card stays in place.
              Stack(
                alignment: Alignment.center,
                children: [
                  for (final reserved in ['Selected', 'Matched'])
                    Opacity(
                      opacity: 0,
                      child: _stateLabel(reserved, foreground, reserve: true),
                    ),
                  if (state != null) _stateLabel(state, foreground),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _board() => LayoutBuilder(
    builder: (context, constraints) {
      final narrow =
          constraints.maxWidth < 600 ||
          MediaQuery.textScalerOf(context).scale(14) > 21;
      Widget heading(String text) => Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text, style: Theme.of(context).textTheme.titleSmall),
        ),
      );
      if (narrow) {
        final words = _game!.wordOrder;
        return Column(
          key: const ValueKey('bridge-stacked-board'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading('Words'),
            for (var index = 0; index < words.length; index += 2)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _card(words[index], true)),
                    const SizedBox(width: 10),
                    Expanded(child: _card(words[index + 1], true)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            heading('Meanings'),
            for (final pair in _game!.meaningOrder) _card(pair, false),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: heading('Words')),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: heading('Meanings')),
            ],
          ),
          for (var index = 0; index < 4; index++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _card(_game!.wordOrder[index], true)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _card(_game!.meaningOrder[index], false),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );

  Widget _prompt() {
    const messages = [
      'Choose a word or meaning.',
      'Choose the matching meaning.',
      'Choose the matching word.',
      'Not a match. Try another pair.',
      'All four pairs connected!',
    ];
    final game = _game!;
    final message = game.isComplete
        ? messages[4]
        : game.selectedWordId != null
        ? messages[1]
        : game.selectedMeaningId != null
        ? messages[2]
        : _message.startsWith('These do not match')
        ? messages[3]
        : messages[0];
    final style = Theme.of(context).textTheme.bodyMedium;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Reserve enough space for each short prompt at the current text scale.
        for (final reserved in messages)
          ExcludeSemantics(
            child: Opacity(
              opacity: 0,
              child: RichText(
                textScaler: MediaQuery.textScalerOf(context),
                text: TextSpan(text: reserved, style: style),
              ),
            ),
          ),
        Text(message, style: style),
      ],
    );
  }

  Widget _stateLabel(String state, Color foreground, {bool reserve = false}) =>
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Icon(
            state == 'Matched'
                ? Icons.check_circle
                : Icons.radio_button_checked,
            size: 18,
            color: foreground,
          ),
          if (reserve)
            RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                text: state,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground),
              ),
            )
          else
            Text(
              state,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Jodo'),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Jodo menu',
          onSelected: (action) {
            if (action == 'help') showGameHelp(context, GameKind.wordBridges);
            if (action == 'statistics') _statistics();
            if (action == 'celebrations') {
              VictoryCelebration.showSettings(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'help', child: Text('How to play')),
            PopupMenuItem(value: 'statistics', child: Text('Statistics')),
            PopupMenuItem(
              value: 'celebrations',
              child: Text('Celebration settings'),
            ),
          ],
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
                      const SizedBox(height: 12),
                      GameGradientButton(
                        label: 'Try again',
                        onPressed: () {
                          setState(() => _error = null);
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
              )
            : _game == null
            ? const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading Jodo',
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const GameArtwork(
                              kind: GameArtworkKind.bridges,
                              size: 44,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ਜੋੜੋ · Word Bridges',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PopupMenuButton<LanguageMode>(
                              tooltip: 'Change language',
                              enabled: !_busy,
                              onSelected: (mode) => _newSet(mode: mode),
                              itemBuilder: (_) => [
                                for (final mode in _content!.availableModes)
                                  PopupMenuItem(
                                    value: mode,
                                    child: Text(mode.label),
                                  ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text('Language: ${_mode.label}'),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                            GameGradientButton(
                              label: 'New set',
                              onPressed: _busy ? null : _newSet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GamePanel(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${_game!.matchedIds.length} of 4 pairs matched · ${_game!.attempts} ${_game!.attempts == 1 ? 'attempt' : 'attempts'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ExcludeSemantics(
                                child: Row(
                                  children: [
                                    for (var index = 0; index < 4; index++)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: index < 3 ? 6 : 0,
                                          ),
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color:
                                                  index <
                                                      _game!.matchedIds.length
                                                  ? Theme.of(context)
                                                        .extension<
                                                          GameThemeTokens
                                                        >()!
                                                        .correct
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _prompt(),
                              if (_saveError != null) ...[
                                const SizedBox(height: 8),
                                Text(_saveError!),
                                TextButton(
                                  onPressed: _pendingSaves > 0 ? null : _save,
                                  child: const Text('Retry saving'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _board(),
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(_message, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Untimed. Try as often as you like. Selecting an item again clears it.',
                          textAlign: TextAlign.center,
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
