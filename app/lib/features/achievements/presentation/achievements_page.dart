import 'achievement_emblems.dart';

import 'package:flutter/material.dart';

import '../../../core/themes/app_theme.dart';

import '../../../core/themes/game_heading.dart';
import '../../../core/themes/game_ui.dart';
import '../../../core/themes/paper_page.dart';
import '../../../core/themes/studio_navigation.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../domain/achievement.dart';
import '../domain/player_progress.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({required this.progress, super.key});
  final PlayerProgress progress;
  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  GameKind? _filter;
  @override
  Widget build(BuildContext context) {
    final facts = widget.progress.facts;
    final earned = achievements.where((badge) => badge.earned(facts)).length;
    return PaperPage(
      destination: StudioDestination.badges,
      title: 'Achievements',
      icon: Icons.workspace_premium,
      introduction:
          '$earned of ${achievements.length} badges earned. Small discoveries, worth keeping.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All games'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final game in GameKind.values)
              ChoiceChip(
                label: Text(GameIdentity.forGame(game).punjabiName),
                selected: _filter == game,
                onSelected: (_) => setState(() => _filter = game),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Saved on this device. Earlier results count where recorded. Listening, perfect rounds, distinct Jodo words and longer sets start counting with this update.',
        ),
        const SizedBox(height: 20),
        for (final game in GameKind.values.where(
          (game) => _filter == null || _filter == game,
        )) ...[
          GameHeading(identity: GameIdentity.forGame(game)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final columns = MediaQuery.textScalerOf(context).scale(14) > 21
                  ? 1
                  : (box.maxWidth / 240).floor().clamp(1, 3);
              final width = (box.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final badge in achievements.where(
                    (badge) => badge.game == game,
                  ))
                    SizedBox(
                      width: width,
                      child: _AchievementCard(badge: badge, facts: facts),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.badge, required this.facts});
  final Achievement badge;
  final Map<String, int> facts;
  @override
  Widget build(BuildContext context) {
    final earned = badge.earned(facts);
    final current = badge.progress(facts);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label:
          '${badge.title}. ${badge.description} ${earned ? 'Earned' : '$current of ${badge.target}'}',
      excludeSemantics: true,
      child: GamePanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 92,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BadgePainter(
                        theme.colorScheme,
                        theme.extension<GameThemeTokens>()!,
                        earned,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 22,
                    child: Icon(
                      achievementEmblems[badge.emblem] ?? Icons.star,
                      size: 36,
                      color: earned
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    child: Icon(
                      earned ? Icons.check_circle : Icons.lock_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: current / badge.target,
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              earned ? 'Earned' : '$current / ${badge.target}',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter(this.colors, this.tokens, this.earned);
  final ColorScheme colors;
  final GameThemeTokens tokens;
  final bool earned;
  @override
  void paint(Canvas canvas, Size size) {
    final fill = earned
        ? colors.secondaryContainer
        : colors.surfaceContainerHighest;
    final border = earned ? colors.secondary : colors.outline;
    final ribbons = Path()
      ..moveTo(20, 58)
      ..lineTo(12, 100)
      ..lineTo(31, 91)
      ..lineTo(43, 102)
      ..lineTo(48, 61)
      ..moveTo(46, 61)
      ..lineTo(50, 102)
      ..lineTo(64, 91)
      ..lineTo(81, 100)
      ..lineTo(73, 58)
      ..close();
    canvas.drawPath(
      ribbons,
      Paint()..color = colors.primary.withValues(alpha: earned ? .85 : .15),
    );
    final rect = Rect.fromLTWH(9, 0, 74, 80);
    final shield = Path()
      ..moveTo(46, 1)
      ..quadraticBezierTo(70, 10, 82, 14)
      ..lineTo(78, 52)
      ..quadraticBezierTo(72, 71, 46, 82)
      ..quadraticBezierTo(20, 71, 14, 52)
      ..lineTo(10, 14)
      ..quadraticBezierTo(24, 10, 46, 1)
      ..close();
    canvas.drawShadow(shield, tokens.elevationShadow.first.color, 3, false);
    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(fill, colors.surface, .15)!, fill],
        ).createShader(rect),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(46, 40), width: 57, height: 58),
      Paint()
        ..color = border.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(21 + i * 3, 51 + i * 6),
          width: 5,
          height: 9,
        ),
        Paint()..color = border,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(71 - i * 3, 51 + i * 6),
          width: 5,
          height: 9,
        ),
        Paint()..color = border,
      );
    }
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.colors != colors || old.tokens != tokens || old.earned != earned;
}
