import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'vocabulary_entry.dart';
import 'vocabulary_source.dart';

export 'vocabulary_source.dart';

class AssetVocabularyRepository implements VocabularyRepository {
  static const assetPaths = [
    'assets/content/release/english/words.json',
    'assets/content/release/punjabi/romanized/words.json',
    'assets/content/release/punjabi/gurmukhi/words.json',
  ];
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
      for (final path in assetPaths) rootBundle.loadString(path),
    ]);
    final entries = kIsWeb
        ? await decodeVocabularyCooperatively(documents)
        : await compute(decodeVocabularyDocuments, documents);
    _cache = entries;
    return entries;
  }
}

/// Native compute entry point: no bundle or widget state crosses the isolate.
List<VocabularyEntry> decodeVocabularyDocuments(List<String> documents) =>
    _validateIds([
      for (final (shard, document) in documents.indexed)
        for (final (index, item)
            in ((jsonDecode(document) as Map<String, Object?>)['words']!
                    as List<Object?>)
                .indexed)
          _decodeRecord(item, index, VocabularyScript.values[shard]),
    ]);

/// Web has no compute worker. Yield before each shard and every 250 records.
Future<List<VocabularyEntry>> decodeVocabularyCooperatively(
  List<String> documents,
) async {
  final entries = <VocabularyEntry>[];
  for (final (shard, document) in documents.indexed) {
    await Future<void>.delayed(Duration.zero);
    final decoded =
        (jsonDecode(document) as Map<String, Object?>)['words']!
            as List<Object?>;
    for (var index = 0; index < decoded.length; index++) {
      entries.add(
        _decodeRecord(decoded[index], index, VocabularyScript.values[shard]),
      );
      if (index % 250 == 249) await Future<void>.delayed(Duration.zero);
    }
  }
  return _validateIds(entries);
}

VocabularyEntry _decodeRecord(
  Object? item,
  int index,
  VocabularyScript script,
) {
  try {
    return VocabularyEntry.fromApprovedJson(
      item! as Map<String, Object?>,
      script,
    );
  } on Object catch (error) {
    final id = item is Map ? item['word'] : null;
    throw FormatException(
      'Invalid vocabulary record ${id ?? "at index $index"}: $error',
    );
  }
}

List<VocabularyEntry> _validateIds(List<VocabularyEntry> entries) {
  final seen = <String>{};
  for (final entry in entries) {
    if (!seen.add(entry.id)) {
      throw FormatException('Duplicate vocabulary ID: ${entry.id}');
    }
  }
  return List.unmodifiable(entries);
}

class MemoryVocabularyRepository implements VocabularyRepository {
  const MemoryVocabularyRepository(this.entries);

  final List<VocabularyEntry> entries;

  @override
  Future<List<VocabularyEntry>> load() async => entries;
}
