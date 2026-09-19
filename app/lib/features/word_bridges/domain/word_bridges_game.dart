import 'dart:math';

class BridgePair {
  const BridgePair({
    required this.id,
    required this.word,
    required this.meaning,
  });
  final String id;
  final String word;
  final String meaning;
  Map<String, Object?> toJson() => {'id': id, 'word': word, 'meaning': meaning};
}

enum BridgeSelectionResult { selected, cleared, matched, mismatched, ignored }

class WordBridgesGame {
  WordBridgesGame({
    required List<BridgePair> pairs,
    Random? random,
    String? roundId,
  }) : this._(pairs, random ?? Random(), roundId ?? _newId());

  WordBridgesGame._(List<BridgePair> pairs, Random random, this.roundId)
    : wordOrder = List.unmodifiable(
        List<BridgePair>.of(pairs)..shuffle(random),
      ),
      meaningOrder = List.unmodifiable(
        List<BridgePair>.of(pairs)..shuffle(random),
      ) {
    _validatePairs(pairs);
    if (roundId.isEmpty) throw ArgumentError('Round ID is empty');
  }

  final String roundId;
  final List<BridgePair> wordOrder;
  final List<BridgePair> meaningOrder;
  String? _selectedWordId;
  String? _selectedMeaningId;
  final Set<String> _matchedIds = {};
  int _attempts = 0;
  String? get selectedWordId => _selectedWordId;
  String? get selectedMeaningId => _selectedMeaningId;
  Set<String> get matchedIds => Set.unmodifiable(_matchedIds);
  int get attempts => _attempts;
  bool get isComplete => _matchedIds.length == 4;

  static String _newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static void _validatePairs(List<BridgePair> pairs) {
    if (pairs.length != 4 ||
        pairs.any(
          (p) =>
              p.id.trim().isEmpty ||
              p.word.trim().isEmpty ||
              p.meaning.trim().isEmpty,
        ) ||
        pairs.map((p) => p.id).toSet().length != 4 ||
        pairs.map((p) => p.word.trim().toLowerCase()).toSet().length != 4 ||
        pairs.map((p) => p.meaning.trim().toLowerCase()).toSet().length != 4) {
      throw ArgumentError('Four distinct word and meaning pairs are required');
    }
  }

  BridgeSelectionResult selectWord(String id) => _select(id, true);
  BridgeSelectionResult selectMeaning(String id) => _select(id, false);
  BridgeSelectionResult _select(String id, bool word) {
    if (isComplete ||
        _matchedIds.contains(id) ||
        !wordOrder.any((p) => p.id == id)) {
      return BridgeSelectionResult.ignored;
    }
    if ((word ? _selectedWordId : _selectedMeaningId) == id) {
      if (word) {
        _selectedWordId = null;
      } else {
        _selectedMeaningId = null;
      }
      return BridgeSelectionResult.cleared;
    }
    if (word) {
      _selectedWordId = id;
    } else {
      _selectedMeaningId = id;
    }
    if (_selectedWordId == null || _selectedMeaningId == null) {
      return BridgeSelectionResult.selected;
    }
    _attempts++;
    final matched = _selectedWordId == _selectedMeaningId;
    if (matched) _matchedIds.add(id);
    _selectedWordId = null;
    _selectedMeaningId = null;
    return matched
        ? BridgeSelectionResult.matched
        : BridgeSelectionResult.mismatched;
  }

  Map<String, Object?> toJson() => {
    'roundId': roundId,
    'pairs': wordOrder.map((p) => p.toJson()).toList(),
    'wordOrder': wordOrder.map((p) => p.id).toList(),
    'meaningOrder': meaningOrder.map((p) => p.id).toList(),
    'selectedWordId': _selectedWordId,
    'selectedMeaningId': _selectedMeaningId,
    'matchedIds': _matchedIds.toList(),
    'attempts': _attempts,
  };

  WordBridgesGame._restored(this.roundId, this.wordOrder, this.meaningOrder);

  factory WordBridgesGame.fromJson(Map<String, Object?> json) {
    try {
      final pairs = (json['pairs'] as List).map((value) {
        final p = value as Map;
        return BridgePair(
          id: p['id'] as String,
          word: p['word'] as String,
          meaning: p['meaning'] as String,
        );
      }).toList();
      _validatePairs(pairs);
      final byId = {for (final p in pairs) p.id: p};
      List<BridgePair> order(String key) {
        final ids = (json[key] as List).cast<String>();
        if (ids.length != 4 ||
            ids.toSet().length != 4 ||
            ids.any((id) => !byId.containsKey(id))) {
          throw const FormatException('Invalid order');
        }
        return List.unmodifiable(ids.map((id) => byId[id]!));
      }

      final roundId = json['roundId'] as String;
      if (roundId.trim().isEmpty) {
        throw const FormatException('Invalid round ID');
      }
      final game = WordBridgesGame._restored(
        roundId,
        order('wordOrder'),
        order('meaningOrder'),
      );
      final matched = (json['matchedIds'] as List).cast<String>();
      if (matched.toSet().length != matched.length ||
          matched.any((id) => !byId.containsKey(id))) {
        throw const FormatException('Invalid matches');
      }
      game._matchedIds.addAll(matched);
      game._attempts = json['attempts'] as int;
      game._selectedWordId = json['selectedWordId'] as String?;
      game._selectedMeaningId = json['selectedMeaningId'] as String?;
      if (game._attempts < matched.length ||
          (game._selectedWordId != null && game._selectedMeaningId != null)) {
        throw const FormatException('Invalid progress');
      }
      for (final id in [game._selectedWordId, game._selectedMeaningId]) {
        if (id != null && (!byId.containsKey(id) || matched.contains(id))) {
          throw const FormatException('Invalid selection');
        }
      }
      return game;
    } on Object {
      throw const FormatException('Invalid Word Bridges save');
    }
  }
}
