/// Source families shipped with the approved offline release.
bool isTrustedVocabularySource(String source) =>
    source.startsWith('Princeton WordNet 3.0 (WordNet license); ') ||
    source ==
        'Project editorial definition; original text for Sikhi Word Games' ||
    source.startsWith(
      'English Wiktionary contributors (CC BY-SA 4.0); '
      'https://en.wiktionary.org/wiki/',
    );

const dictionaryAttribution =
    'English words and definitions: Princeton WordNet 3.0, under the WordNet license. '
    'Punjabi words and definitions: English Wiktionary contributors, extracted by '
    'Kaikki/Wiktextract, under CC BY-SA 4.0. Each Punjabi entry retains its source '
    'page and contributor history. Upstream screening used Shutterstock’s '
    'LDNOOBW list under CC BY 4.0. The supplied release is approved by the project '
    'owner. Full source credits and license texts are included below.';
