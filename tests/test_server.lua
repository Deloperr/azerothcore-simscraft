ALLOUT = {}
-- Эмулятор Eluna/ALE для SimsCraft 4.0
local SQL = {}
local timeNow = 1000000
os.time = function() return timeNow end
math.randomseed(7)

local function strict(name, t)
    return setmetatable(t, { __index = function(_, k) error(name .. ": нет метода " .. tostring(k), 2) end })
end

local nextGuid = 100
local world = {}   -- guid -> object
local function reg(o) nextGuid = nextGuid + 1; o._guid = nextGuid; world[nextGuid] = o; return o end

local mapObj = strict("Map", {
    IsDungeon = function() return false end, IsRaid = function() return false end,
    IsBattleground = function() return false end, IsArena = function() return false end,
    GetWorldObject = function(_, g) local o = world[g]; if o and not o._removed then return o end end,
})

local nextSpawn = 5000
local function newGO(entry, x, y, z, o, save)
    local go = { _entry = entry, _x = x, _y = y, _z = z, _o = o, _removed = false, _save = save }
    if save then nextSpawn = nextSpawn + 1; go._spawn = nextSpawn else go._spawn = 0 end
    go.GetEntry = function(s) return s._entry end
    go.GetLocation = function(s) return s._x, s._y, s._z, s._o end
    go.RemoveFromWorld = function(s, del) s._removed = true; s._deleted = del end
    go.GetGUIDLow = function(s) return s._guid end
    go.GetGUID = function(s) return s._guid end
    go.GetSpawnId = function(s) return s._spawn end
    go._phase = 1
    go.SetPhaseMask = function(s, m) s._phase = m end
    go.GetPhaseMask = function(s) return s._phase end
    return strict("GO", reg(go))
end

spawned = {}
NEAR_ALL = {}
local function newCreature(entry, name)
    local c = { said = {}, emotes = {}, _entry = entry, _scale = 1, _removed = false, _follow = false, _moved = 0, _emst = false, _home = false, _spawnId = 0 }
    c.GetTypeId = function() return 3 end
    c.GetEntry = function(s) return s._entry end
    c.GetName = function() return name end
    c.GetGUIDLow = function(s) return s._guid end
    c.GetGUID = function(s) return s._guid end
    c.GetGender = function() return 1 end
    c.IsDead = function() return false end
    c.IsInCombat = function() return false end
    c.SendUnitSay = function(s, t) s.said[#s.said + 1] = t; ALLOUT[#ALLOUT + 1] = t end
    c.PerformEmote = function(s, e) s.emotes[#s.emotes + 1] = e end
    c.SetScale = function(s, v) s._scale = v end
    c.MoveFollow = function(s, t) s._follow = t end
    c.DespawnOrUnsummon = function(s) s._removed = true end
    c._x, c._y, c._z, c._o = 15, 25, 30, 0
    c.GetLocation = function(s) return s._x, s._y, s._z, s._o end
    c.GetHomePosition = function(s) return 15, 25, 30, 0 end
    c.IsInEvadeMode = function() return false end
    c.GetCreatureType = function() return 7 end
    c.GetNPCFlags = function() return 0 end
    c.IsTrigger = function() return false end
    c.IsWorldBoss = function() return false end
    c.IsGuard = function() return false end
    c.GetDefaultMovementType = function() return 0 end
    c.GetSpawnId = function(s) return s._spawnId or 0 end
    c.MoveTo = function(s, id, x, y, z) s._x, s._y, s._z = x, y, z; s._moved = (s._moved or 0) + 1 end
    c.MoveHome = function(s) s._home = true end
    c._stand = 0
    c.SetStandState = function(s, v) s._stand = v end
    c.EmoteState = function(s, v) s._emst = v end
    c.SetFacingToObject = function() end
    c.SetFacing = function() end
    c._disp = 1000
    c.GetDisplayId = function(s) return s._disp end
    c.SetDisplayId = function(s, v) s._disp = v end
    c.NearTeleport = function(s, x, y, z) s._x, s._y, s._z = x, y, z end
    c._phase = 1
    c.GetPhaseMask = function(s) return s._phase end
    c.SetPhaseMask = function(s, m) s._phase = m end
    c.SetNPCFlags = function(s, f) s._npcflags = f end
    c.SetWalk = function(s, w) s._walk = w end
    c.IsMoving = function() return false end
    c.GetMapId = function() return 0 end
    c.GetInstanceId = function() return 0 end
    c.GetCreaturesInRange = function() return NEAR_ALL end
    c.GetGameObjectsInRange = function() local out = {} for _, g in ipairs(spawned) do if not g._removed then out[#out + 1] = g end end return out end
    c.GetDistance = function(s, o) local x, y = o:GetLocation(); return math.sqrt((s._x - x) ^ 2 + (s._y - y) ^ 2) end
    return strict("Creature", reg(c))
end

local function newPlayer(guidLow, account, name)
    local p = { _money = 100000000, _stand = 0, _combat = false, _water = false, _group = false, _moving = false,
        _hp = 1000, _max = 1000, _sel = nil, _msgs = {}, _addon = {}, _gm = false,
        _x = 10, _y = 20, _z = 30, _o = 0, _level = 80, _gender = 1, _race = 1 }
    p.GetGUIDLow = function() return guidLow end
    p.GetGUID = function() return guidLow end
    p.GetAccountId = function() return guidLow end
    p.GetAccountName = function() return account end
    p.GetName = function() return name end
    p.GetTypeId = function() return 4 end
    p.GetEntry = function() return 0 end
    p.GetGender = function(s) return s._gender end
    p.GetRace = function(s) return s._race end
    p.GetDbLocaleIndex = function(s) return rawget(s, "_loc") or 8 end
    p.SendBroadcastMessage = function(s, m) s._msgs[#s._msgs + 1] = m; ALLOUT[#ALLOUT + 1] = m end
    p.SendAddonMessage = function(s, pre, m, ch, rcv) assert(pre == "SIMSC" and ch == 7 and rcv == s); assert(#m + #pre < 255, "длинное сообщение: " .. m); s._addon[#s._addon + 1] = m; ALLOUT[#ALLOUT + 1] = m end
    p.SendAreaTriggerMessage = function(s, m) s._msgs[#s._msgs + 1] = "AT:" .. m; ALLOUT[#ALLOUT + 1] = m end
    p.SendUnitEmote = function(s, m) s._msgs[#s._msgs + 1] = "EMOTE:" .. m end
    p.PerformEmote = function() end
    p.IsDead = function() return false end
    p.IsGM = function(s) return s._gm end
    p.GetGMRank = function(s) return s._gm and 3 or 0 end
    p.InBattleground = function() return false end
    p.InArena = function() return false end
    p.IsInCombat = function(s) return s._combat end
    p.GetStandState = function(s) return s._stand end
    p.SetStandState = function(s, v) s._stand = v end
    p.IsMoving = function(s) return s._moving end
    p.IsInWater = function(s) return s._water end
    p.IsInGroup = function(s) return s._group end
    p.GetHealthPct = function(s) return s._hp / s._max * 100 end
    p.GetHealth = function(s) return s._hp end
    p.GetMaxHealth = function(s) return s._max end
    p.SetHealth = function(s, v) s._hp = v end
    p.SetSpeed = function() end
    p.IsMounted = function() return false end
    p.IsFlying = function() return false end
    p.ModifyMoney = function(s, v) s._money = s._money + v end
    p.GetCoinage = function(s) return s._money end
    p.GetLevel = function(s) return s._level end
    p.GetSelection = function(s) return s._sel end
    p.GetDistance = function(s, o) local x, y = o:GetLocation(); return math.sqrt((s._x - x) ^ 2 + (s._y - y) ^ 2) end
    p.Say = function() end
    p.SetRooted = function() end
    p._events = {}
    p.RegisterEvent = function(s, fn, delay, rep) s._events[#s._events + 1] = { fn, delay, rep } end
    p._fields = {}
    p.SetUInt32Value = function(s, i, v) s._fields[i] = v end
    p.GetEquippedItemBySlot = function(s, slot) return { GetEntry = function() return 1000 + slot end } end
    p._packets = {}
    p.GetUInt32Value = function(s, i) return s._fields[i] or (i >= 283 and i <= 320 and (i - 283) % 2 == 0 and 1000 + (i - 283) / 2 or 0) end
    p.SendShowBank = function(s, o) s._bank = true end
    p._items = {}
    p.AddItem = function(s, e, c) s._items[e] = (s._items[e] or 0) + (c or 1); return {} end
    p.EmoteState = function(s, e) s._emst = e end
    p.SetFacingToObject = function() end
    p.SendPacket = function(s, pk) s._packets[#s._packets + 1] = pk end
    p.GetPlayersInRange = function() return {} end
    p.GetMap = function() return mapObj end
    p.GetInstanceId = function() return 0 end
    p.GetMapId = function() return 0 end
    p.GetLocation = function(s) return s._x, s._y, s._z, s._o end
    p.NearTeleport = function(s, x, y, z) s._x, s._y, s._z = x, y, z end
    p.GetGameObjectsInRange = function(s, r, entry)
        local out = {}
        for _, g in ipairs(spawned) do if g._entry == entry and not g._removed then out[#out + 1] = g end end
        return out
    end
    p.SpawnCreature = function(s, entry, x, y, z, o)
        local c = newCreature(entry, CNAMES[entry] or "Ребёнок")
        c._x, c._y, c._z = x, y, z
        return c
    end
    p._near = {}
    p.GetCreaturesInRange = function(s, r, entry)
        local out = {}
        for _, c in ipairs(s._near) do if (not entry or entry == 0 or c._entry == entry) and not c._removed then out[#out + 1] = c end end
        return out
    end
    p.GetDisplayId = function() return 55 end
    p.Teleport = function(s, m, x, y, z, o) s._tp = { m, x, y, z, o } end
    p.GossipClearMenu = function(s) s._gossip = {} end
    p.GossipMenuAddItem = function(s, icon, text, sender, intid)
        ALLOUT[#ALLOUT + 1] = text
        assert(type(text) == "string" and type(sender) == "number" and type(intid) == "number")
        s._gossip[#s._gossip + 1] = { text = text, sender = sender, intid = intid }
    end
    p.GossipSendMenu = function(s, txt, sender, menu) assert(txt == 190100); s._menu = menu end
    p.GossipComplete = function() end
    return strict("Player", reg(p))
end

local players = {}
local byName = {}
function GetPlayersInWorld() return players end
function GetPlayerByName(n) return byName[n] end
local maxId = 0
function CharDBQuery(sql)
    SQL[#SQL + 1] = sql
    if sql:match("information_schema") then return {} end
    if sql:match("MAX%(id%)") then
        maxId = maxId + 1
        local v = maxId
        return { GetUInt32 = function() return v end, NextRow = function() return false end }
    end
    return nil
end
function CharDBExecute(sql) SQL[#SQL + 1] = sql end
CNAMES = { [6740] = "Трактирщица Эллисон" }
function CreatePacket(op, size)
    local pk = { op = op, data = {} }
    pk.WriteULong = function(s, v) s.data[#s.data + 1] = v end
    pk.WriteFloat = function(s, v) s.data[#s.data + 1] = v end
    pk.WriteUByte = function(s, v) s.data[#s.data + 1] = v end
    return pk
end
function GetMapById() return mapObj end
function WorldDBQuery(sql)
    assert(not sql:match("id1 ="), "запрос к id1 без проверки")
    if sql:match("information_schema") then return nil end
    if sql:match("JOIN creature_template") then
        local r = { 0, 900, 900, 30, "Трактирщица Аллен" }
        return { GetUInt32 = function(_, c) return r[c + 1] end, GetFloat = function(_, c) return r[c + 1] end,
            GetString = function(_, c) return r[c + 1] end, NextRow = function() return false end }
    end
    if sql:match("FROM creature WHERE") then
        local r = { 777, 0, 15, 25, 30, 0 }
        return { GetUInt32 = function(_, c) return r[c + 1] end, GetFloat = function(_, c) return r[c + 1] end, NextRow = function() return false end }
    end
    local rows = { { 117, 11, 5 }, { 159, 59, 5 }, { 33449, 11, 75 } }
    local i = 1
    return { GetUInt32 = function(_, c) return rows[i][c + 1] end, NextRow = function() i = i + 1; return rows[i] ~= nil end }
end
local ev = { player = {}, server = {}, cg = {}, gg = {} }
local itemHandler, tickFn
function RegisterPlayerEvent(id, fn) ev.player[id] = fn end
function RegisterServerEvent(id, fn) ev.server[id] = fn end
function RegisterPlayerGossipEvent(menu, id, fn) ev.pg = fn end
function RegisterItemEvent(e, id, fn) itemHandler = fn end
function RegisterCreatureGossipEvent(e, id, fn) ev.cg[e] = ev.cg[e] or {}; ev.cg[e][id] = fn end
function RegisterGameObjectGossipEvent(e, id, fn) ev.gg[e] = ev.gg[e] or {}; ev.gg[e][id] = fn end
local fastFn
function CreateLuaEvent(fn, ms) if ms == 2500 then fastFn = fn else tickFn = fn end end
function PerformIngameSpawn(t, entry, map, inst, x, y, z, o, save)
    if t == 2 then local g = newGO(entry, x, y, z, o, save); spawned[#spawned + 1] = g; return g end
    return {}
end

setmetatable(_G, { __index = function(_, k) error("undefined global " .. tostring(k), 2) end })
dofile(arg[1])
local function check(cond, text) if not cond then error("ПРОВАЛ: " .. text, 2) end print("  ок: " .. text) end
local function last(t) return t[#t] end
local function addon(p, text) return ev.server[30](30, p, 7, "SIMSC", text, p) end
local function findAddon(p, pat) for i = #p._addon, 1, -1 do if p._addon[i]:match(pat) then return p._addon[i] end end end
local function lastMsg(p, pat) for i = #p._msgs, 1, -1 do if p._msgs[i]:match(pat) then return p._msgs[i] end end end
local function cmd(p, c) return ev.player[42](42, p, c) end
local function gm(p, c) p._gm = true; cmd(p, c); p._gm = false end
local function runEvents(p) local e = p._events; p._events = {}; for _, x in ipairs(e) do x[1](1, x[2], x[3], p) end end
local function fast(n, step) for _ = 1, n do timeNow = timeNow + (step or 3); fastFn() end end
local function alive(entry) local l = {} for _, o in pairs(world) do if rawget(o, "_entry") == entry and rawget(o, "said") and not o._removed then l[#l + 1] = o end end return l end
local function buyAt(p, cat, kind, x, y)
    local idx
    for _, m in ipairs(p._addon) do
        local i, c, k = m:match("^C;(%d+);(%w+);%d+;[^;]*;(%w*)$")
        if i and c == cat and (not kind or k == kind) and not idx then idx = i end
    end
    assert(idx, "нет предмета " .. cat .. "/" .. tostring(kind))
    p._x, p._y = x, y
    addon(p, "BUY;" .. idx); addon(p, "PM;here;0"); addon(p, "PO")
    return spawned[#spawned]
end

print("== Загрузка и игровые часы")
local p = newPlayer(1, "TEST", "Анна")
players[1] = p; byName["Анна"] = p
ev.player[3](3, p)
runEvents(p)
check(findAddon(p, "^S;"), "HUD")
check(findAddon(p, "^T;%d+;30.000;%d$"), "часы в HUD: " .. findAddon(p, "^T;"))
local pk
for _, x in ipairs(p._packets) do if x.op == 0x042 and not pk then pk = x end end
check(pk and pk.op == 0x042 and math.abs(pk.data[2] - 0.5) < 1e-6, "небо клиента: скорость 0.5 игровой минуты в секунду")
gm(p, "sims time 20:00")
check(lastMsg(p, "Игровое время: 20:00"), "ГМ перевёл часы на 20:00")
local sky
for _, x in ipairs(p._packets) do if x.op == 0x042 then sky = x end end
check(sky.data[1] % 64 == 0 and math.floor(sky.data[1] / 64) % 32 == 20, "небо: 20:00")

print("== Каталог")
addon(p, "CAT")
local ci = 0
for _, m in ipairs(p._addon) do if m:match("^C;") then ci = ci + 1 end end
check(ci == 296, "предметов: " .. ci)

print("== Отношения: лимиты в игровых сутках")
gm(p, "sims time 01:00")
local npc = newCreature(6740, "Трактирщица Эллисон")
npc._spawnId = 777
p._near = { npc }
NEAR_ALL = { npc }
p._x, p._y = 12, 22
p._sel = npc
timeNow = timeNow + 5; addon(p, "SOC;talk")
for i = 1, 12 do timeNow = timeNow + 61; addon(p, "SOC;talk") end
local rel = findAddon(p, "^R;")
check(rel:match("^R;Трактирщица Эллисон;20;0;.-;20;0;20;12$"), "дружба 20 за игровые сутки: " .. rel)
timeNow = timeNow + 300; addon(p, "SOC;flirt")
timeNow = timeNow + 700; addon(p, "SOC;date")
check(lastMsg(p, "знакомы слишком недавно") or lastMsg(p, "романтики"), "рано встречаться")

print("== Брак с настоящим NPC")
gm(p, "sims relset 80 95")
gm(p, "sims partner married")
check(lastMsg(p, "Статус с Трактирщица Эллисон: married"), "женаты")

print("== Дом")
local house = buyAt(p, "house", nil, 100, 100)
check(house._entry >= 600000 and lastMsg(p, "новосельем"), "дом куплен")
local bed = buyAt(p, "bedroom", "bed", 103, 100)
local bed2 = buyAt(p, "bedroom", "bed", 106, 100)
local tub = buyAt(p, "bath", "tub", 100, 104)
local toilet = buyAt(p, "bath", "toilet", 101, 106)
buyAt(p, "fun", "toy", 98, 97)
p._x, p._y = 100, 100

print("== Супруга идёт домой сама, без двойников")
gm(p, "sims time 19:00")
fast(1)
check(npc._phase == 2, "на работе её больше нет (ушла домой)")
local tw = alive(6740)
local twin
for _, c in ipairs(tw) do if c ~= npc then twin = c end end
check(twin and twin:GetName() == "Трактирщица Эллисон", "дома — она сама (то же имя и NPC)")
check(twin._npcflags == 1, "дома не торгует, а разговаривает")
fast(3)
check(#twin.said > 0, "пришла и сказала: " .. table.concat(twin.said, " | "))
ev.cg[6740][1](1, p, twin)
check(#p._gossip >= 5, "меню супруги дома")
p._gossip = {}
check(ev.cg[6740][1](1, p, npc) == nil, "у настоящей на работе обычное меню")
p._sel = twin
timeNow = timeNow + 1000; addon(p, "SOC;kiss")
check(findAddon(p, "^R;Трактирщица Эллисон;"), "общение дома — с ней же")

print("== Дети")
gm(p, "sims fast")
addon(p, "TRACE;3")   -- аддон узнал: супруга — дворф
check(SQL[#SQL]:match("race:.-'3'"), "раса супруги запомнена: " .. SQL[#SQL])
local born = 0
for i = 1, 30 do
    timeNow = timeNow + 2000; addon(p, "SOC;baby"); runEvents(p); runEvents(p)
    if lastMsg(p, "Малыш появится") then gm(p, "sims birth"); tickFn(); born = born + 1; p._msgs = {} end
    if born >= 2 then break end
end
check(born == 2, "родилось двое детей")
local ids, races = {}, {}
for _, q in ipairs(SQL) do
    local id, grp = q:match("INSERT INTO character_sims_children %(id, guid, name, gender, grp.-VALUES %((%d+), %d+, '[^']*', %d, (%d+)")
    if id then check(not ids[id], "у каждого ребёнка свой id: " .. id); ids[id] = true; races[#races + 1] = tonumber(grp) end
end
check(#races == 2 and (races[1] == 101 or races[1] == 103) and (races[2] == 101 or races[2] == 103), "раса детей — одного из родителей: " .. table.concat(races, ","))
gm(p, "sims age 4")
check(lastMsg(p, "Ребёнок"), "выросли до «Ребёнок»")
gm(p, "sims time 17:00")
fast(2)
local kids = {}
for e = 190110, 190119 do for _, c in ipairs(alive(e)) do kids[#kids + 1] = c end end
check(#kids == 2, "дети играют у дома: " .. #kids)
for i = 1, 40 do fast(1, 4) end
local moved = 0
for _, c in ipairs(kids) do moved = moved + (c._moved or 0) end
check(moved >= 6, "дети бегают и играют: перемещений " .. moved)
for _, c in ipairs(kids) do print("   " .. table.concat(c.said, " | "):sub(1, 260)) end

p._sel = kids[1]
addon(p, "REL")
local kr = findAddon(p, "^R;")
check(kr:match("Ваш") and kr:match(";60;"), "ребёнок — «ваш сын/дочь», не «знакомый»: " .. kr)
timeNow = timeNow + 1000; addon(p, "SOC;flirt")
check(lastMsg(p, "Это ваш ребёнок"), "флирт с ребёнком запрещён")
local stranger = newCreature(1500, "Сирота Мэри")
p._sel = stranger
stranger._x, stranger._y = 101, 101
timeNow = timeNow + 1000; addon(p, "SOC;kiss")
check(lastMsg(p, "Это ребёнок"), "и с чужими детьми тоже")

p._gossip = {}
ev.cg[kids[1]._entry][1](1, p, kids[1])
check(#p._gossip >= 3, "меню ребёнка по ПКМ: " .. #p._gossip)
ev.cg[kids[1]._entry][2](2, p, kids[1], 1, 2)
check(lastMsg(p, "Обнять: "), "обнять ребёнка")
addon(p, "FAM;")
check(findAddon(p, "^FK;[^;]*;[^;]*;%d;%d;%d+;%d+;2;"), "в семье: ребёнок дома")
print("== Ночь: все в кроватях")
gm(p, "sims time 23:30")
fast(12, 4)
for _, c in ipairs(alive(6740)) do if c ~= npc then twin = c end end
check(twin._stand == 3, "супруга спит в кровати")
local inBed = 0
for _, c in ipairs(kids) do if c._stand == 3 then inBed = inBed + 1 end end
check(inBed == 2, "оба ребёнка спят: " .. inBed)
check(math.abs(kids[1]._x - bed2._x) < 1 or math.abs(kids[2]._x - bed2._x) < 1, "ребёнок в своей кровати")

print("== Утро и работа")
gm(p, "sims time 08:00")
fast(4, 4)
check(twin._stand ~= 3, "супруга проснулась")
gm(p, "sims time 10:00")
fast(1)
check(lastMsg(p, "") and #twin.said > 0, "супруга: " .. twin.said[#twin.said])
fast(5, 3)
check(twin._removed, "ушла на работу")
check(npc._phase == 1, "и стоит на своём месте")

print("== Позвать и отправить домой")
gm(p, "sims time 17:30")
fast(3)
kids = {}
for e = 190110, 190119 do for _, c in ipairs(alive(e)) do kids[#kids + 1] = c end end
addon(p, "FAM;call")
local fol = 0
for _, c in ipairs(kids) do if c._follow and not c._removed then fol = fol + 1 end end
check(fol == 2, "дети идут за вами")
addon(p, "FAM;home")
check(not kids[1]._removed, "у дома — идут играть, а не исчезают")
p._x = 1000
addon(p, "FAM;call")
local far = {}
for e = 190110, 190119 do for _, c in ipairs(alive(e)) do far[#far + 1] = c end end
addon(p, "FAM;home")
check(lastMsg(p, "Дети пошли домой"), "далеко — уходят пешком")
fast(4, 3)
local still = 0
for _, c in ipairs(far) do if not c._removed then still = still + 1 end end
check(still == 0, "дошли и скрылись")
p._x = 100

print("== Ванна и туалет")
ev.gg[tub._entry][1](1, p, tub)
check(p._fields[283 + 4 * 2] == 0 and p._fields[283 + 6 * 2] == 0, "без одежды (в белье)")
local foam
for _, g in ipairs(spawned) do if g._entry == 600990 and not g._removed then foam = g end end
check(foam, "пена в ванне")
check(p._x == tub._x, "в самой ванне")
runEvents(p)
check(p._fields[283 + 4 * 2] == 1004, "одежда вернулась")
check(foam._removed, "пена исчезла")
ev.gg[toilet._entry][1](1, p, toilet)
check(p._x == toilet._x and p._y == toilet._y and p._stand == 5, "сидит на унитазе")
runEvents(p)
check(lastMsg(p, "облегчение"), "туалет")

print("== Взрослые дети")
gm(p, "sims age 20")
fast(2)
local adult = 0
for e = 190110, 190119 do for _, c in ipairs(alive(e)) do if c._disp ~= 1000 and c._scale == 1 then adult = adult + 1 end end end
check(adult >= 1, "выросли — взрослая модель")
for e = 190110, 190119 do for _, c in ipairs(alive(e)) do
    local info
    for _, k in ipairs({}) do end
end end

print("== Вечер и ночь в городе")
local a1, a2, a3 = newCreature(1001, "Горожанин"), newCreature(1002, "Горожанка"), newCreature(1003, "Фермер")
a1._spawnId, a2._spawnId, a3._spawnId = 1, 2, 3
p._near = { a1, a2, a3 }
NEAR_ALL = { a1, a2, a3 }
gm(p, "sims time 23:30")
for i = 1, 30 do timeNow = timeNow + 3; fastFn(); if i % 7 == 0 then tickFn() end end
local hidden = 0
for _, c in ipairs({ a1, a2, a3 }) do if c._phase == 2 then hidden = hidden + 1 end end
check(hidden >= 1, "ночью NPC ушли по домам: " .. hidden)
gm(p, "sims time 09:00")
for i = 1, 20 do timeNow = timeNow + 3; fastFn() end
local back = 0
for _, c in ipairs({ a1, a2, a3 }) do if c._phase == 1 then back = back + 1 end end
check(back == 3, "утром вышли обратно")


print("== 5.0: шкаф, зеркало, сундук")
p._x, p._y = 100, 100
local wardrobe = buyAt(p, "bedroom", "wardrobe", 102, 98)
ev.gg[wardrobe._entry][1](1, p, wardrobe)
check(p._menu == 19010 and #p._gossip >= 8, "меню гардероба")
ev.pg(2, p, p, 50, 4)
check(p._fields[283 + 4 * 2] == 22276, "нарядное платье (у персонажа женский пол)")
check(p._fields[283 + 15 * 2] == 0, "оружие в наряде не видно")
ev.pg(2, p, p, 50, 21)
ev.pg(2, p, p, 50, 99)
check(p._fields[283 + 4 * 2] == 1004, "снова своя экипировка")
ev.pg(2, p, p, 50, 11)
check(p._fields[283 + 4 * 2] == 22276, "свой сохранённый наряд")
local chest = buyAt(p, "bedroom", "chest", 101, 97)
ev.gg[chest._entry][1](1, p, chest)
check(p._bank, "сундук открывает банк")
local vanity = buyAt(p, "bedroom", "vanity", 99, 96)
ev.gg[vanity._entry][1](1, p, vanity)
ev.pg(2, p, p, 51, 1)
local stool
for _, g in ipairs(spawned) do if g._entry == 601010 and not g._removed then stool = g end end
check(stool and p._stand == 6 and p._packets[#p._packets].op == 0x427, "зеркало: кресло парикмахера и окно причёсок")
runEvents(p)

print("== 5.0: встроенная мебель дома (метки)")
p._x, p._y = 101, 102
addon(p, "SPOT;stove")
check(lastMsg(p, "Отмечено"), "плита отмечена")
p._x, p._y = 104, 104
addon(p, "SPOT;bed")
p._x, p._y = 104.5, 104
p._stand = 0
ev.player[24](24, p, 87, 0, 0)
check(p._stand == 3 and p._x == 104, "/sleep у встроенной кровати — спит в ней")
p._stand = 0
p._x, p._y = 101.5, 102
p._gm = true; cmd(p, "sims set hunger 10"); p._gm = false
addon(p, "USE")
runEvents(p)
check(lastMsg(p, "приготовили") or lastMsg(p, "изысканное"), "«Действие» у встроенной плиты")
p._x, p._y = 300, 300

print("== 5.0: работа — добыча магических материалов")
local keeper = newCreature(190100, "Хранитель жизни")
ev.cg[190100][2](2, p, keeper, 3, 103)
check(lastMsg(p, "Магия"), "устроились магом")
p._gm = true; cmd(p, "sims fill"); p._gm = false
addon(p, "WORK")
local crystals = {}
for _, g in ipairs(spawned) do if g._entry == 601000 and not g._removed then crystals[#crystals + 1] = g end end
check(#crystals == 5, "вокруг 5 кристаллов")
for _, g in ipairs(crystals) do ev.gg[601000][1](1, p, g); timeNow = timeNow + 4; runEvents(p) end
local circle
for _, g in ipairs(spawned) do if g._entry == 601006 and not g._removed then circle = g end end
check(circle, "появился рунный круг")
ev.gg[601006][1](1, p, circle)
check(p._items[10940] and p._items[10940] > 0, "получена магическая пыль: " .. tostring(p._items[10940]))
check(lastMsg(p, "все задания выполнены"), "смена закрыта")

print("== 5.0: взрослый ребёнок переезжает")
gm(p, "sims age 30")
tickFn()
check(lastMsg(p, "переехал"), "переехал(а): " .. tostring(lastMsg(p, "переехал")))
addon(p, "FAM;")
check(findAddon(p, "^FK;.*;3;у таверны"), "в семье: живёт своей семьёй")
p._x, p._y = 905, 905
fast(2)
local partner
for _, o in pairs(world) do if (rawget(o, "_entry") == 190120 or rawget(o, "_entry") == 190121) and not o._removed and o._npcflags == 0 then partner = o end end
check(partner, "в гостях: ребёнок со своей половинкой")
p._x, p._y = 100, 100

print("== 6.0: романтический вечер в спальне")
p._x, p._y = 100, 100
gm(p, "sims time 20:00")
fast(3)
local sp2
for _, c in ipairs(alive(6740)) do if c ~= npc then sp2 = c end end
check(sp2, "супруга дома")
p._sel = sp2
timeNow = timeNow + 4000
addon(p, "SOC;woohoo")
check(lastMsg(p, "уходите в спальню"), "идут в спальню")
runEvents(p)
check(p._stand == 3 and p._fields[283 + 4 * 2] == 0, "в кровати, в белье")
local haze
for _, g in ipairs(spawned) do if g._entry == 601011 and not g._removed then haze = g end end
check(haze, "над кроватью дымка")
runEvents(p)
check(haze._removed and p._stand == 0, "дымка ушла, встали")
check(findAddon(p, "^E;2;"), "эмоция «Счастлив»: " .. tostring(findAddon(p, "^E;")))

print("== 6.0: навыки, стремление, награды")
p._x, p._y = 300, 300
local easel = buyAt(p, "fun", "easel", 302, 300)
for i = 1, 3 do ev.gg[easel._entry][1](1, p, easel); timeNow = timeNow + 20; runEvents(p) end
check(lastMsg(p, "продана"), "картина продана")
check(findAddon(p, "^SK;.*5:%d+:%d+"), "навык живописи в панели: " .. tostring(findAddon(p, "^SK")))
local keeper2 = newCreature(190100, "Хранитель жизни")
ev.cg[190100][2](2, p, keeper2, 1, 9)
check(p._menu == 19010, "меню стремлений")
ev.pg(2, p, p, 60, 6)
check(lastMsg(p, "Стремление: |cffffd100Творец"), "выбрано стремление «Творец»")
gm(p, "sims skill painting 3")
check(lastMsg(p, "этап 1 из 3"), "этап стремления выполнен")
ev.pg(2, p, p, 60, 103)
check(lastMsg(p, "Награда получена"), "награда куплена")

print("== 6.0: компьютер, ТВ, кладовая, торт")
local comp = buyAt(p, "living", "computer", 304, 300)
ev.gg[comp._entry][1](1, p, comp)
ev.pg(2, p, p, 53, 1); timeNow = timeNow + 20; runEvents(p)
check(lastMsg(p, "Гоблинских гонках"), "игра на компьютере")
local tv = buyAt(p, "living", "tv", 305, 302)
ev.gg[tv._entry][1](1, p, tv)
ev.pg(2, p, p, 54, 1); timeNow = timeNow + 20; runEvents(p)
local fr = buyAt(p, "kitchen", "fridge", 306, 302)
ev.gg[fr._entry][1](1, p, fr)
ev.pg(2, p, p, 55, 3); timeNow = timeNow + 20; runEvents(p)
check(lastMsg(p, "Чай"), "чай из кладовой")

print("== 6.0: счета, свет, погода, телефон")
local st1 = nil
timeNow = timeNow + 2880 * 8
tickFn()
addon(p, "PHONE")
check(p._menu == 19010, "телефон открыт")
ev.pg(2, p, p, 58, 3); runEvents(p)
check(lastMsg(p, "пицца"), "пицца доставлена")
local wpk
for _, x in ipairs(p._packets) do if x.op == 0x2F4 then wpk = x end end
check(wpk, "погода отправлена клиенту")
check(findAddon(p, "^W;%d;%d;"), "сезон и погода в панели: " .. tostring(findAddon(p, "^W;")))
print("== 1.0: английский клиент")
local e = newPlayer(2, "TEST2", "John")
e._loc = 0
players[2] = e; byName["John"] = e
ev.player[3](3, e)
runEvents(e)
cmd(e, "sims help"); cmd(e, "sims"); addon(e, "PHONE")
addon(e, "LOC;enUS"); addon(e, "SYNC")
local cyr = {}
for _, m in ipairs(e._msgs) do if m:find("[\208\209]") then cyr[#cyr + 1] = m end end
for _, m in ipairs(e._addon) do if m:find("[\208\209]") then cyr[#cyr + 1] = "ADDON " .. m end end
for _, g in ipairs(rawget(e, "_gossip") or {}) do if g.text:find("[\208\209]") then cyr[#cyr + 1] = "GOSSIP " .. g.text end end
print("   пунктов меню телефона: " .. #(rawget(e, "_gossip") or {}) .. ", первый: " .. tostring(((rawget(e, "_gossip") or {})[1] or {}).text))
for _, m in ipairs(cyr) do print("   RU:", m) end
check(#cyr == 0, "английскому игроку — всё по-английски (" .. #e._msgs .. " сообщений)")
print("   " .. (e._msgs[1] or "") .. " | " .. (e._msgs[#e._msgs] or ""))
check(lastMsg(p, "[\208\209]"), "русскому игроку — по-русски")
print("== Выход")
ev.player[4](4, p)
check(npc._phase == 1, "настоящая супруга на своём месте")
print("\nВсе проверки v6 пройдены. SQL-запросов: " .. #SQL)

-- ПЕРЕВОД: всё, что ушло игроку, переводится на английский без русских остатков
local left, seen = {}, {}
for _, t in ipairs(ALLOUT) do
    local e = SimsCraftTranslate(t)
    local plain = e:gsub("Трактирщица Эллисон", ""):gsub("Тест", "")
    if plain:find("[\208\209]") and not seen[e] then seen[e] = true; left[#left + 1] = e end
end
print("Translation: " .. #ALLOUT .. " phrases, with Russian leftovers (NPC/player names from the mock DB): " .. #left)
if os.getenv("VERBOSE") then for i = 1, math.min(#left, 60) do print("  RU> " .. left[i]) end end
