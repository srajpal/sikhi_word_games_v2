import 'package:characters/characters.dart';

import 'vocabulary_entry.dart';

enum ImportIssueType {
  rowCountMismatch,
  malformedWord,
  malformedDefinition,
  keyMismatch,
  duplicateId,
  missingDefinition,
  missingGurmukhi,
  unexpectedIndicScript,
}

class ImportIssue {
  const ImportIssue({
    required this.type,
    required this.message,
    this.lineNumber,
    this.entryId,
  });

  final ImportIssueType type;
  final String message;
  final int? lineNumber;
  final String? entryId;
}

class ImportResult {
  const ImportResult({required this.entries, required this.issues});

  final List<VocabularyEntry> entries;
  final List<ImportIssue> issues;
}

abstract final class V1VocabularyImporter {
  static final _gurmukhiPattern = RegExp(r'[\u0A00-\u0A7F]');
  static final _otherIndicPattern = RegExp(r'[\u0900-\u09FF\u0A80-\u0DFF]');

  static ImportResult import({
    required List<String> wordLines,
    required List<String> definitionLines,
    required int expectedLatinLength,
    required String sourceVersion,
  }) {
    final entries = <VocabularyEntry>[];
    final issues = <ImportIssue>[];
    final ids = <String>{};

    if (wordLines.length != definitionLines.length) {
      issues.add(
        ImportIssue(
          type: ImportIssueType.rowCountMismatch,
          message:
              '${wordLines.length} word rows and ${definitionLines.length} definition rows.',
        ),
      );
    }

    final rowCount = wordLines.length < definitionLines.length
        ? wordLines.length
        : definitionLines.length;
    for (var index = 0; index < rowCount; index++) {
      final lineNumber = index + 1;
      final wordParts = wordLines[index].trim().split(',');
      final definitionParts = definitionLines[index].trim().split(';');
      if (wordParts.length != 2 ||
          wordParts[0].isEmpty ||
          !const {'E', 'S'}.contains(wordParts[1])) {
        issues.add(
          ImportIssue(
            type: ImportIssueType.malformedWord,
            lineNumber: lineNumber,
            message: wordLines[index],
          ),
        );
        continue;
      }
      if (definitionParts.length < 3 ||
          definitionParts[0].isEmpty ||
          !const {'E', 'S'}.contains(definitionParts[1])) {
        issues.add(
          ImportIssue(
            type: ImportIssueType.malformedDefinition,
            lineNumber: lineNumber,
            message: definitionLines[index],
          ),
        );
        continue;
      }

      final latin = wordParts[0].toUpperCase();
      final languageCode = wordParts[1];
      final language = languageCode == 'E'
          ? VocabularyLanguage.english
          : VocabularyLanguage.panjabi;
      final id = '${language.name}_${latin.toLowerCase()}';
      if (latin != definitionParts[0].toUpperCase() ||
          languageCode != definitionParts[1]) {
        issues.add(
          ImportIssue(
            type: ImportIssueType.keyMismatch,
            lineNumber: lineNumber,
            entryId: id,
            message: '${wordLines[index]} <> ${definitionLines[index]}',
          ),
        );
        continue;
      }
      if (!ids.add(id)) {
        issues.add(
          ImportIssue(
            type: ImportIssueType.duplicateId,
            lineNumber: lineNumber,
            entryId: id,
            message: 'Duplicate vocabulary ID.',
          ),
        );
        continue;
      }

      final rawDefinition = definitionParts.sublist(2).join(';').trim();
      String? gurmukhi;
      var englishDefinition = rawDefinition;
      if (language == VocabularyLanguage.panjabi) {
        final separator = rawDefinition.indexOf(' - ');
        final writtenForm = separator >= 0
            ? rawDefinition.substring(0, separator).trim()
            : '';
        if (_gurmukhiPattern.hasMatch(writtenForm)) {
          gurmukhi = writtenForm;
          englishDefinition = rawDefinition.substring(separator + 3).trim();
        } else {
          issues.add(
            ImportIssue(
              type: ImportIssueType.missingGurmukhi,
              lineNumber: lineNumber,
              entryId: id,
              message: 'No Gurmukhi form found: $writtenForm',
            ),
          );
          if (_otherIndicPattern.hasMatch(writtenForm)) {
            issues.add(
              ImportIssue(
                type: ImportIssueType.unexpectedIndicScript,
                lineNumber: lineNumber,
                entryId: id,
                message: 'Unexpected Indic script: $writtenForm',
              ),
            );
          }
          if (separator >= 0) {
            englishDefinition = rawDefinition.substring(separator + 3).trim();
          }
        }
      }
      if (englishDefinition.isEmpty) {
        issues.add(
          ImportIssue(
            type: ImportIssueType.missingDefinition,
            lineNumber: lineNumber,
            entryId: id,
            message: 'English definition is empty.',
          ),
        );
      }

      entries.add(
        VocabularyEntry(
          id: id,
          language: language,
          latin: latin,
          gurmukhi: gurmukhi,
          englishDefinition: englishDefinition,
          latinLength: latin.characters.length,
          gurmukhiLength: gurmukhi?.characters.length,
          acceptedGuess: true,
          solutionEligible: false,
          reviewStatus: ReviewStatus.unreviewed,
          source: 'sikhi_word_games_v1@$sourceVersion',
        ),
      );
      if (latin.characters.length != expectedLatinLength) {
        issues.add(
          ImportIssue(
            type: ImportIssueType.malformedWord,
            lineNumber: lineNumber,
            entryId: id,
            message:
                '$latin has ${latin.characters.length} graphemes; expected $expectedLatinLength.',
          ),
        );
      }
    }

    return ImportResult(entries: entries, issues: issues);
  }
}
