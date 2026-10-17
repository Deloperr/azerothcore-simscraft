# Installing SimsCraft 1.0.0

[Русская версия](INSTALL.ru.md)

There are two ways to install SimsCraft:

- **One-click installer** (Windows, macOS, Linux) — downloads AzerothCore with mod-playerbots and mod-ale, builds and runs it in Docker, and installs SimsCraft. Best if you don't have a server yet.
- **[Existing AzerothCore server](#existing-azerothcore-server-manual-install)** — copy one Lua file and import two SQL files.

In both cases you also need the **[client addon](#client-addon)**.

Contents: [Windows](#windows) · [macOS](#macos) · [Linux](#linux) · [Existing server](#existing-azerothcore-server-manual-install) · [Client addon](#client-addon) · [Updating](#updating) · [Troubleshooting](#troubleshooting) · [Uninstall](#uninstall)

---

## Windows

**You need:** Windows 10/11 (64-bit), ~15 GB free disk space, 8 GB RAM or more.

1. Install **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** (keep the default "Use WSL 2" option) and start it once. Wait until it says *Engine running*.
2. Install **[Git for Windows](https://git-scm.com/download/win)** (default options are fine).
3. Download `SimsCraft-1.0.0-windows.zip` from [Releases](https://github.com/Deloperr/azerothcore-simscraft/releases) and unpack it, for example to `C:\SimsCraft`.
4. Double-click **`install.bat`**. If Windows SmartScreen warns you, click *More info → Run anyway*.
   - The server is placed in `%USERPROFILE%\AzerothCore-SimsCraft` (set the `SIMSCRAFT_DIR` environment variable before starting to use another folder).
   - The first build takes **20–60 minutes**. A log is written to `simscraft-install.log` next to `install.bat`.
   - At the end you're asked which IP the WoW client connects to. Press Enter for `127.0.0.1` if the game runs on the same PC.
5. Create a game account. Open PowerShell and run `docker attach ac-worldserver`, then type:
   ```
   account create myname mypassword
   account set gmlevel myname 3 -1
   ```
   Leave the console with **Ctrl+P, then Ctrl+Q** (Ctrl+C would stop the server).
6. Install the [client addon](#client-addon) and set the realmlist.

## macOS

**You need:** macOS 12 or newer (Intel or Apple Silicon), ~15 GB free disk space.

1. Install **[Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)** (choose Apple chip or Intel chip) and start it.
2. Git: run `git --version` in Terminal; if it's missing, macOS offers to install the *Command Line Tools* — accept.
3. Download `SimsCraft-1.0.0-macos.zip` from [Releases](https://github.com/Deloperr/azerothcore-simscraft/releases) and unpack it (for example in Downloads).
4. Double-click **`Install SimsCraft.command`**. If macOS says it can't be opened, right-click it → *Open* → *Open*. (Or once in Terminal: `xattr -dr com.apple.quarantine ~/Downloads/SimsCraft-1.0.0-macos`.)
   - The server goes to `~/AzerothCore-SimsCraft`. First build: 20–60 minutes. Log: `simscraft-install.log`.
   - The WoW 3.3.5a client is a Windows program. If you run it in **Parallels / VMware**, the installer detects the virtual network and suggests the Mac's IP (for example `10.211.55.2`). With CrossOver/Whisky on the same Mac use `127.0.0.1`.
5. Create an account: in Terminal run `docker attach ac-worldserver`, then `account create myname mypassword` and `account set gmlevel myname 3 -1`. Leave with **Ctrl+P, Ctrl+Q**.
6. Install the [client addon](#client-addon) and set the realmlist.

## Linux

**You need:** a 64-bit distribution with **Docker Engine** and the **compose v2 plugin** (`docker compose version` must work), **git**, ~15 GB free disk space.

```bash
# Debian/Ubuntu example
sudo apt install docker.io docker-compose-v2 git      # or follow docs.docker.com/engine/install
sudo usermod -aG docker $USER && newgrp docker        # run docker without sudo

tar xzf SimsCraft-1.0.0-linux.tar.gz
cd SimsCraft-1.0.0-linux
./install.sh
```

- The server goes to `~/AzerothCore-SimsCraft` (`SIMSCRAFT_DIR=/path ./install.sh` to change). First build: 20–60 minutes.
- Enter the IP that players connect to (`127.0.0.1` for the same machine, or your LAN IP). Open ports **3724** (auth) and **8085** (world) in your firewall if others connect.
- Create an account: `docker attach ac-worldserver` → `account create myname mypassword` → `account set gmlevel myname 3 -1`, then **Ctrl+P, Ctrl+Q**.
- The client runs fine under Wine/Lutris.

## Existing AzerothCore server (manual install)

Requirements: AzerothCore 3.3.5a with **[mod-ale](https://github.com/azerothcore/mod-ale)** enabled (`ALE.Enabled = 1` in `mod_ale.conf`, Lua scripts folder configured). mod-playerbots is optional.

1. **Lua script.** Copy `server/lua_scripts/SimsCraft/SimsCraft.lua` into your ALE scripts folder (usually `env/dist/etc/lua_scripts/` or the path from `ALE.ScriptPath`).
2. **Characters database.** Import `server/sql/characters/simscraft_characters.sql` into `acore_characters`.
3. **World database.** Import `server/sql/world/simscraft_world.sql` into `acore_world`.
4. Restart the worldserver. The log must contain `[SimsCraft] 1.0.0 loaded`.

Always import with **utf8mb4**, otherwise Russian names break:

```bash
mysql --default-character-set=utf8mb4 -u root -p acore_characters < server/sql/characters/simscraft_characters.sql
mysql --default-character-set=utf8mb4 -u root -p acore_world      < server/sql/world/simscraft_world.sql
```

(HeidiSQL: *File → Run SQL file…*, encoding UTF-8.)

SimsCraft uses these IDs — make sure your custom content doesn't use them:

| Table | IDs |
|---|---|
| `creature_template` | 190100 (Keeper of Life), 190110–190121 (children, spouses) |
| `gameobject_template` | 600000–601099 (catalog and service objects) |
| `npc_text` | 190100 |

**Upgrading from a pre-1.0 test build** (versions 2.0–6.x): before step 3 also import `server/sql/updates/pre1_characters_*.sql` into the characters DB (with `--force`: "duplicate column" errors are expected) and `pre1_world_restore_v3.sql`, then `pre1_world_migrate_v3.sql` into the world DB.

## Client addon

1. Copy the folder `client/Interface/AddOns/SimsCraft` into `World of Warcraft\Interface\AddOns\` (replace the old one if you update).
2. In `World of Warcraft\Data\enUS\realmlist.wtf` (or `ruRU`, `deDE`… — your client's language) write the server address:
   ```
   set realmlist 127.0.0.1
   ```
3. Start the game, enable **SimsCraft** in the AddOns list on the character screen.

The addon language follows the client: Russian on a ruRU client, English otherwise. Settings: Interface → AddOns → SimsCraft, `/scui config`, or right-click the green gem at the minimap.

## Updating

Download the new archive and run **`update.bat`** (Windows), **`Update SimsCraft.command`** (macOS) or **`./update.sh`** (Linux). It backs up the SimsCraft tables to `backup/`, updates both databases, copies the new script and restarts the world server (1–2 minutes). Then replace the addon folder and restart the game.

## Troubleshooting

- **The addon says "waiting for server…"** — the server script isn't running. Check the worldserver log for `[SimsCraft]`; make sure mod-ale is enabled and the file is in the scripts folder.
- **The server restarts or disconnects right after login** — run **`collect-logs.bat`** / **`Collect logs.command`** / **`./collect-logs.sh`** and attach `server-logs.txt` to a [bug report](https://github.com/Deloperr/azerothcore-simscraft/issues/new/choose). A message `[SimsCraft] ERROR: the characters database is not updated` means step 2 (or the updater) wasn't run.
- **Garbled Russian names** — the SQL was imported without `--default-character-set=utf8mb4`. Import it again.
- **Docker build fails on Windows** with `\r` errors — AzerothCore was cloned with CRLF line endings. Delete the server folder and run `install.bat` again (it clones with `core.autocrlf=false`).
- **Can't connect** — check `realmlist.wtf` and that ports 3724 and 8085 are reachable.

## Uninstall

Delete `SimsCraft.lua` from the scripts folder and restart. To remove the data as well:

```sql
-- acore_characters
DROP TABLE IF EXISTS character_sims, character_sims_relations, character_sims_furniture, character_sims_children,
                     character_sims_world, character_sims_spots, character_sims_skills;
-- acore_world (placed furniture is stored as normal gameobject spawns)
DELETE FROM gameobject WHERE id BETWEEN 600000 AND 601099;
DELETE FROM gameobject_template_locale WHERE entry BETWEEN 600000 AND 601099;
DELETE FROM gameobject_template WHERE entry BETWEEN 600000 AND 601099;
DELETE FROM creature WHERE id1 IN (190100) OR id1 BETWEEN 190110 AND 190121;   -- older cores: column `id`
DELETE FROM creature_template_locale WHERE entry = 190100 OR entry BETWEEN 190110 AND 190121;
DELETE FROM creature_template_model WHERE CreatureID = 190100 OR CreatureID BETWEEN 190110 AND 190121;
DELETE FROM creature_template WHERE entry = 190100 OR entry BETWEEN 190110 AND 190121;
DELETE FROM npc_text_locale WHERE ID = 190100;
DELETE FROM npc_text WHERE ID = 190100;
```

To remove a Docker server completely: `cd ~/AzerothCore-SimsCraft && docker compose down -v`, then delete the folder.
