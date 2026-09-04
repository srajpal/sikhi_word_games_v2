# Panjabi definition audit

Audit of the generated Word Quest vocabulary assets (vocabulary_4.json through
vocabulary_6.json), limited to entries tagged `language: panjabi` and currently
marked `acceptedGuess: true`.

## Findings

- 17,651 accepted Panjabi entries were scanned.
- 1,005 entries have a definition whose primary text is only a dictionary
  cross-reference (`See ...`, `The same as ...`, or `Same as ...`). These cannot
  stand alone as clues and should be rejected or replaced with a verified
  primary sense.
- 2,039 entries contain a likely editorial/OCR problem or reference fragment,
  including `Previous page`, `of <capitalized word>` fragments, or an embedded
  `see` reference. This is a review queue, not an automatic rejection list.

Representative failures include `panjabi_umed` (“See Umaid ...”),
`panjabi_wehi` (“See BehI.”), `panjabi_tosh` (“See Tos.”),
`panjabi_borh` (“See BohaR, BohiR.”), `panjabi_eran` (“See Eilan.”),
`panjabi_jera` (“See JigrA.”), and `panjabi_sabera` (“See SawerA.”).

The generated assets were not edited. The existing curation decision files are
the appropriate place to reject these entries or attach a verified,
standalone English definition; bulk guesses would risk assigning the wrong
sense to Romanized/Gurmukhi homographs. In particular, “of X” must not be
treated as a definition unless the complete sense is present (for example,
“of the same age” is meaningful, while “of Ginnee” is not).

Validation command used: `dart run tool/audit_content.dart` (run from `app`).
