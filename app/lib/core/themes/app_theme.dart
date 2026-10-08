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

  BorderRadius get panelRadius => const BorderRadius.only(
    topLeft: Radius.circular(8),
    topRight: Radius.circular(8),
    bottomLeft: Radius.circular(8),
    bottomRight: Radius.circular(24),
  );
  BorderRadius get controlRadius => BorderRadius.circular(sikhiStyle ? 6 : 8);
  Color get paperEdge => tileBorder.withValues(alpha: .42);
  List<BoxShadow> get tileShadow => [
    BoxShadow(
      color: tileBorder.withValues(alpha: .24),
      offset: const Offset(0, 3),
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
      background: const Color(0xFFF3EDE1),
      radius: 8,
      borderWidth: 1.25,
      sikhiStyle: false,
      backgroundGradient: const [Color(0xFFF7F1E7), Color(0xFFEDE4D5)],
      panelGradient: const [Color(0xFFFFFCF5), Color(0xFFFFFCF5)],
    ),
    AppThemeChoice.sikhi => _theme(
      seed: const Color(0xFFE28A16),
      background: const Color(0xFFFFF8E8),
      radius: 5,
      borderWidth: 1.75,
      sikhiStyle: true,
      backgroundGradient: const [Color(0xFFFFF8E8), Color(0xFFF0E4C9)],
      panelGradient: const [Color(0xFFFFFCF2), Color(0xFFFFFCF2)],
    ),
    AppThemeChoice.dark => _theme(
      seed: const Color(0xFF8FB4FF),
      background: const Color(0xFF111318),
      radius: 8,
      borderWidth: 1.25,
      sikhiStyle: false,
      brightness: Brightness.dark,
      backgroundGradient: const [Color(0xFF101C2B), Color(0xFF172436)],
      panelGradient: const [Color(0xFF223247), Color(0xFF223247)],
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
              : const Color(0xFFA5412D),
          secondaryContainer: dark
              ? const Color(0xFF3A455E)
              : sikhiStyle
              ? const Color(0xFFF5D68C)
              : const Color(0xFFF4C2AA),
          onSecondaryContainer: dark
              ? const Color(0xFFE9EFF8)
              : const Color(0xFF382B22),
          onSecondary: dark ? const Color(0xFF103B30) : Colors.white,
          surface: dark
              ? const Color(0xFF223247)
              : sikhiStyle
              ? const Color(0xFFFFFCF2)
              : const Color(0xFFFFFCF5),
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
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: .2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
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
              color: scheme.onSurface.withValues(alpha: dark ? .12 : .13),
              offset: const Offset(3, 4),
            ),
          ],
        ),
      ],
    );
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sikhiStyle ? 6 : 8),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sikhiStyle ? 6 : 8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontFamily: 'NotoSerif',
        ),
        displayMedium: base.textTheme.displayMedium?.copyWith(
          fontFamily: 'NotoSerif',
        ),
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontFamily: 'NotoSerif',
        ),
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
