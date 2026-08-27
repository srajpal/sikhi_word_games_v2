import 'package:flutter/material.dart';

import '../core/themes/app_theme.dart';
import '../features/guess_the_word/presentation/guess_the_word_page.dart';

class SikhiWordGamesApp extends StatefulWidget {
  const SikhiWordGamesApp({super.key});

  @override
  State<SikhiWordGamesApp> createState() => _SikhiWordGamesAppState();
}

class _SikhiWordGamesAppState extends State<SikhiWordGamesApp> {
  AppThemeChoice _choice = AppThemeChoice.modern;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Sikhi Word Games V2',
    theme: AppThemes.forChoice(_choice),
    home: GuessTheWordPage(
      themeChoice: _choice,
      onThemeChanged: (choice) => setState(() => _choice = choice),
    ),
  );
}
