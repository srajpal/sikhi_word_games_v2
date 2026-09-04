import 'dart:convert';
import 'dart:io';

/// Applies the first neutral Open English WordNet (OEWN) definition selected by
/// `reassess_english_definitions.dart` to the curated runtime data.
///
/// The generated vocabulary remains immutable. Definitions for generated words
/// are stored as editorial overrides; supplemental entries are updated in place.
/// Run without arguments to preview, then use `--write` to apply.
void main(List<String> arguments) {
  final shouldWrite = arguments.contains('--write');
  final curation = Directory('assets/content/curation');
  final overridesFile = File('${curation.path}/editorial_overrides.json');
  final supplementalFile = File('${curation.path}/supplemental_entries.json');
  final reassessmentFile = File(
    '../reports/content/english_definition_reassessment.json',
  );
  if (!reassessmentFile.existsSync()) {
    throw StateError(
      'Run tool/reassess_english_definitions.dart before applying OEWN definitions.',
    );
  }

  final overridesDocument = _readDocument(overridesFile);
  final supplementalDocument = _readDocument(supplementalFile);
  final reassessment = _readDocument(reassessmentFile);
  final recommendedById = <String, String>{};
  for (final item in reassessment['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    if (entry['recommendedDefinition'] case final String definition) {
      recommendedById[entry['id']! as String] = definition;
    }
  }
  final generatedIds = _readGeneratedEnglishIds();
  final overrides = <String, Map<String, Object?>>{
    for (final item in overridesDocument['entries']! as List<Object?>)
      (item! as Map<String, Object?>)['id']! as String:
          item as Map<String, Object?>,
  };
  final supplemental = <String, Map<String, Object?>>{
    for (final item in supplementalDocument['entries']! as List<Object?>)
      (item! as Map<String, Object?>)['id']! as String:
          item as Map<String, Object?>,
  };

  var generatedUpdated = 0;
  var supplementalUpdated = 0;
  for (final entry in recommendedById.entries) {
    final id = entry.key;
    final definition = entry.value;
    if (generatedIds.contains(id)) {
      final existing = overrides[id];
      if (existing?['englishDefinition'] == definition &&
          existing?['source'] == _source) {
        continue;
      }
      overrides[id] = {
        ...?existing,
        'id': id,
        'englishDefinition': definition,
        'source': _source,
        'reviewStatus': 'machineChecked',
      };
      generatedUpdated++;
    } else if (supplemental[id] case final existing?) {
      final definitions = {...existing['definitions']! as Map<String, Object?>};
      if ((definitions['en'] as List<Object?>?)?.singleOrNull == definition &&
          existing['reviewStatus'] == 'machineChecked' &&
          (existing['sources'] as List<Object?>?)?.contains(_source) == true) {
        continue;
      }
      definitions['en'] = [definition];
      final sources = [
        ...(existing['sources'] as List<Object?>? ?? const <Object?>[]),
        if (!(existing['sources'] as List<Object?>? ?? const <Object?>[])
            .contains(_source))
          _source,
      ];
      supplemental[id] = {
        ...existing,
        'definitions': definitions,
        'sources': sources,
        'reviewStatus': 'machineChecked',
      };
      supplementalUpdated++;
    }
  }

  stdout.writeln(
    'OEWN definition preview: $generatedUpdated generated entries and '
    '$supplementalUpdated supplemental entries will change. '
    '${reassessment['needsFallbackCount']} English entries have no neutral '
    'OEWN definition and will remain unchanged.',
  );
  if (!shouldWrite) return;

  overridesDocument['note'] =
      'Curated decisions and OEWN 2025 English definitions. Generated '
      'vocabulary files must not be edited directly.';
  overridesDocument['entries'] = overrides.values.toList()..sort(_compareById);
  supplementalDocument['entries'] = supplemental.values.toList()
    ..sort(_compareById);
  _writeDocument(overridesFile, overridesDocument);
  _writeDocument(supplementalFile, supplementalDocument);
  stdout.writeln('Applied OEWN definitions to curated runtime assets.');
}

const _source = 'Open English WordNet 2025 (CC BY 4.0)';

Set<String> _readGeneratedEnglishIds() {
  final ids = <String>{};
  for (final length in const [4, 5, 6]) {
    final entries = jsonDecode(
      File('assets/content/generated/vocabulary_$length.json')
          .readAsStringSync(),
    ) as List<Object?>;
    ids.addAll(
      entries
          .cast<Map<String, Object?>>()
          .where((entry) => entry['language'] == 'english')
          .map((entry) => entry['id']! as String),
    );
  }
  return ids;
}

Map<String, Object?> _readDocument(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

void _writeDocument(File file, Map<String, Object?> value) {
  const encoder = JsonEncoder.withIndent('  ');
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync('${encoder.convert(value)}\n');
  temporary.renameSync(file.path);
}

int _compareById(Map<String, Object?> left, Map<String, Object?> right) =>
    (left['id']! as String).compareTo(right['id']! as String);
