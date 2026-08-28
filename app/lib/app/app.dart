import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/themes/app_theme.dart';
import '../core/content/vocabulary_repository.dart';
import '../features/game_library/presentation/game_library_page.dart';
import '../features/guess_the_word/presentation/guess_the_word_page.dart';
import '../features/dictionary/presentation/dictionary_page.dart';
import '../features/guess_the_word/data/guess_statistics_repository.dart';
import '../features/guess_the_word/data/guess_game_repository.dart';
import '../features/guess_the_word/data/solution_history_repository.dart';
import '../core/persistence/key_value_store.dart';
import '../features/settings/data/app_settings_repository.dart';

class SikhiWordGamesApp extends StatefulWidget {
  SikhiWordGamesApp({
    required this.settingsRepository,
    VocabularyRepository? vocabularyRepository,
    GuessStatisticsRepository? statisticsRepository,
    GuessGameRepository? gameRepository,
    SolutionHistoryRepository? solutionHistoryRepository,
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
           SolutionHistoryRepository(MemoryKeyValueStore());

  final AppSettingsRepository settingsRepository;
  final VocabularyRepository vocabularyRepository;
  final GuessStatisticsRepository statisticsRepository;
  final GuessGameRepository gameRepository;
  final SolutionHistoryRepository solutionHistoryRepository;

  @override
  State<SikhiWordGamesApp> createState() => _SikhiWordGamesAppState();
}

class _SikhiWordGamesAppState extends State<SikhiWordGamesApp> {
  late AppThemeChoice _choice;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _choice = widget.settingsRepository.load().theme;
    _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              GameLibraryPage(onThemeChanged: _changeTheme),
          routes: [
            GoRoute(
              path: 'guess-the-word',
              builder: (context, state) => GuessTheWordPage(
                vocabularyRepository: widget.vocabularyRepository,
                statisticsRepository: widget.statisticsRepository,
                gameRepository: widget.gameRepository,
                solutionHistoryRepository: widget.solutionHistoryRepository,
              ),
            ),
            GoRoute(
              path: 'dictionary',
              builder: (context, state) => DictionaryPage(
                vocabularyRepository: widget.vocabularyRepository,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _changeTheme(AppThemeChoice choice) async {
    setState(() => _choice = choice);
    _router.refresh();
    await widget.settingsRepository.save(
      widget.settingsRepository.load().copyWith(theme: choice),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'Sikhi Word Games V2',
    theme: AppThemes.forChoice(_choice),
    routerConfig: _router,
  );
}
