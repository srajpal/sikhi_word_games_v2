import 'dart:collection';

import 'package:characters/characters.dart';

enum PunjabiQualityIssue {
  missingGurmukhi('missing_gurmukhi'),
  invalidGurmukhi('invalid_gurmukhi'),
  missingLatin('missing_latin'),
  invalidLatin('invalid_latin'),
  missingDefinition('missing_definition'),
  definitionTooLong('definition_too_long'),
  controlCharacter('control_character'),
  crossReferenceOnly('cross_reference_only'),
  circularDefinition('circular_definition'),
  answerLeak('answer_leak'),
  possibleOcrFragment('possible_ocr_fragment'),
  properNameOrPlaceOnly('proper_name_or_place_only'),
  sensitiveAdultOrSlurTerm('sensitive_adult_or_slur_term');

  const PunjabiQualityIssue(this.code);

  final String code;
}

class PunjabiQualityCandidate {
  const PunjabiQualityCandidate({
    required this.gurmukhi,
    required this.latin,
    required this.englishDefinition,
  });

  final String gurmukhi;
  final String latin;
  final String englishDefinition;
}

class PunjabiQualityAssessment {
  PunjabiQualityAssessment({
    required Set<PunjabiQualityIssue> detectedIssues,
    required Set<PunjabiQualityIssue> clearedIssues,
  }) : detectedIssues = UnmodifiableSetView(detectedIssues),
       clearedIssues = UnmodifiableSetView(clearedIssues),
       blockingIssues = UnmodifiableSetView(
         detectedIssues.difference(clearedIssues),
       );

  final Set<PunjabiQualityIssue> detectedIssues;
  final Set<PunjabiQualityIssue> clearedIssues;
  final Set<PunjabiQualityIssue> blockingIssues;

  bool get isPromotionCandidate => blockingIssues.isEmpty;
}

const _editoriallyClearable = {
  PunjabiQualityIssue.possibleOcrFragment,
  PunjabiQualityIssue.properNameOrPlaceOnly,
  PunjabiQualityIssue.sensitiveAdultOrSlurTerm,
};

PunjabiQualityAssessment assessPunjabiQuality(
  PunjabiQualityCandidate candidate, {
  Set<PunjabiQualityIssue> editoriallyClearedIssues = const {},
}) {
  final issues = <PunjabiQualityIssue>{};
  final gurmukhi = candidate.gurmukhi;
  final latin = candidate.latin;
  final definition = candidate.englishDefinition.trim();

  if (gurmukhi.isEmpty) {
    issues.add(PunjabiQualityIssue.missingGurmukhi);
  } else if (gurmukhi != gurmukhi.trim() || !_validGurmukhi(gurmukhi)) {
    issues.add(PunjabiQualityIssue.invalidGurmukhi);
  }
  if (latin.isEmpty) {
    issues.add(PunjabiQualityIssue.missingLatin);
  } else if (!RegExp(r'^[A-Z]+$').hasMatch(latin)) {
    issues.add(PunjabiQualityIssue.invalidLatin);
  }
  if (definition.isEmpty || !RegExp(r'[A-Za-z]').hasMatch(definition)) {
    issues.add(PunjabiQualityIssue.missingDefinition);
  } else {
    if (definition.characters.length > 180) {
      issues.add(PunjabiQualityIssue.definitionTooLong);
    }
    if (_crossReference.hasMatch(definition)) {
      issues.add(PunjabiQualityIssue.crossReferenceOnly);
    }
    final foldedDefinition = _fold(definition);
    if (foldedDefinition == _fold(latin) ||
        foldedDefinition == _fold(gurmukhi)) {
      issues.add(PunjabiQualityIssue.circularDefinition);
    }
    if (_leaksAnswer(definition, latin, gurmukhi)) {
      issues.add(PunjabiQualityIssue.answerLeak);
    }
    if (_looksLikeOcrOrDictionaryDebris(definition)) {
      issues.add(PunjabiQualityIssue.possibleOcrFragment);
    }
    if (_properNameOnly.hasMatch(definition)) {
      issues.add(PunjabiQualityIssue.properNameOrPlaceOnly);
    }
    if (_sensitiveTerm.hasMatch(definition)) {
      issues.add(PunjabiQualityIssue.sensitiveAdultOrSlurTerm);
    }
  }
  if (_controlCharacter.hasMatch(gurmukhi) ||
      _controlCharacter.hasMatch(latin) ||
      _controlCharacter.hasMatch(candidate.englishDefinition)) {
    issues.add(PunjabiQualityIssue.controlCharacter);
  }

  final cleared = issues
      .intersection(editoriallyClearedIssues)
      .intersection(_editoriallyClearable);
  return PunjabiQualityAssessment(
    detectedIssues: issues,
    clearedIssues: cleared,
  );
}

bool _validGurmukhi(String value) {
  // Gurmukhi virama conjuncts can span extended grapheme boundaries in the
  // Unicode version used by characters. Validate the script sequence rather
  // than requiring every cluster to be an independently spelled word.
  var hasBase = false;
  var needsConjunctBase = false;
  for (final rune in value.runes) {
    if (_isGurmukhiBase(rune)) {
      hasBase = true;
      needsConjunctBase = false;
    } else if (_isGurmukhiMark(rune)) {
      if (!hasBase || needsConjunctBase) return false;
      if (rune == 0x0A4D) needsConjunctBase = true;
    } else {
      return false;
    }
  }
  return hasBase && !needsConjunctBase;
}

bool _isGurmukhiBase(int rune) =>
    (rune >= 0x0A05 && rune <= 0x0A0A) ||
    (rune >= 0x0A0F && rune <= 0x0A10) ||
    (rune >= 0x0A13 && rune <= 0x0A28) ||
    (rune >= 0x0A2A && rune <= 0x0A30) ||
    (rune >= 0x0A32 && rune <= 0x0A33) ||
    (rune >= 0x0A35 && rune <= 0x0A36) ||
    (rune >= 0x0A38 && rune <= 0x0A39) ||
    (rune >= 0x0A59 && rune <= 0x0A5C) ||
    rune == 0x0A5E ||
    rune == 0x0A72 ||
    rune == 0x0A73;

bool _isGurmukhiMark(int rune) =>
    (rune >= 0x0A01 && rune <= 0x0A03) ||
    rune == 0x0A3C ||
    (rune >= 0x0A3E && rune <= 0x0A4C) ||
    rune == 0x0A4D ||
    rune == 0x0A51 ||
    (rune >= 0x0A70 && rune <= 0x0A71) ||
    rune == 0x0A75;

String _fold(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z\u0A01-\u0A75]+'), '');

bool _leaksAnswer(String definition, String latin, String gurmukhi) {
  if (latin.characters.length >= 4 &&
      RegExp(
        '\\b${RegExp.escape(latin)}\\b',
        caseSensitive: false,
      ).hasMatch(definition)) {
    return true;
  }
  if (gurmukhi.isNotEmpty && definition.contains(gurmukhi)) return true;
  for (final answer in [latin, gurmukhi]) {
    if (answer.isEmpty) continue;
    if (RegExp(
      '(?:answer|word|spelling|called|written as)\\s+(?:is\\s+)?["“‘\']?${RegExp.escape(answer)}\\b',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(definition)) {
      return true;
    }
  }
  return false;
}

bool _looksLikeOcrOrDictionaryDebris(String definition) {
  if (definition.contains('\uFFFD') ||
      RegExp(r'\b(\w+)\s+\1\b', caseSensitive: false).hasMatch(definition) ||
      RegExp(
        r'\b(?:syph\w*|gonorr\w*|cures?|remedy|treatment|medicine)\b',
        caseSensitive: false,
      ).hasMatch(definition) ||
      RegExp(r'([!?.,;:])\1{2,}').hasMatch(definition) ||
      RegExp(
        r'\b(?:vol|page|p)\.?\s*\d+\b',
        caseSensitive: false,
      ).hasMatch(definition) ||
      RegExp(
        r'^(?:skt|p|h|n|v|adj|adv)\b|(?:^|[.;])\s*\d+[.)]',
        caseSensitive: false,
      ).hasMatch(definition) ||
      RegExp(r'[\u0600-\u06FF\u0900-\u097F\u0A01-\u0A75]')
          .hasMatch(definition)) {
    return true;
  }
  const pairs = {'(': ')', '[': ']', '{': '}'};
  for (final pair in pairs.entries) {
    if (pair.key.allMatches(definition).length !=
        pair.value.allMatches(definition).length) {
      return true;
    }
  }
  return false;
}

final _controlCharacter = RegExp(r'[\u0000-\u001F\u007F-\u009F]');
final _crossReference = RegExp(
  r'^(?:see|compare|variant of|alternative (?:form|spelling) of|plural of|past tense of|present participle of|of)\b',
  caseSensitive: false,
);
final _properNameOnly = RegExp(
  r'^(?:(?:the )?name of|a (?:personal|family|given) name|a surname|a (?:village|town|city|district|province|country)|(?:a )?proper name)\b|\b(?:son|daughter|wife|husband|father|mother) of\b|^[A-Z][A-Za-z\x27-]+,\s+(?:a|an|the)\s+(?:god|goddess|king|queen|prince|princess|saint)\b',
  caseSensitive: false,
);
final _sensitiveTerm = RegExp(
  r'\b(?:rape|rapist|sex|sexual|lust|lustful|pornography|penis|vagina|genitals?|semen|sperm|vulva|clitoris|copulation|adultery|impotence|lewd|obscene|prostitut\w*|castrat\w*|urine|excrement|defec\w*|shit|bastard|illegitimate|whore|slut|racial slur|venereal disease|syphilis|gonorrhea|murder|murderer|kill(?:ing|ed|s)?|behead(?:ing|ed)?|suicide|torture|caste|untouchable|alcohol|wine|liquor|opium|cannabis|intoxicant|abortion|terminating pregnancy|foeticide|feticide|barbarian|uncivilised|uncivilized|heathen|infidel)\b',
  caseSensitive: false,
);
