import 'package:flutter/material.dart';

import 'paper_assets.dart';

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

  BorderRadius get panelRadius => BorderRadius.circular(sikhiStyle ? 10 : 16);
  BorderRadius get controlRadius => BorderRadius.circular(sikhiStyle ? 12 : 28);
  Color get paperEdge => tileBorder.withValues(alpha: .35);
  List<BoxShadow> get tileShadow => [
    BoxShadow(
      color: const Color(0x332A2118),
      offset: const Offset(0, 3),
      blurRadius: 3,
    ),
    BoxShadow(
      color: tileBorder.withValues(alpha: .18),
      offset: const Offset(0, 1),
    ),
  ];
  Color foregroundFor(Color fill) {
    final luminance = fill.computeLuminance();
    if (1.05 / (luminance + .05) >= 4.5) return Colors.white;
    const ink = Color(0xFF14262B);
    if ((luminance + .05) / (ink.computeLuminance() + .05) >= 4.5) return ink;
    return Colors.black;
  }

  BoxDecoration tileDecoration(
    Color fill, {
    Color? border,
    double? borderWidth,
  }) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(fill, Colors.white, .055)!, fill],
    ),
    image: DecorationImage(
      image: const AssetImage(PaperAssets.texture),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(fill, BlendMode.modulate),
      opacity: .35,
    ),
    borderRadius: tileRadius,
    border: Border.all(
      color: border ?? paperEdge,
      width: borderWidth ?? tileBorderWidth,
    ),
    boxShadow: tileShadow,
  );

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
      seed: const Color(0xFF0C4851),
      background: const Color(0xFFF3EDE1),
      radius: 8,
      borderWidth: 1.25,
      sikhiStyle: false,
      backgroundGradient: const [Color(0xFFF5F6EF), Color(0xFFE6EDE6)],
      panelGradient: const [Color(0xFFFFFCF5), Color(0xFFFFFCF5)],
    ),
    AppThemeChoice.sikhi => _theme(
      seed: const Color(0xFFE28A16),
      background: const Color(0xFFFFF8E8),
      radius: 5,
      borderWidth: 1.75,
      sikhiStyle: true,
      backgroundGradient: const [Color(0xFFF8DEA5), Color(0xFFE8BC67)],
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
              : const Color(0xFF0C4851),
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
          onSurface: dark ? const Color(0xFFE9EFF8) : const Color(0xFF14262B),
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
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
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
          present: const Color(0xFFF3B63D),
          absent: dark ? const Color(0xFF465268) : const Color(0xFFB8BDBB),
          tileBorder: dark
              ? const Color(0xFF8296B4)
              : sikhiStyle
              ? const Color(0xFF173A67)
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
              offset: const Offset(0, 4),
              blurRadius: 8,
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
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
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
