#!/bin/bash
# Builds SimsCraft from sources: server Lua script, world SQL, addon translation.
# Usage: tools/build.sh <AzerothCore>/data/sql/base/db_world
# Собирает SimsCraft из исходников: Lua-скрипт сервера, SQL мира, перевод аддона.
set -e
cd "$(dirname "$0")/.."
BASE="${1:?path to AzerothCore data/sql/base/db_world}"
OUT=build
mkdir -p "$OUT/sql"
python3 tools/gen_catalog.py "$BASE" tools/godisp.json "$OUT/sql" "$OUT/catalog.lua"
python3 tools/gen_locale.py "$OUT/sql"
python3 - <<'PY'
import re
t = open('tools/SimsCraft.lua.in', encoding='utf-8').read()
c = open('build/catalog.lua', encoding='utf-8').read()
d = open('tools/i18n/server_en.tsv', encoding='utf-8').read()
have = set(l.split('\t')[0] for l in d.splitlines() if '\t' in l)
strip = lambda x: re.sub(r'\|c[0-9a-fA-F]{8}|\|r', '', x).strip()
extra = []
for l in d.splitlines():
    if '\t' not in l: continue
    ru, en = l.split('\t', 1)
    r2, e2 = strip(ru), strip(en)
    if r2 and r2 != ru and r2 not in have and re.search('[А-Яа-яЁё]', r2):
        have.add(r2); extra.append(r2 + '\t' + e2)
d = d + '\n'.join(extra) + '\n'
t = t.replace('--@@I18N@@', 'TX.EN_SRC = [==[\n' + d + ']==]')
open('server/lua_scripts/SimsCraft/SimsCraft.lua', 'w', encoding='utf-8').write(t.replace('--@@CATALOG@@', c.rstrip()))
PY
cat tools/world_keeper.sql "$OUT/sql/world_simscraft_v3.sql" "$OUT/sql/world_simscraft_locale.sql" > server/sql/world/simscraft_world.sql
cp "$OUT/sql/world_restore_v3.sql" server/sql/updates/pre1_world_restore_v3.sql
cp "$OUT/sql/world_migrate_v3.sql" server/sql/updates/pre1_world_migrate_v3.sql
python3 tools/i18n_addon.py client/Interface/AddOns/SimsCraft
echo "built: server/lua_scripts/SimsCraft/SimsCraft.lua, server/sql/world/simscraft_world.sql"
