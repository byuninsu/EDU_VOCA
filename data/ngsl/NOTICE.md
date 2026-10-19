# NGSL vocabulary data — attribution and changes

The vocabulary dataset, Korean study glosses and derived study bands are
distributed under Creative Commons Attribution-ShareAlike 4.0 International:
https://creativecommons.org/licenses/by-sa/4.0/
Full license: CC-BY-SA-4.0.txt in this directory.
This notice applies to the vocabulary data, not a blanket relicense of unrelated app code.

## Sources

- **New General Service List (NGSL), version 1.2** (2023).
  Authors: Charles Browne, Brent Culligan and Joseph Phillips.
  https://www.newgeneralservicelist.com/new-general-service-list
  Downloaded 2026-10-07:
  - https://www.newgeneralservicelist.com/s/NGSL_12_stats.csv
  - https://www.newgeneralservicelist.com/s/NGSL_12_with_English_definitions.xlsx
- **New General Service List – Spoken (NGSL-S), version 1.2** (2017).
  Authors: Charles Browne and Brent Culligan.
  https://www.newgeneralservicelist.com/ngsl-spoken
  Downloaded 2026-10-07:
  - https://www.newgeneralservicelist.com/s/NGSL-Spoken_12_stats.csv
  - https://www.newgeneralservicelist.com/s/NGSL-Spoken_12_with_en_definitions.csv

Both official source pages identify the lists as CC BY-SA 4.0.
The original authors do not endorse this app. Data is provided without warranty.

## Changes made by Daily English

- Merged 2,809 NGSL entries and 721 NGSL-Spoken entries by case-insensitive lemma.
  There are 697 overlapping entries and **2,833 unique entries**.
- Retained official NGSL SFI ranks and NGSL-Spoken ranks separately.
  The spoken CSV is not in rank order; ordering uses its Rank column.
- `TRUE` in the spoken source has `#N/A` for Rank, SFI and U. Its membership
  remains true and its rank remains null; no rank was inferred. It is placed
  after the ranked spoken words in the app's study order.
- Matched `e-mail` in the official definitions to `email` in the official ranks.
- Used NGSL English definitions where both lists define the same lemma,
  and spoken definitions for the 24 additional spoken-only number words.
- Added AI-authored Korean study glosses. These are **not official NGSL
  translations**, exhaustive dictionary definitions, or independently expert-reviewed content.
- Added an app study order: spoken core first by spoken rank, followed by
  other NGSL entries by general rank. Divided that order into 50 approximately
  equal bands. These are app learning stages, not CEFR or tested difficulty ratings.
- Reused existing app-authored sentence exercises where the headword matches.
  Other words use Korean-meaning recall with a first-letter/length hint.
  Existing non-NGSL phrase reviews remain available and are not labeled as NGSL entries.

`raw/` contains the unchanged downloaded files; `manifest.json` contains their
SHA-256 hashes and import counts. `korean_*.txt` contains the added Korean glosses.
`assets/data/ngsl.json` is the attributed derived dataset. It is included in the
app bundle along with this notice and the full license. `lib/ngsl_data.dart` is
the same data compiled for offline use. Regenerate with `python tools/build_ngsl.py`.

When redistributing adapted data, retain appropriate attribution, a link to the
license, and an indication of changes; distribute adaptations under CC BY-SA 4.0
or a compatible license as allowed by its terms.
