import 'package:flutter/material.dart';

import '../language/gurmukhi_romanization.dart';

/// Shared two-line label for any Gurmukhi keyboard key or revealed tile.
class GurmukhiKeyLabel extends StatelessWidget {
  const GurmukhiKeyLabel({
    required this.grapheme,
    required this.color,
    this.gurmukhiFontSize = 17,
    this.romanizationFontSize = 9,
    super.key,
  });

  final String grapheme;
  final Color color;
  final double gurmukhiFontSize;
  final double romanizationFontSize;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          grapheme,
          style: TextStyle(
            fontSize: gurmukhiFontSize,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          romanizeGurmukhiGrapheme(grapheme),
          style: TextStyle(
            fontSize: romanizationFontSize,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: .75),
          ),
        ),
      ],
    ),
  );
}
