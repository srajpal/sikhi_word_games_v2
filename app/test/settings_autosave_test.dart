import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/app/app.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/settings/presentation/settings_page.dart';

void main() {
  Future<void> open(WidgetTester tester, KeyValueStore store) async {
    await tester.pumpWidget(
      SikhiWordGamesApp(
        settingsRepository: AppSettingsRepository(store),
        vocabularyRepository: MemoryVocabularyRepository([]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('App settings'));
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('theme and switches apply in place and survive app recreation', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    await open(tester, store);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    await toggle(tester, 'letter-clicks');
    await toggle(tester, 'button-clicks');
    await toggle(tester, 'simple-romanized-punjabi');
    final saved = AppSettingsRepository(store).load();
    expect(saved.theme, AppThemeChoice.dark);
    expect(saved.letterClicks, isFalse);
    expect(saved.buttonClicks, isFalse);
    expect(saved.simpleRomanizedPunjabi, isFalse);
    expect(saved.victorySound, isTrue);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Cancel'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await open(tester, store);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    for (final key in [
      'letter-clicks',
      'button-clicks',
      'simple-romanized-punjabi',
    ]) {
      expect(
        tester.widget<SwitchListTile>(find.byKey(ValueKey(key))).value,
        isFalse,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid edits drain in order after leaving Settings', (
    tester,
  ) async {
    final store = _DelayedStore();
    await open(tester, store);
    await toggle(tester, 'letter-clicks');
    await toggle(tester, 'button-clicks');
    await toggle(tester, 'letter-clicks');
    expect(AppSettingsRepository(store).load().buttonClicks, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsNothing);
    store.release.complete();
    await tester.pumpAndSettle();
    final saved = AppSettingsRepository(store).load();
    expect(saved.letterClicks, isTrue);
    expect(saved.buttonClicks, isFalse);
    expect(store.writes, 3);
    await tester.tap(find.byTooltip('App settings'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const ValueKey('button-clicks')))
          .value,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed storage keeps changes applied and later edits recover', (
    tester,
  ) async {
    final store = _RecoverableStore();
    await open(tester, store);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    expect(
      find.text(
        'Settings could not be saved on this device. They still apply for this session.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    store.fail = false;
    await toggle(tester, 'letter-clicks');
    final saved = AppSettingsRepository(store).load();
    expect(saved.theme, AppThemeChoice.dark);
    expect(saved.letterClicks, isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _DelayedStore extends MemoryKeyValueStore {
  final release = Completer<void>();
  int writes = 0;

  @override
  Future<void> setString(String key, String value) async {
    await release.future;
    writes++;
    await super.setString(key, value);
  }
}

class _RecoverableStore extends MemoryKeyValueStore {
  bool fail = true;

  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('Storage unavailable');
    await super.setString(key, value);
  }
}
