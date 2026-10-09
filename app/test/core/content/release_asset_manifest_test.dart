import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';

void main() {
  test('ships exactly three native masters and the supplied full licenses', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final path in AssetVocabularyRepository.assetPaths) {
      expect(pubspec, contains(path));
      expect(
        File(path).readAsBytesSync(),
        File(
          path.replaceFirst(
            'assets/content/release',
            'content/approved_release',
          ),
        ).readAsBytesSync(),
      );
    }
    expect(pubspec, isNot(contains('assets/content/generated/')));
    expect(pubspec, isNot(contains('assets/content/curation/')));
    expect(pubspec, isNot(contains('content/approved_release/')));
    final attribution = File('assets/content/release/ATTRIBUTION.txt')
        .readAsStringSync();
    final notices = File('THIRD_PARTY_NOTICES.txt')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
    expect(notices, contains(attribution.replaceAll('\r\n', '\n')));
    for (final license in [
      'WORDNET_LICENSE.txt',
      'CC_BY_SA_4_0_LICENSE.txt',
      'FILTER_CC_BY_4_0_LICENSE.txt',
    ]) {
      final path = 'assets/content/release/licenses/$license';
      expect(pubspec, contains(path));
      expect(
        notices,
        contains(File(path).readAsStringSync().replaceAll('\r\n', '\n')),
      );
    }
    expect(notices, isNot(contains('wordfreq')));
    expect(notices, isNot(contains('Simple English Wiktionary')));
  });
}
