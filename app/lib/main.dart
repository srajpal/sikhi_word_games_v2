import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/persistence/key_value_store.dart';
import 'features/settings/data/app_settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final settings = AppSettingsRepository(
    SharedPreferencesKeyValueStore(preferences),
  );
  runApp(ProviderScope(child: SikhiWordGamesApp(settingsRepository: settings)));
}
