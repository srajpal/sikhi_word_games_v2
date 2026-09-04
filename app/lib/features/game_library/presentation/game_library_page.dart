import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    super.key,
  });

  final ValueChanged<AppThemeChoice> onThemeChanged;
  final AppSettings settings;
  final ValueChanged<AppSettings> onFeedbackSettingsChanged;
  final GuessGameRepository guessGameRepository;
  final WordSearchSessionRepository wordSearchSessionRepository;
  final WordQuestSessionRepository wordQuestSessionRepository;
  final GameLaunchPreferencesRepository launchPreferencesRepository;

  bool _hasActiveGame(GameKind kind) => switch (kind) {
    GameKind.guessTheWord => guessGameRepository.hasActiveGame,
    GameKind.wordSearch => wordSearchSessionRepository.hasActiveGame,
    GameKind.wordQuest => wordQuestSessionRepository.hasActiveGame,
  };

  String _pathFor(GameKind kind) => switch (kind) {
    GameKind.guessTheWord => '/guess-the-word',
    GameKind.wordSearch => '/word-search',
    GameKind.wordQuest => '/word-quest',
  };

  Future<void> _showNewGameOptions(BuildContext context, GameKind kind) async {
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
  };

  Future<void> _showFeedbackSettings(BuildContext context) async {
    var hapticLevel = settings.hapticLevel;
    var reducedMotion = settings.reducedMotion;
    final updated = await showDialog<AppSettings>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Feedback settings'),
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
              SwitchListTile(
                title: const Text('Reduce motion'),
                subtitle: const Text('Minimize tile and interface animation'),
                value: reducedMotion,
                onChanged: (value) =>
                    setDialogState(() => reducedMotion = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                settings.copyWith(
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
            tooltip: 'Feedback settings',
            onPressed: () => _showFeedbackSettings(context),
            icon: const Icon(Icons.accessibility_new),
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
                padding: const EdgeInsets.all(24),
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
                                color: const Color(0xFFE28A16),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  GamePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose a game',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose your path • learn, play, and grow',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Play offline in English, romanized Punjabi, and Gurmukhi.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _GameCard(
                    icon: Icons.grid_view_rounded,
                    title: 'Bujho: Guess the Word',
                    description: 'Find the hidden word using colored clues.',
                    gameKind: GameKind.guessTheWord,
                    hasActiveGame: _hasActiveGame(GameKind.guessTheWord),
                    onContinue: () =>
                        _continueGame(context, GameKind.guessTheWord),
                    onNewGame: () =>
                        _startNewGame(context, GameKind.guessTheWord),
                    onNewGameOptions: () =>
                        _showNewGameOptions(context, GameKind.guessTheWord),
                  ),
                  const SizedBox(height: 16),
                  _GameCard(
                    icon: Icons.search_rounded,
                    title: 'Khoj: Word Search',
                    description: 'Find offline words hidden in a letter grid.',
                    gameKind: GameKind.wordSearch,
                    hasActiveGame: _hasActiveGame(GameKind.wordSearch),
                    onContinue: () =>
                        _continueGame(context, GameKind.wordSearch),
                    onNewGame: () =>
                        _startNewGame(context, GameKind.wordSearch),
                    onNewGameOptions: () =>
                        _showNewGameOptions(context, GameKind.wordSearch),
                  ),
                  const SizedBox(height: 16),
                  _GameCard(
                    icon: Icons.local_florist_outlined,
                    title: 'Chardi Kala: Word Quest',
                    description: 'A gentle letter game for kids—uncover a word and help a garden grow.',
                    gameKind: GameKind.wordQuest,
                    hasActiveGame: _hasActiveGame(GameKind.wordQuest),
                    onContinue: () =>
                        _continueGame(context, GameKind.wordQuest),
                    onNewGame: () => _startNewGame(context, GameKind.wordQuest),
                    onNewGameOptions: () =>
                        _showNewGameOptions(context, GameKind.wordQuest),
                  ),
                  const SizedBox(height: 16),
                  const _GameCard(
                    icon: Icons.keyboard_rounded,
                    title: 'Typing Challenge',
                    description: 'Practice accurate English, Punjabi, and Gurmukhi typing.',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'English definition data adapted from Open English '
                    'WordNet 2025, licensed CC BY 4.0.',
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
    required this.icon,
    required this.title,
    required this.description,
    this.gameKind,
    this.hasActiveGame = false,
    this.onContinue,
    this.onNewGame,
    this.onNewGameOptions,
  });

  final IconData icon;
  final String title;
  final String description;
  final GameKind? gameKind;
  final bool hasActiveGame;
  final VoidCallback? onContinue;
  final VoidCallback? onNewGame;
  final VoidCallback? onNewGameOptions;

  @override
  Widget build(BuildContext context) => GamePanel(
    padding: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Builder(
        builder: (context) {
          final details = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: Theme.of(context)
                      .extension<GameThemeTokens>()!
                      .elevationShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 34,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
            ],
          );
          final actionButtons = <Widget>[
            if (hasActiveGame && onContinue != null)
              GameGradientButton(
                onPressed: onContinue,
                label: 'Continue game',
                icon: const Icon(Icons.play_arrow),
              ),
            if (onNewGame != null)
              GameGradientButton(
                onPressed: onNewGame,
                label: 'New game',
                icon: const Icon(Icons.play_arrow),
              ),
            if (onNewGameOptions != null)
              GameGradientButton(
                onPressed: onNewGameOptions,
                label: 'New game options',
                icon: const Icon(Icons.tune),
              ),
            if (gameKind == null)
              const GameGradientButton(label: 'Coming later'),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              const SizedBox(height: 18),
              for (final action in actionButtons) ...[
                SizedBox(width: double.infinity, child: action),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    ),
  );
}
