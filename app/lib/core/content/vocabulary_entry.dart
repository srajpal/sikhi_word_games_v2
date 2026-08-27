import 'dart:convert';

enum VocabularyLanguage { english, panjabi }

enum ReviewStatus {
  unreviewed,
  machineChecked,
  communityReviewed,
  editorApproved,
}

class VocabularyEntry {
  const VocabularyEntry({
    required this.id,
    required this.language,
    required this.latin,
    required this.gurmukhi,
    required this.englishDefinition,
    required this.latinLength,
    required this.gurmukhiLength,
    required this.acceptedGuess,
    required this.solutionEligible,
    required this.reviewStatus,
    required this.source,
  });

  final String id;
  final VocabularyLanguage language;
  final String latin;
  final String? gurmukhi;
  final String englishDefinition;
  final int latinLength;
  final int? gurmukhiLength;
  final bool acceptedGuess;
  final bool solutionEligible;
  final ReviewStatus reviewStatus;
  final String source;

  Map<String, Object?> toJson() => {
    'id': id,
    'language': language.name,
    'latin': latin,
    'gurmukhi': gurmukhi,
    'definitions': {
      'en': [englishDefinition],
      'pa': <String>[],
    },
    'lengths': {'latin': latinLength, 'gurmukhi': gurmukhiLength},
    'acceptedGuess': acceptedGuess,
    'solutionEligible': solutionEligible,
    'reviewStatus': reviewStatus.name,
    'sources': [source],
  };

  String toJsonString() => jsonEncode(toJson());
}
