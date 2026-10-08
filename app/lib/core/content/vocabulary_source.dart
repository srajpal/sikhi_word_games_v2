import 'vocabulary_entry.dart';

/// Content loading contract usable by games and offline authoring tools.
abstract interface class VocabularyRepository {
  Future<List<VocabularyEntry>> load();
}
