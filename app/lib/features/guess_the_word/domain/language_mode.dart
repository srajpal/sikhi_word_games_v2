enum LanguageMode { english, romanizedPanjabi, mixedLatin, gurmukhi }

extension LanguageModeLabel on LanguageMode {
  String get label => switch (this) {
    LanguageMode.english => 'English',
    LanguageMode.romanizedPanjabi => 'Romanized Panjabi',
    LanguageMode.mixedLatin => 'Mixed Latin',
    LanguageMode.gurmukhi => 'Gurmukhi',
  };
}
