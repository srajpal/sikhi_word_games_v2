# Sikhi Word Games V2 — Product Decisions

## Confirmed scope

- Build V2 as a clean Flutter/Dart application rather than modifying V1 in place.
- Target Android, iPhone/iPad, and web from one codebase.
- Operate completely offline in the initial release.
- Provide the app for free with no ads or monetization initially.
- Do not include accounts, online leaderboards, or a backend dependency.
- Do not migrate V1 user settings, scores, or statistics.
- Begin with unlimited random Bujho: Guess the Word games.
- The build 8 playable collection includes Bujho: Guess the Word, Khoj: Word Search, and Chardi Kala: Word Quest, plus the Dictionary. Word Bridges is the next implementation candidate. Typing Challenge was subsequently retired in favor of exploring a Gurmukhi letter-recognition game.

## Next games and saved concepts

On September 12, 2026, the owner selected **Word Bridges as the next game**
and **Journey Through Punjab as the next experiment**. Word Bridges is now an
implemented candidate in 1.5.0+9 with automated checks and a local browser playthrough. Journey remains a roadmap
experiment, with no implementation or release commitment.

### Word Bridges: implementation candidate

Match a word to its meaning. It adds a
recognition and connection game to the existing guessing and searching loops.

First playable scope:

- A small untimed set of four pairs. Select an item and then its partner;
  support tap, keyboard and screen-reader activation without requiring dragging.
- Start with word-to-meaning matching. Add Gurmukhi-to-romanized pairs once the
  starter pool has been checked for unambiguous mappings and spelling aliases.
- Keep successful pairs visible. A mismatch gives clear feedback and allows
  another attempt without taking away progress or imposing a timer.
- Use a small explicitly checked starter pool. Shared definitions, near-synonyms and
  duplicate spellings must not create multiple reasonable answers in one set.
  Existing answer eligibility alone does not prove a pair is unambiguous.
- Reuse the three shared themes, offline vocabulary boundaries, saved-game
  pattern, first-launch guide, Help replay and per-game statistics. Record
  finished sets and matching attempts without inventing a cross-game win rate.

The candidate has four fixed decks of four pairs: two English decks and two
Punjabi decks. The Punjabi decks are available in Romanized Punjabi and Gurmukhi;
all meanings are English. These are 16 source entries, not separate content
pools for each script. Mixed-language decks and script-to-script matching remain
future scope. The small starter selection is intended to validate the game;
replay variety needs playtest feedback before expanding it.

Decks resolve stable vocabulary IDs against the shipped release repository.
Every entry must still be an accepted guess, solution eligible, and have a
distributable definition. A missing, duplicate, held, wrong-language, or unusable
record disables the entire affected deck. Gurmukhi also requires a nonempty
script spelling. Each deck requires distinct spellings and meanings. Original
source definitions and provenance remain unchanged; corrections continue through
the existing content curation workflow, never hand-edited release files.

The starter groups were checked by an agent for clear, distinct matches against
the current shipped records. This does not constitute human editorial approval
or a claim that automated eligibility alone establishes age suitability.

### Journey Through Punjab: experimental prototype

Try a short journey that combines word puzzles with a sense of place. Begin
with one location and three short, hand-authored activities, rather than a full
map or campaign. A first prototype can reuse a Word Bridges round and the
existing word-game mechanics so the experiment tests whether the journey itself
adds interest. The location and activity selection remain to be decided.

Proposed acceptance criteria:

- A clear start, one location introduction, a short activity sequence, and a
  satisfying completion page. Save the current stop offline.
- Offer an accessible list of stops as the primary navigation; an illustrated
  map must not be the only way to progress.
- Use sourced, reviewed cultural facts and original or licensed artwork. Do
  not generate historical claims from dictionary definitions. Clearly identify
  the places represented without implying that one short route covers all Punjab.
- Keep sacred symbols decorative and respectful. Do not turn sacred text,
  religious observance or spiritual worth into timed challenges or scores.
- Evaluate variety, replay interest, reading load and content-production effort
  before committing to more locations, narration or a persistent campaign.

### Saved for later inspection

| Concept | Core loop | Review before implementation |
| --- | --- | --- |
| Word Garden | Rearrange grapheme tiles from a definition clue; grow a persistent secular garden. | Distinguish it from Word Quest's existing garden imagery and letter-reveal loop; provide non-drag controls. |
| Find the Connection | Sort words into related groups such as foods, instruments or everyday objects. | Hand-curate groups, check overlapping categories, and avoid depending on obscure cultural knowledge. |
| Build the Sentence | Arrange words into useful Punjabi sentences with optional pronunciation support. | Review Punjabi grammar, valid alternative orders, translations and any audio sources. |
| Akhar Pachhaan (working name) | Recognize a single Gurmukhi letter from three Romanized choices, then build a mastered-letter collection through short practice rounds. | Separate letter names from sounds, review aliases and near-confusable options, and verify any generated pronunciation clips with a fluent speaker. |

These ideas are retained for inspection, with no implementation order assigned
after Word Bridges and the Journey prototype. Familiar-word difficulty and
Dictionary saved words remain separate product follow-ups.

## Language modes

- English uses Latin script.
- Romanized Punjabi uses Latin script.
- English and romanized Punjabi share one on-screen Latin keyboard.
- Mixed English/Punjabi selects English or romanized Punjabi solutions and accepts valid guesses from both pools.
- Gurmukhi is a separate mode with a purpose-built on-screen keyboard.
- Every Gurmukhi on-screen keyboard shows a short romanized pronunciation under
  each key and uses the shared pronunciation/label components.
- Gurmukhi word length is measured in user-visible Unicode grapheme clusters.
- Do not combine Latin and Gurmukhi guesses in one game because their keyboards and length rules differ.

## Vocabulary policy

- Maintain a broad accepted-guess collection.
- Maintain a smaller curated solution collection.
- A word may be accepted as a guess without being eligible as a solution.
- Imported or researched content must retain its source and review status.
- Unreviewed vocabulary must not silently enter the curated solution pool.
- All playable games select only accepted, answer-eligible records with a
  distributable definition. Selection deduplicates the actual displayed
  spelling, including aliases that have different stable IDs.
- Source-matched automatic decisions and owner-authorized editorial decisions
  are recorded as `machineChecked`, not as community or independent human review.

## Design policy

- Players choose their active theme.
- Ship exactly three themes: Modern, Sikhi, and Dark. Sikhi is the default.
- Keep all three themes in the shared theme system without duplicating game screens.
- Use semantic design tokens and reusable themed components.
- Keep game rules independent of visual themes.
- Modern uses teal actions and light neutral surfaces. Sikhi uses navy actions,
  warm cream surfaces and restrained geometric decoration. Dark uses deep blue
  surfaces with pale blue actions. Keep readable sans-serif text in all three.
- Game previews and garden illustration colors belong in the shared theme
  components. Sacred marks remain static header decoration, never game pieces.
- Give Continue game the strongest emphasis when a saved game exists; otherwise
  emphasize New game. Keep options visually secondary.

## Progress and first-time guidance

- Each playable game has its own offline statistics. Keep Bujho history and
  start new Khoj/Word Quest counters without inventing historical results.
- The library offers rounds finished and words solved plus separate game
  summaries. Do not combine win rates across different game rules or count
  unfinished games as losses. Repeated words and finished retries count.
- Show a short, skippable introduction on the first launch of each game, with
  replay available from How to play. Keep instructions direct and consistent.
- Replace the large recurring Choose a game panel with a short language/offline
  line. The individual cards explain each game.
- Preserve system text scaling, non-color feedback and all three themes.
  Accessible activation and readable controls take priority over fitting every
  action into a fixed-height surface.

## Hosting policy

- Cloudflare Pages is the leading candidate for static web previews and hosting.
- Prepare the playable web app for an itch.io public playtest. Publishing remains a separate release action; see README.md and TODO.md for gates.
- The final marketing-site relationship is intentionally undecided.

## Google Play feasibility assessment, September 12, 2026

Recommendation, pending owner decision: prepare a closed beta, then a measured
community launch. Android packaging is feasible and build 1.5.0+9 already exists;
public Play publication is not ready. This assessment does not authorize publishing.

Repository evidence: release signing still uses the debug key in
`app/android/app/build.gradle.kts`. The existing APK targets API 36 and its launcher
label remains `sikhi_word_games_v2`. No privacy policy implementation was found in
the relevant app/docs files. Dependencies show no advertising or analytics SDK.
Prior validation covers 212 distinct tests across full and targeted runs, clean
analysis and a browser playthrough; the latest build lacks physical-device evidence.

Required preparation:
- Configure a protected upload key and Play App Signing; build and validate an AAB.
  Decide the permanent application ID and test migration from debug-signed installs.
- Finish launcher branding, store screenshots, description and support contact.
- Publish an accurate privacy policy and expose it in-app; audit final SDK/data
  behavior before completing Data safety, ads, audience and content-rating forms.
- Confirm developer account type, verification status and production eligibility.
- Test latest release on Pixel and another representative device, including
  airplane mode, updates, text enlargement, TalkBack, and 16 KB compatibility.
- Review the shipped answer pool for the intended audience with a Punjabi reader;
  archive editorial flags are not automatically shipped defects. Expand Word Bridges
  beyond two sets per language before promoting it as a lasting daily activity.

Policy sources checked today:
- [Registration](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en): US$25 one-time account fee; identity/device verification as applicable.
- [Personal-account testing](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en): accounts created after November 13, 2023 require 12 continuously opted-in closed testers for 14 days before applying for production access. Approval is separate.
- [Target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en): new mobile submissions target API 36 from August 31, 2026; current APK does.
- [Bundles](https://developer.android.com/guide/app-bundle): new Play apps use AAB.
- [Native compatibility](https://developer.android.com/guide/practices/page-sizes): verify 16 KB native-library alignment and runtime behavior.
- [Privacy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en): even apps without sensitive-data collection need a policy and accurate disclosures.
- [Families](https://support.google.com/googleplay/android-developer/answer/9893335): child-targeted distribution adds audience/content obligations.
- [Fees](https://support.google.com/googleplay/android-developer/answer/112622?hl=en-GB): service fees concern paid transactions; the initial free/no-purchases model has no per-download service fee.

Audience evidence is directional, not a forecast. The retrieved Play listing for
[Punjabi Spelling Word Game](https://play.google.com/store/apps/details?id=com.amritpunjabi.punjabispelling)
shows 10K+ downloads; [Punjabi Alphabet Amrit Punjabi](https://play.google.com/store/apps/details?id=com.amritpunjabi.amritpunjabi)
shows 50K+. These are cumulative install bands, not monthly usage, revenue or proof
of organic discovery. Both are older, established products; our acquisition and
retention remain unknown. Google describes listing quality, user experience,
ratings, reviews and downloads as [search factors](https://support.google.com/googleplay/android-developer/answer/4448378?hl=en).

Economic rationale: low cash distribution cost and no game backend make a free
community app viable when success means cultural access, returning learners and
studio recognition. Maintenance, support and content review remain real costs.
Downloads do not generate revenue in the current model. Do not spend on paid
acquisition before learning whether players return.

Proposed validation plan: recruit 15-20 genuine testers, including Punjabi teachers,
families and learners. Complete the required test window if applicable. Seek
unprompted repeat play and clear feedback about vocabulary difficulty. Then run a
30-day launch through the studio website and willing community partners; measure
Play listing visitors, acquisitions, retained installs where available, and voluntary
feedback without adding intrusive tracking. Suggested first milestone: 100 real
installs and evidence of repeat use, explicitly a goal rather than a forecast.
A planning allowance of 3-6 calendar weeks assumes prompt account verification,
recruited testers and manageable fixes; Google review timing is not guaranteed.

### Potential advice contact: Amrit Punjabi / Albatross Singh

Recorded at the owner's request on September 12, 2026. Both apps list the same
Google Play developer, **Albatross Singh**. The Alphabet app's public developer
section identifies **sudhir singh atul** and lists **support@amritpunjabi.com**
as the support email. Public project website: **www.amritpunjabi.com**.

| App | Google Play listing | Observed cumulative downloads |
| --- | --- | --- |
| Punjabi Spelling Word Game | https://play.google.com/store/apps/details?id=com.amritpunjabi.punjabispelling | 10K+ |
| Punjabi Alphabet Amrit Punjabi | https://play.google.com/store/apps/details?id=com.amritpunjabi.amritpunjabi | 50K+ |

Names, contact and download bands were checked against the public Play listings
linked above. Both listings describe free, ad-free Punjabi learning tools. Install
bands are historical totals and do not establish current activity or responsiveness.

Possible future advice topics: reaching Punjabi families and teachers, attracting
the first users, vocabulary/age suitability, recording pronunciation audio, and
maintaining a free community app on Google Play. Status: potential outreach only;
no message sent. The owner may decide later whether to make contact.

## Visual review and audience hypothesis, September 12, 2026

Review scope: live packaged 1.5.0+9 in the in-app Chromium browser; library in
Modern/Sikhi/Dark, Bujho and Khoj at 360x800, Word Quest at 360x800 and 1280x800,
and Gurmukhi Word Bridges at normal and 360x800 widths including a matched state.
Also inspected stored Bujho Modern, Khoj Dark and Quest Sikhi completion reference
images and commissioned an independent source review of shared styling. This was
a visual review, not a fresh full test suite, contrast audit or native TalkBack test.
Temporary viewport and theme changes were restored. No application design changes
were made in this review.

Findings:
- The family resemblance is real, but polish and interaction styling are uneven.
  Quest has a scene and richer finish; Bridges has stock stadium outlined buttons.
  Toolbars, action casing, shapes and completion treatments vary between games.
- Library cards devote too much phone space to three repeated actions. Bujho and
  Khoj preview silhouettes are too similar; unavailable Typing Challenge has a
  stronger gradient icon than playable games. Recommend smaller game cards with
  one primary Play/Continue action, secondary options, and a discreet future list.
- At 360px Quest truncates the essential clue and language label despite unused
  vertical space. Its full-definition control and category text are small.
- Bujho keys and Khoj cells are dense on narrow phones. Gurmukhi word text needs
  stronger visual prominence. Readability should improve before more ornament.
- Bridges matched icon/text increases card heights and moves later targets.
  Its gradient stops at the scroll content bottom, exposing the scaffold below;
  the boundary moves after matching. Shared GameBackdrop uses a loose Stack.
- The broad dictionary currently undermines an early-childhood position. A live
  Quest draw displayed 'someone deranged and possibly dangerous', which needs
  editorial review for stigmatizing language and the intended answer pool.

Recommendation (a hypothesis for user testing, not an approved age declaration):
primary audience is literate heritage-language learners, roughly age 12 upward,
especially teens and adults; older children around 8-11 are a secondary guided
or familiar-word audience. Avoid an arbitrary upper age limit. Reading proficiency
is more predictive than age. A preschool product would need picture/audio teaching,
familiar vocabulary and different activities, rather than a brighter skin.
The comparable [Punjabi Spelling listing](https://play.google.com/store/apps/details?id=com.amritpunjabi.punjabispelling)
explicitly uses pictures and narrator voices for young learners. Our hypothesis
needs interviews/playtests across learners, parents and older users.

Proposed direction: a warm illustrated puzzle collection with calm reading areas,
clear lettering and expressive but restrained identity/progress illustrations.
Keep exactly Modern, Sikhi and Dark with one shared layout/component/illustration
system. Modern can use light surfaces with richer teal and selected warm accents;
Sikhi can use navy, cream, saffron and botanical green with restrained geometric
border details; Dark can use ink-blue surfaces and clear mint/blue/gold accents.
Use motifs such as tiles, search paths, gardens and a four-part bridge; do not
cartoon sacred imagery or place patterns behind essential text. Palette details
remain proposals, subject to measured contrast. State colors must retain symbols
and text, following [W3C color guidance](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html).

Recommended order: fix clipping/backdrop/target movement; standardize toolbars,
controls, progress and completion; prototype a compact library and richer Bridges
screen in all three themes; compare with the current design in small playtests.
Assess game recognition, reading clarity and desire to replay, not just preference
for colorful screenshots. Do not add a fourth theme or another game to solve this.

### Approved redesign, candidate 1.6.0+10

The owner approved implementation of the illustrated direction. The library uses
compact responsive cards, distinct shared tile/search/garden/bridge illustrations,
and one primary action with an options icon. Modern, Sikhi and Dark remain the
only themes; shared controls and calmer full-height backdrops carry the family
resemblance. Jodo uses readable rectangular cards, non-color matched cues and
stable selection geometry. Quest clues/status wrap and letter feedback stays
inline so it cannot cover keyboard targets. Further toolbar/completion alignment
and low-vision playtesting remain follow-up work.

Word Bridges is named **Jodo: Word Bridges**, Punjabi **ਜੋੜੋ**, meaning
"join/connect". The name follows the short Punjabi action names Bujho and Khoj.
The root ਜੋੜਨਾ is documented in the
[Punjabi.com dictionary](https://punjabi.com/dictionary/wordmeaning?search=%E0%A8%9C%E0%A9%8B%E0%A9%9C%E0%A8%A8%E0%A8%BE).
This is a display-name change; existing game identifiers, routes and saved progress
are retained. Journey Through Punjab and other ideas remain on the roadmap.

### Phone layout follow-up, 1.6.1+11

Home actions use one compact row: Continue, New game, options when a saved round
exists; New game and options otherwise. Touch targets remain at least 48 pixels.
Enlarged text may move the secondary action below rather than shrink labels.

Jodo uses a two-by-two word bank above full-width meanings below 600 pixels of
content width or with large text. Wider boards use aligned rows with more width
for meanings. Cards retain their dimensions when selected or matched. The header
is smaller so more of the puzzle fits on a phone. Gurmukhi word cards show the
existing vocabulary's Romanized spelling underneath, including on restored games;
this display lookup does not change saved-game serialization or vocabulary assets.

### Studio attribution, 1.6.2+12

Sikhi Word Games is published under **Khalsa Game Studio** with the studio address
**https://khalsagamestudio.com/**. Keep the game title distinct from the publisher.
The library shows a compact studio byline and an explicit external website link;
if no browser can launch, the address remains selectable. Opening the website is
optional and does not participate in gameplay, storage, or offline startup.
Web title, description, loading copy and release cover repeat the attribution.
The app retains its existing SWG tile/garden icon and its three themes. The studio
identity is a text wordmark, not an invented replacement for an official logo.
The supplied site could not be retrieved during implementation; this change does
not claim website deployment, domain health or store publication.

### App data and statistics
The home settings gear includes Your statistics for all four games; the home footer no longer repeats it. Reset all app data requires a separate confirmation and removes local saved games, statistics, word history, launch preferences, settings and tutorial progress. Bundled vocabulary and offline files remain. Cancel leaves data unchanged.



### Victory celebrations and next-game proposal
Newly earned wins in all four games trigger a short original bundled chime and three particle bursts with a trophy banner. Global and per-game sound/particle opt-outs persist in app settings. Device/app reduced motion suppresses the animation; existing completion text remains. Losses, restoration and rebuilds do not celebrate; new rounds, disposal and app backgrounding stop effects. All effects work without a network dependency.

Typing Challenge is removed from the home screen. Proposed successor: ਅੱਖਰ ਪਛਾਣ · Akhar Pachhaan (Recognize the Letter), a beginner-friendly five-to-ten-question recognition round with three answer choices, gentle retry, spaced review, and visible mastery. This is a proposal, not a newly shipped game. Letter-name practice should precede a separate letter-sound mode; avoid one-to-one Romanization assumptions and review aliases. Journey Through Punjab remains the longer-term variety experiment.

Punjabi synthetic voices are technically available (Azure lists pa-IN-OjasNeural and pa-IN-VaaniNeural: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts). Generate and fluent-speaker-review fixed clips before bundling, subject to service usage rights; do not depend on device TTS availability or runtime cloud access. Automated synthesis alone does not establish correct isolated-letter pronunciation.


### Akhar Pachhaan: Learn Letters (1.9.0+15)
The owner approved implementation under this exact English title, and explicitly requested generated pronunciation sounds for testing. Five-question untimed rounds teach the traditional names of the basic35 Gurmukhi letters, not their phonetic sounds in words. Three unique Romanized choices, disabled wrong choices, explicit Next, and no failure state support beginner practice. A letter is marked Practiced after three first-try answers in completed rounds; rounds prioritize lower practice counts. First-try history is a practice indicator, not a certified learning assessment. Extended letters and vowel marks are outside this introductory scope.

The content table is separate from word vocabulary shards. Punjabi University's https://www.learnpunjabi.org/intro1.asp informs the basic alphabet and names-versus-sounds distinction. Romanized spelling is an approximate presentation convention; underdots distinguish retroflex names. The letter-name table and audio remain open to the owner's language review.

35 offline WAV previews were generated locally using eSpeak NG1.52.0's Punjabi voice from native Punjabi letter-name text. These are intentionally labeled computer-generated pronunciation previews and have not received human pronunciation approval. Playback is explicit after a correct answer, on completion, and from Letter progress; no microphone or network service is required. A new clip stops the previous clip. Generated WAVs are bundled; the generator/runtime remain development tools only. Per-clip text, voice, checksums, source and review status live in app/tool/learn_letters_audio_manifest.json. Engine licensing and output-rights notes are recorded separately; do not represent this test build as a teacher-verified audio course.
