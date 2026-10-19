# Oxford CEFR mapping

Source: https://www.oxfordlearnersdictionaries.com/wordlists/oxford3000-5000
Checked: 2026-10-08. Rights holder: Oxford University Press.
Terms: https://www.oxfordlearnersdictionaries.com/terms-and-conditions

This mapping is separate from the NGSL CC BY-SA dataset. No redistribution
permission from Oxford has been obtained; public availability is not an open
license. No Oxford definitions or recordings are included.

`tools/build_oxford.py` extracts headword, part of speech and CEFR facts from a
locally downloaded official HTML page. Exact lowercase headwords only; no
guessed spelling aliases. 2,429 NGSL headwords have one unanimous CEFR across
the listed parts of speech. 326 have ambiguous grades and 78 are unmatched;
these 404 remain unclassified. This does not certify individual sense levels.

A1/A2/B1/B2/C1 map to 1/2/3/4/5 difficulty stars, independently of frequency.
