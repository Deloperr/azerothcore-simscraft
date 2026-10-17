#!/bin/bash
# SimsCraft installer for macOS and Linux (Docker).
# Usage: simscraft.sh install | update | logs
# Установщик SimsCraft для macOS и Linux (Docker). Команды: install | update | logs
#
#   SIMSCRAFT_DIR   where the AzerothCore server lives (default: ~/AzerothCore-SimsCraft)
#   SIMSCRAFT_LANG  en | ru (default: from the system language)

VERSION="1.0.0"
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${SIMSCRAFT_DIR:-$HOME/AzerothCore-SimsCraft}"
SQL="$PKG/server/sql"
CMD="${1:-install}"
OS="$(uname -s)"

# ---------- language / язык ----------
LANGX="${SIMSCRAFT_LANG:-}"
if [ -z "$LANGX" ]; then
    LANGX=en
    case "${LC_ALL:-}${LC_MESSAGES:-}${LANG:-}" in *ru*|*RU*) LANGX=ru ;; esac
    if [ "$OS" = "Darwin" ] && defaults read -g AppleLanguages 2>/dev/null | head -3 | grep -qi '"ru'; then LANGX=ru; fi
fi
t() { if [ "$LANGX" = "ru" ]; then echo "$2"; else echo "$1"; fi; }

LOG="$PKG/simscraft-$CMD.log"
exec > >(tee -a "$LOG") 2>&1

step() { echo; echo "=== [$(date '+%H:%M:%S')] $*"; }
pause() { if [ -t 0 ]; then echo; t "Press Enter to close this window." "Нажмите Enter, чтобы закрыть окно."; read -r; fi; }
fail() { echo; echo "!!! $(t ERROR ОШИБКА): $*"; t "Log: $LOG" "Лог: $LOG"; pause; exit 1; }

DC() { (cd "$DEST" && docker compose "$@"); }
# strict: any SQL error stops (files use transactions) / строгий режим
MYSQL()  { DC exec -T ac-database mysql --default-character-set=utf8mb4 -uroot -ppassword "$@" 2>&1 | grep -v "Using a password"; return "${PIPESTATUS[0]}"; }
# soft: repeated ALTERs ("column already exists") are skipped / мягкий режим
MYSQLF() { DC exec -T ac-database mysql --default-character-set=utf8mb4 --force -uroot -ppassword "$@" 2>&1 | grep -vE "Using a password|Duplicate column|already exists"; return 0; }

need_docker() {
    if ! docker info >/dev/null 2>&1; then
        if [ "$OS" = "Darwin" ]; then
            open -a Docker 2>/dev/null
            t "Waiting for Docker Desktop to start (up to 2 minutes)..." "Жду запуска Docker Desktop (до 2 минут)..."
            for i in $(seq 1 60); do docker info >/dev/null 2>&1 && break; sleep 2; done
        fi
    fi
    docker info >/dev/null 2>&1 || fail "$(t "Docker is not running. Start Docker (Desktop) and run this again. On Linux your user must be in the 'docker' group (or run with sudo)." "Docker не запущен. Запустите Docker (Desktop) и откройте установщик снова. В Linux пользователь должен быть в группе docker (или запустите через sudo).")"
    docker compose version >/dev/null 2>&1 || fail "$(t "'docker compose' (v2) not found. Update Docker." "Не найден 'docker compose' (v2). Обновите Docker.")"
}

wait_db() {
    step "$(t "Waiting for the database" "Жду базу данных")"
    for i in $(seq 1 120); do
        DC exec -T ac-database mysql -uroot -ppassword -e "SELECT 1 FROM acore_auth.realmlist LIMIT 1" >/dev/null 2>&1 && return 0
        sleep 5
    done
    fail "$(t "the database did not start" "база данных не запустилась")"
}

copy_script() {
    step "$(t "SimsCraft server script" "Скрипт SimsCraft на сервер")"
    mkdir -p "$DEST/env/dist/etc/lua_scripts/SimsCraft"
    cp "$PKG/server/lua_scripts/SimsCraft/SimsCraft.lua" "$DEST/env/dist/etc/lua_scripts/SimsCraft/SimsCraft.lua" || fail "$(t "cannot copy the script" "не удалось скопировать скрипт")"
    ls -la "$DEST/env/dist/etc/lua_scripts/SimsCraft"
}

apply_sql() {
    local old_world="$1"
    step "$(t "Characters database" "База персонажей")"
    MYSQL acore_characters < "$SQL/characters/simscraft_characters.sql" || fail "$(t "characters SQL failed" "ошибка SQL базы персонажей")"
    for f in "$SQL"/updates/pre1_characters_*.sql; do MYSQLF acore_characters < "$f"; done
    if [ "$old_world" = "1" ]; then
        step "$(t "Upgrading a pre-1.0 SimsCraft world" "Обновление мира со старых версий SimsCraft")"
        MYSQL acore_world < "$SQL/updates/pre1_world_restore_v3.sql" || fail "restore"
        MYSQLF acore_world < "$SQL/updates/pre1_world_migrate_v3.sql"
    fi
    step "$(t "World database: SimsCraft catalog, NPCs, translations" "База мира: каталог SimsCraft, NPC, переводы")"
    MYSQL acore_world < "$SQL/world/simscraft_world.sql" || fail "$(t "world SQL failed (nothing was changed)" "ошибка SQL базы мира (ничего не изменено)")"
    MYSQL acore_world -e "SELECT COUNT(*) AS 'SimsCraft objects (313)' FROM gameobject_template WHERE entry BETWEEN 600000 AND 601099;
SELECT COUNT(*) AS 'SimsCraft NPCs (13)' FROM creature_template WHERE entry = 190100 OR entry BETWEEN 190110 AND 190121;"
}

restart_world() {
    step "$(t "Restarting the world server (1-2 minutes)" "Перезапуск мира (1–2 минуты)")"
    DC up -d >/dev/null 2>&1
    DC restart ac-worldserver || fail "$(t "cannot restart the world server" "не удалось перезапустить мир")"
    local ok=0
    for i in $(seq 1 100); do
        if DC logs --tail 600 ac-worldserver 2>/dev/null | grep -q "SimsCraft\] $VERSION"; then ok=1; break; fi
        sleep 3
    done
    DC logs --tail 800 ac-worldserver 2>/dev/null | grep -iE "SimsCraft|\[ALE\]|\.lua" | tail -15
    [ "$ok" = "1" ] && t "SimsCraft $VERSION is running." "SimsCraft $VERSION запущен." \
        || t "Did not see the SimsCraft start line yet — check the log above (or run 'logs')." "Строка запуска SimsCraft пока не появилась — посмотрите лог выше (или запустите сбор логов)."
}

detect_ip() {
    local ip=""
    if [ "$OS" = "Darwin" ]; then
        ip=$(ifconfig bridge100 2>/dev/null | awk '/inet /{print $2; exit}')   # Parallels / VMware shared network
        [ -z "$ip" ] && ip=$(ifconfig 2>/dev/null | awk '/inet 10\.211\.55\./{print $2; exit}')
    fi
    [ -z "$ip" ] && ip="127.0.0.1"
    echo "$ip"
}

addon_hint() {
    echo
    t "=== Client (WoW 3.3.5a) ===" "=== Клиент (WoW 3.3.5a) ==="
    t "1. Copy the folder  $PKG/client/Interface/AddOns/SimsCraft" "1. Скопируйте папку  $PKG/client/Interface/AddOns/SimsCraft"
    t "   into  World of Warcraft/Interface/AddOns/  (replace the old one)." "   в  World of Warcraft/Interface/AddOns/  (с заменой старой)."
    t "2. In  World of Warcraft/Data/<locale>/realmlist.wtf  write:  set realmlist $1" "2. В файле  World of Warcraft/Data/ruRU/realmlist.wtf  укажите:  set realmlist $1"
}

do_install() {
    step "$(t "SimsCraft $VERSION — server installation" "SimsCraft $VERSION — установка сервера")"
    t "Server folder: $DEST" "Папка сервера: $DEST"
    need_docker
    git --version >/dev/null 2>&1 || { [ "$OS" = "Darwin" ] && xcode-select --install 2>/dev/null; fail "$(t "git is required. Install git and run again." "Нужен git. Установите его и запустите установщик снова.")"; }
    df -h "$HOME" | tail -1

    step "$(t "Downloading AzerothCore (Playerbot branch)" "Загрузка AzerothCore (ветка Playerbot)")"
    if [ ! -d "$DEST/.git" ]; then
        git clone --depth 1 --branch Playerbot https://github.com/mod-playerbots/azerothcore-wotlk.git "$DEST" || fail "git clone azerothcore"
    else
        t "Already downloaded — skipping." "Уже скачано — пропускаю."
    fi
    step "$(t "Modules: mod-playerbots and mod-ale (Lua engine)" "Модули: mod-playerbots и mod-ale (Lua)")"
    [ -d "$DEST/modules/mod-playerbots" ] || git clone --depth 1 --branch master https://github.com/mod-playerbots/mod-playerbots.git "$DEST/modules/mod-playerbots" || fail "git clone mod-playerbots"
    [ -d "$DEST/modules/mod-ale" ] || git clone --depth 1 https://github.com/azerothcore/mod-ale.git "$DEST/modules/mod-ale" || fail "git clone mod-ale"

    copy_script
    step "$(t "Docker settings" "Настройки Docker")"
    if [ ! -f "$DEST/docker-compose.override.yml" ]; then
        cat > "$DEST/docker-compose.override.yml" <<'YML'
services:
  ac-worldserver:
    volumes:
      - ./modules:/azerothcore/modules:ro
    environment:
      AC_ALE_ENABLED: "1"
      AC_ALE_SCRIPT_PATH: "/azerothcore/env/dist/etc/lua_scripts"
      AC_PLAYERBOTS_DATABASE_INFO: "ac-database;3306;root;password;acore_playerbots"
      AC_AI_PLAYERBOT_RANDOM_BOT_AUTOLOGIN: "1"
      AC_AI_PLAYERBOT_MIN_RANDOM_BOTS: "50"
      AC_AI_PLAYERBOT_MAX_RANDOM_BOTS: "150"
YML
    fi
    cat "$DEST/docker-compose.override.yml"

    step "$(t "Building and starting the server (the longest step: 20-60 minutes)" "Сборка и запуск сервера (самый долгий шаг: 20–60 минут)")"
    DC up -d --build || fail "$(t "build or start failed — see the messages above" "сборка или запуск не удались — смотрите сообщения выше")"
    wait_db
    apply_sql 0

    step "$(t "Server address for the WoW client" "Адрес сервера для клиента WoW")"
    local ip; ip=$(detect_ip)
    t "The WoW client will connect to: $ip  (127.0.0.1 = the game runs on this computer)" "Клиент WoW будет подключаться к: $ip  (127.0.0.1 — игра на этом же компьютере)"
    if [ -t 0 ]; then
        t "Press Enter to keep it, or type another IP (for example your LAN IP):" "Нажмите Enter, чтобы оставить, или введите другой IP (например, адрес в локальной сети):"
        read -r answer; [ -n "$answer" ] && ip="$answer"
    fi
    MYSQL -e "UPDATE acore_auth.realmlist SET address='$ip', name='SimsCraft' WHERE id=1" && t "realmlist: $ip" "realmlist: $ip"
    echo "$ip" > "$PKG/server_ip.txt"
    restart_world
    DC ps

    echo
    t "=== DONE ===" "=== ГОТОВО ==="
    addon_hint "$ip"
    t "3. Create an account in the server console:  docker attach ac-worldserver" "3. Создайте аккаунт в консоли сервера:  docker attach ac-worldserver"
    t "   account create NAME PASSWORD      (GM rights: account set gmlevel NAME 3 -1)" "   account create ИМЯ ПАРОЛЬ      (права ГМ: account set gmlevel ИМЯ 3 -1)"
    t "   Leave the console with Ctrl+P, then Ctrl+Q." "   Выход из консоли: Ctrl+P, затем Ctrl+Q."
    t "4. In game, as GM, place the Keeper of Life NPC:  .sims npc   — help:  .sims help" "4. В игре (ГМ) поставьте NPC «Хранитель жизни»:  .sims npc   — справка:  .sims help"
    pause
}

do_update() {
    step "$(t "SimsCraft $VERSION — update" "SimsCraft $VERSION — обновление")"
    [ -d "$DEST" ] || fail "$(t "server not found in $DEST (run the installer first, or set SIMSCRAFT_DIR)" "сервер не найден в $DEST (сначала запустите установку или укажите SIMSCRAFT_DIR)")"
    need_docker
    DC up -d ac-database >/dev/null 2>&1
    wait_db
    local old=0
    # a pre-1.0 world has the catalog but no English base names yet
    if [ -n "$(DC exec -T ac-database mysql -uroot -ppassword -N -e "SELECT 1 FROM acore_world.gameobject_template WHERE entry=600000 AND name NOT REGEXP '^[ -~]+$' LIMIT 1" 2>/dev/null | tr -d '[:space:]')" ]; then old=1; fi

    step "$(t "Backup" "Резервная копия")"
    mkdir -p "$PKG/backup"
    local stamp; stamp=$(date +%Y%m%d-%H%M%S)
    DC exec -T ac-database mysqldump -uroot -ppassword acore_characters --tables character_sims character_sims_relations character_sims_furniture character_sims_children character_sims_world character_sims_spots character_sims_skills 2>/dev/null | gzip > "$PKG/backup/characters-$stamp.sql.gz"
    ls -la "$PKG/backup" | tail -3

    apply_sql "$old"
    copy_script
    restart_world
    echo
    t "=== DONE ===" "=== ГОТОВО ==="
    local ip; ip=$(DC exec -T ac-database mysql -uroot -ppassword -N -e "SELECT address FROM acore_auth.realmlist WHERE id=1" 2>/dev/null | grep -v "Using a password" | tr -d '[:space:]')
    addon_hint "${ip:-127.0.0.1}"
    t "Restart the game after replacing the addon." "После замены аддона перезапустите игру."
    pause
}

do_logs() {
    local out="$PKG/server-logs.txt"
    {
        echo "=== $(date)  SimsCraft $VERSION  $OS"
        docker inspect -f 'RestartCount={{.RestartCount}} StartedAt={{.State.StartedAt}} ExitCode={{.State.ExitCode}}' ac-worldserver
        echo "=== worldserver, last 2 hours (bot logins filtered)"
        docker logs -t --since 2h ac-worldserver 2>&1 | grep -v "Bot .* logged in\|Missing property\|Found config value\|Random teleporting\|Playerbots" | tail -4000
    } > "$out" 2>&1
    t "Saved: $out — attach it to your GitHub issue." "Сохранено: $out — приложите файл к issue на GitHub."
    pause
}

case "$CMD" in
    install) do_install ;;
    update)  do_update ;;
    logs)    do_logs ;;
    *) echo "usage: $0 install|update|logs"; exit 2 ;;
esac
