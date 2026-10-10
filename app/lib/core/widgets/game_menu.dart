import 'package:flutter/material.dart';

/// The common game actions always have the same label, icon and order.
List<PopupMenuEntry<T>> gameMenuItems<T>({
  required T newGame,
  required T settings,
  required T help,
  required T statistics,
  required T dictionary,
  required T celebrations,
  List<PopupMenuEntry<T>> extra = const [],
}) => [
  gameMenuItem(newGame, 'New game', Icons.refresh),
  gameMenuItem(settings, 'Game settings', Icons.tune_rounded),
  gameMenuItem(help, 'How to play', Icons.help_outline),
  gameMenuItem(statistics, 'Statistics', Icons.bar_chart_rounded),
  gameMenuItem(dictionary, 'Dictionary', Icons.menu_book_outlined),
  gameMenuItem(
    celebrations,
    'Celebration settings',
    Icons.celebration_outlined,
  ),
  ...extra,
];

PopupMenuItem<T> gameMenuItem<T>(
  T value,
  String label,
  IconData icon, {
  bool enabled = true,
}) => PopupMenuItem<T>(
  value: value,
  enabled: enabled,
  child: Row(
    children: [
      Icon(icon, size: 22),
      const SizedBox(width: 12),
      Flexible(child: Text(label)),
    ],
  ),
);
