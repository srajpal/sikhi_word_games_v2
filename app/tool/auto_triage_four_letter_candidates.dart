import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final shouldWrite = arguments.contains('--write');
  final reportFile = File('../reports/content/four_letter_candidates.json');
  final decisionsFile = File(
    'assets/content/curation/four_letter_decisions.json',
  );
  final report =
      jsonDecode(reportFile.readAsStringSync()) as Map<String, Object?>;
  final decisionsDocument =
      jsonDecode(decisionsFile.readAsStringSync()) as Map<String, Object?>;
  final existingDecisions = <String, Map<String, Object?>>{};
  for (final item in decisionsDocument['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    existingDecisions[entry['word']! as String] = entry;
  }

  final approved = <Map<String, Object?>>[];
  final rejected = <Map<String, Object?>>[];
  final skipped = <Map<String, Object?>>[];
  for (final item in report['candidates']! as List<Object?>) {
    final candidate = item! as Map<String, Object?>;
    final word = candidate['word']! as String;
    if (candidate['currentlyActiveAnswer'] == true ||
        existingDecisions.containsKey(word)) {
      continue;
    }
    final definition = (candidate['definition']! as String).trim();
    final rejectionReason = _controversialReason(word);
    if (rejectionReason != null) {
      rejected.add(_decision(word, 'reject', definition, rejectionReason));
      continue;
    }
    final approvalIssue = _approvalIssue(candidate, definition);
    if (approvalIssue == null) {
      approved.add(
        _decision(
          word,
          'approve',
          definition,
          'Auto-approved: common, independently verified, and definition '
              'passed clarity checks.',
        ),
      );
    } else {
      skipped.add({
        'word': word,
        'reason': approvalIssue,
        'recommendation': candidate['recommendation'],
      });
    }
  }

  final proposed = [...existingDecisions.values, ...approved, ...rejected]
    ..sort((a, b) => (a['word']! as String).compareTo(b['word']! as String));
  stdout.writeln(
    'Automatic triage: ${approved.length} approvals, '
    '${rejected.length} controversial-word rejections, '
    '${skipped.length} left for review.',
  );
  _printSamples('Approval sample', approved);
  _printSamples('Rejection sample', rejected);
  _writeTriageReport(approved, rejected, skipped);
  if (!shouldWrite) {
    stdout.writeln('No decisions changed. Rerun with --write to save.');
    return;
  }

  decisionsDocument['entries'] = proposed;
  _writeDocument(decisionsFile, decisionsDocument);
  stdout.writeln('Saved automatic decisions without replacing human choices.');
}

Map<String, Object?> _decision(
  String word,
  String decision,
  String definition,
  String notes,
) => {
  'word': word,
  'decision': decision,
  'definition': definition,
  'notes': notes,
  'method': 'automatic_v1',
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
};

String? _controversialReason(String word) {
  const blockedWords = {
    'ANAL',
    'ANUS',
    'ARSE',
    'COCK',
    'COON',
    'CRAP',
    'CUNT',
    'DAGO',
    'DAMN',
    'DICK',
    'DOPE',
    'DYKE',
    'FUCK',
    'GOOK',
    'HOMO',
    'JISM',
    'JIZZ',
    'KIKE',
    'NAZI',
    'NUDE',
    'PISS',
    'POOP',
    'PORN',
    'PUSS',
    'RAPE',
    'SEXY',
    'SHIT',
    'SLUT',
    'SPIC',
    'SPIK',
    'TITS',
    'TURD',
  };
  if (blockedWords.contains(word)) {
    return 'Auto-rejected: sensitive, explicit, or derogatory spelling.';
  }
  return null;
}

String? _approvalIssue(Map<String, Object?> candidate, String definition) {
  if (!const {
    'high_priority_review',
    'standard_review',
  }.contains(candidate['recommendation'])) {
    return 'not in the common-word review tiers';
  }
  final frequency = (candidate['zipfFrequency'] as num?)?.toDouble() ?? 0;
  if (frequency < 3.5) return 'usage frequency below automatic threshold';
  final scowlSize = candidate['scowlSize'] as int?;
  if (scowlSize == null || scowlSize > 50) {
    return 'SCOWL tier above automatic threshold';
  }
  if (definition.length < 12 || definition.length > 160) {
    return 'definition length requires review';
  }
  if (RegExp(
    r'\b(obscene|vulgar|profan(?:e|ity)|racial slur|ethnic slur|offensive '
    r'term|derogatory|pornograph(?:y|ic)|sexual intercourse|genitals?|'
    r'penis|vagina|feces|excrement|defecat(?:e|ion)|rape|racist|marijuana|'
    r'narcotic)\b',
    caseSensitive: false,
  ).hasMatch(definition)) {
    return 'definition contains sensitive or explicit content';
  }
  final word = candidate['word']! as String;
  if (word.endsWith('S') && !const {'NEWS'}.contains(word)) {
    return 'possible plural or inflected form';
  }
  final unclear = RegExp(
    r'^(of\b|see\b|imp\.|p\. ?p\.|plural\b|past tense\b|present '
    r'participle\b|alternative spelling\b)|\b(see|archaic|obsolete|dialectal|'
    r'Shakespearean|supposed to mean|same as|variant of|word used|'
    r'one of numerous species|formerly|contracted|retinue|moiety|thereof|'
    r'therein|whereby|wherein|therewith|name given)\b|\bimp\.|\besp\.|--|'
    r'\betc\.?$',
    caseSensitive: false,
  );
  if (unclear.hasMatch(definition)) {
    return 'definition is referential, archaic, vague, or overly broad';
  }
  final normalizedDefinition = definition
      .replaceAll(RegExp(r'[^A-Za-z]'), '')
      .toUpperCase();
  if (normalizedDefinition == word) return 'definition repeats the word';
  return null;
}

void _printSamples(String label, List<Map<String, Object?>> entries) {
  final sample = entries.take(30).map((entry) => entry['word']).join(', ');
  stdout.writeln('$label: ${sample.isEmpty ? 'none' : sample}');
}

void _writeTriageReport(
  List<Map<String, Object?>> approved,
  List<Map<String, Object?>> rejected,
  List<Map<String, Object?>> skipped,
) {
  final file = File('../reports/content/four_letter_auto_triage.json');
  _writeDocument(file, {
    'schemaVersion': 1,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'rulesVersion': 1,
    'counts': {
      'approved': approved.length,
      'rejected': rejected.length,
      'leftForReview': skipped.length,
    },
    'approved': approved,
    'rejected': rejected,
    'leftForReview': skipped,
  });
}

void _writeDocument(File file, Map<String, Object?> document) {
  const encoder = JsonEncoder.withIndent('  ');
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync('${encoder.convert(document)}\n');
  temporary.renameSync(file.path);
}
