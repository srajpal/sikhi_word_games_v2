import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundles sanitized release vocabulary only', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/content/release/vocabulary_4.json'));
    expect(pubspec, isNot(contains('assets/content/generated/')));
    expect(pubspec, isNot(contains('assets/content/curation/')));

    var count = 0;
    for (final length in const [4, 5, 6]) {
      final entries = (jsonDecode(
        File('assets/content/release/vocabulary_$length.json')
            .readAsStringSync(),
      ) as List<Object?>).cast<Map<String, Object?>>();
      count += entries.length;
      for (final entry in entries) {
        final definitions = entry['definitions']! as Map<String, Object?>;
        final english = (definitions['en']! as List<Object?>).single as String;
        final sources = (entry['sources']! as List<Object?>).cast<String>();
        if (english.isEmpty) {
          expect(definitions['pa'], isEmpty, reason: entry['id'] as String);
          expect(
            entry['solutionEligible'],
            isFalse,
            reason: entry['id'] as String,
          );
        } else {
          expect(
            sources.any(_trustedSource),
            isTrue,
            reason: entry['id'] as String,
          );
        }
      }
    }
    expect(count, greaterThanOrEqualTo(47093));
  });
}

bool _trustedSource(String source) =>
    source == 'Open English WordNet 2025 (CC BY 4.0)' ||
    source.startsWith(
      'Mahan Kosh multilingual dataset; commit '
      'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6;',
    ) ||
    source ==
        'Project editorial definition; original text for Sikhi Word Games';
