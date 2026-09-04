import 'dart:convert';
import 'dart:io';

const _defaultPort = 8787;

Future<void> main(List<String> arguments) async {
  final port = arguments.isEmpty ? _defaultPort : int.parse(arguments.first);
  final project = Directory.current;
  final curationDirectory = Directory(
    '${project.path}${Platform.pathSeparator}assets'
    '${Platform.pathSeparator}content${Platform.pathSeparator}curation',
  );
  final webDirectory = Directory(
    '${project.path}${Platform.pathSeparator}tool'
    '${Platform.pathSeparator}dictionary_review',
  );
  if (!Directory(
    '${project.path}${Platform.pathSeparator}assets${Platform.pathSeparator}content${Platform.pathSeparator}generated',
  ).existsSync()) {
    stderr.writeln('Missing generated vocabulary assets.');
    exitCode = 66;
    return;
  }

  final store = _DecisionStore(curationDirectory);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Dictionary review tool: http://127.0.0.1:$port');
  stdout.writeln('Press Ctrl+C to stop.');

  await for (final request in server) {
    try {
      await _handleRequest(request, curationDirectory, webDirectory, store);
    } on FormatException catch (error) {
      _json(request.response, HttpStatus.badRequest, {'error': '$error'});
    } catch (error, stackTrace) {
      stderr.writeln('$error\n$stackTrace');
      _json(request.response, HttpStatus.internalServerError, {
        'error': 'The review tool could not complete that request.',
      });
    }
  }
}

Future<void> _handleRequest(
  HttpRequest request,
  Directory curationDirectory,
  Directory webDirectory,
  _DecisionStore store,
) async {
  final path = request.uri.path;
  if (request.method == 'GET' && path == '/api/candidates') {
    final report = _readCandidates(curationDirectory);
    final decisions = store.read();
    _json(request.response, HttpStatus.ok, {...report, 'decisions': decisions});
    return;
  }
  if (request.method == 'POST' && path == '/api/decision') {
    final body = await utf8.decoder.bind(request).join();
    final update = jsonDecode(body) as Map<String, Object?>;
    store.update(update);
    _json(request.response, HttpStatus.ok, {'saved': true});
    return;
  }
  if (request.method == 'POST' && path == '/api/bulk') {
    final body = await utf8.decoder.bind(request).join();
    final document = jsonDecode(body) as Map<String, Object?>;
    final updates = (document['entries']! as List<Object?>)
        .cast<Map<String, Object?>>();
    store.updateAll(updates);
    _json(request.response, HttpStatus.ok, {
      'saved': true,
      'count': updates.length,
    });
    return;
  }
  if (request.method != 'GET') {
    request.response.statusCode = HttpStatus.methodNotAllowed;
    await request.response.close();
    return;
  }

  final fileName = switch (path) {
    '/' => 'index.html',
    '/app.js' => 'app.js',
    '/styles.css' => 'styles.css',
    _ => null,
  };
  if (fileName == null) {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
    return;
  }
  final file = File('${webDirectory.path}${Platform.pathSeparator}$fileName');
  request.response.headers.contentType = switch (fileName.split('.').last) {
    'html' => ContentType.html,
    'js' => ContentType('text', 'javascript', charset: 'utf-8'),
    'css' => ContentType('text', 'css', charset: 'utf-8'),
    _ => ContentType.text,
  };
  request.response.write(file.readAsStringSync());
  await request.response.close();
}

void _json(HttpResponse response, int status, Object value) {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(value));
  response.close();
}

class _DecisionStore {
  const _DecisionStore(this.directory);

  final Directory directory;

  Map<String, Map<String, Object?>> read() {
    final result = <String, Map<String, Object?>>{};
    for (final length in const ['four', 'five', 'six']) {
      final file = File(
        '${directory.path}${Platform.pathSeparator}${length}_letter_decisions.json',
      );
      if (!file.existsSync()) continue;
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      for (final item in (document['entries'] as List<Object?>? ?? const [])) {
        final entry = item! as Map<String, Object?>;
        final key =
            (entry['internalId'] as String?) ??
            'english_${(entry['word']! as String).toLowerCase()}';
        result[key] = {
          ...entry,
          'id': key,
          'length': _lengthValue(length),
          'language': 'english',
        };
      }
    }
    final unified = File(
      '${directory.path}${Platform.pathSeparator}dictionary_review_decisions.json',
    );
    if (unified.existsSync()) {
      final document =
          jsonDecode(unified.readAsStringSync()) as Map<String, Object?>;
      for (final item in (document['entries'] as List<Object?>? ?? const [])) {
        final entry = item! as Map<String, Object?>;
        result[(entry['id'] as String?) ?? (entry['word']! as String)] = entry;
      }
    }
    return result;
  }

  void update(Map<String, Object?> update) => updateAll([update]);

  void updateAll(List<Map<String, Object?>> updates) {
    final entries = read();
    for (final update in updates) {
      final normalized = _validate(update);
      entries[normalized['id']! as String] = normalized;
    }
    final sorted = entries.values.toList()
      ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
    const encoder = JsonEncoder.withIndent('  ');
    final temporary = File(
      '${directory.path}${Platform.pathSeparator}dictionary_review_decisions.json.tmp',
    );
    temporary.writeAsStringSync(
      '${encoder.convert({'schemaVersion': 1, 'note': 'Human editorial decisions created by the local dictionary review tool.', 'entries': sorted})}\n',
    );
    temporary.renameSync(
      '${directory.path}${Platform.pathSeparator}dictionary_review_decisions.json',
    );
  }

  Map<String, Object?> _validate(Map<String, Object?> value) {
    final word = (value['word'] as String?)?.trim().toUpperCase();
    final id = (value['id'] as String?)?.trim();
    final decision = value['decision'] as String?;
    final definition = (value['definition'] as String?)?.trim() ?? '';
    final notes = (value['notes'] as String?)?.trim() ?? '';
    if (word == null || word.isEmpty || id == null || id.isEmpty) {
      throw const FormatException('A decision requires a word and entry ID.');
    }
    if (!const {
      'approve',
      'guess_only',
      'reject',
      'pending',
    }.contains(decision)) {
      throw const FormatException('Unknown editorial decision.');
    }
    if (decision == 'approve' && definition.isEmpty) {
      throw const FormatException('Approved answers require a definition.');
    }
    return {
      'word': word,
      'id': id,
      if (value['language'] is String) 'language': value['language'],
      if (value['length'] is int) 'length': value['length'],
      'decision': decision,
      'definition': definition,
      'notes': notes,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

Map<String, Object?> _readCandidates(Directory curationDirectory) {
  final generated = Directory(
    '${curationDirectory.parent.path}${Platform.pathSeparator}generated',
  );
  final candidates = <Map<String, Object?>>[];
  for (final length in const [4, 5, 6]) {
    final file = File(
      '${generated.path}${Platform.pathSeparator}vocabulary_$length.json',
    );
    final entries = jsonDecode(file.readAsStringSync()) as List<Object?>;
    for (final item in entries) {
      final entry = item! as Map<String, Object?>;
      final definitions = entry['definitions']! as Map<String, Object?>;
      final definition =
          ((definitions['en'] as List<Object?>?) ?? const []).firstOrNull
              as String? ??
          '';
      final lengths = entry['lengths']! as Map<String, Object?>;
      candidates.add({
        'rank': candidates.length + 1,
        'word': entry['latin'],
        'displayWord': entry['gurmukhi'] ?? entry['latin'],
        'internalId': entry['id'],
        'language': _reviewLanguage(entry),
        'length': lengths['latin'] ?? length,
        'gurmukhiLength': lengths['gurmukhi'],
        'score': 0,
        'recommendation': entry['solutionEligible'] == true
            ? 'active'
            : 'existing',
        'currentlyInApp': true,
        'currentlyActiveAnswer': entry['solutionEligible'] == true,
        'openEnglishWordNet': false,
        'definition': definition,
      });
    }
  }
  final supplemental = File(
    '${curationDirectory.path}${Platform.pathSeparator}supplemental_entries.json',
  );
  if (supplemental.existsSync()) {
    final entries =
        (jsonDecode(supplemental.readAsStringSync())
                as Map<String, Object?>)['entries']
            as List<Object?>;
    for (final item in entries) {
      final entry = item! as Map<String, Object?>;
      final definitions = entry['definitions']! as Map<String, Object?>;
      final definition =
          ((definitions['en'] as List<Object?>?) ?? const []).firstOrNull
              as String? ??
          '';
      final lengths = entry['lengths']! as Map<String, Object?>;
      candidates.add({
        'rank': candidates.length + 1,
        'word': entry['latin'],
        'displayWord': entry['gurmukhi'] ?? entry['latin'],
        'internalId': entry['id'],
        'language': _reviewLanguage(entry),
        'length': lengths['latin'],
        'gurmukhiLength': lengths['gurmukhi'],
        'score': 0,
        'recommendation': entry['solutionEligible'] == true
            ? 'active'
            : 'existing',
        'currentlyInApp': true,
        'currentlyActiveAnswer': entry['solutionEligible'] == true,
        'openEnglishWordNet': false,
        'definition': definition,
      });
    }
  }
  _appendNativeGurmukhiCandidates(candidates, curationDirectory);
  return {
    'schemaVersion': 1,
    'scope': 'All bundled dictionary entries',
    'candidates': candidates,
  };
}

void _appendNativeGurmukhiCandidates(
  List<Map<String, Object?>> candidates,
  Directory curationDirectory,
) {
  // The generated Mahan Kosh queue lives at the workspace level, outside the
  // Flutter app's bundled assets. It is intentionally review-only until a
  // curator records an approval in dictionary_review_decisions.json.
  final workspace = curationDirectory.parent.parent.parent.parent;
  final reportFile = File(
    '${workspace.path}${Platform.pathSeparator}reports'
    '${Platform.pathSeparator}content${Platform.pathSeparator}gurmukhi_candidates.json',
  );
  if (!reportFile.existsSync()) return;

  final document = jsonDecode(reportFile.readAsStringSync())
      as Map<String, Object?>;
  final nativeCandidates = (document['candidates'] as List<Object?>?) ?? const [];
  final existingIds = candidates
      .map((candidate) => candidate['internalId'])
      .whereType<String>()
      .toSet();
  final existingDisplayWords = candidates
      .map((candidate) => candidate['displayWord'])
      .whereType<String>()
      .toSet();
  final existingSearchWords = candidates
      .map((candidate) => candidate['word'])
      .whereType<String>()
      .map((word) => word.toUpperCase())
      .toSet();
  for (final raw in nativeCandidates) {
    final candidate = raw! as Map<String, Object?>;
    final sourceId = candidate['id'] as String?;
    final gurmukhi = candidate['gurmukhi'] as String?;
    final romanized = (candidate['romanized'] as String?)?.toUpperCase();
    final definition = candidate['definition'] as String? ?? '';
    final length = candidate['length'];
    if (sourceId == null || gurmukhi == null || length is! int) continue;

    final internalId = 'gurmukhi_mahan_kosh_$sourceId';
    // Once a reviewed candidate has been imported into supplemental entries,
    // do not show a second copy from the source queue. Display-word matching
    // also catches pre-existing spellings imported under a different ID.
    if (existingIds.contains(internalId) ||
        existingDisplayWords.contains(gurmukhi) ||
        (romanized != null && existingSearchWords.contains(romanized))) {
      continue;
    }
    final score = candidate['score'] is num
        ? (candidate['score'] as num).toInt()
        : 0;
    final recommendation = score >= 110
        ? 'high_priority_review'
        : score >= 95
            ? 'standard_review'
            : 'specialist_review';
    candidates.add({
      'rank': candidates.length + 1,
      // Keep a searchable ASCII value when available; the visible value is
      // always the native Gurmukhi headword.
      'word': romanized ?? gurmukhi,
      'displayWord': gurmukhi,
      'internalId': internalId,
      'language': 'gurmukhi',
      'length': length,
      'gurmukhiLength': length,
      'score': score,
      'recommendation': recommendation,
      'currentlyInApp': false,
      'currentlyActiveAnswer': false,
      'openEnglishWordNet': false,
      'definition': definition,
      'source': document['source'],
      'sourceCandidate': true,
    });
  }
}

int _lengthValue(String name) => switch (name) {
  'four' => 4,
  'five' => 5,
  'six' => 6,
  _ => 0,
};

String _reviewLanguage(Map<String, Object?> entry) {
  if (entry['language'] != 'panjabi') return entry['language']! as String;
  final gurmukhi = entry['gurmukhi'] as String?;
  return gurmukhi == null || gurmukhi.isEmpty
      ? 'romanized_panjabi'
      : 'gurmukhi';
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
