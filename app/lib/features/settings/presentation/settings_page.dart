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
    required this.onChanged,
    this.onResetAllData,
    super.key,
  });
  final AppSettings settings;
  final Future<void> Function(AppSettings) onChanged;
  final Future<void> Function()? onResetAllData;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _settings = widget.settings;
  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) _settings = widget.settings;
  }

  Future<void> _update(AppSettings next) async {
    setState(() => _settings = next);
    try {
      await widget.onChanged(next);
    } on Object {
      if (mounted) {
        showGameSnackBar(
          context,
          'Settings could not be saved. Please try again.',
        );
      }
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
                  choice == _settings.theme
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
                  () => _update(_settings.copyWith(theme: choice)),
                ),
              ),
            const Divider(),
            DropdownButtonFormField<HapticFeedbackLevel>(
              key: ValueKey(_settings.hapticLevel),
              isExpanded: true,
              initialValue: _settings.hapticLevel,
              decoration: const InputDecoration(labelText: 'Haptic feedback'),
              items: [
                for (final level in HapticFeedbackLevel.values)
                  DropdownMenuItem(value: level, child: Text(level.label)),
              ],
              onChanged: InteractionSounds.buttonChange<HapticFeedbackLevel?>(
                context,
                (value) {
                  if (value != null) {
                    _update(_settings.copyWith(hapticLevel: value));
                  }
                },
              ),
            ),
            SwitchListTile(
              title: const Text('Reduce motion'),
              subtitle: const Text('Minimize interface animation'),
              value: _settings.reducedMotion,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_settings.copyWith(reducedMotion: value)),
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
        child: SwitchListTile(
          key: const ValueKey('simple-romanized-punjabi'),
          title: const Text('Simple Romanized Punjabi'),
          subtitle: const Text(
            'On by default: plain letters and an A-Z keyboard. Turn off for accents. Applies to new rounds and Dictionary; saved rounds keep their spelling.',
          ),
          value: _settings.simpleRomanizedPunjabi,
          onChanged: InteractionSounds.buttonChange(
            context,
            (value) =>
                _update(_settings.copyWith(simpleRomanizedPunjabi: value)),
          ),
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
              value: _settings.letterClicks,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_settings.copyWith(letterClicks: value)),
              ),
            ),
            SwitchListTile(
              key: const ValueKey('button-clicks'),
              title: const Text('Button clicks'),
              subtitle: const Text(
                'Soft clicks for buttons and other controls',
              ),
              value: _settings.buttonClicks,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_settings.copyWith(buttonClicks: value)),
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
              value: _settings.victorySound,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_settings.copyWith(victorySound: value)),
              ),
            ),
            SwitchListTile(
              title: const Text('Victory particles'),
              subtitle: const Text('Reduce motion turns these off'),
              value: _settings.victoryParticles,
              onChanged: InteractionSounds.buttonChange(
                context,
                (value) => _update(_settings.copyWith(victoryParticles: value)),
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
                    value: !_settings.mutedVictoryGames.contains(game.name),
                    onChanged: InteractionSounds.buttonChange(
                      context,
                      (value) => _update(
                        _settings.withGameVictory(game, sound: value),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    key: ValueKey('victory-particles-${game.name}'),
                    title: const Text('Particles'),
                    value: !_settings.quietVictoryGames.contains(game.name),
                    onChanged: InteractionSounds.buttonChange(
                      context,
                      (value) => _update(
                        _settings.withGameVictory(game, particles: value),
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
                onPressed: InteractionSounds.buttonAction(context, () async {
                  await showResetAppDataDialog(
                    context,
                    onReset: () async {
                      await widget.onResetAllData!();
                    },
                  );
                }),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset all app data'),
              ),
          ],
        ),
      ),
    ],
  );
}
