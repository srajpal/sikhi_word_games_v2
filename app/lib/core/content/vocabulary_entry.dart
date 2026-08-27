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

  VocabularyEntry copyWith({
    bool? acceptedGuess,
    bool? solutionEligible,
    ReviewStatus? reviewStatus,
  }) => VocabularyEntry(
    id: id,
    language: language,
    latin: latin,
    gurmukhi: gurmukhi,
    englishDefinition: englishDefinition,
    latinLength: latinLength,
    gurmukhiLength: gurmukhiLength,
    acceptedGuess: acceptedGuess ?? this.acceptedGuess,
    solutionEligible: solutionEligible ?? this.solutionEligible,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    source: source,
  );

  factory VocabularyEntry.fromJson(Map<String, Object?> json) {
    final definitions = json['definitions']! as Map<String, Object?>;
    final englishDefinitions = definitions['en']! as List<Object?>;
    final lengths = json['lengths']! as Map<String, Object?>;
    final sources = json['sources']! as List<Object?>;
    return VocabularyEntry(
      id: json['id']! as String,
      language: VocabularyLanguage.values.byName(json['language']! as String),
      latin: json['latin']! as String,
      gurmukhi: json['gurmukhi'] as String?,
      englishDefinition: englishDefinitions.first as String,
      latinLength: lengths['latin']! as int,
      gurmukhiLength: lengths['gurmukhi'] as int?,
      acceptedGuess: json['acceptedGuess']! as bool,
      solutionEligible: json['solutionEligible']! as bool,
      reviewStatus: ReviewStatus.values.byName(json['reviewStatus']! as String),
      source: sources.first as String,
    );
  }

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
