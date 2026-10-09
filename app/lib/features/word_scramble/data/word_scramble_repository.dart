import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../domain/word_scramble_game.dart';

class ScrambleSession {
  const ScrambleSession(this.mode, this.game, this.simpleRomanized);
  final LanguageMode mode;
  final WordScrambleGame game;
  final bool simpleRomanized;
}

class ScrambleStatistics {
  const ScrambleStatistics({
    this.solved = 0,
    this.unhinted = 0,
    this.firstCheck = 0,
    this.long = 0,
    this.repeated = 0,
    this.checks = 0,
  });
  final int solved, unhinted, firstCheck, long, repeated, checks;
  ScrambleStatistics plus(ScrambleStatistics other) => ScrambleStatistics(
    solved: solved + other.solved,
    unhinted: unhinted + other.unhinted,
    firstCheck: firstCheck + other.firstCheck,
    long: long + other.long,
    repeated: repeated + other.repeated,
    checks: checks + other.checks,
  );
  Map<String, Object?> toJson() => {
    'solved': solved,
    'unhinted': unhinted,
    'firstCheck': firstCheck,
    'long': long,
    'repeated': repeated,
    'checks': checks,
  };
  factory ScrambleStatistics.fromJson(Map<String, Object?> json) {
    int count(String key) {
      final v = json[key];
      if (v is! int || v < 0) {
        throw const FormatException('Invalid scramble count');
      }
      return v;
    }

    final value = ScrambleStatistics(
      solved: count('solved'),
      unhinted: count('unhinted'),
      firstCheck: count('firstCheck'),
      long: count('long'),
      repeated: count('repeated'),
      checks: count('checks'),
    );
    if ([
          value.unhinted,
          value.firstCheck,
          value.long,
          value.repeated,
        ].any((v) => v > value.solved) ||
        value.checks < value.solved) {
      throw const FormatException('Invalid scramble statistics');
    }
    return value;
  }
}

/// Session, history and completion statistics share one ordered atomic write.
class WordScrambleRepository {
  WordScrambleRepository(this._store);
  final KeyValueStore _store;
  static const storageKey = 'wordScramble.state.v1';
  Map<String, Object?> _load() {
    try {
      final raw = _store.getString(storageKey);
      if (raw == null) return {};
      final state = jsonDecode(raw) as Map<String, Object?>;
      if (state['schemaVersion'] != 1) return {};
      final completed = state['completedRoundIds'];
      if (completed != null &&
          (completed is! List || completed.any((id) => id is! String))) {
        state.remove('completedRoundIds');
      }
      final seenRows = state['seen'];
      if (seenRows != null &&
          (seenRows is! Map ||
              seenRows.values.any(
                (row) => row is! List || row.any((id) => id is! String),
              ))) {
        state.remove('seen');
      }
      final previousRows = state['previous'];
      if (previousRows != null &&
          (previousRows is! Map ||
              previousRows.values.any((id) => id is! String))) {
        state.remove('previous');
      }
      return state;
    } on Object {
      return {};
    }
  }

  Map<String, ScrambleStatistics> get statistics {
    try {
      final rows = _load()['statistics'] as Map<String, Object?>? ?? {};
      return rows.map((key, value) {
        LanguageMode.values.byName(key);
        return MapEntry(
          key,
          ScrambleStatistics.fromJson(value as Map<String, Object?>),
        );
      });
    } on Object {
      return {};
    }
  }

  ScrambleStatistics get total => statistics.values.fold(
    const ScrambleStatistics(),
    (sum, row) => sum.plus(row),
  );
  ScrambleStatistics forMode(LanguageMode mode) =>
      statistics[mode.name] ?? const ScrambleStatistics();
  bool get hasActiveGame => restore() != null;
  Set<String> seen(LanguageMode mode) {
    try {
      return (((_load()['seen'] as Map? ?? {})[mode.name] as List?) ?? [])
          .cast<String>()
          .toSet();
    } on Object {
      return {};
    }
  }

  String? previous(LanguageMode mode) {
    try {
      return (_load()['previous'] as Map? ?? {})[mode.name] as String?;
    } on Object {
      return null;
    }
  }

  ScrambleSession? restore() {
    try {
      final row = _load()['session'] as Map<String, Object?>;
      final game = WordScrambleGame.fromJson(
        row['game'] as Map<String, Object?>,
      );
      if (game.isComplete) return null;
      return ScrambleSession(
        LanguageMode.values.byName(row['mode'] as String),
        game,
        row['simpleRomanized'] == true,
      );
    } on Object {
      return null;
    }
  }

  Future<void> save({
    required LanguageMode mode,
    required WordScrambleGame game,
    bool simpleRomanized = false,
    bool resetHistory = false,
  }) {
    final snapshot = game.toJson();
    // Capture the move now, before another tap can mutate the live game.
    return KeyValueStoreWrites.run(_store, storageKey, () async {
      final state = _load();
      state['schemaVersion'] = 1;
      final completed = (state['completedRoundIds'] as List? ?? [])
          .whereType<String>()
          .toSet();
      if (completed.contains(game.roundId)) return;
      final seenRows = Map<String, Object?>.from(state['seen'] as Map? ?? {});
      seenRows[mode.name] = {
        if (!resetHistory)
          ...(seenRows[mode.name] as List? ?? []).whereType<String>(),
        game.wordId,
      }.toList();
      state['seen'] = seenRows;
      final previousRows = Map<String, Object?>.from(
        state['previous'] as Map? ?? {},
      );
      previousRows[mode.name] = game.wordId;
      state['previous'] = previousRows;
      if (snapshot['complete'] == true) {
        final saved = WordScrambleGame.fromJson(snapshot);
        final rows = statistics;
        rows[mode.name] = (rows[mode.name] ?? const ScrambleStatistics()).plus(
          ScrambleStatistics(
            solved: 1,
            unhinted: saved.usedHint ? 0 : 1,
            firstCheck: saved.checks == 1 ? 1 : 0,
            long: saved.units.length >= 6 ? 1 : 0,
            repeated: saved.units.toSet().length < saved.units.length ? 1 : 0,
            checks: saved.checks,
          ),
        );
        state['statistics'] = rows.map(
          (key, value) => MapEntry(key, value.toJson()),
        );
        completed.add(saved.roundId);
        state['completedRoundIds'] = completed.toList();
        final active = state['session'];
        if (active is Map &&
            active['game'] is Map &&
            (active['game'] as Map)['roundId'] == saved.roundId) {
          state.remove('session');
        }
      } else {
        state['session'] = {
          'mode': mode.name,
          'simpleRomanized': simpleRomanized,
          'game': snapshot,
        };
      }
      await _store.setString(storageKey, jsonEncode(state));
    });
  }

  Future<void> resetAll() => KeyValueStoreWrites.remove(_store, storageKey);
}
