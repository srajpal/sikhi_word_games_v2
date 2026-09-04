import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../domain/game_launch_options.dart';

class GameLaunchPreferences {
  const GameLaunchPreferences({required this.language, required this.wordSize});

  final LanguageMode? language;
  final int? wordSize;

  GameLaunchOptions get options =>
      GameLaunchOptions(language: language, wordSize: wordSize);
}

class GameLaunchPreferencesRepository {
  const GameLaunchPreferencesRepository(this._store);

  static const storageKey = 'gameLibrary.launchPreferences';
  static const schemaVersion = 1;
  static const defaultPreferences = GameLaunchPreferences(
    language: LanguageMode.english,
    wordSize: 5,
  );

  final KeyValueStore _store;

  GameLaunchPreferences load(GameKind kind) {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return defaultPreferences;
    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      if (json['schemaVersion'] != schemaVersion) return defaultPreferences;
      final raw = json[kind.name];
      if (raw == null) return defaultPreferences;
      final values = raw as Map<String, Object?>;

      LanguageMode? language;
      final rawLanguage = values['language'];
      if (rawLanguage != null) {
        if (rawLanguage is! String) return defaultPreferences;
        final matching = LanguageMode.values.where(
          (value) => value.name == rawLanguage,
        );
        if (matching.isEmpty) return defaultPreferences;
        language = matching.first;
      }

      final rawWordSize = values['wordSize'];
      if (rawWordSize != null &&
          (rawWordSize is! int || !const [4, 5, 6].contains(rawWordSize))) {
        return defaultPreferences;
      }
      return GameLaunchPreferences(
        language: language,
        wordSize: rawWordSize as int?,
      );
    } on Object catch (_) {
      return defaultPreferences;
    }
  }

  Future<void> save(GameKind kind, GameLaunchOptions options) async {
    Map<String, Object?> preferences = {};
    final encoded = _store.getString(storageKey);
    if (encoded != null) {
      try {
        preferences = Map<String, Object?>.from(
          jsonDecode(encoded) as Map<String, Object?>,
        );
      } on Object catch (_) {
        preferences = {};
      }
    }
    preferences['schemaVersion'] = schemaVersion;
    preferences[kind.name] = {
      'language': options.language?.name,
      'wordSize': options.wordSize,
    };
    await _store.setString(storageKey, jsonEncode(preferences));
  }
}
