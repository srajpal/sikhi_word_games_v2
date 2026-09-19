import 'package:flutter_test/flutter_test.dart';

import '../../tool/content/punjabi_quality.dart';

void main() {
  test('accepts concise everyday and cultural definitions', () {
    for (final candidate in [
      const PunjabiQualityCandidate(
        gurmukhi: 'ਲੋਹਾ',
        latin: 'LOHA',
        englishDefinition: 'iron',
      ),
      const PunjabiQualityCandidate(
        gurmukhi: 'ਭਰੋਸਾ',
        latin: 'BHAROSA',
        englishDefinition: 'trust',
      ),
      const PunjabiQualityCandidate(
        gurmukhi: 'ਉਸਤਤਿ',
        latin: 'USTATI',
        englishDefinition: 'praise',
      ),
      const PunjabiQualityCandidate(
        gurmukhi: 'ਅਸੀਰਬਾਦ',
        latin: 'ASIRBAD',
        englishDefinition: 'a blessing or benediction',
      ),
      const PunjabiQualityCandidate(
        gurmukhi: 'ਸਲਾਮ',
        latin: 'SALAM',
        englishDefinition: 'a state without conflict',
      ),
      const PunjabiQualityCandidate(
        gurmukhi: 'ਸਪ੍ਰੇਮ',
        latin: 'SAPREM',
        englishDefinition: 'with love',
      ),
      const PunjabiQualityCandidate(
        gurmukhi: 'ਗੁੰਨ੍ਹਣਾ',
        latin: 'GUNHANA',
        englishDefinition: 'to knead',
      ),
    ]) {
      expect(assessPunjabiQuality(candidate).blockingIssues, isEmpty);
    }
  });

  test('rejects malformed spellings and controls as structural issues', () {
    const candidate = PunjabiQualityCandidate(
      gurmukhi: 'ਕਹ੍ਗ੧੧',
      latin: 'KAHG-11',
      englishDefinition: 'building material\nfrom mud and chaff',
    );

    final result = assessPunjabiQuality(
      candidate,
      editoriallyClearedIssues: PunjabiQualityIssue.values.toSet(),
    );

    expect(
      result.blockingIssues,
      containsAll([
        PunjabiQualityIssue.invalidGurmukhi,
        PunjabiQualityIssue.invalidLatin,
        PunjabiQualityIssue.controlCharacter,
      ]),
    );
  });

  test('rejects isolated marks, unfinished conjuncts, and symbols', () {
    for (final spelling in ['ਾ', 'ਕ੍', 'ਕ੍ਾ', 'ੴ']) {
      final result = assessPunjabiQuality(
        PunjabiQualityCandidate(
          gurmukhi: spelling,
          latin: 'TEST',
          englishDefinition: 'a test entry',
        ),
      );
      expect(
        result.blockingIssues,
        contains(PunjabiQualityIssue.invalidGurmukhi),
      );
    }
  });

  test('rejects real cross-reference and OCR-like source fragments', () {
    final crossReference = assessPunjabiQuality(
      const PunjabiQualityCandidate(
        gurmukhi: 'ਅਰਅਜੁਲ',
        latin: 'RJUL',
        englishDefinition: 'See ਅਰੰਭ 1.',
      ),
    );
    final debris = assessPunjabiQuality(
      const PunjabiQualityCandidate(
        gurmukhi: 'ਅਵਤਰਯੂ',
        latin: 'VRYU',
        englishDefinition: 'took birth. Page 250; "nanək kulı".',
      ),
    );

    expect(
      crossReference.blockingIssues,
      contains(PunjabiQualityIssue.crossReferenceOnly),
    );
    expect(
      debris.blockingIssues,
      contains(PunjabiQualityIssue.possibleOcrFragment),
    );
  });

  test('flags circular, leaked, name-only, and sensitive definitions', () {
    final cases = <String, PunjabiQualityIssue>{
      'LOHA': PunjabiQualityIssue.circularDefinition,
      'The answer is LOHA.': PunjabiQualityIssue.answerLeak,
      'A village in Punjab.': PunjabiQualityIssue.properNameOrPlaceOnly,
      'A term for sexual intercourse.':
          PunjabiQualityIssue.sensitiveAdultOrSlurTerm,
    };
    for (final entry in cases.entries) {
      final result = assessPunjabiQuality(
        PunjabiQualityCandidate(
          gurmukhi: 'ਲੋਹਾ',
          latin: 'LOHA',
          englishDefinition: entry.key,
        ),
      );
      expect(result.blockingIssues, contains(entry.value));
    }
    final ordinaryLeak = assessPunjabiQuality(
      const PunjabiQualityCandidate(
        gurmukhi: 'ਰੋਟੀ',
        latin: 'ROTI',
        englishDefinition: 'roti, chapati, or another flatbread',
      ),
    );
    expect(
      ordinaryLeak.blockingIssues,
      contains(PunjabiQualityIssue.answerLeak),
    );
  });

  test('flags lexicographic debris, people-only, violence, and caste text', () {
    final cases = <String, PunjabiQualityIssue>{
      'Skt eighteen.': PunjabiQualityIssue.possibleOcrFragment,
      'n a blessing, benediction': PunjabiQualityIssue.possibleOcrFragment,
      'strong strong and firm': PunjabiQualityIssue.possibleOcrFragment,
      'a historical medicine said to cure syphlosis':
          PunjabiQualityIssue.possibleOcrFragment,
      'Shiv, a god in a historical account':
          PunjabiQualityIssue.properNameOrPlaceOnly,
      'The son of a named king': PunjabiQualityIssue.properNameOrPlaceOnly,
      'a venereal disease': PunjabiQualityIssue.sensitiveAdultOrSlurTerm,
      'a historical caste label': PunjabiQualityIssue.sensitiveAdultOrSlurTerm,
      'violent killing': PunjabiQualityIssue.sensitiveAdultOrSlurTerm,
    };
    for (final entry in cases.entries) {
      final result = assessPunjabiQuality(
        PunjabiQualityCandidate(
          gurmukhi: 'ਪਰਖ',
          latin: 'PARAKH',
          englishDefinition: entry.key,
        ),
      );
      expect(result.blockingIssues, contains(entry.value), reason: entry.key);
    }
  });

  test('explicit editorial clearance resolves only contextual flags', () {
    const candidate = PunjabiQualityCandidate(
      gurmukhi: 'ਪੰਜਾਬ',
      latin: 'PANJAB',
      englishDefinition: 'A proper name for a historic cultural region.',
    );
    final initial = assessPunjabiQuality(candidate);
    final cleared = assessPunjabiQuality(
      candidate,
      editoriallyClearedIssues: {PunjabiQualityIssue.properNameOrPlaceOnly},
    );

    expect(initial.isPromotionCandidate, isFalse);
    expect(cleared.isPromotionCandidate, isTrue);
    expect(
      cleared.clearedIssues,
      contains(PunjabiQualityIssue.properNameOrPlaceOnly),
    );
  });

  test('reason codes are stable and objective failures cannot be cleared', () {
    const candidate = PunjabiQualityCandidate(
      gurmukhi: 'ਲੋਹਾ',
      latin: 'LOHA',
      englishDefinition: 'The answer is LOHA.',
    );
    final result = assessPunjabiQuality(
      candidate,
      editoriallyClearedIssues: {PunjabiQualityIssue.answerLeak},
    );

    expect(PunjabiQualityIssue.answerLeak.code, 'answer_leak');
    expect(result.blockingIssues, contains(PunjabiQualityIssue.answerLeak));
    expect(
      result.clearedIssues,
      isNot(contains(PunjabiQualityIssue.answerLeak)),
    );
  });
}
