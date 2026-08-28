import 'package:flutter/material.dart';

enum AppThemeChoice { modern, sketch, dark }

@immutable
class GameThemeTokens extends ThemeExtension<GameThemeTokens> {
  const GameThemeTokens({
    required this.correct,
    required this.present,
    required this.absent,
    required this.tileBorder,
    required this.tileRadius,
    required this.tileBorderWidth,
    required this.sketchStyle,
  });

  final Color correct;
  final Color present;
  final Color absent;
  final Color tileBorder;
  final BorderRadius tileRadius;
  final double tileBorderWidth;
  final bool sketchStyle;

  @override
  GameThemeTokens copyWith({
    Color? correct,
    Color? present,
    Color? absent,
    Color? tileBorder,
    BorderRadius? tileRadius,
    double? tileBorderWidth,
    bool? sketchStyle,
  }) => GameThemeTokens(
    correct: correct ?? this.correct,
    present: present ?? this.present,
    absent: absent ?? this.absent,
    tileBorder: tileBorder ?? this.tileBorder,
    tileRadius: tileRadius ?? this.tileRadius,
    tileBorderWidth: tileBorderWidth ?? this.tileBorderWidth,
    sketchStyle: sketchStyle ?? this.sketchStyle,
  );

  @override
  GameThemeTokens lerp(GameThemeTokens? other, double t) {
    if (other == null) return this;
    return GameThemeTokens(
      correct: Color.lerp(correct, other.correct, t)!,
      present: Color.lerp(present, other.present, t)!,
      absent: Color.lerp(absent, other.absent, t)!,
      tileBorder: Color.lerp(tileBorder, other.tileBorder, t)!,
      tileRadius: BorderRadius.lerp(tileRadius, other.tileRadius, t)!,
      tileBorderWidth:
          tileBorderWidth + (other.tileBorderWidth - tileBorderWidth) * t,
      sketchStyle: t < 0.5 ? sketchStyle : other.sketchStyle,
    );
  }
}

abstract final class AppThemes {
  static ThemeData forChoice(AppThemeChoice choice) => switch (choice) {
    AppThemeChoice.modern => _theme(
      seed: const Color(0xFF315C9E),
      background: const Color(0xFFF6F7FB),
      radius: 12,
      borderWidth: 1.5,
      sketchStyle: false,
    ),
    AppThemeChoice.sketch => _theme(
      seed: const Color(0xFF53604A),
      background: const Color(0xFFF3EBD8),
      radius: 1,
      borderWidth: 3,
      sketchStyle: true,
      fontFamily: 'monospace',
    ),
    AppThemeChoice.dark => _theme(
      seed: const Color(0xFF8FB4FF),
      background: const Color(0xFF111318),
      radius: 12,
      borderWidth: 1.5,
      sketchStyle: false,
      brightness: Brightness.dark,
    ),
  };

  static ThemeData _theme({
    required Color seed,
    required Color background,
    required double radius,
    required double borderWidth,
    required bool sketchStyle,
    Brightness brightness = Brightness.light,
    String? fontFamily,
  }) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    scaffoldBackgroundColor: background,
    fontFamily: fontFamily,
    filledButtonTheme: sketchStyle
        ? FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                side: BorderSide(color: Color(0xFF30342F), width: 1.5),
              ),
            ),
          )
        : null,
    extensions: [
      GameThemeTokens(
        correct: const Color(0xFF2E7D55),
        present: const Color(0xFFC28A12),
        absent: const Color(0xFF68707A),
        tileBorder: const Color(0xFF34383E),
        tileRadius: BorderRadius.all(Radius.circular(radius)),
        tileBorderWidth: borderWidth,
        sketchStyle: sketchStyle,
      ),
    ],
  );
}
