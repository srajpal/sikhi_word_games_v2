import 'dart:convert';

import 'package:flutter/services.dart';

import 'vocabulary_entry.dart';

abstract interface class VocabularyRepository {
  Future<List<VocabularyEntry>> load();
}

class AssetVocabularyRepository implements VocabularyRepository {
  List<VocabularyEntry>? _cache;
  Future<List<VocabularyEntry>>? _loading;

  @override
  Future<List<VocabularyEntry>> load() async {
    if (_cache case final cached?) return cached;
    final inFlight = _loading;
    if (inFlight != null) return inFlight;
    final future = _loadAssets();
    _loading = future;
    try {
      return await future;
    } finally {
      if (identical(_loading, future)) _loading = null;
    }
  }

  Future<List<VocabularyEntry>> _loadAssets() async {
    final documents = await Future.wait([
      for (final length in const [4, 5, 6])
        rootBundle.loadString('assets/content/release/vocabulary_$length.json'),
    ]);
    final entries = <VocabularyEntry>[];
    for (final document in documents) {
      final decoded = jsonDecode(document) as List<Object?>;
      for (final item in decoded) {
        entries.add(VocabularyEntry.fromJson(item! as Map<String, Object?>));
      }
    }
    final duplicateIds = <String>{};
    final seenIds = <String>{};
    for (final entry in entries) {
      if (!seenIds.add(entry.id)) duplicateIds.add(entry.id);
    }
    if (duplicateIds.isNotEmpty) {
      throw FormatException(
        'Duplicate vocabulary IDs: ${duplicateIds.join(', ')}',
      );
    }
    return _cache = List.unmodifiable(entries);
  }
}

class MemoryVocabularyRepository implements VocabularyRepository {
  const MemoryVocabularyRepository(this.entries);

  final List<VocabularyEntry> entries;

  @override
  Future<List<VocabularyEntry>> load() async => entries;
}
