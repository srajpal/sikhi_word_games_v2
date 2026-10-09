import 'dart:math';

import '../../../core/language/word_units.dart';

enum ScrambleCheck { ignored, tryAgain, solved }

/// Stable tile IDs keep repeated letters separate without splitting written units.
class WordScrambleGame {
  WordScrambleGame({
    required this.wordId,
    required this.spelling,
    required this.definition,
    Random? random,
    String? roundId,
  }) : units = List.unmodifiable(wordUnits(spelling)),
       roundId =
           roundId ??
           '${DateTime.now().microsecondsSinceEpoch}-${(random ?? Random()).nextInt(1 << 30)}' {
    if (wordId.isEmpty ||
        definition.trim().isEmpty ||
        units.length < 2 ||
        units.toSet().length < 2) {
      throw ArgumentError(
        'A scramble needs a defined word with different tiles.',
      );
    }
    _slots = List.filled(units.length, null);
    _tray = List.generate(units.length, (i) => i);
    shuffle(random ?? Random());
    if (_tray.indexed.every((e) => units[e.$2] == units[e.$1])) {
      final other = _tray.indexWhere((id) => units[id] != units[0]);
      final first = _tray[0];
      _tray[0] = _tray[other];
      _tray[other] = first;
    }
  }

  WordScrambleGame._({
    required this.wordId,
    required this.spelling,
    required this.definition,
    required this.roundId,
    required this._slots,
    required this._tray,
    required this._locked,
    required this.checks,
    required this.isComplete,
  }) : units = List.unmodifiable(wordUnits(spelling));

  final String wordId;
  final String spelling;
  final String definition;
  final String roundId;
  final List<String> units;
  late final List<int?> _slots;
  late final List<int> _tray;
  Set<int> _locked = {};
  int checks = 0;
  bool isComplete = false;

  List<int?> get slots => List.unmodifiable(_slots);
  List<int> get tray => List.unmodifiable(_tray);
  Set<int> get locked => Set.unmodifiable(_locked);
  int get hintsRemaining => _locked.isEmpty ? 1 : 0;
  bool get usedHint => _locked.isNotEmpty;
  bool get canCheck => !isComplete && !_slots.contains(null);
  bool get canShuffle =>
      !isComplete && _tray.map((id) => units[id]).toSet().length > 1;

  bool place(int id) {
    final slot = _slots.indexOf(null);
    if (isComplete || slot == -1 || !_tray.contains(id)) return false;
    _slots[slot] = id;
    _tray.remove(id);
    return true;
  }

  bool remove(int position) {
    if (isComplete ||
        position < 0 ||
        position >= units.length ||
        _locked.contains(position)) {
      return false;
    }
    final id = _slots[position];
    if (id == null) return false;
    _slots[position] = null;
    _tray.add(id);
    return true;
  }

  bool shuffle(Random random) {
    if (!canShuffle) return false;
    final before = _tray.map((id) => units[id]).join();
    _tray.shuffle(random);
    if (_tray.map((id) => units[id]).join() == before) {
      _tray.add(_tray.removeAt(0));
    }
    return true;
  }

  /// Relocate one misplaced tile, returning displaced tiles to the tray.
  bool hint() {
    if (isComplete || hintsRemaining == 0) return false;
    final position = _slots.indexed
        .where((e) => e.$2 == null || units[e.$2!] != units[e.$1])
        .firstOrNull
        ?.$1;
    if (position == null) return false;
    final misplaced = _slots.indexed
        .where((e) => e.$2 != null && units[e.$2!] != units[e.$1])
        .map((e) => e.$2!);
    final id = [..._tray, ...misplaced].firstWhere(
      (id) =>
          units[id] == units[position] &&
          !_locked.any((slot) => _slots[slot] == id),
    );
    final previous = _slots[position];
    final existing = _slots.indexOf(id);
    if (existing != -1) _slots[existing] = null;
    _tray.remove(id);
    if (previous != null) _tray.add(previous);
    _slots[position] = id;
    _locked.add(position);
    return true;
  }

  ScrambleCheck check() {
    if (!canCheck) return ScrambleCheck.ignored;
    checks++;
    if (!_slots.indexed.every((e) => units[e.$2!] == units[e.$1])) {
      return ScrambleCheck.tryAgain;
    }
    isComplete = true;
    return ScrambleCheck.solved;
  }

  Map<String, Object?> toJson() => {
    'wordId': wordId,
    'spelling': spelling,
    'definition': definition,
    'roundId': roundId,
    'slots': slots,
    'tray': tray,
    'locked': locked.toList(),
    'checks': checks,
    'complete': isComplete,
  };

  factory WordScrambleGame.fromJson(Map<String, Object?> json) {
    final spelling = json['spelling'] as String;
    final units = wordUnits(spelling);
    final slots = (json['slots'] as List).cast<int?>();
    final tray = (json['tray'] as List).cast<int>();
    final locked = (json['locked'] as List).cast<int>();
    final ids = [...slots.whereType<int>(), ...tray];
    final checks = json['checks'] as int;
    final complete = json['complete'] as bool;
    final wordId = json['wordId'] as String;
    final definition = json['definition'] as String;
    final roundId = json['roundId'] as String;
    if (wordId.isEmpty ||
        roundId.isEmpty ||
        definition.trim().isEmpty ||
        units.length < 2 ||
        units.toSet().length < 2 ||
        slots.length != units.length ||
        ids.length != units.length ||
        ids.toSet().length != units.length ||
        ids.any((id) => id < 0 || id >= units.length) ||
        checks < 0 ||
        locked.length > 1 ||
        locked.any(
          (i) =>
              i < 0 ||
              i >= units.length ||
              slots[i] == null ||
              units[slots[i]!] != units[i],
        ) ||
        (complete &&
            (checks == 0 ||
                slots.contains(null) ||
                !slots.indexed.every((e) => units[e.$2!] == units[e.$1])))) {
      throw const FormatException('Invalid saved scramble');
    }
    return WordScrambleGame._(
      wordId: wordId,
      spelling: spelling,
      definition: definition,
      roundId: roundId,
      slots: List.of(slots),
      tray: List.of(tray),
      locked: locked.toSet(),
      checks: checks,
      isComplete: complete,
    );
  }
}
