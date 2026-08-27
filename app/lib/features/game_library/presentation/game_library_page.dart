import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameLibraryPage extends StatelessWidget {
  const GameLibraryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sikhi Word Games')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
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
                description:
                    'Practice accurate English, Panjabi, and Gurmukhi typing.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
