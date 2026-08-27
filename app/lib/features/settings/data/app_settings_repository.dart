import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/themes/app_theme.dart';

class AppSettings {
  const AppSettings({
    this.schemaVersion = currentSchemaVersion,
    this.theme = AppThemeChoice.modern,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
  });

  static const currentSchemaVersion = 1;
  final int schemaVersion;
  final AppThemeChoice theme;
  final bool hapticsEnabled;
  final bool reducedMotion;

  AppSettings copyWith({
    AppThemeChoice? theme,
    bool? hapticsEnabled,
    bool? reducedMotion,
  }) => AppSettings(
    theme: theme ?? this.theme,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    reducedMotion: reducedMotion ?? this.reducedMotion,
  );

  Map<String, Object> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'theme': theme.name,
    'hapticsEnabled': hapticsEnabled,
    'reducedMotion': reducedMotion,
  };

  static AppSettings fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      return const AppSettings();
    }
    final matchingThemes = AppThemeChoice.values.where(
      (value) => value.name == json['theme'],
    );
    return AppSettings(
      theme: matchingThemes.isEmpty
          ? AppThemeChoice.modern
          : matchingThemes.first,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      reducedMotion: json['reducedMotion'] as bool? ?? false,
    );
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

  Future<void> save(AppSettings settings) =>
      _store.setString(storageKey, jsonEncode(settings.toJson()));

  Future<void> reset() => _store.remove(storageKey);
}
