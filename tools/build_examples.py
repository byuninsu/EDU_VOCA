"""Build offline cloze sentences with full Korean translations and provenance.

Inputs: pinned Tatoeba pairs in data/examples/tatoeba.json, and app-authored
sentences in data/examples/authored.txt (English|Korean). Raw download/import is
an explicit one-time --import operation; normal builds are offline.
"""
import bz2
from functools import lru_cache
import json
from pathlib import Path
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data/examples'
TOKEN = re.compile(r"[A-Za-z]+(?:['’][A-Za-z]+)?")

@lru_cache(maxsize=None)
def forms(word):
    # Only conservative inflections. Competing lemmas are resolved below.
    result = {word}
    pos = {p for p, _ in OXFORD.get(word, [])}
    if 'noun' in pos or 'verb' in pos:
        result.add(word + 's')
        if word.endswith(('s', 'x', 'z', 'ch', 'sh', 'o')): result.add(word + 'es')
        if word.endswith('y') and word[-2:] not in ['ay','ey','iy','oy','uy']:
            result.add(word[:-1] + 'ies')
    if 'verb' in pos:
        result.add(word + 'd' if word.endswith('e') else word + 'ed')
        if word.endswith('y') and word[-2:] not in ['ay','ey','iy','oy','uy']:
            result.add(word[:-1] + 'ied')
        result.add(word[:-1] + 'ing' if word.endswith('e') and not word.endswith('ee') else word + 'ing')
        if re.search(r'[^aeiou][aeiou][^aeiouwxy]$', word):
            result.update([word+word[-1]+'ed', word+word[-1]+'ing'])
    irregular = {'be':'am is are was were been being', 'have':'has had', 'do':'does did done',
      'go':'went gone', 'get':'got gotten', 'make':'made', 'take':'took taken', 'come':'came',
      'see':'saw seen', 'know':'knew known', 'think':'thought', 'say':'said', 'tell':'told',
      'give':'gave given', 'find':'found', 'leave':'left', 'feel':'felt', 'keep':'kept',
      'begin':'began begun', 'write':'wrote written', 'speak':'spoke spoken', 'hear':'heard',
      'run':'ran', 'eat':'ate eaten', 'drink':'drank drunk', 'buy':'bought', 'bring':'brought',
      'meet':'met', 'pay':'paid', 'send':'sent', 'build':'built', 'understand':'understood',
      'win':'won', 'lose':'lost', 'sit':'sat', 'stand':'stood', 'hold':'held', 'read':'read',
      'grow':'grew grown', 'draw':'drew drawn', 'choose':'chose chosen', 'fall':'fell fallen',
      'break':'broke broken', 'drive':'drove driven', 'ride':'rode ridden', 'rise':'rose risen',
      'wear':'wore worn', 'fly':'flew flown', 'forget':'forgot forgotten', 'throw':'threw thrown',
      'teach':'taught', 'catch':'caught', 'sell':'sold', 'sleep':'slept', 'spend':'spent',
      'lead':'led', 'fight':'fought', 'seek':'sought', 'shake':'shook shaken', 'hide':'hid hidden',
      'feed':'fed', 'lay':'laid', 'lie':'lay lain', 'tear':'tore torn', 'bite':'bit bitten',
      'sweep':'swept', 'steal':'stole stolen', 'swear':'swore sworn', 'bear':'bore borne',
      'bind':'bound', 'swim':'swam swum', 'hang':'hung', 'stick':'stuck', 'strike':'struck',
      'child':'children', 'man':'men', 'woman':'women', 'foot':'feet', 'tooth':'teeth',
      'mouse':'mice', 'person':'people'}
    result.update(irregular.get(word,'').split())
    return result

WORDS = json.loads((ROOT/'assets/data/ngsl.json').read_text(encoding='utf-8'))['words']
OXFORD = json.loads((ROOT/'data/oxford/mapping.json').read_text(encoding='utf-8'))['entries']

def import_sources():
    DATA.mkdir(parents=True, exist_ok=True)
    pairs = []
    with zipfile.ZipFile(ROOT/'build/kor-eng.zip') as z:
        for line in z.read('kor.txt').decode('utf-8-sig').splitlines():
            en, ko, credit = line.split('\t')
            pairs.append(dict(en=en, ko=ko, credit=credit, curated=True))
    links = [line.split('\t') for line in bz2.open(ROOT/'build/kor-eng_links.tsv.bz2','rt',encoding='utf-8')]
    ids = {v.strip() for row in links for v in row}
    sentences = {}
    for lang in ['eng','kor']:
        for line in bz2.open(ROOT/f'build/{lang}_sentences_detailed.tsv.bz2','rt',encoding='utf-8'):
            row=line.rstrip('\n').split('\t')
            if row[0] in ids: sentences[row[0]] = row
    for kid,eid in links:
        en,ko = sentences.get(eid.strip()), sentences.get(kid.strip())
        if not en or not ko: continue
        pairs.append(dict(en=en[2], ko=ko[2], credit=f'CC-BY 2.0 FR · Tatoeba #{en[0]} ({en[3]}) & #{ko[0]} ({ko[3]})', curated=False))
    (DATA/'tatoeba.json').write_text(json.dumps(pairs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def build():
    pairs=json.loads((DATA/'tatoeba.json').read_text(encoding='utf-8'))
    authored = DATA/'authored.txt'
    if authored.exists():
        for line in authored.read_text(encoding='utf-8').splitlines():
            if not line or line.startswith('#'): continue
            en,ko = line.split('|')
            pairs.append(dict(en=en,ko=ko,credit='앱 작성 예문·해석 (AI 작성)',curated=True,authored=True))
    keys={w['id'] for w in WORDS}
    index={}
    for word in keys:
        for form in forms(word):
            # An exact headword wins over ambiguous inflected homographs.
            if form in keys and form != word: continue
            index.setdefault(form,set()).add(word)
    candidates={}
    for p in pairs:
        tokens=list(TOKEN.finditer(p['en']))
        if not 4 <= len(tokens) <= 20 or len(p['en']) > 150: continue
        if not re.search('[가-힣]',p['ko']) or re.search('[A-Za-z]',p['ko']): continue
        if p['en'][-1:] not in '.?!' or '\n' in p['en'] or '_' in p['en']: continue
        # Keep short everyday examples and avoid quote fragments or proper-name blanks.
        if any(x in p['en'] for x in ['"',';',':']): continue
        for token in tokens:
            form=token[0].lower()
            for word in index.get(form,[]):
                if sum(t[0].lower() in forms(word) for t in tokens) != 1: continue
                if token.start()>0 and token[0][0].isupper() and word!='i': continue
                target_level = min((['A1','A2','B1','B2','C1'].index(c)+1 for _,c in OXFORD.get(word,[])),default=3)
                def token_level(t):
                    levels=[['A1','A2','B1','B2','C1'].index(c)+1 for _,c in OXFORD.get(t[0].lower(),[])]
                    return min(levels,default=1 if t[0][0].isupper() else 3)
                complexity=sum(max(0,token_level(t)-target_level) for t in tokens if t!=token)
                score=(complexity, 0 if p.get('authored') else 1 if p['curated'] else 2,
                       0 if form==word else 1,abs(len(tokens)-8),len(p['en']))
                entry=dict(word=word, sentence=p['en'][:token.start()]+'____'+p['en'][token.end():],
                           answer=token[0],translation=p['ko'],credit=p['credit'],complete=p['en'])
                if word not in candidates or score<candidates[word][0]: candidates[word]=(score,entry)
    records={w:v[1] for w,v in sorted(candidates.items())}
    # Explicitly selected examples take precedence over automatic homograph matching.
    for word, (sentence, answer, translation, focus) in json.loads(
            (DATA/'reviewed.json').read_text(encoding='utf-8')).items():
        assert word in keys and sentence.count('____') == 1 and focus in translation
        records[word] = dict(word=word, sentence=sentence, answer=answer,
                            translation=translation, translationFocus=focus,
                            complete=sentence.replace('____', answer),
                            credit='앱 작성 예문·해석 (AI 작성)')
    missing=sorted(keys-records.keys())
    (DATA/'missing.txt').write_text('\n'.join(missing)+'\n',encoding='utf-8')
    (DATA/'selected.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Examples: {len(records)}/{len(keys)}. Missing: {len(missing)}')
    if '--inspect' in sys.argv: return
    assert not missing, f'Examples missing: {missing}'
    def dart(v):return json.dumps(v,ensure_ascii=False).replace('$',r'\$')
    lines=['// Generated by tools/build_examples.py. See data/examples/NOTICE.md.',
      "import 'package:edu_voca/domain/models/cloze_example.dart';",'const clozeExamples = <String, ClozeExample>{']
    for w,r in records.items():
        focus = f', translationFocus: {dart(r["translationFocus"])}' if r.get('translationFocus') else ''
        lines.append(f'  {dart(w)}: ClozeExample(sentence: {dart(r["sentence"])}, answer: {dart(r["answer"])}, translation: {dart(r["translation"])}, credit: {dart(r["credit"])}{focus}),')
    lines.append('};\n')
    (ROOT/'lib/data/local/cloze_examples.dart').write_text('\n'.join(lines),encoding='utf-8')

if __name__=='__main__':
    if '--import' in sys.argv: import_sources()
    build()
