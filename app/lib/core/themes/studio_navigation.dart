import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../audio/interaction_sounds.dart';

enum StudioDestination {
  play('/', 'Play', Icons.games_outlined, Icons.games),
  dictionary(
    '/dictionary',
    'Dictionary',
    Icons.menu_book_outlined,
    Icons.menu_book,
  ),
  progress('/progress', 'Progress', Icons.insights_outlined, Icons.insights),
  badges(
    '/achievements',
    'Badges',
    Icons.military_tech_outlined,
    Icons.military_tech,
  );

  const StudioDestination(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The same primary destinations remain visible on all four library pages.
/// Games use their own focused routes, with a normal back button.
class StudioNavigation extends StatelessWidget {
  const StudioNavigation({required this.destination, super.key});
  final StudioDestination destination;

  @override
  Widget build(BuildContext context) => NavigationBar(
    key: const ValueKey('studio-navigation'),
    selectedIndex: destination.index,
    height:
        80 + (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0, 24) * 2,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    onDestinationSelected: (index) {
      if (index == destination.index) return;
      InteractionSounds.button(context);
      context.go(StudioDestination.values[index].path);
    },
    destinations: [
      for (final item in StudioDestination.values)
        NavigationDestination(
          key: ValueKey('destination-${item.name}'),
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: item.label,
        ),
    ],
  );
}
