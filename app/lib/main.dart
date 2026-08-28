import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/persistence/key_value_store.dart';
import 'features/settings/data/app_settings_repository.dart';
import 'features/guess_the_word/data/guess_statistics_repository.dart';
import 'features/guess_the_word/data/guess_game_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final store = SharedPreferencesKeyValueStore(preferences);
  final settings = AppSettingsRepository(store);
  final statistics = GuessStatisticsRepository(store);
  final gameRepository = GuessGameRepository(store);
  runApp(
    ProviderScope(
      child: SikhiWordGamesApp(
        settingsRepository: settings,
        statisticsRepository: statistics,
        gameRepository: gameRepository,
      ),
    ),
  );
}
