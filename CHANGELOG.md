# Changelog

## 1.0.0 — first public release

**New**
- English and Russian: the server and the addon follow each player's client language (ruRU → Russian, others → English). World object and NPC names come in both languages.
- A child's race is 50/50 from the parents (for example human + dwarf). Races without child models in 3.3.5 (dwarf, gnome, night elf, undead, troll, goblin) use a smaller adult model of their race. The addon tells the server an NPC's race from its model.
- A new bottom panel: player frame with portrait, HP/mana and plumbob; WoW action bars with up to 4 extra bars above them; menu and bags; the SimsCraft block; a target frame with portrait, HP/mana, auras, relationship and quick actions. Nothing overlaps the chat.
- Addon settings (Interface → AddOns → SimsCraft, `/scui config`, right-click the minimap button): block order and visibility, scale, styles, border colors, bar textures and text, health color, gaps, a live 3D portrait, presets; the whole page scrolls.
- One-click Docker installers and updaters for Windows, macOS and Linux, plus a log collector; manual install for existing servers.

**Fixed**
- A newborn could share an ID with an older child, so one creature flickered: it appeared teen-sized, shrank, vanished and came back, and could not walk to you. New furniture and marks had the same ID problem.
- Changing the camera no longer hides walls or furniture; camera modes switch silently (normal, top, over the shoulder, first person).

**Earlier test builds (2.0–6.x)** added: needs, emotions and moodlets, traits, 16 skills, 7 interactive careers, aspirations and rewards, relationships, marriage with real NPCs who commute between work and home, children who grow up, go to school and move out, a 296-item furniture catalog with real WoW houses, interactive furniture (wardrobe outfits, barber mirror, bank chest, computer, TV, easel…), a Sims clock with day/night, seasons, weather, holidays, bills, illness, a phone and guests, and living NPCs.
