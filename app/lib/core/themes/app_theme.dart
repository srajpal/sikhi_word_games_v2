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

  BorderRadius get panelRadius => BorderRadius.circular(sikhiStyle ? 22 : 20);
  BorderRadius get controlRadius => BorderRadius.circular(sikhiStyle ? 12 : 14);
  List<BoxShadow> get tileShadow => [
    BoxShadow(
      color: tileBorder.withValues(alpha: .16),
      offset: const Offset(0, 2),
    ),
  ];

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
      seed: const Color(0xFF0B6F66),
      background: const Color(0xFFF5F8F7),
      radius: 12,
      borderWidth: 1.25,
      sikhiStyle: false,
      backgroundGradient: const [Color(0xFFF6FAF8), Color(0xFFE7F0EF)],
      panelGradient: const [Color(0xFFFFFFFF), Color(0xFFF6FAF9)],
    ),
    AppThemeChoice.sikhi => _theme(
      seed: const Color(0xFFE28A16),
      background: const Color(0xFFFFF8E8),
      radius: 8,
      borderWidth: 1.75,
      sikhiStyle: true,
      backgroundGradient: const [Color(0xFFFFFAEF), Color(0xFFF7E4BC)],
      panelGradient: const [Color(0xFFFFFDF7), Color(0xFFFFF5DF)],
    ),
    AppThemeChoice.dark => _theme(
      seed: const Color(0xFF8FB4FF),
      background: const Color(0xFF111318),
      radius: 12,
      borderWidth: 1.25,
      sikhiStyle: false,
      brightness: Brightness.dark,
      backgroundGradient: const [Color(0xFF0D1727), Color(0xFF172D3D)],
      panelGradient: const [Color(0xFF1C2B40), Color(0xFF172436)],
    ),
  };

  static ThemeData _theme({
    required Color seed,
    required Color background,
    required double radius,
    required double borderWidth,
    required bool sikhiStyle,
    Brightness brightness = Brightness.light,
    String fontFamily = 'NotoSans',
    required List<Color> backgroundGradient,
    required List<Color> panelGradient,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
        .copyWith(
          primary: dark
              ? const Color(0xFFA9C9FF)
              : sikhiStyle
              ? const Color(0xFF173A67)
              : const Color(0xFF0B6F66),
          onPrimary: dark ? const Color(0xFF112B4C) : Colors.white,
          secondary: dark
              ? const Color(0xFFA6DBC9)
              : sikhiStyle
              ? const Color(0xFF88550C)
              : const Color(0xFF52658B),
          onSecondary: dark ? const Color(0xFF103B30) : Colors.white,
          surface: dark
              ? const Color(0xFF172436)
              : sikhiStyle
              ? const Color(0xFFFFFDF7)
              : Colors.white,
          onSurface: dark ? const Color(0xFFE9EFF8) : const Color(0xFF202D3D),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,
      fontFamilyFallback: const ['NotoSansGurmukhi'],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: sikhiStyle ? const Color(0xFF173A67) : scheme.surface,
        foregroundColor: sikhiStyle
            ? const Color(0xFFFFF8E8)
            : scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: sikhiStyle ? const Color(0xFFFFF8E8) : scheme.onSurface,
          fontFamily: fontFamily,
          fontFamilyFallback: const ['NotoSansGurmukhi'],
        ),
      ),
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
          correct: const Color(0xFF28734F),
          present: const Color(0xFF866009),
          absent: dark ? const Color(0xFF465268) : const Color(0xFF566579),
          tileBorder: dark
              ? const Color(0xFF8296B4)
              : sikhiStyle
              ? const Color(0xFF8F7959)
              : const Color(0xFF869D99),
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
              color: Colors.black.withValues(alpha: dark ? .24 : .08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ],
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -.35,
        ),
      ),
    );
  }
}
