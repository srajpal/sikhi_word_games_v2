RELEASE DICTIONARIES

Final selected-definition snapshot for use in word games.

Folders: english/, punjabi/romanized/, punjabi/gurmukhi/.
Each folder contains exactly one master dictionary in three formats:
  words.json        One definition per word, plus source metadata and tile counts.
  words.txt         Words only, one per line.
  definitions.txt   Word TAB definition, one entry per line, no header.
English and Romanized Punjabi cover 4-6 tiles. Gurmukhi covers 2-8 tiles.
Retired per-length release files have been removed to keep one current version.

All files are UTF-8. JSON is an object; read its "words" array. Each entry has
"word", "definition", "part_of_speech", "letter_units", and "tile_count",
with further provenance fields. Filter by tile_count for a fixed-width puzzle.
The top-level length_counts reports membership by length. Punjabi entries
also retain counterpart spellings. Definitions
are in English. Do not count bytes or code points to determine Punjabi lengths.

English uses lowercase ASCII letters. Roman Punjabi retains scholarly diacritics;
a Latin letter with attached diacritics is one unit, while kh counts as two.
Gurmukhi uses a base letter with its marks and virama-linked subjoined letters
as one written unit. All lists are sorted by Unicode code-point order.

COUNTS
Letters | English | Romanized Punjabi | Gurmukhi
2       | not included | not included | 1,515
3       | not included | not included | 1,865
4       | 2,263 | 658 | 787
5       | 3,972 | 1,354 | 220
6       | 6,292 | 979 | 33
7       | not included | not included | 7
8       | not included | not included | 1

Totals: English 12,527;
Romanized Punjabi 2,991;
Gurmukhi 4,428.
Punjabi script totals represent overlapping vocabulary and must not be summed
as a count of unique Punjabi meanings.

ATTRIBUTION
Read ATTRIBUTION.txt and licenses/. Keep them with distributed exports.
JSON preserves source licenses, modifications, and Punjabi page/history links.
English uses the WordNet license; Punjabi data uses CC BY-SA 4.0.
Both allow commercial reuse subject to their terms.

REVIEW AND PROVENANCE
Family-content screening is automated with targeted review. It is not a complete
human review. Rare/technical words and brief Punjabi translation glosses remain.
Shared screening checks every eligible sense before choosing a definition,
including profanity compounds, killing/murder inflections, weapon aliases,
toilet language, demeaning wording, alcohol/tobacco, and graphic/sexual content.
Reported inherently sensitive words are excluded even with neutral senses.
English gloss rules do not treat Roman Punjabi spellings as English profanity.
JSON metadata records the content-policy version and implementation hash.
The before/after sanitation audit and ambiguous editorial candidates are kept
in dictionary/audit/sanitation_report.json outside this distribution.
review_notes.json records 7 existing wording flags; those words remain in
these counts and their definitions have not been rewritten during packaging.
Excluded material, raw dictionaries, and multiple-definition exports stay in
the build tree outside this release.

Masters combine the selected-definition build outputs without rewriting senses.
Each JSON records its build inputs and hashes. Tile counts and English letter
units are added during packaging; original entry fields are preserved.
Relative build paths mentioned inside source metadata refer to dictionary/ in
the original project, not runtime dependencies of this package. Applicable
licenses are supplied here in licenses/. No source archive is needed to use it.
manifest.json records counts, packaging time, source paths, sizes, and SHA-256
hashes for all other release files. It does not hash itself.

REFRESH
From the project root, after rebuilding any affected dictionaries:
  python dictionary/package_release.py
After changing shared content rules, rebuild all languages and the release:
  python dictionary/rebuild_sanitized_release.py
This command copies the generated files and verifies counts, one definition
per word, exact length units, sorting, uniqueness, JSON/TXT agreement, preserved
source entries and license notices, review membership, and manifest hashes.
It overwrites the managed release files; do not edit them by hand or add
unfiltered material to this distribution folder.
These dictionaries are candidate vocabulary, not curated everyday-answer lists
or exhaustive valid-guess lexicons. No game or answer pool is implemented here.
