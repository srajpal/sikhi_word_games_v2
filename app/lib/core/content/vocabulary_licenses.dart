/// Exact source families allowed for offline definition display. Source URLs
/// retain page-level attribution; the shipped notice contains the full credits.
bool isTrustedVocabularySource(String source) =>
    source == 'Open English WordNet 2025 (CC BY 4.0)' ||
    source.startsWith(
      'Mahan Kosh multilingual dataset; commit '
      'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6;',
    ) ||
    source ==
        'Project editorial definition; original text for Sikhi Word Games' ||
    source.startsWith(
      'Simple English Wiktionary contributors (CC BY-SA 4.0); '
      'https://simple.wiktionary.org/wiki/',
    ) ||
    source.startsWith(
      'English Wiktionary contributors (CC BY-SA 4.0); '
      'https://en.wiktionary.org/wiki/',
    );

const dictionaryAttribution =
    'Dictionary definitions are adapted from Simple English Wiktionary and '
    'English Wiktionary contributors, extracted by Kaikki/Wiktextract. '
    'English word-frequency data is from wordfreq 3.1.1 by Robyn Speer. '
    'These dictionary data and adaptations are available under CC BY-SA 4.0: '
    'https://creativecommons.org/licenses/by-sa/4.0/. '
    'Entries have been selected, filtered and shortened for the games. '
    'Each entry retains its source-page attribution. Machine checks do not '
    'represent independent human review.';
