"""Prepare instant guidance cues for every practice blank (no LLM at runtime).

- Same-meaning words: authored per sentence (by Claude, AI) in
  data/cloze_cues/same/*.json as {id: [words]}. Each list was written for the
  sentence recorded in data/cloze_cues/sentences.json; changed sentences are
  reported so their lists can be reviewed.
- Wrong forms: generated here by English inflection rules from the headword
  and its parts of speech (verbs, nouns, adjectives, phrasal verbs).

    python tools/build_cloze_cues.py            (writes lib/data/local/cloze_cues.dart)
    python tools/build_cloze_cues.py --freeze   (record current sentences as reviewed)
"""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data/cloze_cues'
SAME = DATA / 'same'
SENTENCES = DATA / 'sentences.json'
ITEMS = ROOT / 'build/cloze_items.json'
DART = ROOT / 'lib/data/local/cloze_cues.dart'
ALLOWED = re.compile(r"^[a-z][a-z' -]*$", re.I)
LIMIT = 6

# base: (past, past participle)
IRREGULAR_VERBS = {
    'arise': ('arose', 'arisen'), 'awake': ('awoke', 'awoken'),
    'be': ('was were', 'been'), 'bear': ('bore', 'born borne'),
    'beat': ('beat', 'beaten'), 'become': ('became', 'become'),
    'begin': ('began', 'begun'), 'bend': ('bent', 'bent'),
    'bet': ('bet', 'bet'), 'bind': ('bound', 'bound'), 'bite': ('bit', 'bitten'),
    'bleed': ('bled', 'bled'), 'blow': ('blew', 'blown'),
    'break': ('broke', 'broken'), 'breed': ('bred', 'bred'),
    'bring': ('brought', 'brought'), 'broadcast': ('broadcast', 'broadcast'),
    'build': ('built', 'built'), 'burn': ('burnt burned', 'burnt burned'),
    'burst': ('burst', 'burst'), 'buy': ('bought', 'bought'),
    'cast': ('cast', 'cast'), 'catch': ('caught', 'caught'),
    'choose': ('chose', 'chosen'), 'cling': ('clung', 'clung'),
    'come': ('came', 'come'), 'cost': ('cost', 'cost'),
    'creep': ('crept', 'crept'), 'cut': ('cut', 'cut'), 'deal': ('dealt', 'dealt'),
    'dig': ('dug', 'dug'), 'do': ('did', 'done'), 'draw': ('drew', 'drawn'),
    'dream': ('dreamt dreamed', 'dreamt dreamed'), 'drink': ('drank', 'drunk'),
    'drive': ('drove', 'driven'), 'eat': ('ate', 'eaten'), 'fall': ('fell', 'fallen'),
    'feed': ('fed', 'fed'), 'feel': ('felt', 'felt'), 'fight': ('fought', 'fought'),
    'find': ('found', 'found'), 'flee': ('fled', 'fled'), 'fly': ('flew', 'flown'),
    'forbid': ('forbade', 'forbidden'), 'forget': ('forgot', 'forgotten'),
    'forgive': ('forgave', 'forgiven'), 'freeze': ('froze', 'frozen'),
    'get': ('got', 'gotten got'), 'give': ('gave', 'given'), 'go': ('went', 'gone'),
    'grind': ('ground', 'ground'), 'grow': ('grew', 'grown'),
    'hang': ('hung', 'hung'), 'have': ('had', 'had'), 'hear': ('heard', 'heard'),
    'hide': ('hid', 'hidden'), 'hit': ('hit', 'hit'), 'hold': ('held', 'held'),
    'hurt': ('hurt', 'hurt'), 'keep': ('kept', 'kept'), 'kneel': ('knelt', 'knelt'),
    'know': ('knew', 'known'), 'lay': ('laid', 'laid'), 'lead': ('led', 'led'),
    'lean': ('leant leaned', 'leant leaned'), 'leap': ('leapt leaped', 'leapt leaped'),
    'learn': ('learnt learned', 'learnt learned'), 'leave': ('left', 'left'),
    'lend': ('lent', 'lent'), 'let': ('let', 'let'), 'lie': ('lay', 'lain'),
    'light': ('lit', 'lit'), 'lose': ('lost', 'lost'), 'make': ('made', 'made'),
    'mean': ('meant', 'meant'), 'meet': ('met', 'met'),
    'mistake': ('mistook', 'mistaken'), 'overcome': ('overcame', 'overcome'),
    'pay': ('paid', 'paid'), 'prove': ('proved', 'proven proved'),
    'put': ('put', 'put'), 'quit': ('quit', 'quit'), 'read': ('read', 'read'),
    'ride': ('rode', 'ridden'), 'ring': ('rang', 'rung'), 'rise': ('rose', 'risen'),
    'run': ('ran', 'run'), 'say': ('said', 'said'), 'see': ('saw', 'seen'),
    'seek': ('sought', 'sought'), 'sell': ('sold', 'sold'), 'send': ('sent', 'sent'),
    'set': ('set', 'set'), 'sew': ('sewed', 'sewn'), 'shake': ('shook', 'shaken'),
    'shed': ('shed', 'shed'), 'shine': ('shone', 'shone'), 'shoot': ('shot', 'shot'),
    'show': ('showed', 'shown'), 'shrink': ('shrank', 'shrunk'),
    'shut': ('shut', 'shut'), 'sing': ('sang', 'sung'), 'sink': ('sank', 'sunk'),
    'sit': ('sat', 'sat'), 'sleep': ('slept', 'slept'), 'slide': ('slid', 'slid'),
    'speak': ('spoke', 'spoken'), 'speed': ('sped', 'sped'),
    'spell': ('spelt spelled', 'spelt spelled'), 'spend': ('spent', 'spent'),
    'spill': ('spilt spilled', 'spilt spilled'), 'spin': ('spun', 'spun'),
    'spit': ('spat', 'spat'), 'split': ('split', 'split'),
    'spoil': ('spoilt spoiled', 'spoilt spoiled'), 'spread': ('spread', 'spread'),
    'spring': ('sprang', 'sprung'), 'stand': ('stood', 'stood'),
    'steal': ('stole', 'stolen'), 'stick': ('stuck', 'stuck'),
    'sting': ('stung', 'stung'), 'stink': ('stank', 'stunk'),
    'strike': ('struck', 'struck'), 'string': ('strung', 'strung'),
    'swear': ('swore', 'sworn'), 'sweep': ('swept', 'swept'),
    'swim': ('swam', 'swum'), 'swing': ('swung', 'swung'),
    'take': ('took', 'taken'), 'teach': ('taught', 'taught'),
    'tear': ('tore', 'torn'), 'tell': ('told', 'told'),
    'think': ('thought', 'thought'), 'throw': ('threw', 'thrown'),
    'understand': ('understood', 'understood'), 'undertake': ('undertook', 'undertaken'),
    'upset': ('upset', 'upset'), 'wake': ('woke', 'woken'), 'wear': ('wore', 'worn'),
    'weep': ('wept', 'wept'), 'win': ('won', 'won'), 'wind': ('wound', 'wound'),
    'withdraw': ('withdrew', 'withdrawn'), 'write': ('wrote', 'written'),
}
IRREGULAR_PLURALS = {
    'child': 'children', 'man': 'men', 'woman': 'women', 'person': 'people',
    'foot': 'feet', 'tooth': 'teeth', 'mouse': 'mice', 'life': 'lives',
    'wife': 'wives', 'knife': 'knives', 'leaf': 'leaves', 'half': 'halves',
    'shelf': 'shelves', 'wolf': 'wolves', 'thief': 'thieves', 'self': 'selves',
    'crisis': 'crises', 'analysis': 'analyses', 'phenomenon': 'phenomena',
    'criterion': 'criteria', 'medium': 'media', 'datum': 'data',
}
IRREGULAR_ADJECTIVES = {
    'good': 'better best', 'well': 'better best', 'bad': 'worse worst',
    'far': 'farther further farthest furthest', 'little': 'less least',
    'many': 'more most', 'much': 'more most', 'old': 'older oldest elder eldest',
}
VERB = {'동사', '연결동사', '동사구'}
NOUN = {'명사', '명사구'}
ADJECTIVE = {'형용사', '형용사구'}
VOWELS = set('aeiou')
# Longer verbs stressed on the last syllable also double the final consonant.
DOUBLING = {'admit', 'begin', 'commit', 'control', 'forget', 'occur', 'omit',
            'permit', 'prefer', 'refer', 'regret', 'submit', 'transfer',
            'upset', 'compel', 'expel', 'equip', 'patrol', 'propel', 'rebel'}
S_FORMS = {'be': 'is', 'have': 'has'}


def normalize(value):
    return re.sub(r'\s+', ' ', re.sub(r'[.!?,]+$', '', value.strip().lower()))


def _double(word):
    """Short consonant-vowel-consonant words double the final letter."""
    return word in DOUBLING or (
        sum(c in VOWELS for c in word) == 1 and len(word) >= 3
        and word[-1] not in VOWELS | set('wxy')
        and word[-2] in VOWELS and word[-3] not in VOWELS)


def s_form(word):
    if word.endswith(('s', 'x', 'z', 'ch', 'sh', 'o')):
        return word + 'es'
    if word.endswith('y') and word[-2:-1] not in VOWELS:
        return word[:-1] + 'ies'
    return word + 's'


def verb_forms(word):
    forms = {S_FORMS.get(word) or s_form(word)}
    if word in IRREGULAR_VERBS:
        for group in IRREGULAR_VERBS[word]:
            forms.update(group.split())
    elif word.endswith('e'):
        forms.add(word + 'd')
    elif word.endswith('y') and word[-2:-1] not in VOWELS:
        forms.add(word[:-1] + 'ied')
    else:
        forms.add(word + (word[-1] if _double(word) else '') + 'ed')
    if word.endswith('ie'):
        forms.add(word[:-2] + 'ying')
    elif word.endswith('e') and not word.endswith(('ee', 'ye', 'oe')) and len(word) > 2:
        forms.add(word[:-1] + 'ing')
    else:
        forms.add(word + (word[-1] if _double(word) else '') + 'ing')
    if word == 'be':
        forms.update(['am', 'is', 'are', 'being'])
    return forms


def adjective_forms(word):
    if word in IRREGULAR_ADJECTIVES:
        return set(IRREGULAR_ADJECTIVES[word].split())
    if len(word) > 6 and not word.endswith('y'):
        return set()  # usually "more ...", not a single-word form
    if word.endswith('e'):
        return {word + 'r', word + 'st'}
    if word.endswith('y') and word[-2:-1] not in VOWELS:
        return {word[:-1] + 'ier', word[:-1] + 'iest'}
    tail = word[-1] if _double(word) else ''
    return {word + tail + 'er', word + tail + 'est'}


def wrong_forms(item, same):
    """Other forms of the headword that differ from this blank's answer."""
    headword = normalize(item['headword'])
    pos = set(item.get('partsOfSpeech') or [])
    words = headword.split(' ')
    first, rest = words[0], ' '.join(words[1:])
    forms = {headword}
    if not ALLOWED.match(headword):
        return []
    if pos & VERB or (len(words) > 1 and not pos):
        forms.update(verb_forms(first))
    if len(words) == 1:
        if pos & NOUN:
            forms.add(IRREGULAR_PLURALS.get(first, s_form(first)))
        if pos & ADJECTIVE:
            forms.update(adjective_forms(first))
    if rest:
        forms = {f'{form} {rest}' if form != headword else form for form in forms}
    answer = normalize(item['answer'])
    return sorted(f for f in forms if f != answer and f not in same)[:LIMIT]


def export_items():
    ITEMS.parent.mkdir(exist_ok=True)
    dart = 'dart.bat' if os.name == 'nt' else 'dart'
    subprocess.run([dart, 'run', 'tools/export_cloze_items.dart', str(ITEMS)],
                   cwd=ROOT, check=True)
    return json.loads(ITEMS.read_text(encoding='utf-8'))


def load_same(items):
    authored = {}
    for path in sorted(SAME.glob('*.json')):
        authored.update(json.loads(path.read_text(encoding='utf-8')))
    result = {}
    for item in items:
        answer = normalize(item['answer'])
        values = []
        for value in authored.get(item['id'], []):
            text = normalize(value)
            if ALLOWED.match(text) and text != answer and text not in values:
                values.append(text)
        result[item['id']] = values[:LIMIT]
    return result


def dart_string(value):
    return json.dumps(value, ensure_ascii=False).replace('$', r'\$')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--freeze', action='store_true',
                        help='record current sentences as reviewed')
    args = parser.parse_args()
    items = sorted(export_items(), key=lambda i: i['id'])
    same = load_same(items)
    current = {i['id']: i['sentence'] for i in items}
    if args.freeze or not SENTENCES.exists():
        SENTENCES.write_text(json.dumps(current, ensure_ascii=False, indent=1,
                                        sort_keys=True), encoding='utf-8')
    reviewed = json.loads(SENTENCES.read_text(encoding='utf-8'))
    changed = [i for i in current if reviewed.get(i) != current[i]]
    if changed:
        print(f'{len(changed)} sentences changed since the same-meaning lists '
              f'were written; review them, then run --freeze: {changed[:20]}')
    lines = ['// Generated by tools/build_cloze_cues.py. '
             'See data/cloze_cues/NOTICE.md.',
             "import 'package:edu_voca/domain/models/cloze_cue.dart';", '',
             'const clozeCues = <String, ClozeCue>{']
    counts = [0, 0]
    for item in items:
        words = [] if item['id'] in changed else same[item['id']]
        forms = wrong_forms(item, words)
        if not (words or forms):
            continue
        counts[0] += bool(words)
        counts[1] += bool(forms)
        lines.append(
            f"  {dart_string(item['id'])}: ClozeCue("
            f"sameMeaning: [{', '.join(map(dart_string, words))}], "
            f"wrongForms: [{', '.join(map(dart_string, forms))}]),")
    lines.append('};')
    DART.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'{len(items)} blanks: {counts[0]} with same-meaning words, '
          f'{counts[1]} with wrong forms -> {DART.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
