import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:sikhi_word_games_v2/core/language/gurmukhi_normalization.dart';

import 'content/punjabi_quality.dart';
import 'content/mahan_kosh_text.dart';

/// Imports a locked, attributed Punjabi dictionary. Machine checks do not
/// approve answers: only the bounded, exact-sense curation list does that.
void main(List<String> arguments) {
  final write = arguments.contains('--write');
  final check = arguments.contains('--check');
  final lock = _object('tool/content/punjabi_v2_source_lock.json');
  final snapshot = lock['snapshot'] as Map<String, dynamic>;
  final bytes = File(snapshot['path'] as String).readAsBytesSync();
  if (sha256.convert(bytes).toString() != snapshot['sha256']) {
    throw StateError('Punjabi source snapshot hash mismatch.');
  }
  final curated = <String, Map<String, dynamic>>{};
  final curatedWords = <String>{};
  final decisions = _object('assets/content/curation/punjabi_v2_answers.json');
  for (final item in decisions['entries'] as List) {
    final decision = item as Map<String, dynamic>;
    final sense = decision['senseId'] as String;
    if (curated.containsKey(sense)) {
      throw StateError('Duplicate Punjabi v2 decision: $sense');
    }
    if (!curatedWords.add(normalizeGurmukhi(decision['word'] as String))) {
      throw StateError(
        'Multiple Punjabi v2 answer senses for ${decision['word']}',
      );
    }
    curated[sense] = decision;
  }
  final applied = <String>{};
  final entries = <String, Map<String, Object?>>{};
  final skipped = <String, int>{};
  final sourceHolds = <Map<String, Object?>>[];
  var records = 0;
  var senseCount = 0;
  void skip(String reason) =>
      skipped.update(reason, (n) => n + 1, ifAbsent: () => 1);
  void hold(
    String word,
    String pos,
    Map<String, dynamic> sense,
    List<String> reasons,
  ) {
    sourceHolds.add({
      'gurmukhi': word,
      'partOfSpeech': pos,
      'senseId': sense['id'],
      'sourceGlosses': sense['glosses'],
      'sourceTags': sense['tags'] ?? [],
      'reasons': reasons,
      'runtimeIncluded': false,
      'sourceUrl':
          'https://en.wiktionary.org/wiki/${Uri.encodeComponent(word)}#Punjabi',
    });
  }

  for (final line in const LineSplitter().convert(
    utf8.decode(gzip.decode(bytes)),
  )) {
    if (line.isEmpty) continue;
    records++;
    final row = jsonDecode(line) as Map<String, dynamic>;
    final word = row['word'] as String;
    final pos = row['pos'] as String;
    if (!RegExp(r'^[\u0A00-\u0A7F]+$').hasMatch(word) ||
        !{'noun', 'verb', 'adj', 'adv'}.contains(pos)) {
      skip('script_or_part_of_speech');
      continue;
    }
    final romans = (row['romanizations'] as List).cast<String>();
    final latin = romans.length == 1
        ? romanizeWiktionaryPunjabi(romans.single)
        : null;
    if (latin == null) {
      skip('uncertain_romanization');
      for (final sense in row['senses'] as List) {
        hold(word, pos, sense as Map<String, dynamic>, [
          'uncertain_romanization',
        ]);
      }
      continue;
    }
    for (final item in row['senses'] as List) {
      senseCount++;
      final sense = item as Map<String, dynamic>;
      final senseId = sense['id'] as String?;
      final glosses = (sense['glosses'] as List? ?? []).cast<String>();
      final tags = (sense['tags'] as List? ?? []).cast<String>().toSet();
      if (senseId == null ||
          glosses.length != 1 ||
          _heldHeadwords.contains(normalizeGurmukhi(word)) ||
          sense.containsKey('form_of') ||
          sense.containsKey('alt_of') ||
          tags.intersection(_heldTags).isNotEmpty ||
          _reference.hasMatch(glosses.single)) {
        skip('reference_or_held_sense');
        hold(word, pos, sense, [
          if (senseId == null || glosses.length != 1)
            'missing_single_source_sense',
          if (_heldHeadwords.contains(normalizeGurmukhi(word)))
            'explicit_source_review_hold',
          if (sense.containsKey('form_of') || sense.containsKey('alt_of'))
            'form_or_alternative',
          ...tags.intersection(_heldTags).map((tag) => 'source_tag:$tag'),
          if (glosses.length == 1 && _reference.hasMatch(glosses.single))
            'reference_only',
        ]);
        continue;
      }
      final decision = curated[senseId];
      if (decision != null &&
          (decision['word'] != word ||
              decision['sourceGloss'] != glosses.single)) {
        throw StateError('Stale Punjabi v2 sense decision: $senseId');
      }
      final definition = (decision?['definition'] as String? ?? glosses.single)
          .trim();
      final checkedLatin = decision?['latin'] as String? ?? latin;
      final assessment = assessPunjabiQuality(
        PunjabiQualityCandidate(
          gurmukhi: word,
          latin: checkedLatin,
          englishDefinition: definition,
        ),
      );
      final risk =
          _risk.hasMatch(definition) ||
          _risk.hasMatch(glosses.single) ||
          (pos == 'noun' &&
              RegExp(
                r'\bsnuff\b',
                caseSensitive: false,
              ).hasMatch(glosses.single));
      if (assessment.blockingIssues.isNotEmpty ||
          risk ||
          !hasMatchingPunjabiConsonants(word, checkedLatin) ||
          definition.split(RegExp(r'\s+')).length > 24) {
        skip('quality_or_suitability_hold');
        hold(word, pos, sense, [
          ...assessment.blockingIssues.map((issue) => issue.code),
          if (risk) 'risky_or_stigmatizing_sense',
          if (!hasMatchingPunjabiConsonants(word, checkedLatin))
            'romanization_consonant_mismatch',
          if (definition.split(RegExp(r'\s+')).length > 24) 'overlong_gloss',
        ]);
        continue;
      }
      if (decision != null) applied.add(senseId);
      final key = normalizeGurmukhi(word);
      final previous = entries[key];
      // Stable first suitable sense, unless a checked everyday sense is selected.
      if (previous != null &&
          (previous['solutionEligible'] == true || decision == null)) {
        continue;
      }
      final url =
          'https://en.wiktionary.org/wiki/${Uri.encodeComponent(word)}#Punjabi';
      entries[key] = {
        'id':
            'panjabi_v2_${word.runes.map((r) => r.toRadixString(16)).join('_')}',
        'language': 'panjabi',
        'latin': checkedLatin,
        'gurmukhi': word,
        'definitions': {
          'en': [definition],
          'pa': <String>[],
        },
        'lengths': {
          'latin': checkedLatin.characters.length,
          'gurmukhi': word.characters.length,
        },
        'acceptedGuess': true,
        'solutionEligible': decision != null,
        'reviewStatus': 'machineChecked',
        'sources': [
          'English Wiktionary contributors (CC BY-SA 4.0); $url',
          'Kaikki Punjabi extraction 2026-10-03; Wiktionary dump 2026-09-02; sense $senseId',
          if (decision != null) 'Sikhi Word Games source-checked AI editorial selection; independent human Punjabi review pending',
        ],
      };
    }
  }
  if (!applied.containsAll(curated.keys)) {
    throw StateError(
      'Unapplied Punjabi v2 decisions: ${curated.keys.toSet().difference(applied)}',
    );
  }
  final output = entries.values.toList()
    ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  final answers = output.where((e) => e['solutionEligible'] == true).toList();
  final report = <String, Object?>{
    'schemaVersion': 1,
    'source': lock['source'],
    'snapshot': snapshot,
    'curationSha256': sha256
        .convert(
          utf8.encode(
            File('assets/content/curation/punjabi_v2_answers.json')
                .readAsStringSync()
                .replaceAll('\r\n', '\n'),
          ),
        )
        .toString(),
    'sourceRecords': records,
    'examinedNativeLemmaSenses': senseCount,
    'skipped': skipped,
    'sourceHolds': sourceHolds,
    'records': output.length,
    'answerRecords': answers.length,
    'frequency': {
      'available': false,
      'reason': 'No verified, licensed Punjabi frequency dataset is bundled. Hindi and Urdu scores are not substitutes.',
    },
    'review': 'Mechanical filters and bounded source-checked AI editorial selections. No independent human linguistic review is claimed.',
    'dictionarySample': [
      for (
        var index = 0;
        index < output.length;
        index += (output.length ~/ 30).clamp(1, output.length)
      )
        {
          'gurmukhi': output[index]['gurmukhi'],
          'latin': output[index]['latin'],
          'definitions': output[index]['definitions'],
          'sources': output[index]['sources'],
        },
    ],
    'answerPools': {
      for (final mode in ['latin', 'gurmukhi'])
        mode: {
          for (final length in [4, 5, 6])
            '$length': answers
                .where((e) => (e['lengths'] as Map)[mode] == length)
                .map((e) => e[mode])
                .toSet()
                .length,
        },
    },
    'answers': answers
        .map(
          (e) => {
            'id': e['id'],
            'latin': e['latin'],
            'gurmukhi': e['gurmukhi'],
            'definition': (e['definitions'] as Map)['en'],
            'lengths': e['lengths'],
            'sources': e['sources'],
          },
        )
        .toList(),
  };
  var stale = false;
  for (final item in {
    'assets/content/generated/punjabi_v2.json': '${jsonEncode(output)}\n',
    '../reports/content/punjabi_dictionary_v2.json':
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  }.entries) {
    final file = File(item.key);
    if (!file.existsSync() ||
        file.readAsStringSync().replaceAll('\r\n', '\n') != item.value) {
      stale = true;
    }
    if (write) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(item.value);
    }
  }
  stdout.writeln(
    'Punjabi v2: ${output.length} dictionary records, ${answers.length} bounded answer selections; pools ${report['answerPools']}.',
  );
  if (check && stale) {
    throw StateError('Punjabi v2 outputs stale. Run --write.');
  }
}

Map<String, dynamic> _object(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

const _heldTags = {
  'form-of',
  'alternative',
  'archaic',
  'obsolete',
  'dated',
  'rare',
  'offensive',
  'vulgar',
  'derogatory',
  'slang',
  'euphemistic',
  'figuratively',
  'historical',
};
final _reference = RegExp(
  r'\b(form of|spelling of|synonym of|alternative|nuqtaless|plural of|inflection of|see also)\b',
  caseSensitive: false,
);
final _risk = RegExp(
  r'\b(sex\w*|sodom\w*|intercourse|penis|vagina|anus|anal|rectum|genitals?|testicles?|scrotum|erection|prostitut\w*|breast|menses|menstru\w*|urine|feces|faeces|excrement|slur|castes?|untouchab\w*|idiot\w*|stupid\w*|fools?|drunk\w*|alcohol\w*|narcotic\w*|addiction|beer|whisk(?:y|ey)|wine|brandy|liquor|booze|intoxicant\w*|intoxicat\w*|inebriat\w*|cigarette\w*|cigar\w*|tobacco|hookah|bidi|heroin|opium|cocaine|cannabis|marijuana|gambl\w*|crippl\w*|imbecile\w*|lunatic\w*|kill\w*|murder\w*|suicide|rapes?|whore\w*|bastard\w*|nigger\w*|faggot\w*|shit\w*|fuck\w*|damn\w*|porn\w*|obscene\w*|semen|masturb\w*|piss\w*|bitch\w*|fart\w*|terror\w*|genocide|holocaust|massacre|slaughter|violent|violence|threateningly|attack|assault|raid|war|warfare|battle|combat\w*|torture\w*|gunpowder|explosive|dynamite|naked|nude|insan\w*|lunacy|madness|deranged|daft|mad|dumb|corpse|death|dead|die|perish)\b',
  caseSensitive: false,
);
// Sample-discovered cases whose source gloss lacks a modern usage warning.
// These are conservative holds, not assertions that every usage is abusive.
final _heldHeadwords = {'ਹਬਸ਼ੀ', 'ਕਾਣਾ', 'ਲੰਙਾ'}.map(normalizeGurmukhi).toSet();

/// ASCII gameplay spelling from the source's Punjabi romanization. Unknown
/// notation is held. Vowel length/tone/retroflex detail remains in the snapshot.
String? romanizeWiktionaryPunjabi(String text) {
  const map = {
    'ā': 'a',
    'ă': 'a',
    'á': 'a',
    'ī': 'i',
    'ĭ': 'i',
    'ū': 'u',
    'ē': 'e',
    'ō': 'o',
    'ṇ': 'n',
    'ṭ': 't',
    'ḍ': 'd',
    'ś': 'sh',
    'ṛ': 'r',
    'ṅ': 'n',
    'ñ': 'n',
    'ḷ': 'l',
    'ġ': 'gh',
    'ṉ': 'n',
    'ź': 'z',
    'ṃ': 'm',
    'ã': 'an',
    'ĩ': 'in',
    'ũ': 'un',
    'ẽ': 'en',
    'õ': 'on',
    '\u0303': 'n',
  };
  final result = StringBuffer();
  for (final character in text.toLowerCase().runes.map(String.fromCharCode)) {
    if (map.containsKey(character)) {
      result.write(map[character]);
    } else if (RegExp(r'^[a-z]$').hasMatch(character)) {
      result.write(character == 'c' ? 'ch' : character);
    } else {
      return null;
    }
  }
  final latin = result.toString().toUpperCase();
  return RegExp(r'^[A-Z]{2,24}$').hasMatch(latin) ? latin : null;
}
