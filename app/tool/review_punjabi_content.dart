import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'content/mahan_kosh_text.dart';
import 'content/punjabi_quality.dart';

const sourceCommit = 'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6';
const editorialSource =
    'Project editorial definition; original text for Sikhi Word Games';

/// Source matching and sense cleanup are separate from explicit editorial
/// proposals. Both record machine decisions; neither claims human review.
void main(List<String> args) {
  final write = args.contains('--write');
  final core = (_read('../mahan-kosh-core.json')['entries'] as List)
      .cast<Map<String, dynamic>>()
      .where((e) => e['excluded'] != true)
      .toList();
  final english = _read('../mahan-kosh-en.json');
  final sourceById = {for (final e in core) e['id'] as String: e};
  final sourceByWord = <String, List<Map<String, dynamic>>>{};
  for (final e in core) {
    sourceByWord.putIfAbsent(e['hw'] as String, () => []).add(e);
  }
  final supplementalFile = 'assets/content/curation/supplemental_entries.json';
  final overrideFile = 'assets/content/curation/editorial_overrides.json';
  final supplements = _read(supplementalFile);
  final overridesDocument = _read(overrideFile);
  final overrides = {
    for (final e in overridesDocument['entries'] as List)
      e['id'] as String: Map<String, dynamic>.from(e as Map),
  };
  if (overrides.length != (overridesDocument['entries'] as List).length) {
    throw const FormatException('Duplicate editorial override ID.');
  }
  final entries = <Map<String, dynamic>>[
    for (final length in [4, 5, 6])
      ...(jsonDecode(
        File('assets/content/generated/vocabulary_$length.json')
            .readAsStringSync(),
      ) as List).cast<Map<String, dynamic>>(),
    ...(supplements['entries'] as List).cast<Map<String, dynamic>>(),
  ];
  final byId = {for (final e in entries) e['id'] as String: e};
  if (byId.length != entries.length) {
    throw const FormatException('Duplicate authoring vocabulary ID.');
  }
  final decisions = <String, Map<String, dynamic>>{};
  var matched = 0;
  for (final entry in entries.where((e) => e['language'] == 'panjabi')) {
    final id = entry['id'] as String;
    final previous = overrides[id];
    if ((previous?['acceptedGuess'] == false &&
            previous?['reviewMethod'] !=
                'exact-headword-and-standalone-sense-v1') ||
        '${previous?['note']}'.contains('Release QA exclusion')) {
      continue;
    }
    final native = id.startsWith('gurmukhi_mahan_kosh_');
    final gurmukhi = (previous?['gurmukhi'] ?? entry['gurmukhi']) as String?;
    if (gurmukhi == null) continue;
    final sourceEntries = native
        ? [?sourceById[id.substring('gurmukhi_mahan_kosh_'.length)]]
        : sourceByWord[gurmukhi] ?? <Map<String, dynamic>>[];
    if (sourceEntries.isEmpty) continue;
    matched++;
    Map<String, dynamic>? chosen;
    for (final source in sourceEntries) {
      if (source['hw'] != gurmukhi) continue;
      final latin = native
          ? romanizeMahanKosh(source['tr'] as String?)
          : entry['latin'] as String;
      if (latin == null || !hasMatchingPunjabiConsonants(gurmukhi, latin)) {
        continue;
      }
      final senses = (english[source['id']]?['definitions'] as List?) ?? [];
      for (final raw in senses.whereType<String>()) {
        final definition = cleanMahanKoshSense(raw);
        if (definition == null) continue;
        // Named people, scriptural quotations and scholarly fragments are
        // common in this encyclopedia. Only short, ordinary lower-case senses
        // qualify for source-only promotion. Explicit editorial decisions can
        // supply a clear meaning for the other entries.
        if (definition.length > 90 ||
            RegExp(
              r'[A-Z]|\b(?:etc|i\.e|viz|lit)\b|\b(?:he|his|her|they|their|this|that is)\b',
            ).hasMatch(definition)) {
          continue;
        }
        final quality = assessPunjabiQuality(
          PunjabiQualityCandidate(
            gurmukhi: gurmukhi,
            latin: latin,
            englishDefinition: definition,
          ),
        );
        if (!quality.isPromotionCandidate) continue;
        chosen = {
          'id': id,
          'latin': latin,
          'gurmukhi': gurmukhi,
          'englishDefinition': definition,
          'acceptedGuess': true,
          'solutionEligible':
              previous?['protectedAnswerExclusion'] != true &&
              !(previous?['solutionEligible'] == false &&
                  previous?['reviewMethod'] == null),
          'protectedAnswerExclusion':
              previous?['protectedAnswerExclusion'] == true ||
              (previous?['solutionEligible'] == false &&
                  previous?['reviewMethod'] == null),
          'reviewStatus': 'machineChecked',
          'source': _sourceLabel(source),
          'sourceId': source['id'],
          'sourceSenseIndex': senses.indexOf(raw),
          'reviewMethod': 'exact-headword-and-standalone-sense-v1',
          'note': 'Source-matched automated decision under the project-owner approved Punjabi policy.',
        };
        break;
      }
      if (chosen != null) break;
    }
    if (chosen != null) {
      decisions[id] = chosen;
    } else if (native) {
      // Keep the licensed original in authoring inputs. Do not present a raw
      // citation, unsafe sense or broken pronunciation as a finished game clue.
      final romanized = romanizeMahanKosh(sourceEntries.first['tr'] as String?);
      final reliableSpelling =
          romanized != null &&
          hasMatchingPunjabiConsonants(gurmukhi, romanized);
      decisions[id] = {
        'id': id,
        if (reliableSpelling) 'latin': romanized,
        'acceptedGuess': reliableSpelling,
        'englishDefinition': '',
        'solutionEligible': false,
        'reviewStatus': 'machineChecked',
        'source': (entry['sources'] as List).first,
        'reviewMethod': 'exact-headword-and-standalone-sense-v1',
        'note': reliableSpelling
            ? 'Held as a guess: spelling corrected, but no complete neutral sense passed the quality gate.'
            : 'Excluded from play: source pronunciation could not be reconciled with the headword.',
      };
    }
  }

  var editorial = 0;
  var added = 0;
  final proposalErrors = <String>[];
  final proposalTargets = <String>{};
  final proposalFiles = [
    '../reports/content/punjabi_common_word_proposals.json',
    '../reports/content/gurmukhi_expansion_proposals.json',
  ];
  for (final path in proposalFiles) {
    if (args.contains('--source-only')) break;
    if (!File(path).existsSync()) continue;
    for (final proposal in _read(path)['entries'] as List) {
      final p = Map<String, dynamic>.from(proposal as Map);
      final source = sourceById[p['sourceId']];
      if (source == null ||
          source['hw'] != p['sourceHeadword'] ||
          source['hw'] != p['gurmukhi']) {
        throw FormatException('Unverified proposal source: ${p['latin']}');
      }
      final rawDefinitions = (english[p['sourceId']]['definitions'] as List)
          .cast<String>();
      if (!rawDefinitions.contains(p['sourceDefinition'])) {
        proposalErrors.add(
          'Proposal source text differs from pinned data: ${p['latin']}',
        );
        continue;
      }
      final latin = p['latin'] as String;
      final gurmukhi = p['gurmukhi'] as String;
      final definition = p['definition'] as String;
      if (!hasMatchingPunjabiConsonants(gurmukhi, latin)) {
        proposalErrors.add('Spelling: $latin / $gurmukhi');
        continue;
      }
      final quality = assessPunjabiQuality(
        PunjabiQualityCandidate(
          gurmukhi: gurmukhi,
          latin: latin,
          englishDefinition: definition,
        ),
      );
      if (!quality.isPromotionCandidate) {
        proposalErrors.add(
          'Definition: $latin '
          '${quality.blockingIssues.map((e) => e.code).join(', ')}',
        );
        continue;
      }
      var id = p['existingId'] as String?;
      id ??= byId.values
          .where(
            (e) =>
                e['language'] == 'panjabi' &&
                e['gurmukhi'] == gurmukhi &&
                e['latin'] == latin,
          )
          .map((e) => e['id'] as String)
          .firstOrNull;
      id ??= 'panjabi_curated_${p['sourceId']}';
      if (!proposalTargets.add(id)) {
        throw FormatException('Multiple editorial proposals target $id.');
      }
      final previous = overrides[id];
      final protected =
          previous?['protectedAnswerExclusion'] == true ||
          previous?['acceptedGuess'] == false ||
          previous?['solutionEligible'] == false;
      if (protected && p['reopenAnswerExclusion'] != true) {
        throw FormatException('Explicit reopen decision required for $id.');
      }
      if (byId[id] case final existing?) {
        if (existing['language'] != 'panjabi' ||
            existing['gurmukhi'] != gurmukhi) {
          throw FormatException('ID collision: $id');
        }
      } else {
        final entry = <String, dynamic>{
          'id': id,
          'language': 'panjabi',
          'latin': latin,
          'gurmukhi': gurmukhi,
          'definitions': {
            'en': [definition],
            'pa': <String>[],
          },
          'lengths': {
            'latin': latin.characters.length,
            'gurmukhi': gurmukhi.characters.length,
          },
          'acceptedGuess': true,
          'solutionEligible': true,
          'reviewStatus': 'machineChecked',
          'sources': [editorialSource],
        };
        (supplements['entries'] as List).add(entry);
        byId[id] = entry;
        added++;
      }
      decisions[id] = {
        'id': id,
        'latin': latin,
        'gurmukhi': gurmukhi,
        'englishDefinition': definition,
        'acceptedGuess': true,
        'solutionEligible': true,
        'protectedAnswerExclusion': false,
        'reviewStatus': 'machineChecked',
        'source': editorialSource,
        'verificationSource': _sourceLabel(source),
        'sourceId': source['id'],
        'sourceSenseIndex': rawDefinitions.indexOf(
          p['sourceDefinition'] as String,
        ),
        'reviewMethod': 'agent-editorial-source-checked-v1',
        'note': p['reason'],
      };
      editorial++;
    }
  }
  if (proposalErrors.isNotEmpty) {
    throw FormatException(
      'Editorial proposals need correction:\n${proposalErrors.join('\n')}',
    );
  }
  var changed = 0;
  for (final item in decisions.entries) {
    final next = {...?overrides[item.key], ...item.value};
    if (jsonEncode(next) != jsonEncode(overrides[item.key])) changed++;
    overrides[item.key] = next;
  }
  final sorted = decisions.values.toList()
    ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  final report = {
    'schemaVersion': 1,
    'sourceCommit': sourceCommit,
    'policy': 'Source-matched automated decisions plus source-checked agent editorial decisions; not human review.',
    'sourceMatchedRecords': matched,
    'editorialProposals': editorial,
    'newEntries': added,
    'changedOverrides': changed,
    'approved': sorted.where((e) => e['solutionEligible'] == true).length,
    'held': sorted.where((e) => e['solutionEligible'] == false).length,
    'entries': sorted,
  };
  _write('../reports/content/punjabi_content_review.json', report);
  stdout.writeln(jsonEncode({...report}..remove('entries')));
  if (!write) return;
  overridesDocument['entries'] = overrides.values.toList()
    ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  _write(overrideFile, overridesDocument);
  _write(supplementalFile, supplements);
}

String _sourceLabel(Map<String, dynamic> source) =>
    'Mahan Kosh multilingual dataset; commit $sourceCommit; '
    'vol. ${source['vol']}, p. ${source['page']}; entry ${source['id']}';

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void _write(String path, Map<String, dynamic> document) {
  final file = File('$path.tmp');
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(document)}\n',
  );
  file.renameSync(path);
}
