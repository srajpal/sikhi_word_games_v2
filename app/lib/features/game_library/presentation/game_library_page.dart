import '../../learn_letters/data/learn_letters_repository.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/themes/game_artwork.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_version.dart';
import '../../../core/studio_brand.dart';
import '../../../core/widgets/reset_app_data_dialog.dart';
import '../../word_bridges/data/word_bridges_repository.dart';
import '../../word_bridges/domain/word_bridges_content.dart';
import '../../guess_the_word/data/guess_statistics_repository.dart';
import '../../guess_the_word/domain/guess_statistics.dart';
import 'library_statistics.dart';
import '../../../core/release_feedback.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/themes/game_ui.dart';
import '../data/game_launch_preferences_repository.dart';
import '../../guess_the_word/data/guess_game_repository.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../domain/game_launch_options.dart';
import '../../word_search/data/word_search_session_repository.dart';
import '../../word_quest/data/word_quest_session_repository.dart';
import '../../settings/data/app_settings_repository.dart';

class GameLibraryPage extends StatelessWidget {
  const GameLibraryPage({
    required this.onThemeChanged,
    required this.settings,
    required this.onFeedbackSettingsChanged,
    required this.guessGameRepository,
    required this.wordSearchSessionRepository,
    required this.wordQuestSessionRepository,
    required this.launchPreferencesRepository,
    this.guessStatisticsRepository,
    this.wordBridgesRepository,
    this.learnLettersRepository,
    this.loadWordBridgesContent,
    this.onResetAllData,
    super.key,
  });

  final ValueChanged<AppThemeChoice> onThemeChanged;
  final AppSettings settings;
  final ValueChanged<AppSettings> onFeedbackSettingsChanged;
  final GuessGameRepository guessGameRepository;
  final WordSearchSessionRepository wordSearchSessionRepository;
  final WordQuestSessionRepository wordQuestSessionRepository;
  final GameLaunchPreferencesRepository launchPreferencesRepository;
  final GuessStatisticsRepository? guessStatisticsRepository;
  final WordBridgesRepository? wordBridgesRepository;
  final LearnLettersRepository? learnLettersRepository;
  final Future<WordBridgesContent> Function()? loadWordBridgesContent;
  final Future<void> Function()? onResetAllData;

  bool _hasActiveGame(GameKind kind) => switch (kind) {
    GameKind.guessTheWord => guessGameRepository.hasActiveGame,
    GameKind.wordSearch => wordSearchSessionRepository.hasActiveGame,
    GameKind.wordQuest => wordQuestSessionRepository.hasActiveGame,
    GameKind.wordBridges => wordBridgesRepository?.hasActiveGame ?? false,
    GameKind.learnLetters => learnLettersRepository?.hasActiveGame ?? false,
  };

  String _pathFor(GameKind kind) => switch (kind) {
    GameKind.guessTheWord => '/guess-the-word',
    GameKind.wordSearch => '/word-search',
    GameKind.wordQuest => '/word-quest',
    GameKind.wordBridges => '/word-bridges',
    GameKind.learnLetters => '/learn-letters',
  };

  Future<void> _showNewGameOptions(BuildContext context, GameKind kind) async {
    if (kind == GameKind.wordBridges) {
      await _showBridgesOptions(context);
      return;
    }
    final saved = launchPreferencesRepository.load(kind);
    var selectedLanguage = saved.language?.name ?? 'random';
    var selectedWordSize = saved.wordSize?.toString() ?? 'random';
    final options = await showModalBottomSheet<GameLaunchOptions>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New ${_gameName(kind)} game',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a language and word size, or let the game pick for you.',
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLanguage,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: [
                      const DropdownMenuItem(
                        value: 'random',
                        child: Text('Random language'),
                      ),
                      for (final mode in LanguageMode.values)
                        DropdownMenuItem(
                          value: mode.name,
                          child: Text(mode.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedLanguage = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedWordSize,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Word size'),
                    items: const [
                      DropdownMenuItem(
                        value: 'random',
                        child: Text('Random size'),
                      ),
                      DropdownMenuItem(value: '4', child: Text('4 letters')),
                      DropdownMenuItem(value: '5', child: Text('5 letters')),
                      DropdownMenuItem(value: '6', child: Text('6 letters')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedWordSize = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  GameGradientButton(
                    label: 'Start new game',
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => Navigator.pop(
                      context,
                      GameLaunchOptions(
                        language: selectedLanguage == 'random'
                            ? null
                            : LanguageMode.values.byName(selectedLanguage),
                        wordSize: selectedWordSize == 'random'
                            ? null
                            : int.parse(selectedWordSize),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (options != null && context.mounted) {
      await launchPreferencesRepository.save(kind, options);
      if (!context.mounted) return;
      context.push(_pathFor(kind), extra: options);
    }
  }

  void _continueGame(BuildContext context, GameKind kind) {
    context.push(
      _pathFor(kind),
      extra: const GameLaunchOptions(continueGame: true),
    );
  }

  void _startNewGame(BuildContext context, GameKind kind) {
    context.push(
      _pathFor(kind),
      extra: launchPreferencesRepository.load(kind).options,
    );
  }

  String _gameName(GameKind kind) => switch (kind) {
    GameKind.guessTheWord => 'Bujho: Guess the Word',
    GameKind.wordSearch => 'Khoj: Word Search',
    GameKind.wordQuest => 'Word Quest',
    GameKind.wordBridges => 'Jodo: Word Bridges',
    GameKind.learnLetters => 'Akhar Pachhaan: Learn Letters',
  };

  Future<void> _showBridgesOptions(BuildContext context) async {
    final loader = loadWordBridgesContent;
    if (loader == null) return;
    late WordBridgesContent content;
    try {
      content = await loader();
    } on Object catch (_) {
      if (context.mounted) {
        showGameSnackBar(
          context,
          'Unable to load matching sets. Please try again.',
        );
      }
      return;
    }
    if (!context.mounted) return;
    final modes = content.availableModes;
    if (modes.isEmpty) {
      showGameSnackBar(context, 'No matching sets are available.');
      return;
    }
    final saved = launchPreferencesRepository
        .load(GameKind.wordBridges)
        .language;
    var selected = saved == null
        ? 'random'
        : modes.contains(saved)
        ? saved.name
        : modes.first.name;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('New Jodo set'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Match four words to their English meanings. Sets include different word lengths.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Language'),
                items: [
                  const DropdownMenuItem(
                    value: 'random',
                    child: Text('Random language'),
                  ),
                  for (final mode in modes)
                    DropdownMenuItem(value: mode.name, child: Text(mode.label)),
                ],
                onChanged: (value) {
                  if (value != null) update(() => selected = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Start new set'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final options = GameLaunchOptions(
      language: result == 'random' ? null : LanguageMode.values.byName(result),
    );
    await launchPreferencesRepository.save(GameKind.wordBridges, options);
    if (context.mounted) context.push('/word-bridges', extra: options);
  }

  Future<void> _showFeedbackSettings(BuildContext context) async {
    var resetRequested = false;
    var statisticsRequested = false;
    var hapticLevel = settings.hapticLevel;
    var reducedMotion = settings.reducedMotion;
    var celebrationSettings = settings;
    final updated = await showDialog<AppSettings>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('App settings'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<HapticFeedbackLevel>(
                initialValue: hapticLevel,
                decoration: const InputDecoration(
                  labelText: 'Haptic feedback',
                  helperText: 'Strength for keys, guesses, and errors',
                ),
                items: [
                  for (final level in HapticFeedbackLevel.values)
                    DropdownMenuItem(value: level, child: Text(level.label)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => hapticLevel = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Use your device display settings for larger or bold text. '
                'Screen-reader controls and letter feedback work without color. '
                'Your device reduce-motion setting is also respected.',
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Reduce motion'),
                subtitle: const Text('Minimize tile and interface animation'),
                value: reducedMotion,
                onChanged: (value) =>
                    setDialogState(() => reducedMotion = value),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Victory sound'),
                subtitle: const Text('Play a short fanfare when you win'),
                value: celebrationSettings.victorySound,
                onChanged: (value) => setDialogState(() {
                  celebrationSettings = celebrationSettings.copyWith(
                    victorySound: value,
                  );
                }),
              ),
              SwitchListTile(
                title: const Text('Victory particles'),
                subtitle: const Text(
                  'Celebrate wins with colorful bursts. Reduce motion turns these off.',
                ),
                value: celebrationSettings.victoryParticles,
                onChanged: (value) => setDialogState(() {
                  celebrationSettings = celebrationSettings.copyWith(
                    victoryParticles: value,
                  );
                }),
              ),
              ExpansionTile(
                title: const Text('Per-game celebrations'),
                subtitle: const Text(
                  'Turn off sound or particles for individual games',
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'The main switches above apply to every game. Your choices below are kept when you turn them back on.',
                    ),
                  ),
                  for (final game in GameKind.values) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        _gameName(game),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    SwitchListTile(
                      title: Text(
                        'Sound',
                        semanticsLabel: '${_gameName(game)} victory sound',
                      ),
                      key: ValueKey('victory-sound-${game.name}'),
                      value: !celebrationSettings.mutedVictoryGames.contains(
                        game.name,
                      ),
                      onChanged: (value) => setDialogState(() {
                        celebrationSettings = celebrationSettings
                            .withGameVictory(game, sound: value);
                      }),
                    ),
                    SwitchListTile(
                      title: Text(
                        'Particles',
                        semanticsLabel: '${_gameName(game)} victory particles',
                      ),
                      key: ValueKey('victory-particles-${game.name}'),
                      value: !celebrationSettings.quietVictoryGames.contains(
                        game.name,
                      ),
                      onChanged: (value) => setDialogState(() {
                        celebrationSettings = celebrationSettings
                            .withGameVictory(game, particles: value);
                      }),
                    ),
                  ],
                ],
              ),
              const Divider(),
              TextButton.icon(
                onPressed: () {
                  statisticsRequested = true;
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('Your statistics'),
              ),
              if (onResetAllData != null) ...[
                const Divider(),
                TextButton.icon(
                  onPressed: () {
                    resetRequested = true;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset all app data'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                celebrationSettings.copyWith(
                  hapticLevel: hapticLevel,
                  reducedMotion: reducedMotion,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (updated != null) onFeedbackSettingsChanged(updated);
    if (statisticsRequested && context.mounted) {
      showLibraryStatistics(
        context,
        bujho: guessStatisticsRepository?.load() ?? const GuessStatisticsBook(),
        khoj: wordSearchSessionRepository.statistics.total,
        quest: wordQuestSessionRepository.statistics.total,
        bridges: wordBridgesRepository?.total,
        letters: learnLettersRepository?.statistics,
      );
    }
    if (resetRequested && context.mounted) {
      await showResetAppDataDialog(context, onReset: onResetAllData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTheme = theme.extension<GameThemeTokens>()!.sikhiStyle
        ? AppThemeChoice.sikhi
        : theme.brightness == Brightness.dark
        ? AppThemeChoice.dark
        : AppThemeChoice.modern;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sikhi Word Games'),
        actions: [
          IconButton(
            tooltip: 'App settings',
            onPressed: () => _showFeedbackSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          PopupMenuButton<AppThemeChoice>(
            key: const ValueKey('app-theme-menu'),
            tooltip: 'Choose app theme',
            initialValue: activeTheme,
            onSelected: onThemeChanged,
            icon: const Icon(Icons.palette_outlined),
            itemBuilder: (context) => [
              for (final choice in AppThemeChoice.values)
                PopupMenuItem(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        choice == activeTheme
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      const SizedBox(width: 12),
                      Text(choice.label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: GameBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (activeTheme == AppThemeChoice.sikhi) ...[
                    Semantics(
                      label: 'Ik Onkar',
                      child: ExcludeSemantics(
                        child: Text(
                          'ੴ',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Offline word games in English, Punjabi and Gurmukhi',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by $studioName',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns =
                          constraints.maxWidth >= 720 &&
                          MediaQuery.textScalerOf(context).scale(14) <= 21;
                      final cardWidth = twoColumns
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      final cards = <Widget>[
                        _GameCard(
                          title: 'Bujho: Guess the Word',
                          description:
                              'Find the hidden word using letter clues.',
                          gameKind: GameKind.guessTheWord,
                          hasActiveGame: _hasActiveGame(GameKind.guessTheWord),
                          onContinue: () =>
                              _continueGame(context, GameKind.guessTheWord),
                          onNewGame: () =>
                              _startNewGame(context, GameKind.guessTheWord),
                          onNewGameOptions: () => _showNewGameOptions(
                            context,
                            GameKind.guessTheWord,
                          ),
                        ),
                        _GameCard(
                          title: 'Khoj: Word Search',
                          description: 'Trace hidden words in a letter grid.',
                          gameKind: GameKind.wordSearch,
                          hasActiveGame: _hasActiveGame(GameKind.wordSearch),
                          onContinue: () =>
                              _continueGame(context, GameKind.wordSearch),
                          onNewGame: () =>
                              _startNewGame(context, GameKind.wordSearch),
                          onNewGameOptions: () =>
                              _showNewGameOptions(context, GameKind.wordSearch),
                        ),
                        _GameCard(
                          title: 'Chardi Kala: Word Quest',
                          description:
                              'Use a clue and choose letters to find the word.',
                          gameKind: GameKind.wordQuest,
                          hasActiveGame: _hasActiveGame(GameKind.wordQuest),
                          onContinue: () =>
                              _continueGame(context, GameKind.wordQuest),
                          onNewGame: () =>
                              _startNewGame(context, GameKind.wordQuest),
                          onNewGameOptions: () =>
                              _showNewGameOptions(context, GameKind.wordQuest),
                        ),
                        _GameCard(
                          title: 'Jodo: Word Bridges',
                          description: 'Connect four words to their meanings.',
                          gameKind: GameKind.wordBridges,
                          hasActiveGame: _hasActiveGame(GameKind.wordBridges),
                          onContinue: () =>
                              _continueGame(context, GameKind.wordBridges),
                          onNewGame: () =>
                              _startNewGame(context, GameKind.wordBridges),
                          onNewGameOptions: () => _showBridgesOptions(context),
                        ),
                        _GameCard(
                          title: 'Akhar Pachhaan: Learn Letters',
                          description: 'Recognize Gurmukhi letters and learn their names.',
                          gameKind: GameKind.learnLetters,
                          hasActiveGame: _hasActiveGame(GameKind.learnLetters),
                          onContinue: () =>
                              _continueGame(context, GameKind.learnLetters),
                          onNewGame: () =>
                              _startNewGame(context, GameKind.learnLetters),
                          onNewGameOptions: () =>
                              showGameHelp(context, GameKind.learnLetters),
                        ),
                      ];
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final card in cards)
                            SizedBox(width: cardWidth, child: card),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const StudioWebsiteLink(),
                  const SizedBox(height: 20),
                  Text(
                    'English definition data adapted from Open English '
                    'WordNet 2025, licensed CC BY 4.0.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gurmukhi dictionary data adapted from Mahan Kosh, '
                    'licensed CC BY 4.0.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Public playtest. Words and meanings are still being reviewed.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => showReleaseFeedback(context),
                    icon: const Icon(Icons.feedback_outlined),
                    label: const Text('Share feedback'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appVersionLabel,
                    key: const ValueKey('app-version'),
                    textAlign: TextAlign.center,
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
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.description,
    required this.gameKind,
    this.hasActiveGame = false,
    this.onContinue,
    this.onNewGame,
    this.onNewGameOptions,
  });

  final String title;
  final String description;
  final GameKind gameKind;
  final bool hasActiveGame;
  final VoidCallback? onContinue;
  final VoidCallback? onNewGame;
  final VoidCallback? onNewGameOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContinue = hasActiveGame && onContinue != null;
    return Semantics(
      key: ValueKey('game-card-semantics-${gameKind.name}'),
      container: true,
      explicitChildNodes: true,
      sortKey: OrdinalSortKey(gameKind.index.toDouble()),
      child: FocusTraversalGroup(
        child: GamePanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GameArtwork(
                    kind: switch (gameKind) {
                      GameKind.guessTheWord => GameArtworkKind.deduction,
                      GameKind.wordSearch => GameArtworkKind.search,
                      GameKind.wordQuest => GameArtworkKind.garden,
                      GameKind.wordBridges => GameArtworkKind.bridges,
                      GameKind.learnLetters => GameArtworkKind.letters,
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title, style: theme.textTheme.titleLarge),
                        ),
                        const SizedBox(height: 4),
                        Text(description, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final labelStyle = theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  );
                  final actionStyle = ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    textStyle: WidgetStatePropertyAll(labelStyle),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: theme
                            .extension<GameThemeTokens>()!
                            .controlRadius,
                      ),
                    ),
                  );
                  final primary = FilledButton(
                    key: hasContinue
                        ? ValueKey('continue-game-${gameKind.name}')
                        : ValueKey('new-game-${gameKind.name}'),
                    onPressed: hasContinue ? onContinue : onNewGame,
                    style: actionStyle,
                    child: Text(
                      hasContinue ? 'Continue' : 'New game',
                      textAlign: TextAlign.center,
                    ),
                  );
                  final secondary = hasContinue
                      ? OutlinedButton(
                          key: ValueKey('new-game-${gameKind.name}'),
                          onPressed: onNewGame,
                          style: actionStyle,
                          child: const Text(
                            'New game',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : null;
                  final options = IconButton.outlined(
                    tooltip: gameKind == GameKind.learnLetters
                        ? 'How to play'
                        : 'New game options',
                    onPressed: onNewGameOptions,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    icon: Icon(
                      gameKind == GameKind.learnLetters
                          ? Icons.help_outline
                          : Icons.tune_rounded,
                    ),
                  );
                  double labelWidth(String text) {
                    final painter = TextPainter(
                      text: TextSpan(text: text, style: labelStyle),
                      textScaler: MediaQuery.textScalerOf(context),
                      textDirection: Directionality.of(context),
                    )..layout();
                    final width = painter.width;
                    painter.dispose();
                    return width;
                  }

                  // Preserve one row on small phones, but let enlarged labels
                  // move the secondary action below instead of shrinking text.
                  final widestLabel =
                      labelWidth('Continue') > labelWidth('New game')
                      ? labelWidth('Continue')
                      : labelWidth('New game');
                  final allFit =
                      constraints.maxWidth >= (widestLabel + 16) * 2 + 64;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: primary),
                          if (secondary != null && allFit) ...[
                            const SizedBox(width: 8),
                            Expanded(child: secondary),
                          ],
                          const SizedBox(width: 8),
                          options,
                        ],
                      ),
                      if (secondary != null && !allFit) ...[
                        const SizedBox(height: 8),
                        secondary,
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
