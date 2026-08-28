import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  test('round-trips versioned offline settings', () async {
    final store = MemoryKeyValueStore();
    final repository = AppSettingsRepository(store);
    await repository.save(
      const AppSettings(
        theme: AppThemeChoice.sikhi,
        hapticsEnabled: false,
        reducedMotion: true,
      ),
    );
    final restored = repository.load();
    expect(restored.theme, AppThemeChoice.sikhi);
    expect(restored.hapticsEnabled, isFalse);
    expect(restored.reducedMotion, isTrue);
  });

  test('migrates the former Sketch choice to Sikhi', () {
    final store = MemoryKeyValueStore()
      ..values[AppSettingsRepository.storageKey] = jsonEncode({
        'schemaVersion': 1,
        'theme': 'sketch',
      });
    expect(AppSettingsRepository(store).load().theme, AppThemeChoice.sikhi);
  });

  test('uses safe defaults for an unsupported schema', () {
    final store = MemoryKeyValueStore()
      ..values[AppSettingsRepository.storageKey] = jsonEncode({
        'schemaVersion': 999,
        'theme': 'sketch',
      });
    expect(AppSettingsRepository(store).load().theme, AppThemeChoice.modern);
  });

  test('uses safe defaults for malformed JSON', () {
    final store = MemoryKeyValueStore()
      ..values[AppSettingsRepository.storageKey] = '{invalid';
    expect(AppSettingsRepository(store).load().theme, AppThemeChoice.modern);
  });
}
