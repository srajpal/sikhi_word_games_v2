import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/game_library/domain/game_launch_options.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';

void main() {
  test('uses the Sikhi theme when no settings are stored', () {
    expect(
      AppSettingsRepository(MemoryKeyValueStore()).load().theme,
      AppThemeChoice.sikhi,
    );
  });

  test('round-trips versioned offline settings', () async {
    final store = MemoryKeyValueStore();
    final repository = AppSettingsRepository(store);
    await repository.save(
      const AppSettings(
        theme: AppThemeChoice.sikhi,
        hapticLevel: HapticFeedbackLevel.strong,
        reducedMotion: true,
      ),
    );
    final restored = repository.load();
    expect(restored.theme, AppThemeChoice.sikhi);
    expect(restored.hapticLevel, HapticFeedbackLevel.strong);
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

  test('migrates the former disabled haptics setting to Off', () {
    final store = MemoryKeyValueStore()
      ..values[AppSettingsRepository.storageKey] = jsonEncode({
        'schemaVersion': 1,
        'theme': 'modern',
        'hapticsEnabled': false,
      });
    expect(
      AppSettingsRepository(store).load().hapticLevel,
      HapticFeedbackLevel.off,
    );
  });

  test('uses safe defaults for an unsupported schema', () {
    final store = MemoryKeyValueStore()
      ..values[AppSettingsRepository.storageKey] = jsonEncode({
        'schemaVersion': 999,
        'theme': 'sketch',
      });
    expect(AppSettingsRepository(store).load().theme, AppThemeChoice.sikhi);
  });

  test('uses safe defaults for malformed JSON', () {
    final store = MemoryKeyValueStore()
      ..values[AppSettingsRepository.storageKey] = '{invalid';
    expect(AppSettingsRepository(store).load().theme, AppThemeChoice.sikhi);
  });
  test(
    'legacy settings enable victories without changing existing preferences',
    () {
      final settings = AppSettings.fromJson({
        'schemaVersion': 1,
        'theme': 'dark',
        'reducedMotion': true,
      });
      expect(settings.theme, AppThemeChoice.dark);
      expect(settings.victorySoundFor(GameKind.wordBridges), isTrue);
      expect(settings.victoryParticles, isTrue);
      expect(settings.victoryParticlesFor(GameKind.wordBridges), isFalse);
    },
  );

  test(
    'per-game victory preferences persist and global switches take priority',
    () async {
      final repository = AppSettingsRepository(MemoryKeyValueStore());
      final settings = const AppSettings().withGameVictory(
        GameKind.wordBridges,
        sound: false,
        particles: false,
      );
      await repository.save(settings);
      final restored = repository.load();
      expect(restored.victorySoundFor(GameKind.wordBridges), isFalse);
      expect(restored.victoryParticlesFor(GameKind.wordBridges), isFalse);
      expect(restored.victorySoundFor(GameKind.wordQuest), isTrue);
      expect(restored.victoryParticlesFor(GameKind.wordQuest), isTrue);
      final disabled = restored.copyWith(
        victorySound: false,
        victoryParticles: false,
      );
      expect(disabled.victorySoundFor(GameKind.wordQuest), isFalse);
      expect(disabled.victoryParticlesFor(GameKind.wordQuest), isFalse);
      final reenabled = disabled.copyWith(
        victorySound: true,
        victoryParticles: true,
      );
      expect(reenabled.victorySoundFor(GameKind.wordBridges), isFalse);
      expect(reenabled.victoryParticlesFor(GameKind.wordBridges), isFalse);
      expect(reenabled.victoryParticlesFor(GameKind.wordQuest), isTrue);
      final gameEnabled = reenabled.withGameVictory(
        GameKind.wordBridges,
        sound: true,
        particles: true,
      );
      expect(gameEnabled.victorySoundFor(GameKind.wordBridges), isTrue);
      expect(gameEnabled.victoryParticlesFor(GameKind.wordBridges), isTrue);
      expect(restored.victorySoundFor(GameKind.wordBridges), isFalse);
      await repository.reset();
      expect(repository.load().victorySoundFor(GameKind.wordBridges), isTrue);
    },
  );

  test('malformed and unknown per-game preferences do not discard theme', () {
    final settings = AppSettings.fromJson({
      'schemaVersion': 1,
      'theme': 'modern',
      'mutedVictoryGames': ['wordBridges', 'unknown', 42],
      'quietVictoryGames': 'bad value',
    });
    expect(settings.theme, AppThemeChoice.modern);
    expect(settings.mutedVictoryGames, {'wordBridges'});
    expect(settings.quietVictoryGames, isEmpty);
  });
}
