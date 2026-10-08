import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/themes/app_theme.dart';
import '../../game_library/domain/game_launch_options.dart';

enum HapticFeedbackLevel { off, light, medium, strong }

extension HapticFeedbackLevelLabel on HapticFeedbackLevel {
  String get label => switch (this) {
    HapticFeedbackLevel.off => 'Off',
    HapticFeedbackLevel.light => 'Light',
    HapticFeedbackLevel.medium => 'Medium',
    HapticFeedbackLevel.strong => 'Strong',
  };
}

class AppSettings {
  const AppSettings({
    this.schemaVersion = currentSchemaVersion,
    this.theme = AppThemeChoice.sikhi,
    this.hapticLevel = HapticFeedbackLevel.medium,
    this.reducedMotion = false,
    this.victorySound = true,
    this.victoryParticles = true,
    this.mutedVictoryGames = const {},
    this.quietVictoryGames = const {},
  });

  static const currentSchemaVersion = 1;
  final int schemaVersion;
  final AppThemeChoice theme;
  final HapticFeedbackLevel hapticLevel;
  final bool reducedMotion;
  final bool victorySound;
  final bool victoryParticles;
  final Set<String> mutedVictoryGames;
  final Set<String> quietVictoryGames;

  bool victorySoundFor(GameKind game) =>
      victorySound && !mutedVictoryGames.contains(game.name);

  bool victoryParticlesFor(GameKind game) =>
      victoryParticles &&
      !reducedMotion &&
      !quietVictoryGames.contains(game.name);

  AppSettings withGameVictory(GameKind game, {bool? sound, bool? particles}) {
    final muted = {...mutedVictoryGames};
    final quiet = {...quietVictoryGames};
    if (sound != null) {
      sound ? muted.remove(game.name) : muted.add(game.name);
    }
    if (particles != null) {
      particles ? quiet.remove(game.name) : quiet.add(game.name);
    }
    return copyWith(
      mutedVictoryGames: Set.unmodifiable(muted),
      quietVictoryGames: Set.unmodifiable(quiet),
    );
  }

  AppSettings copyWith({
    AppThemeChoice? theme,
    HapticFeedbackLevel? hapticLevel,
    bool? reducedMotion,
    bool? victorySound,
    bool? victoryParticles,
    Set<String>? mutedVictoryGames,
    Set<String>? quietVictoryGames,
  }) => AppSettings(
    theme: theme ?? this.theme,
    hapticLevel: hapticLevel ?? this.hapticLevel,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    victorySound: victorySound ?? this.victorySound,
    victoryParticles: victoryParticles ?? this.victoryParticles,
    mutedVictoryGames: mutedVictoryGames ?? this.mutedVictoryGames,
    quietVictoryGames: quietVictoryGames ?? this.quietVictoryGames,
  );

  Map<String, Object> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'theme': theme.name,
    'hapticLevel': hapticLevel.name,
    'reducedMotion': reducedMotion,
    'victorySound': victorySound,
    'victoryParticles': victoryParticles,
    'mutedVictoryGames': mutedVictoryGames.toList(),
    'quietVictoryGames': quietVictoryGames.toList(),
  };

  static AppSettings fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      return const AppSettings();
    }
    final storedTheme = json['theme'];
    final matchingThemes = AppThemeChoice.values.where(
      (value) => value.name == storedTheme,
    );
    return AppSettings(
      theme: storedTheme == 'sketch'
          ? AppThemeChoice.sikhi
          : matchingThemes.isEmpty
          ? AppThemeChoice.sikhi
          : matchingThemes.first,
      hapticLevel: _hapticLevelFromJson(json),
      reducedMotion: json['reducedMotion'] == true,
      victorySound: json['victorySound'] != false,
      victoryParticles: json['victoryParticles'] != false,
      mutedVictoryGames: _gameSet(json['mutedVictoryGames']),
      quietVictoryGames: _gameSet(json['quietVictoryGames']),
    );
  }

  static Set<String> _gameSet(Object? value) {
    if (value is! List) return const {};
    final known = GameKind.values.map((game) => game.name).toSet();
    return Set.unmodifiable(value.whereType<String>().where(known.contains));
  }

  static HapticFeedbackLevel _hapticLevelFromJson(Map<String, Object?> json) {
    final stored = json['hapticLevel'];
    for (final level in HapticFeedbackLevel.values) {
      if (level.name == stored) return level;
    }
    if (json['hapticsEnabled'] == false) return HapticFeedbackLevel.off;
    return HapticFeedbackLevel.medium;
  }
}

class AppSettingsRepository {
  const AppSettingsRepository(this._store);

  static const storageKey = 'app.settings';
  final KeyValueStore _store;

  AppSettings load() {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(encoded) as Map<String, Object?>);
    } on FormatException {
      return const AppSettings();
    } on TypeError {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) => KeyValueStoreWrites.setString(
    _store,
    storageKey,
    jsonEncode(settings.toJson()),
  );

  Future<void> reset() => KeyValueStoreWrites.remove(_store, storageKey);
}
