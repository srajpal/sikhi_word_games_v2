import '../core/themes/game_ui.dart';
import '../core/persistence/reset_sections.dart';
import '../features/learn_letters/data/learn_letters_repository.dart';
import '../features/learn_letters/presentation/learn_letters_page.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/themes/app_theme.dart';
import '../core/widgets/victory_celebration.dart';
import '../features/word_bridges/presentation/word_bridges_page.dart';
import '../features/word_bridges/data/word_bridges_repository.dart';
import '../features/word_bridges/domain/word_bridges_content.dart';
import '../core/persistence/game_guide_repository.dart';
import '../core/widgets/game_guide.dart';
import '../core/content/vocabulary_repository.dart';
import '../features/game_library/presentation/game_library_page.dart';
import '../features/game_library/data/game_launch_preferences_repository.dart';
import '../features/guess_the_word/presentation/guess_the_word_page.dart';
import '../features/word_search/presentation/word_search_page.dart';
import '../features/word_search/data/word_search_session_repository.dart';
import '../features/word_quest/presentation/word_quest_page.dart';
import '../features/word_quest/domain/word_quest_vocabulary.dart';
import '../features/word_quest/data/word_quest_session_repository.dart';
import '../features/game_library/domain/game_launch_options.dart';
import '../features/dictionary/presentation/dictionary_page.dart';
import '../features/guess_the_word/data/guess_statistics_repository.dart';
import '../features/guess_the_word/data/guess_game_repository.dart';
import '../features/guess_the_word/data/solution_history_repository.dart';
import '../core/persistence/key_value_store.dart';
import '../features/settings/data/app_settings_repository.dart';

class SikhiWordGamesApp extends StatefulWidget {
  SikhiWordGamesApp({
    required this.settingsRepository,
    this.guideRepository,
    VocabularyRepository? vocabularyRepository,
    GuessStatisticsRepository? statisticsRepository,
    GuessGameRepository? gameRepository,
    SolutionHistoryRepository? solutionHistoryRepository,
    WordSearchSessionRepository? wordSearchSessionRepository,
    WordQuestSessionRepository? wordQuestSessionRepository,
    WordBridgesRepository? wordBridgesRepository,
    LearnLettersRepository? learnLettersRepository,
    this.wordBridgesContentFuture,
    GameLaunchPreferencesRepository? launchPreferencesRepository,
    super.key,
  }) : vocabularyRepository =
           vocabularyRepository ?? AssetVocabularyRepository(),
       statisticsRepository =
           statisticsRepository ??
           GuessStatisticsRepository(MemoryKeyValueStore()),
       gameRepository =
           gameRepository ?? GuessGameRepository(MemoryKeyValueStore()),
       solutionHistoryRepository =
           solutionHistoryRepository ??
           SolutionHistoryRepository(MemoryKeyValueStore()),
       wordSearchSessionRepository =
           wordSearchSessionRepository ??
           WordSearchSessionRepository(MemoryKeyValueStore()),
       wordQuestSessionRepository =
           wordQuestSessionRepository ??
           WordQuestSessionRepository(MemoryKeyValueStore()),
       wordBridgesRepository =
           wordBridgesRepository ??
           WordBridgesRepository(MemoryKeyValueStore()),
       learnLettersRepository =
           learnLettersRepository ??
           LearnLettersRepository(MemoryKeyValueStore()),
       launchPreferencesRepository =
           launchPreferencesRepository ??
           GameLaunchPreferencesRepository(MemoryKeyValueStore());

  final WordBridgesRepository wordBridgesRepository;
  final LearnLettersRepository learnLettersRepository;
  final Future<WordBridgesContent>? wordBridgesContentFuture;
  final AppSettingsRepository settingsRepository;
  final GameGuideRepository? guideRepository;
  final VocabularyRepository vocabularyRepository;
  final GuessStatisticsRepository statisticsRepository;
  final GuessGameRepository gameRepository;
  final SolutionHistoryRepository solutionHistoryRepository;
  final WordSearchSessionRepository wordSearchSessionRepository;
  final WordQuestSessionRepository wordQuestSessionRepository;
  final GameLaunchPreferencesRepository launchPreferencesRepository;

  @override
  State<SikhiWordGamesApp> createState() => _SikhiWordGamesAppState();
}

class _SikhiWordGamesAppState extends State<SikhiWordGamesApp> {
  late AppSettings _settings;
  late final GoRouter _router;
  Future<WordQuestVocabulary>? _wordQuestVocabularyFuture;
  Future<WordBridgesContent>? _wordBridgesContentFuture;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsRepository.load();
    _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => GameLibraryPage(
            onThemeChanged: _changeTheme,
            settings: _settings,
            onFeedbackSettingsChanged: _changeFeedbackSettings,
            guessGameRepository: widget.gameRepository,
            guessStatisticsRepository: widget.statisticsRepository,
            wordSearchSessionRepository: widget.wordSearchSessionRepository,
            wordQuestSessionRepository: widget.wordQuestSessionRepository,
            launchPreferencesRepository: widget.launchPreferencesRepository,
            wordBridgesRepository: widget.wordBridgesRepository,
            learnLettersRepository: widget.learnLettersRepository,
            loadWordBridgesContent: _wordBridgesContent,
            onResetAllData: _resetAllData,
          ),
          routes: [
            GoRoute(
              path: 'learn-letters',
              builder: (context, state) => _gameShell(
                game: GameKind.learnLetters,
                child: LearnLettersPage(
                  repository: widget.learnLettersRepository,
                  startFresh:
                      !_launchOptions(state).continueGame &&
                      state.extra is GameLaunchOptions,
                ),
              ),
            ),
            GoRoute(
              path: 'word-bridges',
              builder: (context, state) => _gameShell(
                game: GameKind.wordBridges,

                child: WordBridgesPage(
                  vocabularyRepository: widget.vocabularyRepository,
                  repository: widget.wordBridgesRepository,
                  contentFuture: _wordBridgesContent(),
                  initialMode: _launchOptions(state).language,
                  startFresh:
                      !_launchOptions(state).continueGame &&
                      state.extra is GameLaunchOptions,
                ),
              ),
            ),
            GoRoute(
              path: 'guess-the-word',
              builder: (context, state) => _gameShell(
                game: GameKind.guessTheWord,

                child: GuessTheWordPage(
                  vocabularyRepository: widget.vocabularyRepository,
                  statisticsRepository: widget.statisticsRepository,
                  gameRepository: widget.gameRepository,
                  solutionHistoryRepository: widget.solutionHistoryRepository,
                  hapticLevel: _settings.hapticLevel,
                  reducedMotion:
                      _settings.reducedMotion ||
                      MediaQuery.disableAnimationsOf(context),
                  initialMode: _launchOptions(state).language,
                  initialWordLength: _launchOptions(state).wordSize,
                  startFresh:
                      !_launchOptions(state).continueGame &&
                      state.extra is GameLaunchOptions,
                ),
              ),
            ),
            GoRoute(
              path: 'dictionary',
              builder: (context, state) => DictionaryPage(
                vocabularyRepository: widget.vocabularyRepository,
              ),
            ),
            GoRoute(
              path: 'word-search',
              builder: (context, state) => _gameShell(
                game: GameKind.wordSearch,

                child: WordSearchPage(
                  vocabularyRepository: widget.vocabularyRepository,
                  sessionRepository: widget.wordSearchSessionRepository,
                  initialMode: _launchOptions(state).language,
                  initialWordSize: _launchOptions(state).wordSize,
                  startFresh:
                      !_launchOptions(state).continueGame &&
                      state.extra is GameLaunchOptions,
                ),
              ),
            ),
            GoRoute(
              path: 'word-quest',
              builder: (context, state) => _gameShell(
                game: GameKind.wordQuest,

                child: WordQuestPage(
                  vocabularyRepository: widget.vocabularyRepository,
                  sessionRepository: widget.wordQuestSessionRepository,
                  vocabularyFuture: _wordQuestVocabulary(),
                  hapticLevel: _settings.hapticLevel,
                  reducedMotion:
                      _settings.reducedMotion ||
                      MediaQuery.disableAnimationsOf(context),
                  initialMode: _launchOptions(state).language,
                  initialWordSize: _launchOptions(state).wordSize,
                  startFresh:
                      !_launchOptions(state).continueGame &&
                      state.extra is GameLaunchOptions,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gameShell({required GameKind game, required Widget child}) =>
      VictoryCelebration(
        game: game,
        settings: _settings,
        onSettingsChanged: _changeFeedbackSettings,
        child: GameGuide(
          game: game,
          repository: widget.guideRepository,
          child: child,
        ),
      );
  Future<WordBridgesContent> _wordBridgesContent() =>
      _wordBridgesContentFuture ??=
          widget.wordBridgesContentFuture ??
          WordBridgesContent.load(widget.vocabularyRepository);

  Future<WordQuestVocabulary> _wordQuestVocabulary() =>
      _wordQuestVocabularyFuture ??= WordQuestVocabulary.load(
        widget.vocabularyRepository,
      );

  GameLaunchOptions _launchOptions(GoRouterState state) =>
      state.extra is GameLaunchOptions
      ? state.extra! as GameLaunchOptions
      : const GameLaunchOptions();

  Future<void> _resetAllData() async {
    // Only the library exposes reset: game routes must be closed first.
    try {
      await resetSections({
        'Bujho game': widget.gameRepository.resetAll,
        'Bujho statistics': widget.statisticsRepository.resetAll,
        'Word history': widget.solutionHistoryRepository.resetAll,
        'Word Search': widget.wordSearchSessionRepository.resetAll,
        'Word Quest': widget.wordQuestSessionRepository.resetAll,
        'Jodo': widget.wordBridgesRepository.resetAll,
        'Learn Letters': widget.learnLettersRepository.resetAll,
        'Game preferences': widget.launchPreferencesRepository.resetAll,
        if (widget.guideRepository case final guide?)
          'Tutorials': guide.resetAll,
        'Settings': widget.settingsRepository.reset,
      });
    } finally {
      if (mounted) {
        setState(() => _settings = widget.settingsRepository.load());
        _router.refresh();
      }
    }
  }

  Future<void> _changeTheme(AppThemeChoice choice) async {
    setState(() => _settings = _settings.copyWith(theme: choice));
    _router.refresh();
    await _saveSettings();
  }

  Future<void> _changeFeedbackSettings(AppSettings settings) async {
    setState(() => _settings = settings);
    _router.refresh();
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      await widget.settingsRepository.save(_settings);
    } on Object {
      if (!mounted) return;
      final context = _router.routerDelegate.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      showGameSnackBar(
        context,
        'Settings could not be saved on this device. They still apply for this session.',
      );
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Sikhi Word Games | Khalsa Game Studio',
    theme: AppThemes.forChoice(_settings.theme),
    routerConfig: _router,
  );
}
