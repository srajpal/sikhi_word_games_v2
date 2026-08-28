import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../../core/themes/app_theme.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../../guess_the_word/domain/word_pool.dart';
import '../../guess_the_word/presentation/game_keyboard.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({
    required this.themeChoice,
    required this.onThemeChanged,
    required this.vocabularyRepository,
    super.key,
  });

  final AppThemeChoice themeChoice;
  final ValueChanged<AppThemeChoice> onThemeChanged;
  final VocabularyRepository vocabularyRepository;

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  static const _modes = [
    LanguageMode.english,
    LanguageMode.romanizedPanjabi,
    LanguageMode.gurmukhi,
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode(debugLabel: 'Dictionary keyboard');
  WordPool? _pool;
  LanguageMode _mode = LanguageMode.english;
  List<VocabularyEntry> _results = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    try {
      final entries = await widget.vocabularyRepository.load();
      if (!mounted) return;
      setState(() => _pool = WordPool(entries));
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNode.requestFocus(),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load the offline dictionary: $error');
    }
  }

  void _runSearch() {
    setState(() {
      _results =
          _pool?.search(mode: _mode, query: _controller.text) ?? const [];
    });
  }

  void _appendCharacter(String character) {
    if (_controller.text.characters.length >= 32) return;
    final candidate = '${_controller.text}$character';
    _controller.value = TextEditingValue(
      text: candidate,
      selection: TextSelection.collapsed(offset: candidate.length),
    );
    _runSearch();
    _focusNode.requestFocus();
  }

  void _backspace() {
    if (_controller.text.isEmpty) return;
    final shortened = _controller.text.characters.skipLast(1).toString();
    _controller.value = TextEditingValue(
      text: shortened,
      selection: TextSelection.collapsed(offset: shortened.length),
    );
    _runSearch();
    _focusNode.requestFocus();
  }

  void _clear() {
    _controller.clear();
    _runSearch();
    _focusNode.requestFocus();
  }

  void _changeMode(LanguageMode mode) {
    setState(() {
      _mode = mode;
      _controller.clear();
      _results = const [];
    });
    _focusNode.requestFocus();
  }

  void _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return;
    }
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return;
    }
    final character = event.character;
    if (character == null || character.isEmpty) return;
    if (_mode != LanguageMode.gurmukhi &&
        !RegExp(r'^[A-Za-z]$').hasMatch(character)) {
      return;
    }
    _appendCharacter(
      _mode == LanguageMode.gurmukhi ? character : character.toUpperCase(),
    );
  }

  String _sourceLabel(VocabularyEntry entry) => switch (_mode) {
    LanguageMode.english => 'English',
    LanguageMode.romanizedPanjabi => 'Romanized Panjabi',
    LanguageMode.gurmukhi => 'Gurmukhi · Panjabi',
    LanguageMode.mixedLatin =>
      entry.language == VocabularyLanguage.english
          ? 'English'
          : 'Romanized Panjabi',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Dictionary'),
      actions: [
        DropdownButton<AppThemeChoice>(
          value: widget.themeChoice,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          underline: const SizedBox.shrink(),
          onChanged: (value) {
            if (value != null) widget.onThemeChanged(value);
          },
          items: const [
            DropdownMenuItem(
              value: AppThemeChoice.modern,
              child: Text('Modern'),
            ),
            DropdownMenuItem(
              value: AppThemeChoice.sketch,
              child: Text('Sketch'),
            ),
            DropdownMenuItem(value: AppThemeChoice.dark, child: Text('Dark')),
          ],
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _error != null
                ? Center(child: Text(_error!, textAlign: TextAlign.center))
                : _pool == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 650;
                      return KeyboardListener(
                        focusNode: _focusNode,
                        autofocus: true,
                        onKeyEvent: _handleHardwareKey,
                        child: Column(
                          children: [
                            DropdownButton<LanguageMode>(
                              value: _mode,
                              isExpanded: true,
                              onChanged: (value) {
                                if (value != null) _changeMode(value);
                              },
                              items: [
                                for (final mode in _modes)
                                  DropdownMenuItem(
                                    value: mode,
                                    child: Text(mode.label),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Semantics(
                              textField: true,
                              label: 'Dictionary search word',
                              value: _controller.text,
                              onTap: _focusNode.requestFocus,
                              child: GestureDetector(
                                key: const ValueKey('dictionary-search'),
                                onTap: _focusNode.requestFocus,
                                child: InputDecorator(
                                  isFocused: _focusNode.hasFocus,
                                  decoration: InputDecoration(
                                    labelText: 'Search word',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _controller.text.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Clear search',
                                            onPressed: _clear,
                                            icon: const Icon(Icons.clear),
                                          ),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    _controller.text.isEmpty
                                        ? ' '
                                        : _controller.text,
                                    key: const ValueKey('dictionary-query'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(child: _buildResults(context)),
                            const SizedBox(height: 6),
                            GameKeyboard(
                              mode: _mode,
                              enabled: true,
                              disabledCharacters: const {},
                              compact: compact,
                              enterLabel: 'SEARCH',
                              onCharacter: _appendCharacter,
                              onBackspace: _backspace,
                              onEnter: _runSearch,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    ),
  );

  Widget _buildResults(BuildContext context) {
    if (_controller.text.characters.length < 2) {
      return const Center(child: Text('Enter at least two characters.'));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No matching words.'));
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _results[index];
        final spelling = WordPool.spelling(entry, _mode)!;
        return ListTile(
          title: Text(spelling),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sourceLabel(entry),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(entry.englishDefinition),
            ],
          ),
        );
      },
    );
  }
}
