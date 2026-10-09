import '../../../core/content/vocabulary_entry.dart';

enum LanguageMode { english, romanizedPanjabi, gurmukhi }

extension LanguageModeLabel on LanguageMode {
  VocabularyScript get script => switch (this) {
    LanguageMode.english => VocabularyScript.english,
    LanguageMode.romanizedPanjabi => VocabularyScript.romanizedPunjabi,
    LanguageMode.gurmukhi => VocabularyScript.gurmukhi,
  };

  String get label => switch (this) {
    LanguageMode.english => 'English',
    LanguageMode.romanizedPanjabi => 'Romanized Punjabi',
    LanguageMode.gurmukhi => 'Gurmukhi',
  };
}
