import '../../../core/themes/studio_logo.dart';
import '../../../core/themes/studio_navigation.dart';
import '../../../core/audio/interaction_sounds.dart';
import '../../../core/themes/game_heading.dart';
import '../../learn_letters/data/learn_letters_repository.dart';
import '../../../core/widgets/game_guide.dart';
import '../../../core/themes/game_artwork.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_version.dart';
import '../../../core/studio_brand.dart';
import '../../word_bridges/data/word_bridges_repository.dart';
import '../../word_bridges/domain/word_bridges_content.dart';
import '../../guess_the_word/data/guess_statistics_repository.dart';
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
                  Text(
                    kind == GameKind.wordSearch
                        ? 'Choose a language, or let the game pick for you.'
                        : 'Choose a language and word size, or let the game pick for you.',
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
                  if (kind != GameKind.wordSearch) ...[
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
                  ],
                  if (kind != GameKind.wordSearch &&
                      selectedLanguage == LanguageMode.gurmukhi.name &&
                      selectedWordSize == '6') ...[
                    const SizedBox(height: 12),
                    const Text(gurmukhiVarietyNote),
                  ],
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
                        wordSize:
                            kind == GameKind.wordSearch ||
                                selectedWordSize == 'random'
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
      await _saveLaunchPreferences(context, kind, options);
      if (!context.mounted) return;
      context.push(_pathFor(kind), extra: options);
    }
  }

  Future<void> _saveLaunchPreferences(
    BuildContext context,
    GameKind kind,
    GameLaunchOptions options,
  ) async {
    try {
      await launchPreferencesRepository.save(kind, options);
    } on Object {
      if (!context.mounted) return;
      showGameSnackBar(
        context,
        'Game options could not be saved on this device. You can still play.',
      );
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

  String _gameName(GameKind game) => GameIdentity.forGame(game).fullName;

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
    await _saveLaunchPreferences(context, GameKind.wordBridges, options);
    if (context.mounted) context.push('/word-bridges', extra: options);
  }

  void _showFeedbackSettings(BuildContext context) => context.push('/settings');
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTheme = theme.extension<GameThemeTokens>()!.sikhiStyle
        ? AppThemeChoice.sikhi
        : theme.brightness == Brightness.dark
        ? AppThemeChoice.dark
        : AppThemeChoice.modern;
    return Scaffold(
      bottomNavigationBar: const StudioNavigation(
        destination: StudioDestination.play,
      ),
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(28) * 2 + 24,
        flexibleSpace: const PaperTexture(),
        title: const StudioLogo(),
        actions: [
          IconButton(
            tooltip: 'App settings',
            onPressed: InteractionSounds.buttonAction(
              context,
              () => _showFeedbackSettings(context),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          PopupMenuButton<AppThemeChoice>(
            onOpened: () => InteractionSounds.button(context),
            key: const ValueKey('app-theme-menu'),
            tooltip: 'Choose app theme',
            initialValue: activeTheme,
            onSelected: InteractionSounds.buttonChange(context, onThemeChanged),
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
                    'PLAY  ·  LEARN  ·  GROW',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns =
                          constraints.maxWidth >= 600 &&
                          MediaQuery.textScalerOf(context).scale(14) <= 21;
                      final cardWidth = twoColumns
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      final cards = <Widget>[
                        _GameCard(
                          grid: twoColumns,
                          featured: true,
                          description:
                              'Figure out the word, one guess at a time.',
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
                          grid: twoColumns,
                          description: 'Find hidden words in a sea of letters.',
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
                          grid: twoColumns,
                          description: 'Follow the clues. Find the word.',
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
                          grid: twoColumns,
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
                          grid: twoColumns,
                          description: 'Explore Gurmukhi letters step by step.',
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
                          SizedBox(
                            width: constraints.maxWidth,
                            child: cards.first,
                          ),
                          for (final card in cards.skip(1))
                            SizedBox(width: cardWidth, child: card),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const StudioWebsiteLink(),
                  const SizedBox(height: 20),
                  Text(
                    'Offline dictionary: Wiktionary contributors and wordfreq, '
                    'CC BY-SA 4.0. Full credits in Dictionary, under Sources.',
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
    this.featured = false,
    this.grid = false,
    required this.description,
    required this.gameKind,
    this.hasActiveGame = false,
    this.onContinue,
    this.onNewGame,
    this.onNewGameOptions,
  });

  final bool featured;
  final bool grid;
  final String description;
  final GameKind gameKind;
  final bool hasActiveGame;
  final VoidCallback? onContinue;
  final VoidCallback? onNewGame;
  final VoidCallback? onNewGameOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identity = GameIdentity.forGame(gameKind);
    final hasContinue = hasActiveGame && onContinue != null;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
    final scenic = (featured || grid) && !largeText;
    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameHeading(
          identity: identity,
          prominent: featured,
          titleSize: !grid && !featured && !largeText ? 22 : null,
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: !grid && !featured && !largeText
              ? theme.textTheme.bodySmall
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
    final actions = LayoutBuilder(
      builder: (context, constraints) {
        final primary = GameGradientButton(
          key: ValueKey(
            '${hasContinue ? 'continue' : 'new'}-game-${gameKind.name}',
          ),
          label: hasContinue ? 'Continue' : 'Play ${identity.punjabiName}',
          compact: true,
          iconTrailing: true,
          semanticLabel: hasContinue
              ? 'Continue ${identity.punjabiName}'
              : 'New game, Play ${identity.punjabiName}',
          onPressed: hasContinue ? onContinue : onNewGame,
          icon: hasContinue ? null : const Icon(Icons.arrow_forward, size: 18),
        );
        final secondary = hasContinue
            ? GameGradientButton(
                key: ValueKey('new-game-${gameKind.name}'),
                label: 'New game',
                compact: true,
                prominent: false,
                onPressed: onNewGame,
              )
            : null;
        final options = IconButton.filledTonal(
          tooltip: gameKind == GameKind.learnLetters
              ? 'How to play'
              : 'New game options',
          onPressed: InteractionSounds.buttonAction(context, onNewGameOptions),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
          ),
          icon: Icon(
            gameKind == GameKind.learnLetters
                ? Icons.help_outline
                : Icons.tune_rounded,
            size: 20,
          ),
        );
        final allFit = constraints.maxWidth >= 238 && !largeText;
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
    );
    return Semantics(
      key: ValueKey('game-card-semantics-${gameKind.name}'),
      container: true,
      explicitChildNodes: true,
      sortKey: OrdinalSortKey(gameKind.index.toDouble()),
      child: FocusTraversalGroup(
        child: GamePanel(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: theme.extension<GameThemeTokens>()!.panelRadius,
            child: scenic
                ? Stack(
                    children: [
                      Positioned.fill(child: GameScene(kind: identity.artwork)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) => Align(
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: featured
                                      ? (constraints.maxWidth >= 550
                                            ? 230
                                            : 174)
                                      : constraints.maxWidth * .59,
                                  child: PaperLabel(
                                    padding: const EdgeInsets.all(14),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: grid && !featured ? 138 : 0,
                                      ),
                                      child: copy,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: featured ? (grid ? 74 : 62) : 26),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: featured && grid ? 350 : 500,
                                ),
                                child: actions,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: !largeText && !featured && !hasContinue
                        ? Row(
                            children: [
                              GameArtwork(kind: identity.artwork, size: 80),
                              const SizedBox(width: 12),
                              Expanded(child: copy),
                              const SizedBox(width: 4),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: ValueKey('new-game-${gameKind.name}'),
                                    tooltip:
                                        'New game, Play ${identity.punjabiName}',
                                    onPressed: onNewGame,
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                  IconButton(
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
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GameArtwork(
                                    kind: identity.artwork,
                                    size: largeText ? 64 : 92,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: copy),
                                ],
                              ),
                              const SizedBox(height: 12),
                              actions,
                            ],
                          ),
                  ),
          ),
        ),
      ),
    );
  }
}
