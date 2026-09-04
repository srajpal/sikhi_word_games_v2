import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../../core/themes/app_theme.dart';

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
  });

  static const currentSchemaVersion = 1;
  final int schemaVersion;
  final AppThemeChoice theme;
  final HapticFeedbackLevel hapticLevel;
  final bool reducedMotion;

  AppSettings copyWith({
    AppThemeChoice? theme,
    HapticFeedbackLevel? hapticLevel,
    bool? reducedMotion,
  }) => AppSettings(
    theme: theme ?? this.theme,
    hapticLevel: hapticLevel ?? this.hapticLevel,
    reducedMotion: reducedMotion ?? this.reducedMotion,
  );

  Map<String, Object> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'theme': theme.name,
    'hapticLevel': hapticLevel.name,
    'reducedMotion': reducedMotion,
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
      reducedMotion: json['reducedMotion'] as bool? ?? false,
    );
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

  Future<void> save(AppSettings settings) =>
      _store.setString(storageKey, jsonEncode(settings.toJson()));

  Future<void> reset() => _store.remove(storageKey);
}
