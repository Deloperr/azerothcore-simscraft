# Установка SimsCraft 1.0.0

[English version](INSTALL.md)

Установить SimsCraft можно двумя способами:

- **Установщик в один щелчок** (Windows, macOS, Linux). Он скачает AzerothCore с mod-playerbots и mod-ale, соберёт и запустит его в Docker и установит SimsCraft. Подходит, если своего сервера ещё нет.
- **[Свой сервер AzerothCore](#свой-сервер-azerothcore-ручная-установка)**: скопировать один Lua-файл и загрузить два SQL-файла.

В обоих случаях нужен ещё **[аддон для клиента](#аддон-для-клиента)**.

Разделы: [Windows](#windows) · [macOS](#macos) · [Linux](#linux) · [Свой сервер](#свой-сервер-azerothcore-ручная-установка) · [Аддон](#аддон-для-клиента) · [Обновление](#обновление) · [Если что-то не работает](#если-что-то-не-работает) · [Удаление](#удаление)

---

## Windows

**Нужно:** Windows 10/11 (64 бит), около 15 ГБ на диске, от 8 ГБ памяти.

1. Установите **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** (оставьте вариант «Use WSL 2») и один раз запустите его. Дождитесь надписи *Engine running*.
2. Установите **[Git for Windows](https://git-scm.com/download/win)** (настройки по умолчанию подходят).
3. Скачайте `SimsCraft-1.0.0-windows.zip` в [Releases](https://github.com/Deloperr/azerothcore-simscraft/releases) и распакуйте, например, в `C:\SimsCraft`.
4. Дважды щёлкните **`install.bat`**. Если появится предупреждение SmartScreen, нажмите «Подробнее» → «Выполнить в любом случае».
   - Сервер ставится в `%USERPROFILE%\AzerothCore-SimsCraft` (другую папку можно задать переменной окружения `SIMSCRAFT_DIR`).
   - Первая сборка идёт **20–60 минут**. Лог пишется в `simscraft-install.log` рядом с `install.bat`.
   - В конце установщик спросит, к какому IP будет подключаться клиент WoW. Если игра на этом же компьютере, просто нажмите Enter (`127.0.0.1`).
5. Создайте игровой аккаунт. Откройте PowerShell, выполните `docker attach ac-worldserver` и введите:
   ```
   account create myname mypassword
   account set gmlevel myname 3 -1
   ```
   Выход из консоли: **Ctrl+P, затем Ctrl+Q** (Ctrl+C остановит сервер).
6. Установите [аддон](#аддон-для-клиента) и укажите realmlist.

## macOS

**Нужно:** macOS 12 или новее (Intel или Apple Silicon), около 15 ГБ на диске.

1. Установите **[Docker Desktop для Mac](https://www.docker.com/products/docker-desktop/)** (Apple chip или Intel chip) и запустите его.
2. Git: выполните в Терминале `git --version`. Если его нет, macOS предложит установить «Инструменты командной строки» — согласитесь.
3. Скачайте `SimsCraft-1.0.0-macos.zip` в [Releases](https://github.com/Deloperr/azerothcore-simscraft/releases) и распакуйте (например, в «Загрузки»).
4. Дважды щёлкните **`Install SimsCraft.command`**. Если macOS пишет, что файл нельзя открыть, щёлкните по нему правой кнопкой → «Открыть» → «Открыть». (Или один раз в Терминале: `xattr -dr com.apple.quarantine ~/Downloads/SimsCraft-1.0.0-macos`.)
   - Сервер ставится в `~/AzerothCore-SimsCraft`. Первая сборка — 20–60 минут. Лог — `simscraft-install.log`.
   - Клиент WoW 3.3.5a — программа для Windows. Если он запущен в **Parallels / VMware**, установщик сам найдёт виртуальную сеть и предложит IP Mac (например, `10.211.55.2`). Для CrossOver/Whisky на этом же Mac — `127.0.0.1`.
5. Создайте аккаунт: в Терминале `docker attach ac-worldserver`, затем `account create myname mypassword` и `account set gmlevel myname 3 -1`. Выход: **Ctrl+P, Ctrl+Q**.
6. Установите [аддон](#аддон-для-клиента) и укажите realmlist.

## Linux

**Нужно:** 64-битный дистрибутив с **Docker Engine** и плагином **compose v2** (`docker compose version` должен работать), **git**, около 15 ГБ на диске.

```bash
# пример для Debian/Ubuntu
sudo apt install docker.io docker-compose-v2 git      # или по инструкции docs.docker.com/engine/install
sudo usermod -aG docker $USER && newgrp docker        # docker без sudo

tar xzf SimsCraft-1.0.0-linux.tar.gz
cd SimsCraft-1.0.0-linux
./install.sh
```

- Сервер ставится в `~/AzerothCore-SimsCraft` (другая папка: `SIMSCRAFT_DIR=/путь ./install.sh`). Первая сборка — 20–60 минут.
- Введите IP, к которому будут подключаться игроки (`127.0.0.1` — этот же компьютер, или адрес в локальной сети). Если подключаются другие, откройте в файрволе порты **3724** (вход) и **8085** (мир).
- Аккаунт: `docker attach ac-worldserver` → `account create myname mypassword` → `account set gmlevel myname 3 -1`, затем **Ctrl+P, Ctrl+Q**.
- Клиент нормально работает через Wine/Lutris.

## Свой сервер AzerothCore (ручная установка)

Нужно: AzerothCore 3.3.5a с включённым **[mod-ale](https://github.com/azerothcore/mod-ale)** (`ALE.Enabled = 1` в `mod_ale.conf`, указана папка Lua-скриптов). mod-playerbots не обязателен.

1. **Lua-скрипт.** Скопируйте `server/lua_scripts/SimsCraft/SimsCraft.lua` в папку скриптов ALE (обычно `env/dist/etc/lua_scripts/` или путь из `ALE.ScriptPath`).
2. **База персонажей.** Загрузите `server/sql/characters/simscraft_characters.sql` в `acore_characters`.
3. **База мира.** Загрузите `server/sql/world/simscraft_world.sql` в `acore_world`.
4. Перезапустите worldserver. В логе должна появиться строка `[SimsCraft] 1.0.0 loaded`.

Загружайте SQL обязательно в кодировке **utf8mb4**, иначе русские названия испортятся:

```bash
mysql --default-character-set=utf8mb4 -u root -p acore_characters < server/sql/characters/simscraft_characters.sql
mysql --default-character-set=utf8mb4 -u root -p acore_world      < server/sql/world/simscraft_world.sql
```

(HeidiSQL: «Файл → Выполнить SQL-файл…», кодировка UTF-8.)

SimsCraft занимает эти номера — проверьте, что ваши собственные дополнения их не используют:

| Таблица | Номера |
|---|---|
| `creature_template` | 190100 (Хранитель жизни), 190110–190121 (дети, супруги) |
| `gameobject_template` | 600000–601099 (каталог и служебные объекты) |
| `npc_text` | 190100 |

**Обновление с тестовых версий до 1.0** (2.0–6.x): перед шагом 3 загрузите ещё `server/sql/updates/pre1_characters_*.sql` в базу персонажей (с `--force`: ошибки «duplicate column» — это нормально), а в базу мира — `pre1_world_restore_v3.sql`, затем `pre1_world_migrate_v3.sql`.

## Аддон для клиента

1. Скопируйте папку `client/Interface/AddOns/SimsCraft` в `World of Warcraft\Interface\AddOns\` (при обновлении — с заменой).
2. В файле `World of Warcraft\Data\ruRU\realmlist.wtf` (или `enUS` и т. д. — язык вашего клиента) укажите адрес сервера:
   ```
   set realmlist 127.0.0.1
   ```
3. Запустите игру и включите **SimsCraft** в списке модификаций на экране выбора персонажа.

Язык аддона — как у клиента: на русском клиенте (ruRU) по-русски, на остальных по-английски. Настройки: «Интерфейс → Модификации → SimsCraft», `/scui config` или правый щелчок по зелёному самоцвету у миникарты.

## Обновление

Скачайте новый архив и запустите **`update.bat`** (Windows), **`Update SimsCraft.command`** (macOS) или **`./update.sh`** (Linux). Он сохранит таблицы SimsCraft в папку `backup/`, обновит обе базы, скопирует новый скрипт и перезапустит мир (1–2 минуты). Потом замените папку аддона и перезапустите игру.

## Если что-то не работает

- **Аддон пишет «ожидание сервера…»** — скрипт на сервере не запущен. Найдите в логе worldserver строки `[SimsCraft]`; проверьте, что mod-ale включён, а файл лежит в папке скриптов.
- **Сервер перезапускается или выкидывает сразу после входа** — запустите **`collect-logs.bat`** / **`Collect logs.command`** / **`./collect-logs.sh`** и приложите `server-logs.txt` к [сообщению об ошибке](https://github.com/Deloperr/azerothcore-simscraft/issues/new/choose). Строка `[SimsCraft] ERROR: the characters database is not updated` значит, что не выполнен шаг 2 (или обновление).
- **Русские названия — «кракозябры»** — SQL загрузили без `--default-character-set=utf8mb4`. Загрузите его ещё раз.
- **В Windows сборка Docker падает с ошибками про `\r`** — AzerothCore скачан с концами строк CRLF. Удалите папку сервера и запустите `install.bat` снова (он скачивает с `core.autocrlf=false`).
- **Не подключается** — проверьте `realmlist.wtf` и доступность портов 3724 и 8085.

## Удаление

Удалите `SimsCraft.lua` из папки скриптов и перезапустите сервер. Чтобы удалить и данные:

```sql
-- acore_characters
DROP TABLE IF EXISTS character_sims, character_sims_relations, character_sims_furniture, character_sims_children,
                     character_sims_world, character_sims_spots, character_sims_skills;
-- acore_world (поставленная мебель хранится как обычные объекты мира)
DELETE FROM gameobject WHERE id BETWEEN 600000 AND 601099;
DELETE FROM gameobject_template_locale WHERE entry BETWEEN 600000 AND 601099;
DELETE FROM gameobject_template WHERE entry BETWEEN 600000 AND 601099;
DELETE FROM creature WHERE id1 IN (190100) OR id1 BETWEEN 190110 AND 190121;   -- в старых ядрах столбец `id`
DELETE FROM creature_template_locale WHERE entry = 190100 OR entry BETWEEN 190110 AND 190121;
DELETE FROM creature_template_model WHERE CreatureID = 190100 OR CreatureID BETWEEN 190110 AND 190121;
DELETE FROM creature_template WHERE entry = 190100 OR entry BETWEEN 190110 AND 190121;
DELETE FROM npc_text_locale WHERE ID = 190100;
DELETE FROM npc_text WHERE ID = 190100;
```

Удалить Docker-сервер целиком: `cd ~/AzerothCore-SimsCraft && docker compose down -v`, затем удалить папку.
