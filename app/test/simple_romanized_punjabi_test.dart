import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/romanized_vocabulary_views.dart';
import 'package:sikhi_word_games_v2/core/content/answer_eligibility.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/dictionary/presentation/dictionary_page.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/word_pool.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/presentation/guess_the_word_page.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/presentation/word_bridges_page.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';
import 'package:sikhi_word_games_v2/features/word_search/data/word_search_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_search/presentation/word_search_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const mode = LanguageMode.romanizedPanjabi;
  final one = MemoryVocabularyRepository([_entry('one', 'ĀSĀN')]);

  test(
    'legacy settings default to simple and the explicit choice persists',
    () async {
      expect(
        AppSettings.fromJson({'schemaVersion': 1}).simpleRomanizedPunjabi,
        isTrue,
      );
      final repository = AppSettingsRepository(MemoryKeyValueStore());
      await repository.save(
        const AppSettings().copyWith(simpleRomanizedPunjabi: false),
      );
      expect(repository.load().simpleRomanizedPunjabi, isFalse);
      expect(LanguageMode.values, hasLength(3));
    },
  );

  testWidgets('Dictionary searches simple text and retains the original view', (
    tester,
  ) async {
    for (final simple in [true, false]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _app(
          DictionaryPage(vocabularyRepository: one, simpleRomanized: simple),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Find a word and its meaning'), findsNothing);
      await tester.tap(find.byType(DropdownButton<LanguageMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(mode.label).last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('key-Ā')),
        simple ? findsNothing : findsOneWidget,
      );
      for (final letter in 'ĀSĀN'.split('')) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: letter);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(simple ? 'ASAN' : 'ĀSĀN'), findsWidgets);
      expect(find.text('An easy task'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test(
    'all approved Roman letters simplify without changing units or sources',
    () {
      final entries = decodeVocabularyDocuments([
        for (final path in AssetVocabularyRepository.assetPaths)
          File(path).readAsStringSync(),
      ]);
      final views = RomanizedVocabularyViews(entries);
      final simple = views.entries(simple: true);
      expect(simple, same(views.entries(simple: true)));
      for (var i = 0; i < entries.length; i++) {
        final original = entries[i], plain = simple[i];
        expect(plain.id, original.id);
        expect(plain.englishDefinition, original.englishDefinition);
        expect(plain.source, original.source);
        expect(plain.gurmukhi, original.gurmukhi);
        expect(plain.script, original.script);
        if (original.script == VocabularyScript.romanizedPunjabi) {
          expect(plain.latin, matches(RegExp(r'^[A-Z]+$')));
          expect(wordUnitCount(plain.latin), original.latinLength);
        } else {
          expect(plain, same(original));
        }
      }
      final original = WordPool(entries), plain = WordPool(simple);
      for (final size in [4, 5, 6]) {
        final expected = original
            .acceptedGuesses(mode: mode, wordLength: size)
            .map(simplifyRomanizedPunjabi)
            .toSet();
        expect(plain.acceptedGuesses(mode: mode, wordLength: size), expected);
        expect(
          plain
              .solutions(mode: mode, wordLength: size)
              .map((e) => e.latin)
              .toSet(),
          simple
              .where(
                (e) =>
                    e.supportsScript(mode.script) &&
                    e.solutionEligible &&
                    AnswerEligibility.allows(e, mode.script) &&
                    e.latinLength == size,
              )
              .map((e) => e.latin)
              .toSet(),
        );
      }
      final english = plain.acceptedGuesses(
        mode: LanguageMode.english,
        wordLength: 4,
      );
      expect(english, contains('MICE'));
      expect(
        GuessGame(
          solution: 'BOOK',
          acceptedGuesses: english,
        ).submit('MICE').isAccepted,
        isTrue,
      );
    },
  );

  testWidgets(
    'English and simple Punjabi fit the same phone screen at every size',
    (tester) async {
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final mode in [
        LanguageMode.english,
        LanguageMode.romanizedPanjabi,
      ]) {
        for (final size in [4, 5, 6]) {
          final store = MemoryKeyValueStore();
          final entry = VocabularyEntry(
            id: 'phone-${mode.name}-$size',
            language: mode == LanguageMode.english
                ? VocabularyLanguage.english
                : VocabularyLanguage.panjabi,
            script: mode.script,
            latin: mode == LanguageMode.english ? 'A' * size : 'Ā' * size,
            gurmukhi: null,
            englishDefinition: 'A layout test word',
            latinLength: size,
            gurmukhiLength: null,
            acceptedGuess: true,
            solutionEligible: true,
            reviewStatus: ReviewStatus.editorApproved,
            source: 'Project editorial definition; original text for Sikhi Word Games',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            _app(
              GuessTheWordPage(
                vocabularyRepository: MemoryVocabularyRepository([entry]),
                statisticsRepository: GuessStatisticsRepository(store),
                gameRepository: GuessGameRepository(store),
                solutionHistoryRepository: SolutionHistoryRepository(store),
                initialMode: mode,
                initialWordLength: size,
                startFresh: true,
                simpleRomanized: true,
                reducedMotion: true,
                hapticLevel: HapticFeedbackLevel.off,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .state<ScrollableState>(find.byType(Scrollable))
                .position
                .maxScrollExtent,
            0,
            reason: '${mode.label}, $size letters should fit without scrolling',
          );
          expect(
            tester.getRect(find.byKey(const ValueKey('key-enter'))).bottom,
            lessThanOrEqualTo(780),
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  test(
    'equivalent accent forms collapse once in matching and solution pools',
    () {
      final entries = [_entry('one', 'ĀSĀN'), _entry('two', 'AŚAN')];
      final simple = RomanizedVocabularyViews(entries).entries(simple: true);
      expect(
        WordPool(simple).solutions(mode: mode, wordLength: 4),
        hasLength(1),
      );
      expect(WordBridgesContent(simple).pairsFor(mode), hasLength(1));
      expect(entries.map((e) => e.latin), ['ĀSĀN', 'AŚAN']);
      expect(simplifyRomanizedPunjabi('a\u0304\u0303sā́n'), 'asan');
    },
  );

  Widget bujho(
    MemoryKeyValueStore store, {
    bool simple = true,
    bool fresh = false,
  }) => _app(
    GuessTheWordPage(
      vocabularyRepository: one,
      statisticsRepository: GuessStatisticsRepository(store),
      gameRepository: GuessGameRepository(store),
      solutionHistoryRepository: SolutionHistoryRepository(store),
      hapticLevel: HapticFeedbackLevel.off,
      reducedMotion: true,
      initialMode: mode,
      initialWordLength: 4,
      simpleRomanized: simple,
      startFresh: fresh,
    ),
  );

  testWidgets(
    'simple Bujho accepts plain input with no accented keyboard rows',
    (tester) async {
      final store = MemoryKeyValueStore();
      await tester.pumpWidget(bujho(store, fresh: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('key-Ā')), findsNothing);
      expect(GuessGameRepository(store).usesSimpleRomanized, isTrue);
      for (final letter in 'ASAN'.split('')) {
        await tester.ensureVisible(find.byKey(ValueKey('key-$letter')));
        await tester.tap(find.byKey(ValueKey('key-$letter')));
        await tester.pump();
      }
      await tester.ensureVisible(find.byKey(const ValueKey('key-enter')));
      await tester.tap(find.byKey(const ValueKey('key-enter')));
      await tester.pumpAndSettle();
      expect(find.text('ASAN'), findsOneWidget);
      expect(
        GuessStatisticsRepository(store).load().records.values.single.gamesWon,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy accented Bujho resumes, then New game uses simple choice',
    (tester) async {
      final store = MemoryKeyValueStore();
      final repository = GuessGameRepository(store);
      await repository.save(
        mode: mode,
        game: GuessGame(solution: 'ĀSĀN', acceptedGuesses: {'ĀSĀN'}),
      );
      await tester.pumpWidget(bujho(store));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('key-Ā')), findsOneWidget);
      expect(repository.usesSimpleRomanized, isFalse);
      await tester.tap(find.byTooltip('Game menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New game').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('key-Ā')), findsNothing);
      expect(repository.usesSimpleRomanized, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(bujho(store, simple: false));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('key-Ā')), findsNothing);
      expect(repository.usesSimpleRomanized, isTrue);
    },
  );

  testWidgets('Quest resumes simple letters after the preference changes', (
    tester,
  ) async {
    final repository = WordQuestSessionRepository(MemoryKeyValueStore());
    Widget page(bool simple, bool fresh) => _app(
      WordQuestPage(
        vocabularyRepository: one,
        sessionRepository: repository,
        hapticLevel: HapticFeedbackLevel.off,
        reducedMotion: true,
        initialMode: mode,
        initialWordSize: 4,
        simpleRomanized: simple,
        startFresh: fresh,
      ),
    );
    await tester.pumpWidget(page(true, true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('word-quest-key-A')));
    await tester.pumpAndSettle();
    final before = repository.restore()!;
    expect(before.simpleRomanized, isTrue);
    expect(before.game.solution, 'ASAN');
    expect(before.game.guessedGraphemes, contains('A'));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(false, false));
    await tester.pumpAndSettle();
    expect(
      repository.restore()!.game.guessedGraphemes,
      before.game.guessedGraphemes,
    );
    expect(find.byKey(const ValueKey('word-quest-key-Ā')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khoj simple targets and filler survive preference changes', (
    tester,
  ) async {
    final repository = WordSearchSessionRepository(MemoryKeyValueStore());
    Widget page(bool simple, bool fresh) => _app(
      WordSearchPage(
        vocabularyRepository: one,
        sessionRepository: repository,
        initialMode: mode,
        simpleRomanized: simple,
        startFresh: fresh,
      ),
    );
    await tester.pumpWidget(page(true, true));
    await tester.pumpAndSettle();
    final before = repository.restore()!;
    expect(before.simpleRomanized, isTrue);
    expect(before.puzzle.words.single.word, 'ASAN');
    expect(
      before.puzzle.cells
          .expand((r) => r)
          .every((v) => RegExp(r'^[A-Z]$').hasMatch(v)),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(false, false));
    await tester.pumpAndSettle();
    expect(repository.restore()!.puzzle.toJson(), before.puzzle.toJson());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Jodo simple pairs resume with IDs and progress intact', (
    tester,
  ) async {
    final repository = WordBridgesRepository(MemoryKeyValueStore());
    final words = MemoryVocabularyRepository([
      _entry('one', 'ĀSĀN'),
      _entry('two', 'GĪTĀ'),
      _entry('three', 'KAMĪ'),
      _entry('four', 'MITṬĪ'),
    ]);
    Widget page(bool simple, bool fresh) => _app(
      WordBridgesPage(
        vocabularyRepository: words,
        repository: repository,
        initialMode: mode,
        simpleRomanized: simple,
        startFresh: fresh,
      ),
    );
    await tester.pumpWidget(page(true, true));
    await tester.pumpAndSettle();
    final before = repository.restore()!;
    expect(before.simpleRomanized, isTrue);
    expect(before.game.wordOrder.map((p) => p.word).toSet(), {
      'ASAN',
      'GITA',
      'KAMI',
      'MITTI',
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(false, false));
    await tester.pumpAndSettle();
    expect(repository.restore()!.game.roundId, before.game.roundId);
    expect(repository.restore()!.simpleRomanized, isTrue);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home) =>
    MaterialApp(theme: AppThemes.forChoice(AppThemeChoice.modern), home: home);

VocabularyEntry _entry(String id, String word) => VocabularyEntry(
  id: id,
  language: VocabularyLanguage.panjabi,
  script: VocabularyScript.romanizedPunjabi,
  latin: word,
  gurmukhi: null,
  englishDefinition: switch (id) {
    'one' => 'An easy task',
    'two' => 'A musical song',
    'three' => 'An amount that is missing',
    _ => 'Earth used for planting',
  },
  latinLength: wordUnitCount(word),
  gurmukhiLength: null,
  acceptedGuess: true,
  solutionEligible: true,
  reviewStatus: ReviewStatus.editorApproved,
  source: 'Project editorial definition; original text for Sikhi Word Games',
);
