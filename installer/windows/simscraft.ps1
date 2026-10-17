# SimsCraft installer for Windows (Docker Desktop + Git for Windows).
# Usage: simscraft.ps1 install | update | logs   (normally started by install.bat / update.bat / collect-logs.bat)
# Установщик SimsCraft для Windows (Docker Desktop + Git for Windows).
#   $env:SIMSCRAFT_DIR   server folder (default: %USERPROFILE%\AzerothCore-SimsCraft)
#   $env:SIMSCRAFT_LANG  en | ru (default: Windows language)
param([string]$Cmd = "install")

$ErrorActionPreference = "Continue"
$VERSION = "1.0.0"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PKG  = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$DEST = if ($env:SIMSCRAFT_DIR) { $env:SIMSCRAFT_DIR } else { Join-Path $env:USERPROFILE "AzerothCore-SimsCraft" }
$SQL  = Join-Path $PKG "server\sql"
$LANGX = if ($env:SIMSCRAFT_LANG) { $env:SIMSCRAFT_LANG } elseif ((Get-UICulture).TwoLetterISOLanguageName -eq "ru" -or (Get-Culture).TwoLetterISOLanguageName -eq "ru") { "ru" } else { "en" }
function T([string]$en, [string]$ru) { if ($LANGX -eq "ru") { $ru } else { $en } }

$LOG = Join-Path $PKG "simscraft-$Cmd.log"
try { Start-Transcript -Path $LOG -Append | Out-Null } catch {}

function Step([string]$m) { Write-Host ""; Write-Host ("=== [{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $m) -ForegroundColor Cyan }
function Pause-End { Write-Host ""; Read-Host (T "Press Enter to close this window" "Нажмите Enter, чтобы закрыть окно") | Out-Null }
function Fail([string]$m) {
    Write-Host ""; Write-Host ("!!! " + (T "ERROR" "ОШИБКА") + ": " + $m) -ForegroundColor Red
    Write-Host ((T "Log: " "Лог: ") + $LOG)
    try { Stop-Transcript | Out-Null } catch {}
    Pause-End; exit 1
}
function DC { Push-Location $DEST; try { & docker compose @args; $code = $LASTEXITCODE } finally { Pop-Location }; $global:LASTEXITCODE = $code }
# mysql < file: cmd.exe keeps the UTF-8 bytes intact / cmd передаёт файл без перекодировки
function Mysql-File([string]$db, [string]$file, [switch]$Force) {
    $f = if ($Force) { "--force " } else { "" }
    Push-Location $DEST
    try {
        $out = cmd /c "docker compose exec -T ac-database mysql --default-character-set=utf8mb4 $f-uroot -ppassword $db < `"$file`" 2>&1"
        $code = $LASTEXITCODE
    } finally { Pop-Location }
    $out | Where-Object { $_ -notmatch "Using a password|Duplicate column|already exists" } | ForEach-Object { Write-Host $_ }
    if ($Force) { return $true }
    return ($code -eq 0)
}
function Mysql-Q([string]$q) {
    Push-Location $DEST
    try { $out = & docker compose exec -T ac-database mysql --default-character-set=utf8mb4 -N -uroot -ppassword -e $q 2>&1 } finally { Pop-Location }
    ($out | Where-Object { $_ -notmatch "Using a password" }) -join "`n"
}

function Need-Docker {
    docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        $dd = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dd) { Start-Process $dd | Out-Null }
        Write-Host (T "Waiting for Docker Desktop to start (up to 3 minutes)..." "Жду запуска Docker Desktop (до 3 минут)...")
        for ($i = 0; $i -lt 90; $i++) { docker info *> $null; if ($LASTEXITCODE -eq 0) { break }; Start-Sleep 2 }
    }
    docker info *> $null
    if ($LASTEXITCODE -ne 0) { Fail (T "Docker Desktop is not running (or not installed). Install it from docker.com, start it and run this again." "Docker Desktop не запущен (или не установлен). Установите его с docker.com, запустите и откройте установщик снова.") }
    docker compose version *> $null
    if ($LASTEXITCODE -ne 0) { Fail (T "'docker compose' (v2) not found. Update Docker Desktop." "Не найден 'docker compose' (v2). Обновите Docker Desktop.") }
}

function Wait-Db {
    Step (T "Waiting for the database" "Жду базу данных")
    for ($i = 0; $i -lt 120; $i++) {
        $r = Mysql-Q "SELECT 1 FROM acore_auth.realmlist LIMIT 1"
        if ($r -match "^\s*1\s*$") { return }
        Start-Sleep 5
    }
    Fail (T "the database did not start" "база данных не запустилась")
}

function Copy-Script {
    Step (T "SimsCraft server script" "Скрипт SimsCraft на сервер")
    $d = Join-Path $DEST "env\dist\etc\lua_scripts\SimsCraft"
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    Copy-Item (Join-Path $PKG "server\lua_scripts\SimsCraft\SimsCraft.lua") $d -Force -ErrorAction Stop
    Get-ChildItem $d | Format-Table Name, Length, LastWriteTime -AutoSize | Out-String | Write-Host
}

function Apply-Sql([bool]$oldWorld) {
    Step (T "Characters database" "База персонажей")
    if (-not (Mysql-File "acore_characters" (Join-Path $SQL "characters\simscraft_characters.sql"))) { Fail (T "characters SQL failed" "ошибка SQL базы персонажей") }
    Get-ChildItem (Join-Path $SQL "updates\pre1_characters_*.sql") | Sort-Object Name | ForEach-Object { Mysql-File "acore_characters" $_.FullName -Force | Out-Null }
    if ($oldWorld) {
        Step (T "Upgrading a pre-1.0 SimsCraft world" "Обновление мира со старых версий SimsCraft")
        if (-not (Mysql-File "acore_world" (Join-Path $SQL "updates\pre1_world_restore_v3.sql"))) { Fail "restore" }
        Mysql-File "acore_world" (Join-Path $SQL "updates\pre1_world_migrate_v3.sql") -Force | Out-Null
    }
    Step (T "World database: SimsCraft catalog, NPCs, translations" "База мира: каталог SimsCraft, NPC, переводы")
    if (-not (Mysql-File "acore_world" (Join-Path $SQL "world\simscraft_world.sql"))) { Fail (T "world SQL failed (nothing was changed)" "ошибка SQL базы мира (ничего не изменено)") }
    Write-Host ((T "SimsCraft objects (313): " "Объектов SimsCraft (313): ") + (Mysql-Q "SELECT COUNT(*) FROM acore_world.gameobject_template WHERE entry BETWEEN 600000 AND 601099"))
    Write-Host ((T "SimsCraft NPCs (13): " "NPC SimsCraft (13): ") + (Mysql-Q "SELECT COUNT(*) FROM acore_world.creature_template WHERE entry = 190100 OR entry BETWEEN 190110 AND 190121"))
}

function Restart-World {
    Step (T "Restarting the world server (1-2 minutes)" "Перезапуск мира (1–2 минуты)")
    DC up -d | Out-Null
    DC restart ac-worldserver
    if ($LASTEXITCODE -ne 0) { Fail (T "cannot restart the world server" "не удалось перезапустить мир") }
    $ok = $false
    for ($i = 0; $i -lt 100; $i++) {
        $l = (DC logs --tail 600 ac-worldserver 2>&1) -join "`n"
        if ($l -match [regex]::Escape("SimsCraft] $VERSION")) { $ok = $true; break }
        Start-Sleep 3
    }
    (DC logs --tail 800 ac-worldserver 2>&1) | Select-String -Pattern "SimsCraft|\[ALE\]|\.lua" | Select-Object -Last 15 | ForEach-Object { Write-Host $_.Line }
    if ($ok) { Write-Host (T "SimsCraft $VERSION is running." "SimsCraft $VERSION запущен.") -ForegroundColor Green }
    else { Write-Host (T "Did not see the SimsCraft start line yet — check the log above (or run collect-logs.bat)." "Строка запуска SimsCraft пока не появилась — посмотрите лог выше (или запустите collect-logs.bat).") -ForegroundColor Yellow }
}

function Addon-Hint([string]$ip) {
    Write-Host ""
    Write-Host (T "=== Client (WoW 3.3.5a) ===" "=== Клиент (WoW 3.3.5a) ===")
    Write-Host ((T "1. Copy the folder  " "1. Скопируйте папку  ") + (Join-Path $PKG "client\Interface\AddOns\SimsCraft"))
    Write-Host (T "   into  World of Warcraft\Interface\AddOns\  (replace the old one)." "   в  World of Warcraft\Interface\AddOns\  (с заменой старой).")
    Write-Host ((T "2. In  World of Warcraft\Data\<locale>\realmlist.wtf  write:  set realmlist " "2. В файле  World of Warcraft\Data\ruRU\realmlist.wtf  укажите:  set realmlist ") + $ip)
}

function Do-Install {
    Step (T "SimsCraft $VERSION — server installation" "SimsCraft $VERSION — установка сервера")
    Write-Host ((T "Server folder: " "Папка сервера: ") + $DEST)
    Need-Docker
    git --version *> $null
    if ($LASTEXITCODE -ne 0) { Fail (T "Git is required: install Git for Windows (git-scm.com) and run again." "Нужен Git: установите Git for Windows (git-scm.com) и запустите установщик снова.") }

    Step (T "Downloading AzerothCore (Playerbot branch)" "Загрузка AzerothCore (ветка Playerbot)")
    if (-not (Test-Path (Join-Path $DEST ".git"))) {
        git -c core.autocrlf=false clone --depth 1 --branch Playerbot https://github.com/mod-playerbots/azerothcore-wotlk.git "$DEST"
        if ($LASTEXITCODE -ne 0) { Fail "git clone azerothcore" }
    } else { Write-Host (T "Already downloaded — skipping." "Уже скачано — пропускаю.") }
    Step (T "Modules: mod-playerbots and mod-ale (Lua engine)" "Модули: mod-playerbots и mod-ale (Lua)")
    $mp = Join-Path $DEST "modules\mod-playerbots"; $ma = Join-Path $DEST "modules\mod-ale"
    if (-not (Test-Path $mp)) { git -c core.autocrlf=false clone --depth 1 --branch master https://github.com/mod-playerbots/mod-playerbots.git "$mp"; if ($LASTEXITCODE -ne 0) { Fail "git clone mod-playerbots" } }
    if (-not (Test-Path $ma)) { git -c core.autocrlf=false clone --depth 1 https://github.com/azerothcore/mod-ale.git "$ma"; if ($LASTEXITCODE -ne 0) { Fail "git clone mod-ale" } }

    Copy-Script
    Step (T "Docker settings" "Настройки Docker")
    $ov = Join-Path $DEST "docker-compose.override.yml"
    if (-not (Test-Path $ov)) {
        $yml = @"
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
"@
        [System.IO.File]::WriteAllText($ov, $yml.Replace("`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
    }
    Get-Content $ov | Write-Host

    Step (T "Building and starting the server (the longest step: 20-60 minutes)" "Сборка и запуск сервера (самый долгий шаг: 20–60 минут)")
    DC up -d --build
    if ($LASTEXITCODE -ne 0) { Fail (T "build or start failed — see the messages above" "сборка или запуск не удались — смотрите сообщения выше") }
    Wait-Db
    Apply-Sql $false

    Step (T "Server address for the WoW client" "Адрес сервера для клиента WoW")
    $ip = "127.0.0.1"
    Write-Host (T "The WoW client will connect to: 127.0.0.1 (the game runs on this PC)." "Клиент WoW будет подключаться к: 127.0.0.1 (игра на этом же компьютере).")
    $a = Read-Host (T "Press Enter to keep it, or type another IP (for example your LAN IP)" "Нажмите Enter, чтобы оставить, или введите другой IP (например, адрес в локальной сети)")
    if ($a) { $ip = $a.Trim() }
    Mysql-Q "UPDATE acore_auth.realmlist SET address='$ip', name='SimsCraft' WHERE id=1" | Out-Null
    Set-Content -Path (Join-Path $PKG "server_ip.txt") -Value $ip
    Restart-World
    DC ps

    Write-Host ""; Write-Host (T "=== DONE ===" "=== ГОТОВО ===") -ForegroundColor Green
    Addon-Hint $ip
    Write-Host (T "3. Create an account in the server console:  docker attach ac-worldserver" "3. Создайте аккаунт в консоли сервера:  docker attach ac-worldserver")
    Write-Host (T "   account create NAME PASSWORD      (GM rights: account set gmlevel NAME 3 -1)" "   account create ИМЯ ПАРОЛЬ      (права ГМ: account set gmlevel ИМЯ 3 -1)")
    Write-Host (T "   Leave the console with Ctrl+P, then Ctrl+Q." "   Выход из консоли: Ctrl+P, затем Ctrl+Q.")
    Write-Host (T "4. In game, as GM, place the Keeper of Life NPC:  .sims npc   — help:  .sims help" "4. В игре (ГМ) поставьте NPC «Хранитель жизни»:  .sims npc   — справка:  .sims help")
    Pause-End
}

function Do-Update {
    Step (T "SimsCraft $VERSION — update" "SimsCraft $VERSION — обновление")
    if (-not (Test-Path $DEST)) { Fail ((T "server not found in " "сервер не найден в ") + $DEST) }
    Need-Docker
    DC up -d ac-database | Out-Null
    Wait-Db
    $old = [bool]((Mysql-Q "SELECT 1 FROM acore_world.gameobject_template WHERE entry=600000 AND name NOT REGEXP '^[ -~]+$' LIMIT 1").Trim())
    Step (T "Backup" "Резервная копия")
    $bk = Join-Path $PKG "backup"; New-Item -ItemType Directory -Force -Path $bk | Out-Null
    $file = Join-Path $bk ("characters-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".sql")
    Push-Location $DEST
    try { cmd /c "docker compose exec -T ac-database mysqldump -uroot -ppassword acore_characters --tables character_sims character_sims_relations character_sims_furniture character_sims_children character_sims_world character_sims_spots character_sims_skills > `"$file`" 2>nul" } finally { Pop-Location }
    Write-Host $file
    Apply-Sql $old
    Copy-Script
    Restart-World
    Write-Host ""; Write-Host (T "=== DONE ===" "=== ГОТОВО ===") -ForegroundColor Green
    $ip = (Mysql-Q "SELECT address FROM acore_auth.realmlist WHERE id=1").Trim(); if (-not $ip) { $ip = "127.0.0.1" }
    Addon-Hint $ip
    Write-Host (T "Restart the game after replacing the addon." "После замены аддона перезапустите игру.")
    Pause-End
}

function Do-Logs {
    $out = Join-Path $PKG "server-logs.txt"
    $lines = @("=== $(Get-Date)  SimsCraft $VERSION  Windows")
    $lines += (docker inspect -f "RestartCount={{.RestartCount}} StartedAt={{.State.StartedAt}} ExitCode={{.State.ExitCode}}" ac-worldserver 2>&1)
    $lines += "=== worldserver, last 2 hours (bot logins filtered)"
    $lines += (docker logs -t --since 2h ac-worldserver 2>&1 | Where-Object { $_ -notmatch "Bot .* logged in|Missing property|Found config value|Random teleporting|Playerbots" } | Select-Object -Last 4000)
    [System.IO.File]::WriteAllLines($out, [string[]]$lines, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ((T "Saved: " "Сохранено: ") + $out + (T " — attach it to your GitHub issue." " — приложите файл к issue на GitHub."))
    Pause-End
}

switch ($Cmd) {
    "install" { Do-Install }
    "update"  { Do-Update }
    "logs"    { Do-Logs }
    default   { Write-Host "usage: simscraft.ps1 install|update|logs"; exit 2 }
}
try { Stop-Transcript | Out-Null } catch {}
