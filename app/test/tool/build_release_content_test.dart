import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/build_release_content.dart';

void main() {
  test('applies both spelling corrections and recomputes both lengths', () {
    final result = buildReleaseEntry(
      _entry(),
      override: {
        'latin': 'BHAROSA',
        'gurmukhi': 'ਭਰੋਸਾ',
        'englishDefinition': 'trust',
        'acceptedGuess': true,
        'solutionEligible': true,
        'source':
            'Project editorial definition; original text for Sikhi Word Games',
      },
    );

    expect(result['latin'], 'BHAROSA');
    expect(result['gurmukhi'], 'ਭਰੋਸਾ');
    expect(result['lengths'], {
      'latin': 'BHAROSA'.characters.length,
      'gurmukhi': 'ਭਰੋਸਾ'.characters.length,
    });
  });

  test('an answer is always an accepted guess', () {
    final result = buildReleaseEntry(
      _entry(),
      override: {
        'acceptedGuess': false,
        'solutionEligible': true,
        'englishDefinition': 'trust',
        'source':
            'Project editorial definition; original text for Sikhi Word Games',
      },
    );

    expect(result['acceptedGuess'], isFalse);
    expect(result['solutionEligible'], isFalse);
  });

  test('release output clears non-English definitions without field provenance', () {
    final source = _entry();
    source['definitions'] = {
      'en': ['legacy text'],
      'pa': ['legacy Punjabi definition'],
    };
    final result = buildReleaseEntry(
      source,
      override: {
        'englishDefinition': 'trust',
        'source':
            'Project editorial definition; original text for Sikhi Word Games',
      },
    );

    expect(result['definitions'], {
      'en': ['trust'],
      'pa': <String>[],
    });
  });

  test('new Punjabi review methods must pass the content quality gate', () {
    final result = buildReleaseEntry(
      _entry(),
      override: {
        'englishDefinition': 'See another entry.',
        'acceptedGuess': true,
        'solutionEligible': true,
        'source':
            'Project editorial definition; original text for Sikhi Word Games',
        'reviewMethod': 'agent-editorial-source-checked-v1',
      },
    );

    expect(result['solutionEligible'], isFalse);
    expect(result['definitions'], {
      'en': [''],
      'pa': <String>[],
    });
  });

  test('duplicate IDs are rejected across input collections', () {
    final seen = <String>{};
    ensureUniqueVocabularyId(seen, _entry());

    expect(
      () => ensureUniqueVocabularyId(seen, _entry()),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _entry() => {
  'id': 'panjabi_bharosa',
  'language': 'panjabi',
  'latin': 'BHROSA',
  'gurmukhi': 'ਭਰੋਸ',
  'definitions': {
    'en': ['legacy text'],
    'pa': <String>[],
  },
  'lengths': {'latin': 99, 'gurmukhi': 99},
  'acceptedGuess': true,
  'solutionEligible': false,
  'reviewStatus': 'pending',
  'sources': ['Legacy definition source unclear; not distributed'],
};
