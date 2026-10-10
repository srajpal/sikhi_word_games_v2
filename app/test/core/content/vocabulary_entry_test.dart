import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';

void main() {
  for (final (script, word, latin, native) in [
    (VocabularyScript.english, 'mice', 'MICE', null),
    (VocabularyScript.romanizedPunjabi, 'āsān', 'ĀSĀN', 'ਅਸਾਨ'),
    (VocabularyScript.gurmukhi, 'ਅਪ੍ਰੈਲ', 'APRĒL', 'ਅਪ੍ਰੈਲ'),
  ]) {
    test(
      'approved decoder preserves $script spelling, definition, units and membership',
      () {
        final json = <String, Object?>{
          'word': word,
          'definition': 'A supplied definition—or meaning…',
          'letter_units': wordUnits(word),
          'tile_count': wordUnitCount(word),
          'gurmukhi_word': native,
          'romanizations': ['aprēl', 'aprail'],
          'synset_id': 'n00000001',
          'tag_count': 3,
          'source_url': 'https://en.wiktionary.org/wiki/$word',
          'source_history_url':
              'https://en.wiktionary.org/w/index.php?title=$word&action=history',
        };
        final entry = VocabularyEntry.fromApprovedJson(json, script);
        expect(entry.latin, latin);
        expect(entry.gurmukhi, native);
        expect(
          entry.wordNetTagCount,
          script == VocabularyScript.english ? 3 : null,
        );
        expect(
          entry.copyWith(latin: latin).wordNetTagCount,
          entry.wordNetTagCount,
        );
        expect(
          VocabularyEntry.fromJson(entry.toJson()).wordNetTagCount,
          entry.wordNetTagCount,
        );
        expect(entry.englishDefinition, json['definition']);
        expect(
          entry.displayDefinition,
          'A supplied definition - or meaning...',
        );
        expect(entry.latinLength, wordUnitCount(latin));
        expect(
          entry.gurmukhiLength,
          native == null ? null : wordUnitCount(native),
        );
        expect(
          entry.isOwnerApproved &&
              entry.acceptedGuess &&
              entry.solutionEligible,
          isTrue,
        );
        expect(entry.hasDistributableDefinition, isTrue);
        expect(entry.id, VocabularyEntry.fromApprovedJson(json, script).id);
        expect(entry.id, startsWith('approved_'));
        for (final candidate in VocabularyScript.values) {
          expect(entry.supportsScript(candidate), candidate == script);
        }
        expect(
          entry.source,
          contains(
            script == VocabularyScript.english
                ? 'synset n00000001'
                : 'contributor history',
          ),
        );
      },
    );
  }
  test('approved decoder rejects split conjuncts, wrong counts and blank definitions', () {
    final json = <String, Object?>{
      'word': 'ਅਪ੍ਰੈਲ',
      'definition': 'April',
      'letter_units': ['ਅ', 'ਪ੍ਰੈ', 'ਲ'],
      'tile_count': 3,
      'romanizations': ['aprail'],
      'source_url': 'https://en.wiktionary.org/wiki/ਅਪ੍ਰੈਲ',
      'source_history_url':
          'https://en.wiktionary.org/w/index.php?title=ਅਪ੍ਰੈਲ&action=history',
    };
    for (final changes in <Map<String, Object?>>[
      {
        'letter_units': ['ਅ', 'ਪ', '੍ਰੈ', 'ਲ'],
        'tile_count': 4,
      },
      {
        'letter_units': ['ਅ', 'ਪ੍ਰੈ', 'ਰ'],
      },
      {'tile_count': 4},
      {'definition': '  '},
    ]) {
      expect(
        () => VocabularyEntry.fromApprovedJson({
          ...json,
          ...changes,
        }, VocabularyScript.gurmukhi),
        throwsFormatException,
      );
    }
    expect(
      VocabularyEntry.fromApprovedJson(
        json,
        VocabularyScript.gurmukhi,
      ).gurmukhiLength,
      3,
    );
  });
  test('normalizes typographic punctuation in displayed definitions', () {
    final entry = VocabularyEntry.fromJson({
      'id': 'english_test',
      'language': 'english',
      'latin': 'TEST',
      'gurmukhi': null,
      'definitions': {
        'en': ['A trial—or check…'],
        'pa': <String>[],
      },
      'lengths': {'latin': 4, 'gurmukhi': null},
      'acceptedGuess': true,
      'solutionEligible': true,
      'reviewStatus': 'machineChecked',
      'sources': [
        'Princeton WordNet 3.0 (WordNet license); https://wordnet.princeton.edu/',
      ],
    });

    expect(entry.englishDefinition, 'A trial—or check…');
    expect(entry.displayDefinition, 'A trial - or check...');
    expect(
      entry.copyWith(englishDefinition: 'One–two').displayDefinition,
      'One - two',
    );
  });

  test('hides a definition with unclear distribution rights', () {
    const entry = VocabularyEntry(
      id: 'legacy_test',
      language: VocabularyLanguage.english,
      wordNetTagCount: 3,
      latin: 'TEST',
      gurmukhi: null,
      englishDefinition: 'Legacy source text',
      latinLength: 4,
      gurmukhiLength: null,
      acceptedGuess: true,
      solutionEligible: false,
      reviewStatus: ReviewStatus.unreviewed,
      source: 'legacy import',
    );

    expect(entry.hasDistributableDefinition, isFalse);
    expect(entry.displayDefinition, 'Definition unavailable for this word.');
  });

  test('round-trips a vocabulary entry through JSON', () {
    const original = VocabularyEntry(
      id: 'panjabi_seva',
      language: VocabularyLanguage.panjabi,
      latin: 'SEVA',
      gurmukhi: 'ਸੇਵਾ',
      englishDefinition: 'Service without thought of reward',
      latinLength: 4,
      gurmukhiLength: 2,
      acceptedGuess: true,
      solutionEligible: false,
      reviewStatus: ReviewStatus.unreviewed,
      source: 'test',
    );
    final restored = VocabularyEntry.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.gurmukhi, original.gurmukhi);
    expect(restored.englishDefinition, original.englishDefinition);
  });
}
