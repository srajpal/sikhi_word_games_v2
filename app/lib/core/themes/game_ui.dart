import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'paper_assets.dart';
import '../../features/guess_the_word/domain/language_mode.dart';

/// Identical, non-interactive language information on every game route.
class GameLanguageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const GameLanguageHeader({
    required this.mode,
    this.wordLength,
    this.textScale = 1,
    super.key,
  });
  final LanguageMode mode;
  final int? wordLength;
  final double textScale;
  @override
  Size get preferredSize =>
      Size.fromHeight(textScale > 1.5 ? 64 * textScale / 2 : 36);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
    child: Text(
      '${mode.label}${wordLength == null ? '' : ' · $wordLength letters'}',
      key: const ValueKey('game-language-status'),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelMedium,
    ),
  );
}

const gameSnackBarDuration = Duration(seconds: 5);

void showGameSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  final media = MediaQuery.of(context);
  final scheme = Theme.of(context).colorScheme;
  final appBar = context.findAncestorWidgetOfExactType<Scaffold>()?.appBar;
  final scaler = media.textScaler;
  final header = GameLanguageHeader(
    mode: LanguageMode.english,
    textScale: scaler.scale(12) / 12,
  );
  final toolbarHeight =
      scaler.scale(20) * 2.5 +
      scaler.scale(12) +
      36 +
      header.preferredSize.height;
  // Float below the toolbar without changing board geometry or covering keys.
  final painter = TextPainter(
    text: TextSpan(
      text: message,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    textDirection: Directionality.of(context),
    textScaler: media.textScaler,
  )..layout(maxWidth: (media.size.width - 140).clamp(100, 650));
  final height = painter.height + 48;
  painter.dispose();
  final bottom =
      (media.size.height -
              media.padding.top -
              media.padding.bottom -
              (appBar?.preferredSize.height ?? toolbarHeight) -
              height -
              12)
          .clamp(12.0, double.infinity);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        content: IgnorePointer(
          child: Semantics(
            liveRegion: true,
            child: Text(message, style: TextStyle(color: scheme.onSurface)),
          ),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: scheme.primary,
          onPressed: messenger.hideCurrentSnackBar,
        ),
        behavior: SnackBarBehavior.floating,
        hitTestBehavior: HitTestBehavior.translucent,
        dismissDirection: DismissDirection.none,
        margin: EdgeInsets.fromLTRB(12, 0, 12, bottom),
        duration: gameSnackBarDuration,
        persist: media.accessibleNavigation,
      ),
    );
}

class GameBackdrop extends StatelessWidget {
  const GameBackdrop({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: PaperTexture()),
        child,
      ],
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        gradient: color == null ? tokens.panelGradient : null,
        image: DecorationImage(
          image: const AssetImage(PaperAssets.texture),
          repeat: ImageRepeat.repeat,
          scale: 2,
          colorFilter: ColorFilter.mode(
            color ?? Theme.of(context).colorScheme.surface,
            BlendMode.modulate,
          ),
          opacity: .45,
        ),
        borderRadius: tokens.panelRadius,
        border: Border.all(color: tokens.paperEdge),
        boxShadow: tokens.elevationShadow,
      ),
      child: child,
    );
  }
}

class GameStatusPill extends StatelessWidget {
  const GameStatusPill({required this.child, this.icon, super.key});

  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: tokens.controlRadius,
        border: Border.all(color: tokens.paperEdge),
        boxShadow: tokens.tileShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameGradientButton extends StatelessWidget {
  const GameGradientButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.prominent = true,
    this.semanticLabel,
    this.compact = false,
    this.iconTrailing = false,
    super.key,
  });

  final bool compact;
  final bool iconTrailing;
  final String? semanticLabel;
  final bool prominent;
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final enabled = onPressed != null;
    final radius = tokens.controlRadius;
    final foreground = enabled
        ? prominent
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: .45);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled && prominent
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(theme.colorScheme.primary, Colors.white, .07)!,
                  theme.colorScheme.primary,
                  Color.lerp(theme.colorScheme.primary, Colors.black, .15)!,
                ],
              )
            : null,
        color: !enabled
            ? theme.colorScheme.surfaceContainerHighest
            : !prominent
            ? theme.colorScheme.surface
            : null,
        borderRadius: radius,
        border: Border.all(
          color: enabled
              ? theme.colorScheme.surface.withValues(alpha: .85)
              : theme.colorScheme.outline.withValues(alpha: .35),
          width: 1.5,
        ),
        boxShadow: enabled && prominent ? tokens.tileShadow : null,
      ),
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 18,
                  vertical: 11,
                ),
                child: IconTheme(
                  data: IconThemeData(color: foreground, size: 19),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null && !iconTrailing) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          semanticsLabel: semanticLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                      ),
                      if (icon != null && iconTrailing) ...[
                        const SizedBox(width: 8),
                        icon!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Real paper fibers, tinted centrally for the three app themes.
class PaperTexture extends StatelessWidget {
  const PaperTexture({this.panel = false, super.key});
  final bool panel;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final tint = panel
        ? theme.colorScheme.surface
        : tokens.backgroundGradient.colors.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        image: DecorationImage(
          image: const AssetImage(PaperAssets.texture),
          repeat: ImageRepeat.repeat,
          scale: 2,
          colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
          opacity: theme.brightness == Brightness.dark
              ? .55
              : panel
              ? .5
              : .7,
        ),
      ),
      child: tokens.sikhiStyle && !panel
          ? CustomPaint(
              painter: _WovenPaper(theme.colorScheme.primary),
              child: const SizedBox.expand(),
            )
          : const SizedBox.expand(),
    );
  }
}

/// A quiet geometric woven border distinguishes Sikhi from Modern paper.
class _WovenPaper extends CustomPainter {
  const _WovenPaper(this.ink);
  final Color ink;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final x in [8.0, size.width - 8]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      for (var y = 14.0; y < size.height; y += 24) {
        canvas.drawPath(
          Path()
            ..moveTo(x, y - 6)
            ..lineTo(x + 5, y)
            ..lineTo(x, y + 6)
            ..lineTo(x - 5, y)
            ..close(),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WovenPaper old) => old.ink != ink;
}

/// Deterministic deckled edges keep labels tactile without animating texture.
class PaperLabel extends StatelessWidget {
  const PaperLabel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => PhysicalShape(
    clipper: const _PaperEdge(),
    color: Theme.of(context).colorScheme.surface,
    shadowColor: const Color(0x33372B1A),
    elevation: 2,
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        const Positioned.fill(child: PaperTexture(panel: true)),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

class _PaperEdge extends CustomClipper<Path> {
  const _PaperEdge();
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(3, 4);
    const offsets = [2.0, 0.0, 3.0, 1.0, 2.5, .5];
    for (var i = 0; i <= 24; i++) {
      path.lineTo(3 + (size.width - 6) * i / 24, offsets[i % offsets.length]);
    }
    for (var i = 0; i <= 16; i++) {
      path.lineTo(
        size.width - offsets[i % offsets.length],
        3 + (size.height - 6) * i / 16,
      );
    }
    for (var i = 24; i >= 0; i--) {
      path.lineTo(
        3 + (size.width - 6) * i / 24,
        size.height - offsets[i % offsets.length],
      );
    }
    for (var i = 16; i >= 0; i--) {
      path.lineTo(offsets[i % offsets.length], 3 + (size.height - 6) * i / 16);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_PaperEdge oldClipper) => false;
}
