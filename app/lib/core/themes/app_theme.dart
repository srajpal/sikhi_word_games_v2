import 'package:flutter/material.dart';

enum AppThemeChoice { modern, sikhi, dark }

extension AppThemeChoiceLabel on AppThemeChoice {
  String get label => switch (this) {
    AppThemeChoice.modern => 'Modern',
    AppThemeChoice.sikhi => 'Sikhi',
    AppThemeChoice.dark => 'Dark',
  };
}

@immutable
class GameThemeTokens extends ThemeExtension<GameThemeTokens> {
  const GameThemeTokens({
    required this.correct,
    required this.present,
    required this.absent,
    required this.tileBorder,
    required this.tileRadius,
    required this.tileBorderWidth,
    required this.sikhiStyle,
    required this.backgroundGradient,
    required this.panelGradient,
    required this.elevationShadow,
  });

  final Color correct;
  final Color present;
  final Color absent;
  final Color tileBorder;
  final BorderRadius tileRadius;
  final double tileBorderWidth;
  final bool sikhiStyle;
  final LinearGradient backgroundGradient;
  final LinearGradient panelGradient;
  final List<BoxShadow> elevationShadow;

  @override
  GameThemeTokens copyWith({
    Color? correct,
    Color? present,
    Color? absent,
    Color? tileBorder,
    BorderRadius? tileRadius,
    double? tileBorderWidth,
    bool? sikhiStyle,
    LinearGradient? backgroundGradient,
    LinearGradient? panelGradient,
    List<BoxShadow>? elevationShadow,
  }) => GameThemeTokens(
    correct: correct ?? this.correct,
    present: present ?? this.present,
    absent: absent ?? this.absent,
    tileBorder: tileBorder ?? this.tileBorder,
    tileRadius: tileRadius ?? this.tileRadius,
    tileBorderWidth: tileBorderWidth ?? this.tileBorderWidth,
    sikhiStyle: sikhiStyle ?? this.sikhiStyle,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    panelGradient: panelGradient ?? this.panelGradient,
    elevationShadow: elevationShadow ?? this.elevationShadow,
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
      sikhiStyle: t < 0.5 ? sikhiStyle : other.sikhiStyle,
      backgroundGradient: LinearGradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      )!,
      panelGradient: LinearGradient.lerp(
        panelGradient,
        other.panelGradient,
        t,
      )!,
      elevationShadow: t < 0.5 ? elevationShadow : other.elevationShadow,
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
      sikhiStyle: false,
      backgroundGradient: const [Color(0xFFF8FBFF), Color(0xFFE6EEFF)],
      panelGradient: const [Color(0xFFFFFFFF), Color(0xFFEFF4FF)],
    ),
    AppThemeChoice.sikhi => _theme(
      seed: const Color(0xFFE28A16),
      background: const Color(0xFFFFF8E8),
      radius: 6,
      borderWidth: 2.5,
      sikhiStyle: true,
      fontFamily: 'serif',
      backgroundGradient: const [Color(0xFFFFF8E8), Color(0xFFFFD9A0)],
      panelGradient: const [Color(0xFFFFFCF4), Color(0xFFFFEBC7)],
    ),
    AppThemeChoice.dark => _theme(
      seed: const Color(0xFF8FB4FF),
      background: const Color(0xFF111318),
      radius: 12,
      borderWidth: 1.5,
      sikhiStyle: false,
      brightness: Brightness.dark,
      backgroundGradient: const [Color(0xFF171329), Color(0xFF30184A)],
      panelGradient: const [Color(0xFF30234B), Color(0xFF211A38)],
    ),
  };

  static ThemeData _theme({
    required Color seed,
    required Color background,
    required double radius,
    required double borderWidth,
    required bool sikhiStyle,
    Brightness brightness = Brightness.light,
    String? fontFamily,
    required List<Color> backgroundGradient,
    required List<Color> panelGradient,
  }) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    scaffoldBackgroundColor: background,
    fontFamily: fontFamily,
    appBarTheme: sikhiStyle
        ? const AppBarTheme(
            centerTitle: true,
            backgroundColor: Color(0xFF173A67),
            foregroundColor: Color(0xFFFFF8E8),
          )
        : null,
    cardTheme: sikhiStyle
        ? const CardThemeData(
            color: Color(0xFFFFFCF4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
              side: BorderSide(color: Color(0xFF173A67), width: 1.5),
            ),
          )
        : null,
    filledButtonTheme: sikhiStyle
        ? FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                side: BorderSide(color: Color(0xFF173A67), width: 1.5),
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
        sikhiStyle: sikhiStyle,
        backgroundGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundGradient,
        ),
        panelGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: panelGradient,
        ),
        elevationShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: brightness == Brightness.dark ? .35 : .16,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    ],
  );
}
