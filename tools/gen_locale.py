#!/usr/bin/env python3
"""1.0: английские имена объектов и NPC SimsCraft в базе мира (основной язык — английский),
русские — в таблицах *_locale для клиентов ruRU."""
import re, sys, os
here = os.path.dirname(os.path.abspath(__file__))
out_dir = sys.argv[1]
D = {}
for f in ("server_en.tsv", "world_extra_en.tsv"):
    for line in open(os.path.join(here, "i18n", f), encoding="utf-8"):
        if "\t" in line:
            ru, en = line.rstrip("\n").split("\t", 1)
            D[ru] = en
esc = lambda s: s.replace("'", "''")
v3 = open(os.path.join(out_dir, "world_simscraft_v3.sql"), encoding="utf-8").read()
gos = re.findall(r"^\((6\d{5}),\d+,\d+,'((?:[^'\\]|\\.|'')*)'", v3, re.M)
sql = ["-- SimsCraft 1.0: названия на английском (основные) и русском (ruRU). Повторный запуск безопасен.",
       "SET NAMES utf8mb4;", "START TRANSACTION;",
       "DELETE FROM `gameobject_template_locale` WHERE `entry` BETWEEN 600000 AND 601099 AND `locale` = 'ruRU';"]
missing = []
loc = []
for entry, ru in gos:
    ru = ru.replace("\\'", "'").replace("''", "'")
    en = D.get(ru)
    if not en:
        missing.append(ru); continue
    sql.append(f"UPDATE `gameobject_template` SET `name` = '{esc(en)}' WHERE `entry` = {entry};")
    loc.append(f"({entry},'ruRU','{esc(ru)}','',0)")
sql.append("INSERT INTO `gameobject_template_locale` (`entry`,`locale`,`name`,`castBarCaption`,`VerifiedBuild`) VALUES\n" + ",\n".join(loc) + ";")
# существа: дети, супруги, Хранитель жизни
cre = [(e, "Сын" if (e - 190110) % 2 == 0 else "Дочь", "Семья") for e in range(190110, 190120)]
cre += [(190120, "Супруг", "Семья"), (190121, "Супруга", "Семья"), (190100, "Хранитель жизни", "SimsCraft")]
sql.append("DELETE FROM `creature_template_locale` WHERE `entry` IN (" + ",".join(str(e) for e, _, _ in cre) + ") AND `locale` = 'ruRU';")
rows = []
for e, ru, sub in cre:
    sql.append(f"UPDATE `creature_template` SET `name` = '{esc(D[ru])}', `subname` = '{esc(D.get(sub, sub))}' WHERE `entry` = {e};")
    rows.append(f"({e},'ruRU','{esc(ru)}','{esc(sub)}',0)")
sql.append("INSERT INTO `creature_template_locale` (`entry`,`locale`,`Name`,`Title`,`VerifiedBuild`) VALUES " + ",".join(rows) + ";")
ru_t = "Каждая жизнь — история, $N. Голод, сон, друзья, работа, уютный дом... Чем займёмся?"
en_t = "Every life is a story, $N. Hunger, sleep, friends, work, a cozy home... What shall we do?"
sql += [f"UPDATE `npc_text` SET `text0_0` = '{esc(en_t)}', `text0_1` = '{esc(en_t)}' WHERE `ID` = 190100;",
        "DELETE FROM `npc_text_locale` WHERE `ID` = 190100 AND `Locale` = 'ruRU';",
        f"INSERT INTO `npc_text_locale` (`ID`,`Locale`,`Text0_0`,`Text0_1`) VALUES (190100,'ruRU','{esc(ru_t)}','{esc(ru_t)}');",
        "COMMIT;"]
open(os.path.join(out_dir, "world_simscraft_locale.sql"), "w", encoding="utf-8").write("\n".join(sql) + "\n")
print("локализация мира: объектов", len(loc), "существ", len(cre), "без перевода", len(missing), missing[:10])
