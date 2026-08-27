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
        entries.add(entry);
      }
    }
    final missingIds = solutionIds.difference(
      entries.map((entry) => entry.id).toSet(),
    );
    if (missingIds.isNotEmpty) {
      throw FormatException(
        'Unknown curated solution IDs: ${missingIds.join(', ')}',
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
