import 'package:flutter/material.dart';

import 'game_ui.dart';

Future<void> showPaperDetails(
  BuildContext context, {
  required String title,
  required String introduction,
  required Widget child,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => PaperPage(
      title: title,
      icon: Icons.insights,
      introduction: introduction,
      children: [
        GamePanel(child: child),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  ),
);

class PaperPage extends StatelessWidget {
  const PaperPage({
    required this.title,
    required this.icon,
    required this.introduction,
    required this.children,
    this.actions,
    super.key,
  });
  final String title;
  final IconData icon;
  final String introduction;
  final List<Widget> children;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: const PaperTexture(),
      title: Text(title),
      actions: actions,
    ),
    body: GameBackdrop(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GamePanel(
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            introduction,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
