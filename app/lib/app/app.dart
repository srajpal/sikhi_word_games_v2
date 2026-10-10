import '../features/achievements/domain/player_progress.dart';

import 'dart:async';

import '../features/achievements/presentation/achievement_feedback.dart';
import '../features/achievements/presentation/achievements_page.dart';
import '../features/game_library/presentation/progress_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../core/themes/game_ui.dart';
import '../core/audio/interaction_sounds.dart';
import '../core/persistence/reset_sections.dart';
import '../features/learn_letters/data/learn_letters_repository.dart';
import '../features/learn_letters/presentation/learn_letters_page.dart';
import '../features/word_scramble/data/word_scramble_repository.dart';
import '../features/word_scramble/presentation/word_scramble_page.dart';

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
    WordScrambleRepository? wordScrambleRepository,
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
       wordScrambleRepository =
           wordScrambleRepository ??
           WordScrambleRepository(MemoryKeyValueStore()),
       launchPreferencesRepository =
           launchPreferencesRepository ??
           GameLaunchPreferencesRepository(MemoryKeyValueStore());

  final WordBridgesRepository wordBridgesRepository;
  final LearnLettersRepository learnLettersRepository;
  final WordScrambleRepository wordScrambleRepository;
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
    // Decode the bundled dictionary while the player is on Play, rather than
    // making the first game tap wait for the asset download/isolate startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.vocabularyRepository is AssetVocabularyRepository) {
        unawaited(
          widget.vocabularyRepository.load().then<void>(
            (_) {},
            onError: (Object error, StackTrace stack) {},
          ),
        );
      }
    });
    _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _page(
            context,
            state,
            GameLibraryPage(
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
              wordScrambleRepository: widget.wordScrambleRepository,
              loadWordBridgesContent: _wordBridgesContent,
              onResetAllData: _resetAllData,
            ),
          ),
          routes: [
            GoRoute(
              path: 'word-scramble',
              pageBuilder: (context, state) => _page(
                context,
                state,
                _gameShell(
                  game: GameKind.wordScramble,
                  child: WordScramblePage(
                    vocabularyRepository: widget.vocabularyRepository,
                    repository: widget.wordScrambleRepository,
                    simpleRomanized: _settings.simpleRomanizedPunjabi,
                    initialMode: _launchOptions(state).language,
                    startFresh:
                        !_launchOptions(state).continueGame &&
                        state.extra is GameLaunchOptions,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: 'learn-letters',
              pageBuilder: (context, state) => _page(
                context,
                state,
                _gameShell(
                  game: GameKind.learnLetters,
                  child: LearnLettersPage(
                    repository: widget.learnLettersRepository,
                    initialPracticeMode: _launchOptions(state)
                        .letterPracticeMode,
                    startFresh:
                        !_launchOptions(state).continueGame &&
                        state.extra is GameLaunchOptions,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: 'word-bridges',
              pageBuilder: (context, state) => _page(
                context,
                state,
                _gameShell(
                  game: GameKind.wordBridges,

                  child: WordBridgesPage(
                    simpleRomanized: _settings.simpleRomanizedPunjabi,
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
            ),
            GoRoute(
              path: 'guess-the-word',
              pageBuilder: (context, state) => _page(
                context,
                state,
                _gameShell(
                  game: GameKind.guessTheWord,

                  child: GuessTheWordPage(
                    simpleRomanized: _settings.simpleRomanizedPunjabi,
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
            ),
            GoRoute(
              path: 'settings',
              pageBuilder: (context, state) => _page(
                context,
                state,
                SettingsPage(
                  settings: _settings,
                  onChanged: _changeFeedbackSettings,
                  onResetAllData: _resetAllData,
                ),
              ),
            ),
            GoRoute(
              path: 'progress',
              pageBuilder: (context, state) =>
                  _page(context, state, ProgressPage(progress: _progress())),
            ),
            GoRoute(
              path: 'achievements',
              pageBuilder: (context, state) => _page(
                context,
                state,
                AchievementsPage(progress: _progress()),
              ),
            ),
            GoRoute(
              path: 'dictionary',
              pageBuilder: (context, state) => _page(
                context,
                state,
                DictionaryPage(
                  key: ValueKey(_settings.simpleRomanizedPunjabi),
                  simpleRomanized: _settings.simpleRomanizedPunjabi,
                  vocabularyRepository: widget.vocabularyRepository,
                ),
              ),
            ),
            GoRoute(
              path: 'word-search',
              pageBuilder: (context, state) => _page(
                context,
                state,
                _gameShell(
                  game: GameKind.wordSearch,

                  child: WordSearchPage(
                    simpleRomanized: _settings.simpleRomanizedPunjabi,
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
            ),
            GoRoute(
              path: 'word-quest',
              pageBuilder: (context, state) => _page(
                context,
                state,
                _gameShell(
                  game: GameKind.wordQuest,

                  child: WordQuestPage(
                    simpleRomanized: _settings.simpleRomanizedPunjabi,
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
            ),
          ],
        ),
      ],
    );
  }

  CustomTransitionPage<void> _page(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration:
        _settings.reducedMotion || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120),
    reverseTransitionDuration:
        _settings.reducedMotion || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  PlayerProgress _progress() => PlayerProgress(
    bujho: widget.statisticsRepository.load(),
    khoj: widget.wordSearchSessionRepository.statistics.load(),
    quest: widget.wordQuestSessionRepository.statistics.load(),
    bridges: widget.wordBridgesRepository,
    letters: widget.learnLettersRepository,
    scramble: widget.wordScrambleRepository,
  );

  Widget _gameShell({required GameKind game, required Widget child}) =>
      ScaffoldMessenger(
        child: AchievementFeedback(
          game: game,
          facts: () => _progress().facts,
          reducedMotion: _settings.reducedMotion,
          child: VictoryCelebration(
            game: game,
            settings: _settings,
            onSettingsChanged: _changeFeedbackSettings,
            child: GameGuide(
              game: game,
              repository: widget.guideRepository,
              child: child,
            ),
          ),
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
    // The library and Settings expose app-wide reset after leaving game routes.
    try {
      await resetSections({
        'Bujho game': widget.gameRepository.resetAll,
        'Bujho statistics': widget.statisticsRepository.resetAll,
        'Word history': widget.solutionHistoryRepository.resetAll,
        'Word Search': widget.wordSearchSessionRepository.resetAll,
        'Word Quest': widget.wordQuestSessionRepository.resetAll,
        'Jodo': widget.wordBridgesRepository.resetAll,
        'Learn Letters': widget.learnLettersRepository.resetAll,
        'Shabad Banao': widget.wordScrambleRepository.resetAll,
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
    builder: (context, child) =>
        InteractionSounds(settings: _settings, child: child!),
    routerConfig: _router,
  );
}
