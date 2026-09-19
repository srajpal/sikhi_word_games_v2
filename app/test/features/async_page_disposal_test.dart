import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  for (final quest in [false, true]) {
    for (final duringClear in [false, true]) {
      testWidgets(
        '${quest ? 'Quest' : 'Search'} popped during ${duringClear ? 'clear' : 'load'}',
        (tester) async {
          final vocabulary = _DelayedVocabulary();
          final store = _DelayedClearStore();
          final navigator = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigator,
              theme: AppThemes.forChoice(AppThemeChoice.modern),
              home: const Scaffold(),
            ),
          );
          unawaited(
            navigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => quest
                    ? WordQuestPage(
                        vocabularyRepository: vocabulary,
                        sessionRepository: WordQuestSessionRepository(store),
                        hapticLevel: HapticFeedbackLevel.off,
                        reducedMotion: true,
                      )
                    : WordSearchPage(
                        vocabularyRepository: vocabulary,
                        sessionRepository: WordSearchSessionRepository(store),
                      ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          if (duringClear) {
            vocabulary.result.complete([]);
            await tester.pump();
            expect(store.started, isTrue);
          }
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
          if (!duringClear) vocabulary.result.complete([]);
          store.release.complete();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(store.values, isEmpty);
        },
      );
    }
  }
}

class _DelayedVocabulary implements VocabularyRepository {
  final result = Completer<List<VocabularyEntry>>();
  @override
  Future<List<VocabularyEntry>> load() => result.future;
}

class _DelayedClearStore extends MemoryKeyValueStore {
  final release = Completer<void>();
  bool started = false;
  @override
  Future<void> remove(String key) async {
    started = true;
    await release.future;
    await super.remove(key);
  }
}
