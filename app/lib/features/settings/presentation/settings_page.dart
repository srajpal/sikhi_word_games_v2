import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/interaction_sounds.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/themes/game_heading.dart';
import '../../../core/themes/game_ui.dart';
import '../../../core/themes/paper_page.dart';
import '../../../core/widgets/reset_app_data_dialog.dart';
import '../../game_library/domain/game_launch_options.dart';
import '../data/app_settings_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.settings,
    required this.onSave,
    this.onResetAllData,
    super.key,
  });
  final AppSettings settings;
  final Future<void> Function(AppSettings) onSave;
  final Future<void> Function()? onResetAllData;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _draft = widget.settings;
  bool _saving = false;
  void _update(AppSettings next) => setState(() => _draft = next);
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_draft);
    } on Object {
      if (mounted) {
        showGameSnackBar(
          context,
          'Settings could not be saved. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PaperPage(
    title: 'App settings',
    icon: Icons.tune,
    introduction: 'Make this your place to play.',
    children: [
      GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Look & feel',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            for (final choice in AppThemeChoice.values)
              ListTile(
                leading: Icon(
                  choice == _draft.theme
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(choice.label),
                subtitle: Text(switch (choice) {
                  AppThemeChoice.modern =>
                    'Cool paper, teal ink and rounded tiles',
                  AppThemeChoice.sikhi =>
                    'Saffron paper, navy ink and woven borders',
                  AppThemeChoice.dark =>
                    'Midnight paper with soft blue highlights',
                }),
                onTap: InteractionSounds.buttonAction(
                  context,
                  () => _update(_draft.copyWith(theme: choice)),
                ),
              ),
            const Divider(),
            DropdownButtonFormField<HapticFeedbackLevel>(
              isExpanded: true,
              initialValue: _draft.hapticLevel,
              decoration: const InputDecoration(labelText: 'Haptic feedback'),
              items: [
                for (final level in HapticFeedbackLevel.values)
                  DropdownMenuItem(value: level, child: Text(level.label)),
              ],
              onChanged: InteractionSounds.buttonChange<HapticFeedbackLevel?>(
                context,
                (value) {
                  if (value != null) {
                    _update(_draft.copyWith(hapticLevel: value));
                  }
                },
              ),
            ),
            SwitchListTile(
              title: const Text('Reduce motion'),
              subtitle: const Text('Minimize interface animation'),
              value: _draft.reducedMotion,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_draft.copyWith(reducedMotion: value)),
              ),
            ),
            const Text(
              'Your device text size and reduce-motion settings are also respected.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Click sounds',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SwitchListTile(
              key: const ValueKey('letter-clicks'),
              title: const Text('Letter clicks'),
              subtitle: const Text(
                'Gentle ticks when choosing or typing letters',
              ),
              value: _draft.letterClicks,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_draft.copyWith(letterClicks: value)),
              ),
            ),
            SwitchListTile(
              key: const ValueKey('button-clicks'),
              title: const Text('Button clicks'),
              subtitle: const Text(
                'Soft clicks for buttons and other controls',
              ),
              value: _draft.buttonClicks,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_draft.copyWith(buttonClicks: value)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GamePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Celebrations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SwitchListTile(
              title: const Text('Victory sound'),
              value: _draft.victorySound,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_draft.copyWith(victorySound: value)),
              ),
            ),
            SwitchListTile(
              title: const Text('Victory particles'),
              subtitle: const Text('Reduce motion turns these off'),
              value: _draft.victoryParticles,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_draft.copyWith(victoryParticles: value)),
              ),
            ),
            ExpansionTile(
              title: const Text('Per-game celebrations'),
              onExpansionChanged: InteractionSounds.buttonChange(
                context,
                (_) {},
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'The main switches apply to every game. Your choices below are kept when you turn them back on.',
                  ),
                ),
                for (final game in GameKind.values) ...[
                  GameHeading(identity: GameIdentity.forGame(game)),
                  SwitchListTile(
                    key: ValueKey('victory-sound-${game.name}'),
                    title: const Text('Sound'),
                    value: !_draft.mutedVictoryGames.contains(game.name),
                    onChanged: InteractionSounds.buttonChange(
                      context,
                      (value) =>
                          _update(_draft.withGameVictory(game, sound: value)),
                    ),
                  ),
                  SwitchListTile(
                    key: ValueKey('victory-particles-${game.name}'),
                    title: const Text('Particles'),
                    value: !_draft.quietVictoryGames.contains(game.name),
                    onChanged: InteractionSounds.buttonChange(
                      context,
                      (value) => _update(
                        _draft.withGameVictory(game, particles: value),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GamePanel(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Your statistics'),
              onTap: InteractionSounds.buttonAction(
                context,
                () => context.push('/progress'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('Achievements'),
              onTap: InteractionSounds.buttonAction(
                context,
                () => context.push('/achievements'),
              ),
            ),
            if (widget.onResetAllData != null)
              TextButton.icon(
                onPressed: InteractionSounds.buttonAction(
                  context,
                  _saving
                      ? null
                      : () async {
                          await showResetAppDataDialog(
                            context,
                            onReset: () async {
                              await widget.onResetAllData!();
                              if (mounted) _update(const AppSettings());
                            },
                          );
                        },
                ),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset all app data'),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 12,
        children: [
          TextButton(
            onPressed: InteractionSounds.buttonAction(
              context,
              _saving ? null : () => Navigator.pop(context),
            ),
            child: const Text('Cancel'),
          ),
          GameGradientButton(
            label: _saving ? 'Saving...' : 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    ],
  );
}
