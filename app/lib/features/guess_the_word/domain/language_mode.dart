enum LanguageMode { english, romanizedPanjabi, gurmukhi }

extension LanguageModeLabel on LanguageMode {
  String get label => switch (this) {
    LanguageMode.english => 'English',
    LanguageMode.romanizedPanjabi => 'Romanized Punjabi',
    LanguageMode.gurmukhi => 'Gurmukhi',
  };
}
