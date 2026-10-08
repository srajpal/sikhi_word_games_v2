import 'package:flutter/material.dart';

/// Crisp, responsive wordmark with tactile bilingual letter tiles.
class StudioLogo extends StatelessWidget {
  const StudioLogo({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Sikhi Word Games',
      header: true,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 360;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: compact ? 46 : 68,
                height: compact ? 48 : 62,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 5,
                      child: Transform.rotate(
                        angle: -.14,
                        child: _tile(
                          context,
                          'S',
                          colors.primary,
                          colors.onPrimary,
                          compact,
                        ),
                      ),
                    ),
                    Positioned(
                      left: compact ? 18 : 28,
                      top: 16,
                      child: Transform.rotate(
                        angle: .12,
                        child: _tile(
                          context,
                          'ਕ',
                          colors.secondaryContainer,
                          colors.onSecondaryContainer,
                          compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIKHI',
                      style: TextStyle(
                        fontFamily: 'NotoSerif',
                        fontSize: compact ? 19 : 28,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'WORD GAMES',
                      style: TextStyle(
                        fontSize: compact ? 9 : 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: compact ? 1.2 : 2.5,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String letter,
    Color fill,
    Color ink,
    bool small,
  ) => Container(
    width: small ? 28 : 39,
    height: small ? 33 : 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: Theme.of(context).colorScheme.surface,
        width: 1.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40352617),
          offset: Offset(0, 3),
          blurRadius: 2,
        ),
      ],
    ),
    child: Text(
      letter,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontSize: small ? 22 : 30,
        fontWeight: FontWeight.w900,
        color: ink,
        fontFamilyFallback: const ['NotoSansGurmukhi'],
      ),
    ),
  );
}
