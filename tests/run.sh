#!/bin/bash
# Runs SimsCraft tests with an Eluna/WoW API mock. Needs Lua 5.2+ (mod-ale uses Lua 5.2).
# Запуск тестов SimsCraft на заглушках Eluna и API клиента WoW. Нужен Lua 5.2+.
set -e
cd "$(dirname "$0")/.."
LUA="${LUA:-$(command -v lua5.2 || command -v lua5.3 || command -v lua5.4 || command -v lua)}"
A=client/Interface/AddOns/SimsCraft
"$LUA" tests/test_server.lua server/lua_scripts/SimsCraft/SimsCraft.lua | grep -E "Все проверки|Translation|ПРОВАЛ"
LOCALE=ruRU "$LUA" tests/test_addon.lua $A/Locale.lua $A/SimsCraft.lua $A/SimsUI.lua | tail -1
LOCALE=enUS "$LUA" tests/test_addon.lua $A/Locale.lua $A/SimsCraft.lua $A/SimsUI.lua | tail -1
