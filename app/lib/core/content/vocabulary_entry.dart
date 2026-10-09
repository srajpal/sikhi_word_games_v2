import 'dart:convert';

import 'vocabulary_licenses.dart';
import '../language/word_units.dart';

enum VocabularyLanguage { english, panjabi }

enum VocabularyScript { english, romanizedPunjabi, gurmukhi }

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
    this.script,
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
  final VocabularyScript? script;

  bool get isOwnerApproved =>
      script != null && reviewStatus == ReviewStatus.editorApproved;

  bool supportsScript(VocabularyScript mode) => script != null
      ? script == mode
      : language == VocabularyLanguage.english
      ? mode == VocabularyScript.english
      : mode != VocabularyScript.english;

  bool get hasDistributableDefinition =>
      englishDefinition.trim().isNotEmpty && isTrustedVocabularySource(source);

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
    script: script,
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
        isTrustedVocabularySource,
        orElse: () => sources.first as String,
      ),
      script: json['script'] is String
          ? VocabularyScript.values.byName(json['script']! as String)
          : null,
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
    if (script != null) 'script': script!.name,
  };

  factory VocabularyEntry.fromApprovedJson(
    Map<String, Object?> json,
    VocabularyScript script,
  ) {
    final word = json['word']! as String;
    final units = (json['letter_units']! as List<Object?>).cast<String>();
    final computed = wordUnits(word);
    if (units.join() != word ||
        units.length != json['tile_count'] ||
        computed.length != units.length ||
        !List.generate(
          units.length,
          (i) => computed[i] == units[i],
        ).every((v) => v)) {
      throw FormatException('Approved word has invalid letter units: $word');
    }
    final definition = json['definition']! as String;
    if (definition.trim().isEmpty) {
      throw FormatException('Approved word has no definition: $word');
    }
    final romanizations = json['romanizations'] as List<Object?>?;
    final latin = script == VocabularyScript.gurmukhi
        ? (romanizations?.firstOrNull as String? ?? '').toUpperCase()
        : word.toUpperCase();
    final gurmukhi = script == VocabularyScript.gurmukhi
        ? word
        : json['gurmukhi_word'] as String?;
    final prefix = switch (script) {
      VocabularyScript.english => 'en',
      VocabularyScript.romanizedPunjabi => 'rom',
      VocabularyScript.gurmukhi => 'gur',
    };
    return VocabularyEntry(
      id: 'approved_${prefix}_${base64Url.encode(utf8.encode(word)).replaceAll('=', '')}',
      language: script == VocabularyScript.english
          ? VocabularyLanguage.english
          : VocabularyLanguage.panjabi,
      latin: latin,
      gurmukhi: gurmukhi,
      englishDefinition: definition,
      latinLength: wordUnitCount(latin),
      gurmukhiLength: gurmukhi == null ? null : wordUnitCount(gurmukhi),
      acceptedGuess: true,
      solutionEligible: true,
      reviewStatus: ReviewStatus.editorApproved,
      source: script == VocabularyScript.english
          ? 'Princeton WordNet 3.0 (WordNet license); https://wordnet.princeton.edu/; synset ${json['synset_id']}'
          : 'English Wiktionary contributors (CC BY-SA 4.0); ${json['source_url']}; contributor history ${json['source_history_url']}',
      script: script,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}
