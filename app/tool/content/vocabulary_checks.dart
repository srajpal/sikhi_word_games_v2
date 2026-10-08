import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';

const vocabularyRuleVersion = 1;

/// Binds a hold to the actual public spelling, definition and attribution.
/// Changing editorial text requires a fresh recheck, not a silent release.
String vocabularyFingerprint(Map<String, Object?> entry) => sha256
    .convert(
      utf8.encode(
        jsonEncode([
          entry['id'],
          entry['language'],
          entry['latin'],
          entry['gurmukhi'],
          entry['definitions'],
          entry['sources'],
        ]),
      ),
    )
    .toString();

String englishDefinition(Map<String, Object?> entry) =>
    ((entry['definitions']! as Map<String, Object?>)['en']! as List).first
        as String;

/// Conservative quarantine signals, not a certificate of child suitability.
/// A source-correct sense may still be unsuitable for the intended audience.
List<String> definitionHoldReasons(String text) {
  if (text.isEmpty) return const [];
  final reasons = <String>[];
  if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\uFFFD]').hasMatch(text)) {
    reasons.add('corrupt_definition');
  }
  if (text.characters.length > 220) reasons.add('overlong_definition');
  if (RegExp(
    r'^(?:see also|see definition of|compare with|plural of|past tense of|present participle of|alternative (?:spelling|form) of|variant of)\b|^(?:see|compare|of)\s+[\p{L}\p{M}\x27-]+\.$',
    caseSensitive: false,
    unicode: true,
  ).hasMatch(text.trim())) {
    reasons.add('reference_only');
  }
  if (RegExp(
    r'\b(?:deranged|idiot|idiots|imbecile|imbeciles|retarded|heathen|heathens|infidel|infidels|uncivilized|nigger|niggers|fuck|fucking|shit|cunt|sexual intercourse|sexual arousal|genitals|penis|vagina|prostitute|prostitution|pornography|masturbation)\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    reasons.add('sensitive_or_stigmatizing');
  }
  return reasons;
}

Map<String, Object?> applyVocabularyHold(
  Map<String, Object?> entry,
  Map<String, Object?> hold,
) {
  if (hold['fingerprint'] != vocabularyFingerprint(entry)) {
    throw StateError(
      'Stale vocabulary hold for ${entry['id']}. Recheck vocabulary.',
    );
  }
  return {
    ...entry,
    'definitions': {
      'en': [''],
      'pa': <String>[],
    },
    'solutionEligible': false,
  };
}
