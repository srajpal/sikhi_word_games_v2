/// Traditional letter names, not the sounds letters make inside words.
class LetterEntry {
  const LetterEntry(this.id, this.gurmukhi, this.name);
  final String id;
  final String gurmukhi;
  final String name;
  String get nativeName => _nativeNames[id]!;
}

const _nativeNames = {
  'ura': 'ਊੜਾ',
  'aira': 'ਐੜਾ',
  'iri': 'ਈੜੀ',
  'sa': 'ਸੱਸਾ',
  'ha': 'ਹਾਹਾ',
  'ka': 'ਕੱਕਾ',
  'kha': 'ਖੱਖਾ',
  'ga': 'ਗੱਗਾ',
  'gha': 'ਘੱਗਾ',
  'nga': 'ਙੰਙਾ',
  'ca': 'ਚੱਚਾ',
  'cha': 'ਛੱਛਾ',
  'ja': 'ਜੱਜਾ',
  'jha': 'ਝੱਜਾ',
  'nya': 'ਞੰਞਾ',
  'tta': 'ਟੈਂਕਾ',
  'ttha': 'ਠੱਠਾ',
  'dda': 'ਡੱਡਾ',
  'ddha': 'ਢੱਡਾ',
  'nna': 'ਣਾਣਾ',
  'ta': 'ਤੱਤਾ',
  'tha': 'ਥੱਥਾ',
  'da': 'ਦੱਦਾ',
  'dha': 'ਧੱਦਾ',
  'na': 'ਨੰਨਾ',
  'pa': 'ਪੱਪਾ',
  'pha': 'ਫੱਫਾ',
  'ba': 'ਬੱਬਾ',
  'bha': 'ਭੱਬਾ',
  'ma': 'ਮੰਮਾ',
  'ya': 'ਯੱਯਾ',
  'ra': 'ਰਾਰਾ',
  'la': 'ਲੱਲਾ',
  'va': 'ਵਾਵਾ',
  'rra': 'ੜਾੜਾ',
};

/// Basic 35-letter sequence, checked against Punjabi University's teaching
/// chart: https://www.learnpunjabi.org/intro1.asp (2026-09-12).
/// Beginner Roman spellings are an editorial presentation convention.
/// Underdots distinguish retroflex names from their dental counterparts.
/// Audio from the source is not redistributed. Extended letters/vowel marks
/// are intentionally outside this introductory activity.
const learnLetters = <LetterEntry>[
  LetterEntry('ura', 'ੳ', 'Oora'),
  LetterEntry('aira', 'ਅ', 'Aira'),
  LetterEntry('iri', 'ੲ', 'Iri'),
  LetterEntry('sa', 'ਸ', 'Sassa'),
  LetterEntry('ha', 'ਹ', 'Haha'),
  LetterEntry('ka', 'ਕ', 'Kakka'),
  LetterEntry('kha', 'ਖ', 'Khakha'),
  LetterEntry('ga', 'ਗ', 'Gagga'),
  LetterEntry('gha', 'ਘ', 'Ghagha'),
  LetterEntry('nga', 'ਙ', 'Nganga'),
  LetterEntry('ca', 'ਚ', 'Chacha'),
  LetterEntry('cha', 'ਛ', 'Chhachha'),
  LetterEntry('ja', 'ਜ', 'Jajja'),
  LetterEntry('jha', 'ਝ', 'Jhajha'),
  LetterEntry('nya', 'ਞ', 'Nyanja'),
  LetterEntry('tta', 'ਟ', 'Tainka'),
  LetterEntry('ttha', 'ਠ', 'Ṭhaṭha'),
  LetterEntry('dda', 'ਡ', 'Ḍaḍḍa'),
  LetterEntry('ddha', 'ਢ', 'Ḍhaḍha'),
  LetterEntry('nna', 'ਣ', 'Ṇaṇa'),
  LetterEntry('ta', 'ਤ', 'Tatta'),
  LetterEntry('tha', 'ਥ', 'Thatha'),
  LetterEntry('da', 'ਦ', 'Dadda'),
  LetterEntry('dha', 'ਧ', 'Dhadha'),
  LetterEntry('na', 'ਨ', 'Nanna'),
  LetterEntry('pa', 'ਪ', 'Pappa'),
  LetterEntry('pha', 'ਫ', 'Phapha'),
  LetterEntry('ba', 'ਬ', 'Babba'),
  LetterEntry('bha', 'ਭ', 'Bhabha'),
  LetterEntry('ma', 'ਮ', 'Mamma'),
  LetterEntry('ya', 'ਯ', 'Yayya'),
  LetterEntry('ra', 'ਰ', 'Rara'),
  LetterEntry('la', 'ਲ', 'Lalla'),
  LetterEntry('va', 'ਵ', 'Vava'),
  LetterEntry('rra', 'ੜ', 'Ṛaṛa'),
];

final learnLettersById = Map<String, LetterEntry>.unmodifiable({
  for (final letter in learnLetters) letter.id: letter,
});
