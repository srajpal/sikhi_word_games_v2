enum LanguageMode { english, romanizedPanjabi, mixedLatin, gurmukhi }

extension LanguageModeLabel on LanguageMode {
  String get label => switch (this) {
    LanguageMode.english => 'English',
    LanguageMode.romanizedPanjabi => 'Romanized Punjabi',
    LanguageMode.mixedLatin => 'Mixed English/Punjabi',
    LanguageMode.gurmukhi => 'Gurmukhi',
  };
}
