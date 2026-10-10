import 'achievement_emblems.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../domain/achievement.dart';

/// Announces newly earned, persisted badges inside the game that earned them.
/// Existing achievements form the initial baseline and never replay on launch.
class AchievementFeedback extends StatefulWidget {
  const AchievementFeedback({
    required this.game,
    required this.facts,
    required this.child,
    this.reducedMotion = false,
    super.key,
  });
  final GameKind game;
  final Map<String, int> Function() facts;
  final Widget child;
  final bool reducedMotion;

  static void check(BuildContext context) =>
      context.findAncestorStateOfType<_AchievementFeedbackState>()?._check();

  @override
  State<AchievementFeedback> createState() => _AchievementFeedbackState();
}

class _AchievementFeedbackState extends State<AchievementFeedback> {
  late final Set<String> _earned;
  final _pending = <Achievement>[];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final facts = widget.facts();
    _earned = achievements
        .where((badge) => badge.earned(facts))
        .map((badge) => badge.id)
        .toSet();
  }

  void _check() {
    final facts = widget.facts();
    final fresh = achievements
        .where(
          (badge) =>
              badge.game == widget.game &&
              !_earned.contains(badge.id) &&
              badge.earned(facts),
        )
        .toList();
    if (fresh.isEmpty) return;
    _earned.addAll(fresh.map((badge) => badge.id));
    final wasEmpty = _pending.isEmpty;
    setState(() => _pending.addAll(fresh));
    if (wasEmpty) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!MediaQuery.accessibleNavigationOf(context)) {
      _timer = Timer(const Duration(seconds: 6), _dismiss);
    }
  }

  void _dismiss() {
    if (!mounted || _pending.isEmpty) return;
    _timer?.cancel();
    setState(() => _pending.removeAt(0));
    if (_pending.isNotEmpty) _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_pending.isNotEmpty)
        Positioned(
          top: 8,
          left: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_pending.first.id),
                  tween: Tween(begin: .9, end: 1),
                  duration:
                      widget.reducedMotion ||
                          MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: _AchievementBanner(
                    badge: _pending.first,
                    count: _pending.length,
                    onDismiss: _dismiss,
                    onView: () {
                      _dismiss();
                      context.push('/achievements');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _AchievementBanner extends StatelessWidget {
  const _AchievementBanner({
    required this.badge,
    required this.count,
    required this.onDismiss,
    required this.onView,
  });
  final Achievement badge;
  final int count;
  final VoidCallback onDismiss, onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<GameThemeTokens>()!;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: tokens.elevationShadow,
        ),
        child: Material(
          key: const ValueKey('achievement-unlocked'),
          elevation: 0,
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.primary.withValues(alpha: .45),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, tokens.correct, tokens.present],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [scheme.secondaryContainer, tokens.present],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.secondary, width: 2),
                      ),
                      child: Icon(
                        achievementEmblems[badge.emblem] ??
                            Icons.emoji_events_rounded,
                        size: 36,
                        color: tokens.foregroundFor(tokens.present),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BADGE EARNED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss achievement',
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 4),
                child: Row(
                  children: [
                    if (count > 1)
                      Expanded(
                        child: Text(
                          '${count - 1} more to celebrate',
                          style: theme.textTheme.labelMedium,
                        ),
                      )
                    else
                      const Spacer(),
                    TextButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('View badges'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
