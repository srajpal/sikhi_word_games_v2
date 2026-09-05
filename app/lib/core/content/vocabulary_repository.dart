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
      rootBundle.loadString('assets/content/curation/starter_solutions.json'),
      rootBundle.loadString('assets/content/curation/editorial_overrides.json'),
      for (final length in const [4, 5, 6])
        rootBundle.loadString(
          'assets/content/generated/vocabulary_$length.json',
        ),
      rootBundle.loadString(
        'assets/content/curation/supplemental_entries.json',
      ),
    ]);
    final curation = jsonDecode(documents[0]) as Map<String, Object?>;
    final solutionIds = (curation['solutionIds']! as List<Object?>)
        .cast<String>()
        .toSet();
    final overridesDocument = jsonDecode(documents[1]) as Map<String, Object?>;
    if (overridesDocument['schemaVersion'] != 1 ||
        overridesDocument['entries'] is! List<Object?>) {
      throw const FormatException('Unsupported editorial override schema.');
    }
    final overrides = <String, Map<String, Object?>>{};
    for (final item in overridesDocument['entries']! as List<Object?>) {
      final override = item! as Map<String, Object?>;
      overrides[override['id']! as String] = override;
    }
    final entries = <VocabularyEntry>[];
    for (final document in documents.sublist(2, 5)) {
      final decoded = jsonDecode(document) as List<Object?>;
      for (final item in decoded) {
        var entry = VocabularyEntry.fromJson(item! as Map<String, Object?>);
        if (solutionIds.contains(entry.id)) {
          entry = entry.copyWith(
            solutionEligible: true,
            reviewStatus: ReviewStatus.machineChecked,
          );
        }
        final override = overrides[entry.id];
        if (override != null) {
          final reviewStatus = override['reviewStatus'] as String?;
          entry = entry.copyWith(
            englishDefinition: override['englishDefinition'] as String?,
            gurmukhi: override['gurmukhi'] as String?,
            acceptedGuess: override['acceptedGuess'] as bool?,
            solutionEligible: override['solutionEligible'] as bool?,
            reviewStatus: reviewStatus == null
                ? null
                : ReviewStatus.values.byName(reviewStatus),
          );
        }
        entries.add(entry);
      }
    }
    final supplementalDocument =
        jsonDecode(documents[5]) as Map<String, Object?>;
    if (supplementalDocument['schemaVersion'] != 1 ||
        supplementalDocument['entries'] is! List<Object?>) {
      throw const FormatException('Unsupported supplemental entry schema.');
    }
    for (final item in supplementalDocument['entries']! as List<Object?>) {
      entries.add(VocabularyEntry.fromJson(item! as Map<String, Object?>));
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
    final missingIds = solutionIds.difference(
      entries.map((entry) => entry.id).toSet(),
    );
    if (missingIds.isNotEmpty) {
      throw FormatException(
        'Unknown curated solution IDs: ${missingIds.join(', ')}',
      );
    }
    final missingOverrideIds = overrides.keys.toSet().difference(
      entries.map((entry) => entry.id).toSet(),
    );
    if (missingOverrideIds.isNotEmpty) {
      throw FormatException(
        'Unknown editorial override IDs: ${missingOverrideIds.join(', ')}',
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
