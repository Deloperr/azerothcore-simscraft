#!/usr/bin/env python3
"""Локализация аддона: оборачивает русские строки в LS"..." и собирает Locale.lua из tools/i18n/client_en.tsv.
Запуск: python3 tools/i18n_addon.py client/Interface/AddOns/SimsCraft   (повторный запуск безопасен)"""
import os, re, sys
here = os.path.dirname(os.path.abspath(__file__))
CYR = re.compile('[А-Яа-яЁё]')
HEADER = 'local LS = SimsCraftLS or function(s) return s end   -- перевод (Locale.lua)\n'

def literals(src):
    i, n = 0, len(src)
    while i < n:
        if src.startswith('--', i):
            m = re.match(r'--\[(=*)\[', src[i:])
            if m:
                e = src.find(']' + m.group(1) + ']', i); i = e + 2 + len(m.group(1)); continue
            j = src.find('\n', i); i = n if j < 0 else j; continue
        c = src[i]
        if c in '"\'':
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == '\\': j += 1
                j += 1
            yield i, j + 1, src[i + 1:j]; i = j + 1; continue
        i += 1

def wrap(path):
    s = open(path, encoding='utf-8').read()
    out, pos, found = [], 0, []
    for a, b, v in literals(s):
        if not CYR.search(v): continue
        found.append(v)
        if s[max(0, a - 2):a] == 'LS': continue
        out.append(s[pos:a]); out.append('LS' + s[a:b]); pos = b
    out.append(s[pos:])
    s = ''.join(out)
    if HEADER not in s:
        # после первой строки-комментария шапки (или в начало)
        s = HEADER + s
    open(path, 'w', encoding='utf-8').write(s)
    return found

def main(addon):
    tsv = os.path.join(here, 'i18n', 'client_en.tsv')
    D = {}
    for line in open(tsv, encoding='utf-8'):
        if '\t' in line:
            ru, en = line.rstrip('\n').split('\t', 1); D[ru] = en
    used = []
    for f in ('SimsCraft.lua', 'SimsUI.lua'):
        used += wrap(os.path.join(addon, f))
    missing = sorted(set(v for v in used if v not in D))
    q = lambda x: '"' + x.replace('"', '\\"') + '"' if '\\"' not in x else '"' + x + '"'
    lines = ['-- SimsCraft: перевод интерфейса. Русский клиент (ruRU) — по-русски, остальные — по-английски.',
             '-- Сгенерировано tools/i18n_addon.py из tools/i18n/client_en.tsv', 'local EN = {']
    for ru in sorted(set(used)):
        if ru in D: lines.append('    [%s] = %s,' % (q(ru), q(D[ru])))
    lines += ['}', 'local RU = GetLocale and GetLocale() == "ruRU"',
              'SimsCraftIsRu = RU',
              'function SimsCraftLS(s) if RU then return s end return EN[s] or s end', '']
    open(os.path.join(addon, 'Locale.lua'), 'w', encoding='utf-8').write('\n'.join(lines))
    toc = os.path.join(addon, 'SimsCraft.toc')
    t = open(toc, encoding='utf-8').read()
    if 'Locale.lua' not in t:
        t = t.replace('SimsCraft.lua', 'Locale.lua\nSimsCraft.lua', 1)
        open(toc, 'w', encoding='utf-8').write(t)
    print('аддон: строк', len(set(used)), 'без перевода', len(missing))
    for m in missing: print('  нет перевода:', m)
    return 1 if missing else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
