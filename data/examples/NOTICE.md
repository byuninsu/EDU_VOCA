# Bilingual cloze examples

Sources retrieved 2026-10-08:

- https://www.manythings.org/anki/kor-eng.zip (curated Tatoeba pairs)
- https://downloads.tatoeba.org/exports/per_language/kor/kor-eng_links.tsv.bz2
- https://downloads.tatoeba.org/exports/per_language/kor/kor_sentences_detailed.tsv.bz2
- https://downloads.tatoeba.org/exports/per_language/eng/eng_sentences_detailed.tsv.bz2

Tatoeba sentences and translations are CC BY 2.0 FR:
https://creativecommons.org/licenses/by/2.0/fr/
https://tatoeba.org/en/terms_of_use

The `credit` field preserves contributor names and both source sentence IDs.
Original pages: `https://tatoeba.org/en/sentences/show/<ID>`.
ManyThings compilation: https://www.manythings.org/anki/
The imported pair subset is pinned in `tatoeba.json` for offline regeneration.
Raw archives are development downloads, not app assets.

App-authored examples in `authored.txt` were written by AI, with full Korean
translations, and are supplied under CC BY-SA 4.0. They are not official
NGSL/Oxford examples. No expert review is claimed for either source.

Processing: select a 4–20-token sentence with a full Korean translation,
replace exactly one whole token with `____`, retain the original token as the
answer (including inflected forms), and preserve the sentence translation.
Prefer simpler surrounding vocabulary, app-authored/curated pairs and exact
headwords. Some different words use the same underlying sentence.
Existing app examples and their alternative answers take precedence.

Run `python tools/build_examples.py` to generate
`lib/data/local/cloze_examples.dart` and `selected.json` offline. Generation
fails if any of the 2,833 headwords is missing an example. `--import` explicitly
reimports the downloaded archives from build/; it does not fetch the network.
NGSL ranks, Oxford metadata, Korean headword glosses and stable review IDs are
unchanged. Sentence-level CEFR is not assessed.

`reviewed.json` contains explicitly selected app-authored replacements and
their Korean highlight spans. They override automatic example selection;
this includes separating rose (flower) from rose (past of rise), and found
(establish) from found (past of find). These replacements are AI-authored,
CC BY-SA 4.0, and do not claim expert review. The original Tatoeba files remain
unchanged. Additional contextual highlight cues are app-authored in WordCues.

Dialogue openings: `lib/data/local/dialogue_contexts.dart` adds AI-authored
Sam turns, Korean translations and scene labels under CC BY-SA 4.0. All 64
phrases and the original app examples have individual openings. Other entries
use topic-based openings or general conversational prompts; these are not
individually reviewed conversations. Sally's existing sentence, translation,
answer and original credit remain unchanged. No online generation is used.
