import 'package:flutter/material.dart';

enum AppThemeChoice { modern, sketch }

@immutable
class GameThemeTokens extends ThemeExtension<GameThemeTokens> {
  const GameThemeTokens({
    required this.correct,
    required this.present,
    required this.absent,
    required this.tileBorder,
    required this.tileRadius,
    required this.tileBorderWidth,
  });

  final Color correct;
  final Color present;
  final Color absent;
  final Color tileBorder;
  final BorderRadius tileRadius;
  final double tileBorderWidth;

  @override
  GameThemeTokens copyWith({
    Color? correct,
    Color? present,
    Color? absent,
    Color? tileBorder,
    BorderRadius? tileRadius,
    double? tileBorderWidth,
  }) => GameThemeTokens(
    correct: correct ?? this.correct,
    present: present ?? this.present,
    absent: absent ?? this.absent,
    tileBorder: tileBorder ?? this.tileBorder,
    tileRadius: tileRadius ?? this.tileRadius,
    tileBorderWidth: tileBorderWidth ?? this.tileBorderWidth,
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
    ),
    AppThemeChoice.sketch => _theme(
      seed: const Color(0xFF283044),
      background: const Color(0xFFF7F0DE),
      radius: 3,
      borderWidth: 2.25,
    ),
  };

  static ThemeData _theme({
    required Color seed,
    required Color background,
    required double radius,
    required double borderWidth,
  }) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    scaffoldBackgroundColor: background,
    extensions: [
      GameThemeTokens(
        correct: const Color(0xFF2E7D55),
        present: const Color(0xFFC28A12),
        absent: const Color(0xFF68707A),
        tileBorder: const Color(0xFF34383E),
        tileRadius: BorderRadius.all(Radius.circular(radius)),
        tileBorderWidth: borderWidth,
      ),
    ],
  );
}
