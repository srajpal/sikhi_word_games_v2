import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/persistence/key_value_store.dart';
import 'features/settings/data/app_settings_repository.dart';
import 'features/guess_the_word/data/guess_statistics_repository.dart';
import 'features/guess_the_word/data/guess_game_repository.dart';
import 'features/guess_the_word/data/solution_history_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureOrientations();
  final preferences = await SharedPreferences.getInstance();
  final store = SharedPreferencesKeyValueStore(preferences);
  final settings = AppSettingsRepository(store);
  final statistics = GuessStatisticsRepository(store);
  final gameRepository = GuessGameRepository(store);
  final solutionHistoryRepository = SolutionHistoryRepository(store);
  runApp(
    ProviderScope(
      child: SikhiWordGamesApp(
        settingsRepository: settings,
        statisticsRepository: statistics,
        gameRepository: gameRepository,
        solutionHistoryRepository: solutionHistoryRepository,
      ),
    ),
  );
}

Future<void> _configureOrientations() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  await SystemChrome.setPreferredOrientations(
    shortestSide < 600
        ? const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
        : DeviceOrientation.values,
  );
}
