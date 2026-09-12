import 'dart:convert';
import 'dart:io';

/// Adds the bounded project-authored definitions needed to keep every
/// supported language and length available under the release source policy.
/// Preview by default; pass `--write` to update editorial overrides.
void main(List<String> arguments) {
  final write = arguments.contains('--write');
  final file = File('assets/content/curation/editorial_overrides.json');
  final document = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final overrides = <String, Map<String, Object?>>{
    for (final item in document['entries']! as List<Object?>)
      (item! as Map<String, Object?>)['id']! as String:
          item as Map<String, Object?>,
  };
  var changes = 0;
  for (final correction in _definitions.entries) {
    final current = overrides[correction.key];
    if (current?['englishDefinition'] == correction.value &&
        current?['source'] == _source &&
        current?['acceptedGuess'] == true &&
        current?['solutionEligible'] == true &&
        current?['reviewStatus'] == 'machineChecked') {
      continue;
    }
    overrides[correction.key] = {
      ...?current,
      'id': correction.key,
      'englishDefinition': correction.value,
      'acceptedGuess': true,
      'solutionEligible': true,
      'reviewStatus': 'machineChecked',
      'source': _source,
    };
    changes++;
  }
  for (final id in _excludedIds) {
    final current = overrides[id];
    if (current?['source'] == _unclearSource &&
        current?['acceptedGuess'] == true &&
        current?['solutionEligible'] == false) {
      continue;
    }
    overrides[id] = {
      ...?current,
      'id': id,
      'acceptedGuess': true,
      'solutionEligible': false,
      'reviewStatus': 'machineChecked',
      'source': _unclearSource,
    };
    changes++;
  }
  stdout.writeln(
    'Release definition preview: $changes of '
    '${_definitions.length + _excludedIds.length} bounded '
    'editorial definitions will change.',
  );
  if (!write) {
    return;
  }
  document['entries'] = overrides.values.toList()
    ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(document)}\n',
  );
  temporary.renameSync(file.path);
  stdout.writeln('Applied bounded release definitions.');
}

const _source =
    'Project editorial definition; original text for Sikhi Word Games';
const _unclearSource = 'Legacy definition source unclear; not distributed';
const _definitions = <String, String>{
  'panjabi_ahsas': 'a feeling or awareness',
  'panjabi_amrit': 'sacred nectar',
  'panjabi_arpna': 'to offer or dedicate',
  'panjabi_asrit': 'a person who depends on another',
  'panjabi_ispat': 'steel',
  'panjabi_itbar': 'trust or confidence',
  'panjabi_rupia': 'a rupee',
  'panjabi_ustat': 'praise',
  'panjabi_utpad': 'a product',
};
const _excludedIds = {'panjabi_adkar', 'panjabi_ixar'};
