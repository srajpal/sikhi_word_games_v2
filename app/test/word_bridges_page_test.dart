import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/data/word_bridges_repository.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_game.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/presentation/word_bridges_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WordBridgesContent shippedContent;
  setUpAll(() async {
    shippedContent = await WordBridgesContent.load(AssetVocabularyRepository());
  });
  Widget page(
    WordBridgesRepository repository, {
    Future<WordBridgesContent>? content,
    double scale = 1,
  }) => MaterialApp(
    theme: AppThemes.forChoice(AppThemeChoice.modern),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: WordBridgesPage(
      vocabularyRepository: AssetVocabularyRepository(),
      repository: repository,
      contentFuture: content ?? Future.value(shippedContent),
      initialMode: LanguageMode.english,
    ),
  );

  testWidgets(
    'semantic matching supports meaning first, retries and completion once',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final repository = WordBridgesRepository(MemoryKeyValueStore());
      await tester.pumpWidget(page(repository));
      await tester.pumpAndSettle();
      final pairs = repository.restore()!.game.wordOrder;
      Future<void> activate(String side, String id) async {
        final finder = find.byKey(ValueKey('bridge-$side-$id'));
        await tester.ensureVisible(finder);
        final node = tester.getSemantics(finder);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
      }

      await activate('meaning', pairs[0].id);
      await activate('word', pairs[1].id);
      expect(find.textContaining('These do not match'), findsOneWidget);
      expect(repository.restore()!.game.attempts, 1);
      for (final pair in pairs) {
        await activate('meaning', pair.id);
        await activate('word', pair.id);
      }
      expect(repository.total.finishedSets, 1);
      semantics.dispose();
      expect(repository.total.attempts, 5);
      expect(find.text('Matched'), findsNWidgets(8));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page(repository));
      await tester.pumpAndSettle();
      expect(repository.total.finishedSets, 1);
    },
  );

  testWidgets('matching preserves card sizes and board positions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = WordBridgesRepository(MemoryKeyValueStore());
    await tester.pumpWidget(page(repository));
    await tester.pumpAndSettle();
    final game = repository.restore()!.game;
    final cards = [
      for (final pair in game.wordOrder)
        find.byKey(ValueKey('bridge-word-${pair.id}')),
      for (final pair in game.meaningOrder)
        find.byKey(ValueKey('bridge-meaning-${pair.id}')),
    ];
    final rectangles = cards.map(tester.getRect).toList();
    await tester.tap(cards.first);
    await tester.pumpAndSettle();
    expect(cards.map(tester.getRect).toList(), rectangles);
    await tester.tap(
      find.byKey(ValueKey('bridge-meaning-${game.wordOrder.first.id}')),
    );
    await tester.pumpAndSettle();
    expect(repository.restore()!.game.matchedIds, hasLength(1));
    expect(cards.map(tester.getRect).toList(), rectangles);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone word bank gives long meanings full width and stays stable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = WordBridgesRepository(MemoryKeyValueStore());
      final deck = shippedContent
          .decksFor(LanguageMode.english)
          .firstWhere((deck) => deck.pairs.any((pair) => pair.word == 'BREAD'));
      await repository.save(
        mode: LanguageMode.english,
        game: WordBridgesGame(pairs: deck.pairs),
      );
      await tester.pumpWidget(page(repository));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('bridge-stacked-board')),
        findsOneWidget,
      );
      final game = repository.restore()!.game;
      final words = [
        for (final pair in game.wordOrder)
          find.byKey(ValueKey('bridge-word-${pair.id}')),
      ];
      final meanings = [
        for (final pair in game.meaningOrder)
          find.byKey(ValueKey('bridge-meaning-${pair.id}')),
      ];
      expect(tester.getRect(words[0]).top, tester.getRect(words[1]).top);
      expect(
        tester.getRect(meanings.first).top,
        greaterThan(tester.getRect(words.last).bottom),
      );
      for (final meaning in meanings) {
        expect(tester.getSize(meaning).width, 288);
      }
      final cards = [...words, ...meanings];
      final before = cards.map(tester.getRect).toList();
      await tester.tap(words.first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('bridge-meaning-${game.wordOrder.first.id}')),
      );
      await tester.pumpAndSettle();
      expect(cards.map(tester.getRect).toList(), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restored Gurmukhi words show Romanized spelling underneath at 320px and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = WordBridgesRepository(MemoryKeyValueStore());
      final pairs = shippedContent.decksFor(LanguageMode.gurmukhi).first.pairs;
      await repository.save(
        mode: LanguageMode.gurmukhi,
        game: WordBridgesGame(pairs: pairs),
      );
      await tester.pumpWidget(page(repository, scale: 2));
      await tester.pumpAndSettle();
      for (final pair in pairs) {
        final romanized = find.byKey(ValueKey('bridge-romanized-${pair.id}'));
        expect(
          tester.widget<Text>(romanized).data,
          shippedContent.romanizedFor(pair.id),
        );
        expect(
          tester.getRect(romanized).top,
          greaterThanOrEqualTo(tester.getRect(find.text(pair.word)).bottom),
        );
      }
      expect(repository.restore()!.game.roundId, isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rapid selections remain responsive while storage is slow', (
    tester,
  ) async {
    final store = _DelayedStore();
    final repository = WordBridgesRepository(store);
    await tester.pumpWidget(page(repository));
    await tester.pumpAndSettle();
    final pair = repository.restore()!.game.wordOrder.first;
    store.delayWrites = true;
    await tester.tap(find.byKey(ValueKey('bridge-word-${pair.id}')));
    await tester.pump();
    final meaning = find.byKey(ValueKey('bridge-meaning-${pair.id}'));
    await tester.ensureVisible(meaning);
    await tester.tap(meaning);
    await tester.pump();
    expect(find.text('Matched'), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repository.restore()!.game.matchedIds, contains(pair.id));
    expect(repository.restore()!.game.attempts, 1);
  });

  testWidgets(
    'selection survives navigation and keyboard Space activates cards',
    (tester) async {
      final repository = WordBridgesRepository(MemoryKeyValueStore());
      await tester.pumpWidget(page(repository));
      await tester.pumpAndSettle();
      final pair = repository.restore()!.game.wordOrder.first;
      final finder = find.byKey(ValueKey('bridge-word-${pair.id}'));
      await tester.tap(finder);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page(repository));
      await tester.pumpAndSettle();
      expect(repository.restore()!.game.selectedWordId, pair.id);
      final button = find.descendant(
        of: finder,
        matching: find.byType(OutlinedButton),
      );
      final focus = Focus.of(
        tester.element(
          find.descendant(of: button, matching: find.text(pair.word)),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(repository.restore()!.game.selectedWordId, isNull);
    },
  );

  testWidgets('320px screen and large text scroll without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = WordBridgesRepository(MemoryKeyValueStore());
    await tester.pumpWidget(page(repository, scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final last = repository.restore()!.game.meaningOrder.last;
    await tester.ensureVisible(
      find.byKey(ValueKey('bridge-meaning-${last.id}')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale restored definitions start a current set', (tester) async {
    final repository = WordBridgesRepository(MemoryKeyValueStore());
    final content = shippedContent;
    final deck = content.decksFor(LanguageMode.english).first;
    final stale = WordBridgesGame(
      pairs: [
        for (final pair in deck.pairs)
          BridgePair(
            id: pair.id,
            word: pair.word,
            meaning: 'Old definition for ${pair.word}',
          ),
      ],
    );
    await repository.save(mode: LanguageMode.english, game: stale);
    await tester.pumpWidget(page(repository, content: Future.value(content)));
    await tester.pumpAndSettle();
    expect(repository.restore()!.game.roundId, isNot(stale.roundId));
    expect(find.textContaining('Old definition'), findsNothing);
    expect(
      find.text(
        'Your saved set was no longer valid, so a new one was started.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('completed set can retry a failed statistics save once', (
    tester,
  ) async {
    final store = _RetryStore();
    final repository = WordBridgesRepository(store);
    final pairs = shippedContent.decksFor(LanguageMode.english).first.pairs;
    final game = WordBridgesGame(pairs: pairs);
    for (final pair in pairs.take(3)) {
      game.selectWord(pair.id);
      game.selectMeaning(pair.id);
    }
    await repository.save(mode: LanguageMode.english, game: game);
    await tester.pumpWidget(page(repository));
    await tester.pumpAndSettle();
    store.fail = true;
    for (final side in ['word', 'meaning']) {
      final target = find.byKey(ValueKey('bridge-$side-${pairs.last.id}'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(repository.total.finishedSets, 0);
    store.fail = false;
    final retry = find.text('Retry saving');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(repository.total.finishedSets, 1);
    expect(retry, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed storage leaves matching playable with clear feedback', (
    tester,
  ) async {
    final repository = WordBridgesRepository(_FailingStore());
    await tester.pumpWidget(page(repository));
    await tester.pumpAndSettle();
    expect(find.textContaining('Progress could not be saved'), findsOneWidget);
    final cards = find.byType(OutlinedButton);
    await tester.tap(cards.first);
    await tester.pumpAndSettle();
    expect(find.text('Selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty content explains unavailability and late load is disposal safe',
    (tester) async {
      final repository = WordBridgesRepository(MemoryKeyValueStore());
      await tester.pumpWidget(
        page(repository, content: Future.value(WordBridgesContent(const []))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No matching sets'), findsOneWidget);
      final pending = Completer<WordBridgesContent>();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page(repository, content: pending.future));
      await tester.pumpWidget(const SizedBox());
      pending.complete(WordBridgesContent(const []));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

class _FailingStore extends MemoryKeyValueStore {
  @override
  Future<void> setString(String key, String value) async =>
      throw StateError('Storage unavailable');
}

class _RetryStore extends MemoryKeyValueStore {
  bool fail = false;
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('Storage unavailable');
    await super.setString(key, value);
  }
}

class _DelayedStore extends MemoryKeyValueStore {
  bool delayWrites = false;
  @override
  Future<void> setString(String key, String value) async {
    if (delayWrites) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await super.setString(key, value);
  }
}
