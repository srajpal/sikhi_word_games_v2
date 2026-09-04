import 'dart:convert';

import 'package:flutter/services.dart';

import 'vocabulary_entry.dart';

abstract interface class VocabularyRepository {
  Future<List<VocabularyEntry>> load();
}

class AssetVocabularyRepository implements VocabularyRepository {
  List<VocabularyEntry>? _cache;

  @override
  Future<List<VocabularyEntry>> load() async {
    if (_cache case final cached?) return cached;
    final curation = jsonDecode(
      await rootBundle.loadString(
        'assets/content/curation/starter_solutions.json',
      ),
    ) as Map<String, Object?>;
    final solutionIds = (curation['solutionIds']! as List<Object?>)
        .cast<String>()
        .toSet();
    final overridesDocument = jsonDecode(
      await rootBundle.loadString(
        'assets/content/curation/editorial_overrides.json',
      ),
    ) as Map<String, Object?>;
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
    for (final length in const [4, 5, 6]) {
      final decoded = jsonDecode(
        await rootBundle.loadString(
          'assets/content/generated/vocabulary_$length.json',
        ),
      ) as List<Object?>;
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
    final supplementalDocument = jsonDecode(
      await rootBundle.loadString(
        'assets/content/curation/supplemental_entries.json',
      ),
    ) as Map<String, Object?>;
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
