class ResetDataFailure implements Exception {
  ResetDataFailure(Iterable<String> sections)
    : sections = List.unmodifiable(sections);
  final List<String> sections;
}

/// Try every owned section even if storage rejects an earlier removal.
Future<void> resetSections(
  Map<String, Future<void> Function()> sections,
) async {
  final failed = <String>[];
  for (final section in sections.entries) {
    try {
      await section.value();
    } on ResetDataFailure catch (error) {
      failed.addAll(error.sections.map((name) => '${section.key}: $name'));
    } on Object {
      failed.add(section.key);
    }
  }
  if (failed.isNotEmpty) throw ResetDataFailure(failed);
}
