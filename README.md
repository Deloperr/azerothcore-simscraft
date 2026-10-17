# SimsCraft for AzerothCore

**The Sims-style life simulation inside World of Warcraft 3.3.5a.** Your hero gets needs and emotions, a job, friends and a partner, a house full of furniture, a wedding, children who grow up and move out — all running on an [AzerothCore](https://www.azerothcore.org/) server with the Lua engine [mod-ale](https://github.com/azerothcore/mod-ale), plus a Sims-like UI addon for the client.

[Русская версия](README.ru.md) · [Installation](docs/INSTALL.md) · [Changelog](CHANGELOG.md) · [Report a bug / suggest an idea](https://github.com/Deloperr/azerothcore-simscraft/issues/new/choose)

> Version **1.0.0**. English and Russian: the server and the addon automatically follow the language of each player's WoW client (ruRU → Russian, everything else → English).

---

## Features

**Needs and emotions**
- Six needs — hunger, energy, hygiene, fun, social, bladder — that drain over time and are refilled by food, sleep, baths, fun, people and the toilet.
- 15 emotions built from moodlets ("Well rested", "Romantic evening", "Great shift", "Soaked to the bone", "Cozy home", …). Good emotions give more WoW experience; the right emotion speeds up matching skills.
- 12 personality traits (Glutton, Loner, Romantic, Workaholic, Bookworm, Family-oriented, …).

**Skills, careers and aspirations**
- 16 skills, levels 1–10: cooking, fitness, logic, charisma, painting, music, writing, programming, handiness, gardening, fishing, mixology, comedy, dancing, mischief, video games. Paintings sell, books pay royalties, programming earns commissions, garden beds yield real WoW herbs.
- 7 careers with interactive shifts next to you: gather magical essence from crystals as a mage, cook orders in a cauldron, patrol and light signal torches, carry crates to a stall, perform on street stages, heal patients, run a flag course. Promotions, salary, ranks.
- 9 aspirations with 3 stages each; satisfaction points buy potions and permanent perks.

**Relationships, marriage and family**
- Friendship (−100…100) and romance (0…100) with NPCs, bots and real players; 15 social actions from "Chat" to "Propose". Real players get a yes/no dialog for serious actions.
- Marry a real NPC (for example a Stormwind stable master): she works at her post 9–17, walks home after work, cooks, reads and sleeps in your bed at night — the same NPC, no clones.
- Babies are made the Sims way: a romantic evening in your bedroom (underwear and a cozy haze over the bed). Twins happen.
- **The child's race is 50/50 from the parents** (a human and a dwarf have a human or a dwarf child). Children grow: infant → toddler → child → teen → adult, play at home with each other and neighbour kids, go to school on weekdays, sleep in their beds, and eventually move out to live with their own family near a tavern in another town — visit them!

**Homes and furniture**
- A catalog of **296 items** built from real WoW 3.3.5 models: beds, wardrobes, stoves, bathtubs, tables, chairs, lamps, plants, fences, walls, tents — and **ready-made houses**, real WoW buildings (Westfall, Redridge and Duskwood farmhouses, a two-story house, a draenei hut, barns, chapels, towers…).
- Place furniture with a "ghost" preview: move, rotate, raise, lower, then place. Sell or move it later.
- Built-in furniture of a ready-made house can be marked once ("Furnish") so it works like bought furniture.
- Interactive furniture: sleep in a bed, cook, take a bubble bath, use the toilet, read, play music, change outfits at the wardrobe, get a real haircut at the vanity mirror, store items in the chest (your bank), play on the computer, watch the crystal-ball TV, paint, play chess, train, mix cocktails, tend herbs. Things break — repair them yourself or call a repairman.

**A living world**
- A Sims clock (a game day is 48 real minutes by default) with sky, sunrise and night synced to the client.
- NPCs around you walk the streets, chat, sit on benches, work, dance in the evening and go home at night.
- Seasons, weather (rain, thunderstorms, fog, snow, blizzards), holidays, weekly house bills (unpaid → the power is cut), colds, a phone (call your spouse, invite friends over, order pizza, call a doctor).

**Client addon**
- A bottom panel that replaces the default WoW bar layout: your portrait with HP/mana and the green plumbob (emotion color), the WoW action bars (with up to 4 extra bars above them), menu and bags, the SimsCraft block (needs, sections, actions) and a target frame with portrait, HP/mana, auras, relationship and quick social actions.
- Everything is configurable: block order, visibility, scale, styles, border colors, bar textures and text, a live 3D portrait; Interface → AddOns → SimsCraft, `/scui config`, or right-click the minimap button.
- Camera modes: normal, top-down (Sims style, click-to-move), over the shoulder, first person.

## Requirements

- An **AzerothCore 3.3.5a** server with **[mod-ale](https://github.com/azerothcore/mod-ale)** (Lua 5.2). The installers use the [Playerbot fork](https://github.com/mod-playerbots/azerothcore-wotlk) with **mod-playerbots**, but bots are optional.
- A **WoW 3.3.5a (12340)** client.
- For the one-click installers: **Docker Desktop** (Windows, macOS) or **Docker Engine + compose v2** (Linux), and **git**. ~15 GB of disk space; the first build takes 20–60 minutes.

## Install

Download the archive for your system from **[Releases](https://github.com/Deloperr/azerothcore-simscraft/releases)**:

| System | Archive | Start |
|---|---|---|
| Windows 10/11 | `SimsCraft-1.0.0-windows.zip` | `install.bat` |
| macOS (Intel / Apple Silicon) | `SimsCraft-1.0.0-macos.zip` | `Install SimsCraft.command` |
| Linux | `SimsCraft-1.0.0-linux.tar.gz` | `./install.sh` |

The installer downloads AzerothCore with mod-playerbots and mod-ale, builds and starts it in Docker, installs SimsCraft, and tells you what to put into `realmlist.wtf`. To update later, run `update.bat` / `Update SimsCraft.command` / `./update.sh` from the new archive.

**Already have an AzerothCore server with mod-ale?** Copy one Lua file and import two SQL files — see [docs/INSTALL.md → Existing server](docs/INSTALL.md#existing-azerothcore-server-manual-install).

**Addon:** copy `client/Interface/AddOns/SimsCraft` into `World of Warcraft/Interface/AddOns/`.

Full step-by-step guides for Windows, macOS and Linux: **[docs/INSTALL.md](docs/INSTALL.md)**.

## Getting started in game

1. As a GM, place the **Keeper of Life** NPC somewhere central: `.sims npc`. Players choose traits, a career and an aspiration there.
2. Open the SimsCraft panel (it's at the bottom; the green gem at the minimap toggles it). `/scui config` opens the settings.
3. Buy a house or a bed in the catalog — that place becomes your home. Make friends, fall in love, marry, have kids.

| Command | What it does |
|---|---|
| `.sims`, `.sims help` | your status, help |
| `.sims shop`, `.sims move`, `.sims sell` | catalog; move / sell your nearest item |
| `.sims home`, `.sims sethome` | teleport home; make this place your home |
| `.sims family`, `.sims kids`, `.sims work`, `.sims rel` | family, call the kids, work shift, relationships |
| `.sims npc` (GM) | place the Keeper of Life |
| `.sims gm` (GM) | debug commands: `.sims time 21:30`, `.sims daylen 48`, `.sims age 3`, `.sims birth`, `.sims fill`, `.sims skill painting 5`, … |
| `/scui`, `/scui config`, `/scui top`, `/scui shoulder`, `/scui first`, `/scui cam` | panel, settings, camera modes |

## Configuration

Server settings are in the `CFG` table at the top of `SimsCraft.lua`: day length (`DAY_MINUTES`), schedule, pregnancy and growing-up times, needs speed, relationship limits, prices, object limits, default language (`DEFAULT_LANG`), log language (`LOG_LANG`). Edit and run the updater (or `.reload ale`).

## Known limitations

- The 3.3.5 client can't hide only a building's roof — buildings are one model.
- In first-person view the 3.3.5 client hides your own body; use the "over the shoulder" camera to see your hands and body.
- The server only simulates areas near players: your family lives at home while you are nearby; when you're away, time still runs (kids grow, your spouse goes to work).
- Building is done with ready-made pieces (walls, fences, stairs…); there is no brick-by-brick building in 3.3.5.

## Bugs and ideas

Found a bug or have an idea? **[Open an issue](https://github.com/Deloperr/azerothcore-simscraft/issues/new/choose)** — there are templates for bug reports and feature requests. For crashes, attach `server-logs.txt` (run `collect-logs.bat` / `Collect logs.command` / `./collect-logs.sh`). Pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[GPL-2.0](LICENSE), like AzerothCore. World of Warcraft is a trademark of Blizzard Entertainment; The Sims is a trademark of Electronic Arts. SimsCraft is a fan project and is not affiliated with either. It uses only models that already ship with the 3.3.5a client.
