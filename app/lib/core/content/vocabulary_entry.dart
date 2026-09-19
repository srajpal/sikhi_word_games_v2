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

  bool get hasDistributableDefinition =>
      englishDefinition.trim().isNotEmpty &&
      (source == 'Open English WordNet 2025 (CC BY 4.0)' ||
          source.startsWith(
            'Mahan Kosh multilingual dataset; commit '
            'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6;',
          ) ||
          source ==
              'Project editorial definition; original text for Sikhi Word Games');

  /// Player-facing form of the source definition. The imported text remains
  /// unchanged for provenance, review, and serialization.
  String get displayDefinition =>
      hasDistributableDefinition && englishDefinition.trim().isNotEmpty
      ? englishDefinition
            .replaceAll(RegExp(r'\s*[\u2013\u2014]\s*'), ' - ')
            .replaceAll('\u2026', '...')
      : 'Definition unavailable for this word.';

  VocabularyEntry copyWith({
    String? englishDefinition,
    String? gurmukhi,
    bool? acceptedGuess,
    bool? solutionEligible,
    ReviewStatus? reviewStatus,
    String? source,
  }) => VocabularyEntry(
    id: id,
    language: language,
    latin: latin,
    gurmukhi: gurmukhi ?? this.gurmukhi,
    englishDefinition: englishDefinition ?? this.englishDefinition,
    latinLength: latinLength,
    gurmukhiLength: gurmukhiLength,
    acceptedGuess: acceptedGuess ?? this.acceptedGuess,
    solutionEligible: solutionEligible ?? this.solutionEligible,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    source: source ?? this.source,
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
      source: sources.cast<String>().firstWhere(
        (source) =>
            source == 'Open English WordNet 2025 (CC BY 4.0)' ||
            source.startsWith(
              'Mahan Kosh multilingual dataset; commit '
              'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6;',
            ) ||
            source == 'Project editorial definition; original text for Sikhi Word Games',
        orElse: () => sources.first as String,
      ),
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
