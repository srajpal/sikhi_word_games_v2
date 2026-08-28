import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../settings/data/app_settings_repository.dart';

class GameLibraryPage extends StatelessWidget {
  const GameLibraryPage({
    required this.onThemeChanged,
    required this.settings,
    required this.onFeedbackSettingsChanged,
    super.key,
  });

  final ValueChanged<AppThemeChoice> onThemeChanged;
  final AppSettings settings;
  final ValueChanged<AppSettings> onFeedbackSettingsChanged;

  Future<void> _showFeedbackSettings(BuildContext context) async {
    var haptics = settings.hapticsEnabled;
    var reducedMotion = settings.reducedMotion;
    final updated = await showDialog<AppSettings>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Feedback settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Haptic feedback'),
                subtitle: const Text('Vibrate for keys, guesses, and errors'),
                value: haptics,
                onChanged: (value) => setDialogState(() => haptics = value),
              ),
              SwitchListTile(
                title: const Text('Reduce motion'),
                subtitle: const Text('Minimize tile and interface animation'),
                value: reducedMotion,
                onChanged: (value) =>
                    setDialogState(() => reducedMotion = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                settings.copyWith(
                  hapticsEnabled: haptics,
                  reducedMotion: reducedMotion,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (updated != null) onFeedbackSettingsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTheme = theme.extension<GameThemeTokens>()!.sikhiStyle
        ? AppThemeChoice.sikhi
        : theme.brightness == Brightness.dark
        ? AppThemeChoice.dark
        : AppThemeChoice.modern;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sikhi Word Games'),
        actions: [
          IconButton(
            tooltip: 'Feedback settings',
            onPressed: () => _showFeedbackSettings(context),
            icon: const Icon(Icons.accessibility_new),
          ),
          PopupMenuButton<AppThemeChoice>(
            key: const ValueKey('app-theme-menu'),
            tooltip: 'Choose app theme',
            initialValue: activeTheme,
            onSelected: onThemeChanged,
            icon: const Icon(Icons.palette_outlined),
            itemBuilder: (context) => [
              for (final choice in AppThemeChoice.values)
                PopupMenuItem(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        choice == activeTheme
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      const SizedBox(width: 12),
                      Text(choice.label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (activeTheme == AppThemeChoice.sikhi) ...[
                  Semantics(
                    label: 'Ik Onkar',
                    child: ExcludeSemantics(
                      child: Text(
                        'ੴ',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: const Color(0xFFE28A16),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Choose a game',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Play offline in English, romanized Panjabi, and Gurmukhi.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                _GameCard(
                  icon: Icons.grid_view_rounded,
                  title: 'Guess the Word',
                  description: 'Find the hidden word using colored clues.',
                  actionLabel: 'Play prototype',
                  onPressed: () => context.push('/guess-the-word'),
                ),
                const SizedBox(height: 16),
                const _GameCard(
                  icon: Icons.search_rounded,
                  title: 'Word Search',
                  description: 'Find themed words hidden in a letter grid.',
                ),
                const SizedBox(height: 16),
                const _GameCard(
                  icon: Icons.keyboard_rounded,
                  title: 'Typing Challenge',
                  description: 'Practice accurate English, Panjabi, and Gurmukhi typing.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel = 'Coming later',
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 42),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
            ],
          );
          final action = FilledButton.tonal(
            onPressed: onPressed,
            child: Text(actionLabel),
          );
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 16), action],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    ),
  );
}
