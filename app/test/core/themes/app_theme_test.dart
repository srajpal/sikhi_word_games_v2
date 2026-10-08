import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';

void main() {
  test('Game state and action labels meet normal-text contrast', () {
    double contrast(Color first, Color second) {
      final a = first.computeLuminance();
      final b = second.computeLuminance();
      return ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
    }

    for (final choice in AppThemeChoice.values) {
      final theme = AppThemes.forChoice(choice);
      final scheme = theme.colorScheme;
      final tokens = theme.extension<GameThemeTokens>()!;
      for (final pair in [
        (scheme.primary, scheme.onPrimary),
        (scheme.secondary, scheme.onSecondary),
        (scheme.surface, scheme.onSurface),
        (tokens.correct, Colors.white),
        (tokens.present, Colors.white),
        (tokens.absent, Colors.white),
      ]) {
        expect(
          contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.5),
          reason: '${choice.label} has a low-contrast label',
        );
      }
    }
  });

  test('All themes bundle a Gurmukhi font fallback for offline play', () {
    for (final choice in AppThemeChoice.values) {
      final theme = AppThemes.forChoice(choice);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'NotoSans');
      expect(theme.textTheme.bodyMedium?.fontFamilyFallback, [
        'NotoSansGurmukhi',
      ]);
    }
  });

  test('Sikhi uses distinct colors and game-board treatment', () {
    final modern = AppThemes.forChoice(AppThemeChoice.modern);
    final sketch = AppThemes.forChoice(AppThemeChoice.sikhi);
    final modernTokens = modern.extension<GameThemeTokens>()!;
    final sketchTokens = sketch.extension<GameThemeTokens>()!;

    expect(sketch.colorScheme.primary, isNot(modern.colorScheme.primary));
    expect(sketchTokens.sikhiStyle, isTrue);
    expect(sketchTokens.tileRadius, isNot(modernTokens.tileRadius));
    expect(
      sketchTokens.tileBorderWidth,
      greaterThan(modernTokens.tileBorderWidth),
    );
  });

  test('Dark uses a true dark color scheme', () {
    final dark = AppThemes.forChoice(AppThemeChoice.dark);

    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.brightness, Brightness.dark);
  });
}
