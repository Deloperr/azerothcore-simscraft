# Contributing to SimsCraft

[Русский — ниже](#как-помочь-проекту)

Thanks for helping! The easiest ways to contribute:

- **Report bugs** — [open a bug report](https://github.com/Deloperr/azerothcore-simscraft/issues/new?template=bug_report.yml). Attach `server-logs.txt` from the collect-logs script if the server crashes or disconnects.
- **Suggest ideas** — [open an idea](https://github.com/Deloperr/azerothcore-simscraft/issues/new?template=feature_request.yml). Features from The Sims that would fit WoW are very welcome.
- **Translate** — texts live in `tools/i18n/` (`server_en.tsv`, `client_en.tsv`, `world_extra_en.tsv`): one line per phrase, `Russian<TAB>English`.
- **Send pull requests** — see below.

## Project layout

| Path | What it is |
|---|---|
| `tools/SimsCraft.lua.in` | server script source (Lua 5.2, mod-ale/Eluna API) |
| `tools/gen_catalog.py` | furniture catalog: generates the world SQL and the Lua catalog |
| `tools/gen_locale.py`, `tools/i18n/` | English/Russian names and texts |
| `tools/i18n_addon.py` | wraps addon strings with `LS"..."` and builds `Locale.lua` |
| `tools/build.sh` | builds `server/lua_scripts/SimsCraft/SimsCraft.lua` and `server/sql/world/simscraft_world.sql` |
| `client/Interface/AddOns/SimsCraft/` | the WoW 3.3.5a addon |
| `installer/` | Docker installers (bash for macOS/Linux, PowerShell for Windows) |
| `tests/` | tests with an Eluna / WoW API mock |

## Building and testing

```bash
# needs the AzerothCore base world SQL (data/sql/base/db_world from azerothcore-wotlk)
tools/build.sh /path/to/azerothcore-wotlk/data/sql/base/db_world
# needs Lua 5.2+
tests/run.sh
```

Please run the tests before a pull request, and test in game when you can. Notes:

- Texts in the code are Russian; English comes from `tools/i18n/*.tsv`. When you add a phrase, add its translation (the build prints untranslated addon strings; `VERBOSE=1 tests/run.sh` lists server leftovers).
- AzerothCore **stops the whole server** on an SQL error against a missing table or column. Check `information_schema` before using new columns, and add new columns to the startup schema check.
- Lua allows at most 200 local variables per function — new helpers go into the `F` table and constants into `TX`.
- Keep the addon compatible with the 3.3.5a API (no newer functions).

---

# Как помочь проекту

Спасибо! Проще всего помочь так:

- **Сообщить об ошибке** — [создайте issue](https://github.com/Deloperr/azerothcore-simscraft/issues/new?template=bug_report.yml). Если сервер падает или выкидывает, приложите `server-logs.txt` из сбора логов.
- **Предложить идею** — [создайте issue с идеей](https://github.com/Deloperr/azerothcore-simscraft/issues/new?template=feature_request.yml). Особенно ждём возможности из «Симс», которые подойдут для WoW.
- **Улучшить перевод** — тексты лежат в `tools/i18n/` (`server_en.tsv`, `client_en.tsv`, `world_extra_en.tsv`): одна строка — одна фраза, `русский<TAB>английский`.
- **Прислать pull request** — устройство проекта, сборка и тесты описаны выше. Тексты в коде пишутся по-русски, перевод — в `tools/i18n/`. Перед pull request'ом запустите `tests/run.sh` и, если можете, проверьте в игре.
