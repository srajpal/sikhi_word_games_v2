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
}
