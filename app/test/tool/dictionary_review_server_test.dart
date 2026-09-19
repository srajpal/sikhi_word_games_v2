import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/dictionary_review_server.dart';

void main() {
  const serverOrigin = 'http://127.0.0.1:8787';
  const serverPort = 8787;

  test('accepts same-origin JSON writes', () {
    expect(
      dictionaryReviewWriteRejection(
        contentType: 'application/json',
        origin: serverOrigin,
        serverPort: serverPort,
      ),
      isNull,
    );
  });

  test('rejects cross-origin JSON writes', () {
    expect(
      dictionaryReviewWriteRejection(
        contentType: 'application/json',
        origin: 'https://example.com',
        serverPort: serverPort,
      ),
      HttpStatus.forbidden,
    );
  });

  test('rejects requests without an origin', () {
    expect(
      dictionaryReviewWriteRejection(
        contentType: 'application/json',
        origin: null,
        serverPort: serverPort,
      ),
      HttpStatus.forbidden,
    );
  });

  test('rejects simple form-compatible content types', () {
    for (final contentType in [
      null,
      'text/plain',
      'application/x-www-form-urlencoded',
      'multipart/form-data',
    ]) {
      expect(
        dictionaryReviewWriteRejection(
          contentType: contentType,
          origin: serverOrigin,
          serverPort: serverPort,
        ),
        HttpStatus.unsupportedMediaType,
      );
    }
  });

  test('rejects opaque and malformed origins without throwing', () {
    for (final origin in ['null', 'not an origin', 'http://[invalid']) {
      expect(
        dictionaryReviewWriteRejection(
          contentType: 'application/json',
          origin: origin,
          serverPort: serverPort,
        ),
        HttpStatus.forbidden,
      );
    }
  });

  test('rejects a matching Host-style origin outside loopback', () {
    expect(
      dictionaryReviewWriteRejection(
        contentType: 'application/json',
        origin: 'http://attacker.example:8787',
        serverPort: serverPort,
      ),
      HttpStatus.forbidden,
    );
  });

  test('accepts localhost on the bound port', () {
    expect(
      dictionaryReviewWriteRejection(
        contentType: 'application/json',
        origin: 'http://localhost:8787',
        serverPort: serverPort,
      ),
      isNull,
    );
  });

  test('adds pinned provenance to native review decisions server-side', () {
    final enriched = enrichDictionaryReviewDecision(
      {'id': 'gurmukhi_mahan_kosh_2-10-3', 'decision': 'approve'},
      [
        {
          'internalId': 'gurmukhi_mahan_kosh_2-10-3',
          'sourceCandidate': true,
          'sourceId': '2-10-3',
        },
      ],
    );

    expect(enriched['reviewMethod'], 'manual-review-v1');
    expect(
      enriched['verificationSource'],
      contains('fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6'),
    );
    expect(enriched['verificationSource'], contains('entry 2-10-3'));
  });

  test('native matching never annotates an English Latin homograph', () {
    final candidates = <Map<String, Object?>>[
      {
        'internalId': 'english_sing',
        'language': 'english',
        'word': 'SING',
        'displayWord': 'SING',
      },
    ];

    expect(
      annotateImportedNativeCandidate(
        candidates: candidates,
        internalId: 'gurmukhi_mahan_kosh_2-10-3',
        gurmukhi: 'ਸਿੰਘ',
        sourceId: '2-10-3',
        source: const {'commit': 'pinned'},
      ),
      isFalse,
    );
    expect(candidates.single['sourceCandidate'], isNull);
  });

  test('native matching annotates the exact imported native ID', () {
    final candidates = <Map<String, Object?>>[
      {
        'internalId': 'legacy_duplicate',
        'language': 'gurmukhi',
        'displayWord': 'ਸਿੰਘ',
      },
      {
        'internalId': 'gurmukhi_mahan_kosh_2-10-3',
        'language': 'gurmukhi',
        'displayWord': 'ਸਿੰਘ',
      },
    ];

    expect(
      annotateImportedNativeCandidate(
        candidates: candidates,
        internalId: 'gurmukhi_mahan_kosh_2-10-3',
        gurmukhi: 'ਸਿੰਘ',
        sourceId: '2-10-3',
        source: const {'commit': 'pinned'},
      ),
      isTrue,
    );
    expect(candidates.first['sourceCandidate'], isNull);
    expect(candidates.last['sourceId'], '2-10-3');
  });

  test('only the pinned report commit establishes provenance', () {
    expect(isPinnedDictionaryReportSource(const {'commit': 'wrong'}), isFalse);
    expect(
      isPinnedDictionaryReportSource(const {
        'commit': 'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6',
      }),
      isTrue,
    );
  });
}
