import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';

class SolutionHistory {
  const SolutionHistory({this.usedIds = const {}, this.lastSelectedId});

  final Set<String> usedIds;
  final String? lastSelectedId;
}

class SolutionHistoryRepository {
  const SolutionHistoryRepository(this._store);

  static const storageKey = 'guessTheWord.usedSolutions';
  final KeyValueStore _store;

  SolutionHistory load() {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return const SolutionHistory();
    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      if ((json['schemaVersion'] != 1 && json['schemaVersion'] != 2) ||
          json['usedIds'] is! List<Object?>) {
        return const SolutionHistory();
      }
      return SolutionHistory(
        usedIds: {
          for (final id in json['usedIds']! as List<Object?>)
            if (id is String) id,
        },
        lastSelectedId: json['lastSelectedId'] as String?,
      );
    } on FormatException {
      return const SolutionHistory();
    } on TypeError {
      return const SolutionHistory();
    }
  }

  Future<void> save(SolutionHistory history) => _store.setString(
    storageKey,
    jsonEncode({
      'schemaVersion': 2,
      'usedIds': history.usedIds.toList(),
      'lastSelectedId': history.lastSelectedId,
    }),
  );
}
