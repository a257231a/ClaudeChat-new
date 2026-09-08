# -*- coding: utf-8 -*-
"""Regenerates assets/our_home/economy.json from docs/OUR_HOME_ECONOMY.md.

Run this after editing the markdown doc, then check in the regenerated
JSON — Dart loads it as a plain asset at runtime, it never parses the doc
itself. Mirrors the same parsing logic used for the standalone HTML demo's
scratchpad/gen_economy_js.py, just emitting JSON instead of a JS literal.
"""
import re, json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC_PATH = os.path.join(ROOT, 'docs', 'OUR_HOME_ECONOMY.md')
OUT_PATH = os.path.join(ROOT, 'assets', 'our_home', 'economy.json')

with open(DOC_PATH, encoding='utf-8') as f:
    content = f.read()


def get_section(title_substr):
    # split only on "## " headers (not "### " subsection headers) so a
    # section's own subsections stay embedded in its text
    parts = re.split(r'(?m)^## (?!#)', content)
    for p in parts:
        if p.split('\n')[0].strip().startswith(title_substr):
            return p
    raise Exception('not found: ' + title_substr)


def table_rows(section):
    lines = [l for l in section.split('\n') if l.startswith('|')]
    rows = []
    for l in lines[2:]:
        cols = [c.strip() for c in l.strip('|').split('|')]
        rows.append(cols)
    return rows


def parse_money(s):
    s = s.replace('，', ',').strip()
    m = re.match(r'^([+-]?\d+)~([+-]?\d+)', s)
    if m:
        a, b = int(m.group(1)), int(m.group(2))
        return {'min': min(a, b), 'max': max(a, b)}
    m2 = re.match(r'^([+-]?\d+)$', s)
    if m2:
        return int(m2.group(1))
    raise Exception('cant parse money: ' + repr(s))


# ---- Need-category mapping ("消耗品分类对照" bullet list) ----
NEED_LABELS = {
    '洗澡类': 'bath',
    '正餐类': 'meal',
    '饮品类': 'drink',
    '零食/甜点类': 'snack',
    '食材类': 'ingredient',
}
need_of_item = {}
sec_needs = get_section('一、采购清单').split('### 消耗品分类对照')[1].split('### 做饭食谱')[0]
for line in sec_needs.split('\n'):
    line = line.strip()
    if not line.startswith('- **'):
        continue
    m = re.match(r'^- \*\*([^*]+?)(?:（[^）]*）)?\*\*[：:](.+)$', line)
    if not m:
        continue
    label, itemlist = m.group(1), m.group(2)
    need_key = NEED_LABELS.get(label)
    if not need_key:
        continue
    for name in itemlist.split('、'):
        need_of_item[name.strip()] = need_key

# ---- Section 1: shop items ----
sec1 = get_section('一、采购清单')
sec1_shop_only = sec1.split('### 消耗品分类对照')[0]
rows1 = table_rows(sec1_shop_only)
shop_items = []
for cat, name, price, mood, note in rows1:
    entry = {
        'cat': cat,
        'name': name,
        'price': int(price),
        'mood': int(mood.replace('+', '')),
    }
    need = need_of_item.get(name)
    if need:
        entry['need'] = need
    shop_items.append(entry)

# ---- Recipes ("做饭食谱" table) ----
sec_recipes_full = get_section('一、采购清单').split('### 做饭食谱')[1]
recipe_rows = table_rows(sec_recipes_full[:sec_recipes_full.find('\n\n如果')])
recipes = []
for name, ingredients, mood, note in recipe_rows:
    recipes.append({
        'name': name,
        'ingredients': [x.strip() for x in ingredients.split('+')],
        'mood': int(mood.replace('+', '')),
    })

# ---- Section 2: work jobs ----
sec2 = get_section('二、工作清单')
rows2 = table_rows(sec2)
work_jobs = []
for jobtype, income, moodstr, note in rows2:
    inc = parse_money(income.replace('（随机）', ''))
    mm = re.match(r'^([+-]?\d+)', moodstr)
    work_jobs.append({
        'name': jobtype,
        'inc': inc,
        'mood': int(mm.group(1)),
    })


def gen_outcome_table(section_title, has_type_col):
    sec = get_section(section_title)
    rows = table_rows(sec)
    out = []
    for r in rows:
        if has_type_col:
            typ, result, prob, coin, moodv, note = r
        else:
            result, prob, coin, moodv = r[0], r[1], r[2], r[3]
        out.append({
            'w': float(prob.replace('%', '')),
            'result': result,
            'coin': parse_money(coin),
            'mood': int(moodv.replace('+', '')),
        })
    return out


data = {
    'shopItems': shop_items,
    'recipes': recipes,
    'workJobs': work_jobs,
    'adventureOutcomes': gen_outcome_table('三、冒险结果清单', has_type_col=False),
    'outingOutcomes': gen_outcome_table('四、外出娱乐结果清单', has_type_col=False),
    'mysteryOutcomes': gen_outcome_table('五、剧本杀结果清单', has_type_col=True),
    'escapeOutcomes': gen_outcome_table('六、密室逃脱结果清单', has_type_col=True),
}

os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
with open(OUT_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('shopItems:', len(shop_items))
print('recipes:', len(recipes))
print('workJobs:', len(work_jobs))
print('adventureOutcomes:', len(data['adventureOutcomes']))
print('outingOutcomes:', len(data['outingOutcomes']))
print('mysteryOutcomes:', len(data['mysteryOutcomes']))
print('escapeOutcomes:', len(data['escapeOutcomes']))
print('wrote', OUT_PATH)
