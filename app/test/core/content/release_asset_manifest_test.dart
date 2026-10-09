import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_licenses.dart';

void main() {
  test('bundles sanitized release vocabulary only', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/content/release/english_v2.json'));
    expect(pubspec, isNot(contains('assets/content/generated/')));
    expect(pubspec, isNot(contains('assets/content/curation/')));

    var count = 0;
    for (final language in const ['english', 'punjabi']) {
      final entries = (jsonDecode(
        File('assets/content/release/${language}_v2.json').readAsStringSync(),
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
            sources.any(isTrustedVocabularySource),
            isTrue,
            reason: entry['id'] as String,
          );
        }
      }
    }
    expect(count, inInclusiveRange(6000, 10000));
    expect(pubspec, contains('THIRD_PARTY_NOTICES.txt'));
  });
}
