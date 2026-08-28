import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';

void main() {
  test('Sketch uses distinct typography and game-board treatment', () {
    final modern = AppThemes.forChoice(AppThemeChoice.modern);
    final sketch = AppThemes.forChoice(AppThemeChoice.sketch);
    final modernTokens = modern.extension<GameThemeTokens>()!;
    final sketchTokens = sketch.extension<GameThemeTokens>()!;

    expect(sketch.textTheme.bodyMedium?.fontFamily, 'monospace');
    expect(sketchTokens.sketchStyle, isTrue);
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
