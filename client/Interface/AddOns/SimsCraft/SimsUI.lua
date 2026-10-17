local LS = SimsCraftLS or function(s) return s end   -- перевод (Locale.lua)
-- SimsCraft 1.0.0: нижняя панель, собранная из блоков (порядок и вид — в настройках аддона):
--   [рамка персонажа: портрет, здоровье, мана, эмоция] [панели действий WoW без грифонов, доп. панели над ними]
--   [меню и сумки + блок SimsCraft] [рамка цели: здоровье, мана, портрет, отношения и действия].
--   Настройки: Интерфейс → Модификации → SimsCraft, или /scui config. Кнопка у миникарты ездит по краю карты.

local A = SimsCraftAPI
if not A then return end
local send = A.send

BINDING_HEADER_SIMSCRAFT = "SimsCraft"
BINDING_NAME_SIMSCRAFT_TOGGLE = LS"Окно SimsCraft"
BINDING_NAME_SIMSCRAFT_USE = LS"Действие (ближайшая мебель)"
BINDING_NAME_SIMSCRAFT_PHONE = LS"Телефон"

local EMOS = {
    { LS"Спокоен", 0.85, 0.85, 0.85 }, { LS"Счастлив", 0.55, 1.00, 0.30 }, { LS"Энергичен", 1.00, 0.65, 0.20 },
    { LS"Флиртует", 1.00, 0.45, 0.75 }, { LS"Сосредоточен", 0.35, 0.60, 1.00 }, { LS"Вдохновлён", 0.30, 0.90, 1.00 },
    { LS"Уверен", 0.30, 0.45, 1.00 }, { LS"Игрив", 1.00, 0.90, 0.25 }, { LS"Грустит", 0.40, 0.50, 0.80 },
    { LS"Зол", 1.00, 0.25, 0.25 }, { LS"Напряжён", 1.00, 0.55, 0.25 }, { LS"Смущён", 1.00, 0.45, 0.65 },
    { LS"Неуютно", 0.70, 0.50, 0.25 }, { LS"Скучает", 0.60, 0.60, 0.60 }, { LS"В оцепенении", 0.75, 0.50, 1.00 },
}
local EMO_LOW = { LS"спокоен", LS"счастлив", LS"энергичен", LS"флиртует", LS"сосредоточен", LS"вдохновлён", LS"уверен", LS"игрив",
    LS"грустит", LS"зол", LS"напряжён", LS"смущён", LS"неуютно", LS"скучает", LS"в оцепенении" }
local SKILLS = {
    { LS"Кулинария", "INV_Misc_Food_15" }, { LS"Фитнес", "Ability_Warrior_Charge" }, { LS"Логика", "INV_Misc_Book_11" },
    { LS"Обаяние", "Spell_Holy_PrayerOfSpirit" }, { LS"Живопись", "INV_Inscription_Pigment_Bug07" }, { LS"Музыка", "INV_Misc_Drum_04" },
    { LS"Писательство", "INV_Inscription_Papyrus" }, { LS"Программирование", "INV_Misc_Gear_01" }, { LS"Мастерство", "Trade_Engineering" },
    { LS"Садоводство", "INV_Misc_Herb_01" }, { LS"Рыбалка", "Trade_Fishing" }, { LS"Барменство", "INV_Drink_04" },
    { LS"Комедия", "Spell_Shadow_Charm" }, { LS"Танцы", "Spell_Holy_Restoration" }, { LS"Озорство", "Ability_Rogue_Disguise" },
    { LS"Видеоигры", "INV_Gizmo_02" },
}
local ASPS = { LS"Мастер кулинарии", LS"Любящий родитель", LS"Душа компании", LS"Романтик", LS"Богатство", LS"Творец", LS"Учёный", LS"Атлет", LS"Садовод" }
local SEASONS = { LS"Весна", LS"Лето", LS"Осень", LS"Зима" }
local STATUS = { dating = LS"встречаетесь", married = LS"супруги", ex = LS"бывшие", child = LS"ваш ребёнок" }
local NEED_ICON = { hunger = "INV_Misc_Food_15", energy = "Spell_Nature_Sleep", hygiene = "Spell_Frost_SummonWaterElemental",
    fun = "INV_Misc_Toy_10", social = "Achievement_Reputation_01", bladder = "INV_Drink_05" }

local data = { emo = 1, emoI = 1, moodlets = {}, skills = {}, asp = 0, aspStage = 0, sp = 0, aspLines = {}, rel = {}, world = {} }

local function fs(parent, font, layer)
    return parent:CreateFontString(nil, layer or "OVERLAY", font or "GameFontHighlightSmall")
end
local function wowBar(parent, w, h, r, g, b)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetWidth(w); bar:SetHeight(h)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(r, g, b)
    bar:SetMinMaxValues(0, 100)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar); bg:SetTexture(0, 0, 0, 0.6)
    local border = CreateFrame("Frame", nil, bar)
    border:SetPoint("TOPLEFT", -3, 3); border:SetPoint("BOTTOMRIGHT", 3, -3)
    border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    border:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    bar.label = fs(bar); bar.label:SetPoint("LEFT", 3, 0)
    bar.value = fs(bar); bar.value:SetPoint("RIGHT", -3, 0)
    return bar
end
local function iconButton(parent, icon, tip, onClick, size)
    local b = CreateFrame("Button", nil, parent)
    size = size or 30
    b:SetWidth(size); b:SetHeight(size)
    local t = b:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints(b); t:SetTexture("Interface\\Icons\\" .. icon)
    b.icon = t
    local nt = b:CreateTexture(nil, "OVERLAY")
    nt:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    nt:SetWidth(size * 1.8); nt:SetHeight(size * 1.8)
    nt:SetPoint("CENTER", 0, 0)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(tip, 1, 1, 1, true); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end
local function gameHours(leftReal)
    local h = leftReal * ((A.clock and A.clock.speed) or 30) / 3600
    if h >= 1 then return math.floor(h + 0.5) .. LS" ч" end
    return math.max(1, math.floor(h * 60)) .. LS" мин"
end

---------------------------------------------------------------------
-- НИЖНЯЯ ПАНЕЛЬ: [рамка игрока] [панели действий WoW] [цель] [SimsCraft] — порядок и вид меняются в настройках
---------------------------------------------------------------------
local DEFAULT_LAYOUT = {
    order = { "player", "wow", "menu", "sims", "target" },
    show = { player = true, wow = true, menu = true, sims = true, target = true },
    stack = { sims = true },          -- блок SimsCraft — в одном столбце с меню, поверх него
    scale = 1.0, x = 0, y = 0, enabled = true, lock = true,
    hideGryphons = true, hideBlizzFrames = true, moveChat = true, bar3 = false, bar4 = false, rowsSwap = false, portrait3d = false,
    style = 1, border = 1, alpha = 0.85, barTex = 1, barText = 1, hpColor = 1, gap = 4, bigNames = false,
}
local function L() return SimsCraftDB.layout end
local function initLayout()
    SimsCraftDB.layout = SimsCraftDB.layout or {}
    local l = SimsCraftDB.layout
    for k, v in pairs(DEFAULT_LAYOUT) do
        if l[k] == nil then
            if type(v) == "table" then l[k] = {}; for a, b in pairs(v) do l[k][a] = b end else l[k] = v end
        end
    end
end

local SEG_BACK = { bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } }

local root = CreateFrame("Frame", "SimsCraftUI", UIParent, "SecureHandlerStateTemplate")
root:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
root:SetWidth(100); root:SetHeight(80)
local segs = {}
local function segment(key, w, h, secure)
    local f = CreateFrame(secure and "Button" or "Frame", "SimsCraftSeg_" .. key, root, secure and "SecureUnitButtonTemplate" or nil)
    f:SetWidth(w); f:SetHeight(h)
    f:SetBackdrop(SEG_BACK)
    f:SetBackdropColor(0.03, 0.03, 0.05, 0.85)
    f:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.9)
    f.key = key
    f.w, f.h, f.padL, f.padR = w, h, 0, 0
    segs[key] = f
    return f
end

---------------------------------------------------------------------
-- рамки игрока и цели (портрет, здоровье, мана); щелчок — выделить, правый — меню, как у рамок WoW
---------------------------------------------------------------------
local function unitFrame(key, unit)
    local f = segment(key, 232, 80, true)
    f:SetAttribute("unit", unit)
    f:SetAttribute("*type1", "target")
    f:SetAttribute("*type2", "menu")
    f.unit = unit
    f.menu = function(self)
        local dd = unit == "player" and PlayerFrameDropDown or TargetFrameDropDown
        if dd then ToggleDropDownMenu(1, nil, dd, "cursor") end
    end
    f:RegisterForClicks("AnyUp")
    -- портрет как у стандартной рамки WoW: 64×64, лицо крупно; по настройке — живой 3D-портрет
    local side = unit == "player" and "LEFT" or "RIGHT"
    local pbg = f:CreateTexture(nil, "BACKGROUND")
    pbg:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask"); pbg:SetVertexColor(0, 0, 0, 0.85); pbg:SetWidth(64); pbg:SetHeight(64)
    pbg:SetPoint(side, f, side, unit == "player" and 7 or -7, 0)
    f.portrait = f:CreateTexture(nil, "ARTWORK")
    f.portrait:SetWidth(64); f.portrait:SetHeight(64)
    f.portrait:SetPoint("CENTER", pbg, "CENTER", 0, 0)
    f.model = CreateFrame("PlayerModel", nil, f)
    f.model:SetWidth(60); f.model:SetHeight(60)
    f.model:SetPoint("CENTER", pbg, "CENTER", 0, 0)
    f.model:Hide()
    local x0 = unit == "player" and 78 or 8
    f.name = fs(f, "GameFontNormal"); f.name:SetPoint("TOPLEFT", x0, -7); f.name:SetWidth(112); f.name:SetJustifyH("LEFT")
    f.level = fs(f, "GameFontHighlightSmall"); f.level:SetPoint("TOPRIGHT", f, "TOPRIGHT", unit == "player" and -8 or -78, -8)
    f.hp = CreateFrame("StatusBar", nil, f)
    f.hp:SetWidth(146); f.hp:SetHeight(16); f.hp:SetPoint("TOPLEFT", x0, -24)
    f.hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); f.hp:SetStatusBarColor(0.1, 0.85, 0.1)
    f.mp = CreateFrame("StatusBar", nil, f)
    f.mp:SetWidth(146); f.mp:SetHeight(12); f.mp:SetPoint("TOPLEFT", f.hp, "BOTTOMLEFT", 0, -3)
    f.mp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    for _, b in ipairs({ f.hp, f.mp }) do
        local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(b); bg:SetTexture(0, 0, 0, 0.7)
        b.text = fs(b, "TextStatusBarText"); b.text:SetPoint("CENTER", 0, 0)
    end
    f.extra = fs(f, "GameFontDisableSmall"); f.extra:SetPoint("TOPLEFT", f.mp, "BOTTOMLEFT", 0, -2); f.extra:SetWidth(146); f.extra:SetJustifyH("LEFT")
    return f
end
local pUnit = unitFrame("player", "player")
local tUnit = unitFrame("target", "target")
RegisterUnitWatch(tUnit)

local function short(n)
    if n >= 1000000 then return string.format(LS"%.1fм", n / 1000000) elseif n >= 10000 then return math.floor(n / 1000) .. LS"к" end
    return tostring(n)
end
-- 1: 500 / 1000, 2: 50%, 3: 500 (50%), 4: без текста
local function barLabel(mode, v, m)
    local pct = math.floor(v * 100 / math.max(1, m) + 0.5) .. "%"
    if mode == 2 then return pct elseif mode == 3 then return short(v) .. " (" .. pct .. ")" elseif mode == 4 then return "" end
    return short(v) .. " / " .. short(m)
end
local function hpColor(f, u)
    local l = SimsCraftDB and SimsCraftDB.layout
    if l and l.hpColor == 2 and UnitIsPlayer(u) then
        local _, cls = UnitClass(u)
        local c = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
        if c then f.hp:SetStatusBarColor(c.r, c.g, c.b); return true end
    end
end
local function updatePortrait(f)
    if not UnitExists(f.unit) then return end
    if SimsCraftDB and SimsCraftDB.layout and SimsCraftDB.layout.portrait3d then
        f.portrait:Hide(); f.model:Show()
        f.model:SetUnit(f.unit); if f.model.SetPortraitZoom then f.model:SetPortraitZoom(1) end
        if f.model.SetCamDistanceScale then f.model:SetCamDistanceScale(1) end
    else
        f.model:Hide(); f.portrait:Show()
        SetPortraitTexture(f.portrait, f.unit)
    end
end
local function updateUnit(f)
    local u = f.unit
    if not UnitExists(u) then return end
    local hp, hpm = UnitHealth(u), UnitHealthMax(u)
    local mode = (SimsCraftDB and SimsCraftDB.layout and SimsCraftDB.layout.barText) or 1
    f.hp:SetMinMaxValues(0, math.max(1, hpm)); f.hp:SetValue(hp); f.hp.text:SetText(barLabel(mode, hp, hpm))
    local pt = UnitPowerType(u)
    local c = PowerBarColor and PowerBarColor[pt] or { r = 0, g = 0.4, b = 1 }
    local mp, mpm = UnitPower(u, pt), UnitPowerMax(u, pt)
    f.mp:SetStatusBarColor(c.r, c.g, c.b)
    f.mp:SetMinMaxValues(0, math.max(1, mpm)); f.mp:SetValue(mp); f.mp.text:SetText(mpm > 0 and barLabel(mode, mp, mpm) or "")
    f.name:SetText(UnitName(u) or "")
    if u == "player" and not hpColor(f, u) then f.hp:SetStatusBarColor(0.1, 0.85, 0.1) end
    local lvl = UnitLevel(u)
    f.level:SetText(lvl and lvl > 0 and lvl or "??")
    if u == "target" then
        if hpColor(f, u) then
        elseif UnitIsPlayer(u) or UnitPlayerControlled(u) then f.hp:SetStatusBarColor(0.1, 0.85, 0.1)
        elseif UnitIsEnemy("player", u) then f.hp:SetStatusBarColor(0.9, 0.15, 0.15)
        elseif UnitCanAttack("player", u) then f.hp:SetStatusBarColor(0.9, 0.85, 0.1)
        else f.hp:SetStatusBarColor(0.1, 0.85, 0.1) end
    end
end

-- плюмбоб над портретом игрока (цвет — эмоция)
local plumbTex = pUnit:CreateTexture(nil, "OVERLAY")
plumbTex:SetTexture("Interface\\Icons\\INV_Misc_Gem_Emerald_02")
plumbTex:SetTexCoord(0.15, 0.85, 0.05, 0.95)
plumbTex:SetWidth(16); plumbTex:SetHeight(22)
plumbTex:SetPoint("BOTTOM", pUnit.portrait, "TOP", 0, 3)   -- ровно над центром портрета
local mainPlumb = plumbTex
local emoLine = pUnit.extra
local portrait = pUnit.portrait

-- отношения с целью: под полосками рамки цели + быстрые действия
local tdock = CreateFrame("Frame", "SimsCraftTargetDock", tUnit)
tdock:SetAllPoints(tUnit)
local tRel = tUnit.extra
local tF = CreateFrame("StatusBar", nil, tdock)
tF:SetWidth(70); tF:SetHeight(4); tF:SetPoint("BOTTOMLEFT", tUnit, "BOTTOMLEFT", 8, 6)
tF:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); tF:SetStatusBarColor(0.35, 0.9, 0.35); tF:SetMinMaxValues(-100, 100)
local tR = CreateFrame("StatusBar", nil, tdock)
tR:SetWidth(70); tR:SetHeight(4); tR:SetPoint("LEFT", tF, "RIGHT", 4, 0)
tR:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); tR:SetStatusBarColor(1, 0.45, 0.75); tR:SetMinMaxValues(0, 100)
local tTitle = tRel
local tPortrait = tUnit.portrait
local tQuick = CreateFrame("Frame", nil, root)
tQuick:SetWidth(232); tQuick:SetHeight(20)
tQuick:SetPoint("BOTTOMLEFT", tUnit, "TOPLEFT", 4, 1)
local QUICK = {
    { "talk", LS"Поболтать", "Spell_Holy_PrayerOfSpirit" }, { "joke", LS"Пошутить", "Spell_Shadow_Charm" },
    { "compliment", LS"Комплимент", "INV_ValentinesCard02" }, { "hug", LS"Обнять", "Spell_Holy_HealingAura" },
    { "flirt", LS"Флиртовать", "INV_ValentinesCandy" }, { "kiss", LS"Поцеловать", "INV_Misc_Rose_02" },
    { nil, LS"Все действия общения…", "INV_Misc_Note_01" },
}
for i, q in ipairs(QUICK) do
    local b = iconButton(tQuick, q[3], q[2], function() if q[1] then send("SOC;" .. q[1]) else A.Social:Toggle() end end, 18)
    b:SetPoint("LEFT", (i - 1) * 23, 0)
end
tQuick:Hide()

---------------------------------------------------------------------
-- блок SimsCraft: потребности, разделы, действия
---------------------------------------------------------------------
local bar = segment("sims", 262, 62)
local dockBars = {}
for i, n in ipairs(A.NEEDS) do
    local b = CreateFrame("StatusBar", nil, bar)
    b:SetWidth(66); b:SetHeight(8)
    b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    b:SetStatusBarColor(n.color[1], n.color[2], n.color[3])
    b:SetMinMaxValues(0, 100)
    local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(b); bg:SetTexture(0, 0, 0, 0.7)
    local ic = b:CreateTexture(nil, "OVERLAY")
    ic:SetTexture("Interface\\Icons\\" .. NEED_ICON[n.key]); ic:SetWidth(10); ic:SetHeight(10); ic:SetPoint("RIGHT", b, "LEFT", -2, 0)
    b:SetPoint("TOPLEFT", bar, "TOPLEFT", 20 + ((i - 1) % 3) * 82, -7 - math.floor((i - 1) / 3) * 12)
    b:EnableMouse(true)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(n.name .. ": " .. (A.state.values[n.key] or 0) .. "%", n.color[1], n.color[2], n.color[3])
        GameTooltip:AddLine(n.tip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseUp", function() SimsCraftUI_Open(1, b) end)
    dockBars[n.key] = b
end
local subLine = fs(bar, "GameFontDisableSmall")
subLine:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -6, 26); subLine:SetJustifyH("RIGHT")
local nameText = subLine

-- окно раздела над панелью
local fly = CreateFrame("Frame", "SimsCraftPanel", UIParent)
fly:SetWidth(352); fly:SetHeight(372)
fly:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
fly:SetFrameStrata("HIGH")
fly:EnableMouse(true)
fly:SetClampedToScreen(true)
fly:Hide()
tinsert(UISpecialFrames, "SimsCraftPanel")
local flyHeader = fly:CreateTexture(nil, "ARTWORK")
flyHeader:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
flyHeader:SetWidth(300); flyHeader:SetHeight(64); flyHeader:SetPoint("TOP", 0, 12)
local titleText = fs(fly, "GameFontNormal"); titleText:SetPoint("TOP", flyHeader, "TOP", 0, -14)
local flyClose = CreateFrame("Button", nil, fly, "UIPanelCloseButton"); flyClose:SetPoint("TOPRIGHT", -6, -6)
local body = CreateFrame("Frame", nil, fly)
body:SetPoint("TOPLEFT", 18, -34)
body:SetWidth(316); body:SetHeight(320)
local pages = {}
local PAGE_TITLES = { LS"Потребности", LS"Навыки", LS"Карьера", LS"Отношения", LS"Стремление и награды", LS"Эмоции и мудлеты", LS"Семья", LS"Дом" }
for i = 1, #PAGE_TITLES do
    local pg = CreateFrame("Frame", nil, body)
    pg:SetAllPoints(body)
    pg:Hide()
    pages[i] = pg
end
local currentTab = 1
local sectionButtons = {}
function SimsCraftUI_Open(i, anchor)
    if fly:IsShown() and currentTab == i then fly:Hide(); return end
    currentTab = i
    for k, pg in ipairs(pages) do if k == i then pg:Show() else pg:Hide() end end
    titleText:SetText(PAGE_TITLES[i])
    anchor = anchor or sectionButtons[i] or bar
    local x = anchor.GetCenter and anchor:GetCenter()
    local s = (anchor.GetEffectiveScale and anchor:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
    local top = root.GetTop and root:GetTop()
    fly:ClearAllPoints()
    if x and top then
        fly:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", math.max(0, x * s - 176), top * (root:GetEffectiveScale() / UIParent:GetEffectiveScale()) + 4)
    else
        fly:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 160)
    end
    fly:Show()
    PlaySound("igCharacterInfoOpen")
    if SimsCraftDB then SimsCraftDB.tab = i end
    send("INFO")
end
function SimsCraftUI_Toggle() SimsCraftUI_Open(SimsCraftDB and SimsCraftDB.tab or 1) end

local SECTIONS = {
    { "INV_Misc_Food_15", LS"Потребности" }, { "INV_Misc_Book_09", LS"Навыки" }, { "INV_Misc_Coin_01", LS"Карьера" },
    { "Spell_Holy_PrayerOfSpirit", LS"Отношения" }, { "Achievement_Quests_Completed_08", LS"Стремление и награды" },
    { "Spell_Shadow_Charm", LS"Эмоции и мудлеты" }, { "Achievement_Reputation_01", LS"Семья" },
}
for i, s in ipairs(SECTIONS) do
    local b = iconButton(bar, s[1], s[2], function(self) SimsCraftUI_Open(i, self) end, 18)
    b:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 8 + (i - 1) * 21, 6)
    sectionButtons[i] = b
end
local ACTIONS = {
    { "INV_Misc_Note_02", LS"Телефон: супруг, гости, пицца, врач, счета", function() send("PHONE") end },
    { "INV_Misc_Bag_10", LS"Каталог мебели, стройка и дома", function() A.Catalog:Toggle() end },
    { "Spell_Nature_Sleep", LS"Действие: использовать ближайшую мебель", function() send("USE") end },
    { "INV_Misc_Spyglass_02", LS"Сменить камеру", function() A.nextCam() end },
    { "Spell_Arcane_TeleportStormWind", LS"Дом: обустроить, камера внутри, телепорт домой", function(self) SimsCraftUI_Open(8, self) end },
}
for i, a in ipairs(ACTIONS) do
    local b = iconButton(bar, a[1], a[2], a[3], 18)
    b:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 8 + (7 + i - 1) * 21 + 6, 6)
    if i == 5 then sectionButtons[8] = b end
end

local function updateTarget()
    if UnitExists("target") and not UnitIsUnit("target", "player") and (UnitIsPlayer("target") or not UnitCanAttack("player", "target")) then
        tRel:SetText("…"); tF:SetValue(0); tR:SetValue(0)
        tdock:Show(); if SimsCraftDB and SimsCraftDB.layout and SimsCraftDB.layout.show.target then tQuick:Show() end
        send("REL")
    else
        tdock:Hide(); tQuick:Hide()
        if UnitExists("target") then tRel:SetText(UnitCreatureType("target") or "") end
    end
end

-- страница «Дом»
A.makeButton(pages[8], LS"Обустроить готовый дом (встроенная мебель)", 300, 24, function() send("SPOTS") end):SetPoint("TOPLEFT", 0, -6)
A.makeButton(pages[8], LS"Переставить ближайший предмет", 300, 24, function() send("MOVE") end):SetPoint("TOPLEFT", 0, -36)
A.makeButton(pages[8], LS"Продать ближайший предмет", 300, 24, function() send("SELL") end):SetPoint("TOPLEFT", 0, -66)
A.makeButton(pages[8], LS"Телепорт домой", 300, 24, function() send("HOME") end):SetPoint("TOPLEFT", 0, -96)
A.makeButton(pages[8], LS"Сделать это место домом", 300, 24, function() send("SETHOME") end):SetPoint("TOPLEFT", 0, -126)
local houseHint = fs(pages[8], "GameFontHighlightSmall"); houseHint:SetPoint("TOPLEFT", 0, -166); houseHint:SetWidth(316); houseHint:SetJustifyH("LEFT")
houseHint:SetText(LS"«Обустроить»: встаньте у кровати, плиты, ванны и т. д. внутри готового дома и отметьте, что это — тогда мебель дома начнёт работать.")
-- 1. потребности
local needBars = {}
for i, n in ipairs(A.NEEDS) do
    local icon = pages[1]:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\" .. NEED_ICON[n.key]); icon:SetWidth(22); icon:SetHeight(22)
    icon:SetPoint("TOPLEFT", 0, -(i - 1) * 30)
    local bar = wowBar(pages[1], 280, 16, n.color[1], n.color[2], n.color[3])
    bar:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    bar.label:SetText(n.name)
    needBars[n.key] = bar
end
local needInfo = fs(pages[1]); needInfo:SetPoint("TOPLEFT", 0, -186); needInfo:SetWidth(318); needInfo:SetJustifyH("LEFT")

-- 2. навыки (до 16, в две колонки)
local skillRows = {}
for i = 1, 16 do
    local r = CreateFrame("Frame", nil, pages[2])
    r:SetWidth(155); r:SetHeight(32)
    r:SetPoint("TOPLEFT", ((i - 1) % 2) * 162, -math.floor((i - 1) / 2) * 34)
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetWidth(24); r.icon:SetHeight(24); r.icon:SetPoint("LEFT", 0, 0)
    r.name = fs(r, "GameFontNormalSmall"); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 5, 1)
    r.bar = CreateFrame("StatusBar", nil, r)
    r.bar:SetWidth(122); r.bar:SetHeight(8); r.bar:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 5, 0)
    r.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); r.bar:SetStatusBarColor(0.3, 0.75, 1); r.bar:SetMinMaxValues(0, 100)
    local bg = r.bar:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(r.bar); bg:SetTexture(0, 0, 0, 0.6)
    r.lvl = fs(r, "GameFontHighlightSmall"); r.lvl:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 1)
    r:Hide()
    skillRows[i] = r
end
local skillEmpty = fs(pages[2], "GameFontDisable"); skillEmpty:SetPoint("TOPLEFT", 0, 0); skillEmpty:SetWidth(318); skillEmpty:SetJustifyH("LEFT")
skillEmpty:SetText(LS"Навыков пока нет.\n\nГотовьте, рисуйте, тренируйтесь, читайте, играйте на инструментах, работайте за компьютером, ухаживайте за грядками — навыки появятся сами.")

-- 3. карьера
local careerTitle = fs(pages[3], "GameFontNormalLarge"); careerTitle:SetPoint("TOPLEFT", 0, 0)
local careerRank = fs(pages[3], "GameFontHighlight"); careerRank:SetPoint("TOPLEFT", 0, -24)
local perfBar = wowBar(pages[3], 314, 16, 0.35, 0.85, 0.35); perfBar:SetPoint("TOPLEFT", 2, -52); perfBar.label:SetText(LS"Успеваемость")
local shiftText = fs(pages[3]); shiftText:SetPoint("TOPLEFT", 0, -80); shiftText:SetWidth(318); shiftText:SetJustifyH("LEFT")
A.makeButton(pages[3], LS"Выйти на смену", 140, 22, function() send("WORK") end):SetPoint("TOPLEFT", 0, -150)

-- 4. отношения
local relRows = {}
for i = 1, 9 do
    local r = CreateFrame("Frame", nil, pages[4])
    r:SetWidth(318); r:SetHeight(30)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * 32)
    r.name = fs(r, "GameFontNormalSmall"); r.name:SetPoint("TOPLEFT", 0, 0); r.name:SetWidth(150); r.name:SetJustifyH("LEFT")
    r.st = fs(r, "GameFontDisableSmall"); r.st:SetPoint("TOPRIGHT", 0, 0)
    r.f = CreateFrame("StatusBar", nil, r); r.f:SetWidth(154); r.f:SetHeight(8); r.f:SetPoint("TOPLEFT", 0, -14)
    r.f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); r.f:SetStatusBarColor(0.35, 0.9, 0.35); r.f:SetMinMaxValues(-100, 100)
    r.r = CreateFrame("StatusBar", nil, r); r.r:SetWidth(154); r.r:SetHeight(8); r.r:SetPoint("TOPLEFT", 162, -14)
    r.r:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); r.r:SetStatusBarColor(1, 0.45, 0.75); r.r:SetMinMaxValues(0, 100)
    for _, b in ipairs({ r.f, r.r }) do local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(b); bg:SetTexture(0, 0, 0, 0.6) end
    r:Hide()
    relRows[i] = r
end

-- 5. стремление
local aspTitle = fs(pages[5], "GameFontNormalLarge"); aspTitle:SetPoint("TOPLEFT", 0, 0)
local aspLines = {}
for i = 1, 3 do
    local t = fs(pages[5], "GameFontHighlight"); t:SetPoint("TOPLEFT", 0, -20 - i * 22); t:SetWidth(318); t:SetJustifyH("LEFT")
    aspLines[i] = t
end
local spText = fs(pages[5], "GameFontNormal"); spText:SetPoint("TOPLEFT", 0, -120)
A.makeButton(pages[5], LS"Выбрать стремление / купить награду", 240, 22, function() send("ASPM") end):SetPoint("TOPLEFT", 0, -146)

-- 6. эмоции
local emoBig = fs(pages[6], "GameFontNormalLarge"); emoBig:SetPoint("TOPLEFT", 0, 0)
local moodRows = {}
for i = 1, 11 do
    local t = fs(pages[6], "GameFontHighlightSmall"); t:SetPoint("TOPLEFT", 0, -26 - (i - 1) * 18); t:SetWidth(318); t:SetJustifyH("LEFT")
    moodRows[i] = t
end

-- 7. семья
local famText = fs(pages[7], "GameFontHighlight"); famText:SetPoint("TOPLEFT", 0, 0); famText:SetWidth(318); famText:SetJustifyH("LEFT")
A.makeButton(pages[7], LS"Позвать детей", 110, 22, function() send("FAM;call") end):SetPoint("TOPLEFT", 0, -230)
A.makeButton(pages[7], LS"Отправить домой", 120, 22, function() send("FAM;home") end):SetPoint("TOPLEFT", 114, -230)
A.makeButton(pages[7], LS"Имена…", 76, 22, function() A.Family:Toggle() end):SetPoint("TOPLEFT", 238, -230)

---------------------------------------------------------------------
-- ДАННЫЕ С СЕРВЕРА
---------------------------------------------------------------------
local function refreshNeeds()
    for _, n in ipairs(A.NEEDS) do
        local v = A.state.values[n.key] or 0
        local low = v < 25
        local c = low and { 1, 0.3, 0.3 } or n.color
        needBars[n.key]:SetValue(v); needBars[n.key].value:SetText(v .. "%")
        needBars[n.key]:SetStatusBarColor(c[1], c[2], c[3])
        dockBars[n.key]:SetValue(v); dockBars[n.key]:SetStatusBarColor(c[1], c[2], c[3])
    end
    local lines = {}
    if A.state.sleeping then lines[#lines + 1] = LS"|cff8080ffСпит... Zzz|r" end
    if A.state.pregEnd then lines[#lines + 1] = LS"|cffff80ffМалыш появится через|r " .. A.fmtTime(A.state.pregEnd - GetTime()) end
    lines[#lines + 1] = LS"|cffffd100Уют дома:|r " .. (A.state.comfort or 0)
    local names = {}
    for id in string.gmatch(A.state.traits or "", "%d+") do names[#names + 1] = A.TRAITS[tonumber(id)] end
    lines[#lines + 1] = LS"|cffffd100Черты:|r " .. (#names > 0 and table.concat(names, ", ") or LS"не выбраны (Хранитель жизни)")
    needInfo:SetText(table.concat(lines, "\n"))
    local c = A.CAREERS[A.state.career or 0]
    careerTitle:SetText(c and c[1] or LS"Безработный")
    careerRank:SetText(c and ((c[2][A.state.rank] or "?") .. LS" — ранг " .. (A.state.rank or 1) .. LS" из 5") or LS"Выберите карьеру у Хранителя жизни")
    perfBar:SetValue(math.min(A.state.perf or 0, 100)); perfBar.value:SetText(math.min(A.state.perf or 0, 100) .. "%")
    shiftText:SetText(A.state.workEnd and (LS"|cff40ff40На смене:|r осталось " .. A.fmtTime(A.state.workEnd - GetTime()) .. LS".\nВыполняйте задания вокруг вас.")
        or LS"Смена — это задания рядом с вами: кристаллы мага, корзины повара, посты стражи, ящики торговца, сцены артиста, больные лекаря, флажки забега.")
end

local function refreshEmotion()
    local e = EMOS[data.emo] or EMOS[1]
    local name = (data.emoI or 1) > 1 and ((data.emoI == 2 and LS"Очень " or LS"Крайне ") .. EMO_LOW[data.emo]) or e[1]
    plumbTex:SetVertexColor(e[2], e[3], e[4]); mainPlumb:SetVertexColor(e[2], e[3], e[4])
    emoLine:SetText(name); emoLine:SetTextColor(e[2], e[3], e[4])
    emoBig:SetText(name); emoBig:SetTextColor(e[2], e[3], e[4])
    for i, row in ipairs(moodRows) do
        local m = data.moodlets[i]
        if m then
            local me = EMOS[m.e] or EMOS[1]
            row:SetText(string.format("|cff%02x%02x%02x%s %s%d|r  %s", me[2] * 255, me[3] * 255, me[4] * 255, me[1],
                m.e >= 9 and "-" or "+", m.w, m.n) .. (m.left >= 0 and ("  |cff888888(" .. gameHours(m.left) .. ")|r") or ""))
            row:Show()
        else row:Hide() end
    end
end

local function refreshSkills()
    local n = 0
    for _, s in ipairs(data.skills) do
        n = n + 1
        local r = skillRows[n]
        local def = SKILLS[s.i]
        if r and def then
            r.icon:SetTexture("Interface\\Icons\\" .. def[2])
            r.name:SetText(def[1]); r.lvl:SetText(s.l)
            r.bar:SetValue(s.l >= 10 and 100 or s.p)
            r:Show()
        end
    end
    for i = n + 1, 16 do skillRows[i]:Hide() end
    if n == 0 then skillEmpty:Show() else skillEmpty:Hide() end
end

local function refreshAsp()
    aspTitle:SetText(data.asp > 0 and ASPS[data.asp] or LS"Стремление не выбрано")
    for i = 1, 3 do
        local l = data.aspLines[i]
        aspLines[i]:SetText(l and ((l.done and "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t " or "|TInterface\\RaidFrame\\ReadyCheck-Waiting:14|t ") .. l.t) or "")
    end
    spText:SetText(LS"Очки удовлетворения: |cffffffff" .. data.sp .. "|r")
end

local function refreshRel()
    for i, row in ipairs(relRows) do
        local r = data.rel[i]
        if r then
            row.name:SetText(r.name); row.st:SetText(STATUS[r.status] or "")
            row.f:SetValue(r.f); row.r:SetValue(r.r)
            row:Show()
        else row:Hide() end
    end
end

local function refreshFamily()
    local fam = A.family
    local lines = { LS"|cffffd100Партнёр:|r " .. ((fam.partner and fam.partner ~= "") and (fam.partner .. " (" .. (STATUS[fam.status] or fam.status or "") .. ")") or LS"нет"), "" }
    for _, k in ipairs(fam.kids or {}) do
        lines[#lines + 1] = string.format(LS"%s %s — %s, счастье %d%%%s%s", k.gender == 1 and LS"|cffff9ad5Дочь|r" or LS"|cff8ac8ffСын|r", k.name,
            A.KID_STAGES[k.stage] or "?", k.happy or 0, (k.grade and k.grade ~= "") and (LS", оценка " .. k.grade) or "",
            k.out and LS" |cff80c0ff(с вами)|r" or (k.home and LS" |cff80ff80(дома)|r" or (k.moved and LS" |cffffb0ff(живёт своей семьёй)|r" or "")))
    end
    if #(fam.kids or {}) == 0 then lines[#lines + 1] = LS"|cff888888Детей пока нет.|r" end
    famText:SetText(table.concat(lines, "\n"))
end

A.on("S", function() refreshNeeds() end)
A.on("E", function(p)
    data.emo, data.emoI = tonumber(p[2]) or 1, tonumber(p[3]) or 1
    data.moodlets = {}
    for chunk in string.gmatch(p[4] or "", "[^|]+") do
        local n, e, w, left = chunk:match("^(.-)~(%d+)~(%d+)~(%-?%d+)$")
        if n then data.moodlets[#data.moodlets + 1] = { n = n, e = tonumber(e), w = tonumber(w), left = tonumber(left) } end
    end
    table.sort(data.moodlets, function(a, b) return a.w > b.w end)
    refreshEmotion()
end)
local function parseSkills(s, append)
    if not append then data.skills = {} end
    for i, l, pr in string.gmatch(s or "", "(%d+):(%d+):(%d+)") do
        data.skills[#data.skills + 1] = { i = tonumber(i), l = tonumber(l), p = tonumber(pr) }
    end
    table.sort(data.skills, function(a, b) return a.l > b.l end)
    refreshSkills()
end
A.on("SK", function(p) parseSkills(p[2], false) end)
A.on("SK+", function(p) parseSkills(p[2], true) end)
A.on("ASP", function(p)
    data.asp, data.aspStage, data.sp = tonumber(p[2]) or 0, tonumber(p[3]) or 0, tonumber(p[4]) or 0
    data.aspLines = {}
    for chunk in string.gmatch(p[5] or "", "[^%^]+") do
        local d, t = chunk:match("^(%d)~(.*)$")
        if d then data.aspLines[#data.aspLines + 1] = { done = d == "1", t = t } end
    end
    refreshAsp()
end)
A.on("RL", function(p)
    data.rel = {}
    for chunk in string.gmatch(p[2] or "", "[^|]+") do
        local n, f, r, st = chunk:match("^(.-)~(%-?%d+)~(%d+)~(.*)$")
        if n then data.rel[#data.rel + 1] = { name = n, f = tonumber(f), r = tonumber(r), status = st } end
    end
    refreshRel()
end)
A.on("W", function(p)
    local w = { season = tonumber(p[2]) or 1, weather = p[4] or "", holiday = p[5] or "", bill = p[6] or "", power = p[7] == "1", ill = p[8] == "1" }
    data.world = w
    local s = (SEASONS[w.season] or "") .. ", " .. w.weather
    if w.holiday ~= "" then s = s .. " — |cffff80ff" .. w.holiday .. "|r" end
    if w.bill ~= "" then local amt = w.bill:match("(%d+):"); s = s .. LS"  |cffffd100счёт: " .. A.moneyText(amt or 0) .. "|r" end
    if w.power then s = s .. LS"  |cffff4040свет отключён|r" end
    if w.ill then s = s .. LS"  |cffff8040простуда|r" end
    data.worldText = s
end)
A.on("R", function(p)
    if not tdock:IsShown() then return end
    tTitle:SetText((p[5] or "") ~= "" and p[5] or LS"Знакомство")
    tF:SetValue(tonumber(p[3]) or 0); tR:SetValue(tonumber(p[4]) or 0)
end)
A.on("FE", function() refreshFamily() end)

---------------------------------------------------------------------
-- ПАНЕЛИ ДЕЙСТВИЙ WOW И МЕНЮ ВНУТРИ НАШЕЙ ПАНЕЛИ
---------------------------------------------------------------------
local GAP, BTN, ROW_W, GRYPH = 4, 42, 548, 92   -- GAP берётся из настроек
local wowSeg = segment("wow", ROW_W, 60)
wowSeg:SetBackdropColor(0.02, 0.02, 0.03, 0.75)
local menuSeg = segment("menu", 268, 84)

local MICRO = { "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", "AchievementMicroButton", "QuestLogMicroButton",
    "SocialsMicroButton", "PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton" }
local ART = { "MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3", "MainMenuBarMaxLevelBar",
    "MainMenuXPBarTexture0", "MainMenuXPBarTexture1", "MainMenuXPBarTexture2", "MainMenuXPBarTexture3",
    "ReputationWatchBarTexture0", "ReputationWatchBarTexture1", "ReputationWatchBarTexture2", "ReputationWatchBarTexture3",
    "ReputationXPBarTexture0", "ReputationXPBarTexture1", "ReputationXPBarTexture2", "ReputationXPBarTexture3",
    "SlidingActionBarTexture0", "SlidingActionBarTexture1", "ShapeshiftBarLeft", "ShapeshiftBarMiddle", "ShapeshiftBarRight",
    "PossessBackground1", "PossessBackground2" }

local active = false        -- панель встроена (Blizzard-рамки перенесены)
local pending = false       -- нужна перестройка после боя
local xpH = 0
local function G(n) return _G[n] end
local function shown(n) local f = G(n); return f and f:IsShown() end

-- прячем «обрамление»: фон панели, грифонов (по настройке), фон полос опыта
local function stripArt()
    for _, n in ipairs(ART) do local t = G(n); if t and t.SetAlpha then t:SetAlpha(0) end end
    local a = L().hideGryphons and 0 or 1
    for _, n in ipairs({ "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap" }) do local t = G(n); if t and t.SetAlpha then t:SetAlpha(a) end end
end

-- полосы опыта и репутации — тонкие, под кнопками
local function placeXP()
    local e, r = G("MainMenuExpBar"), G("ReputationWatchBar")
    local w = ROW_W - 10
    xpH = 0
    if e and e:IsShown() then
        e:ClearAllPoints(); e:SetWidth(w); e:SetHeight(8); e:SetPoint("BOTTOMLEFT", wowSeg, "BOTTOMLEFT", 5, 5)
        xpH = 10
    end
    if r and r:IsShown() then
        r:ClearAllPoints(); r:SetWidth(w); r:SetHeight(8)
        r:SetPoint("BOTTOMLEFT", wowSeg, "BOTTOMLEFT", 5, 5 + xpH)
        local rs = G("ReputationWatchStatusBar"); if rs then rs:SetWidth(w); rs:SetHeight(8) end
        xpH = xpH + 10
    end
    for _, n in ipairs({ "MainMenuBarOverlayFrame", "ExhaustionTick" }) do local f = G(n); if f and f.SetFrameLevel and e then f:SetFrameLevel(e:GetFrameLevel() + 2) end end
end

-- строки кнопок: основная внизу, над ней 1–3 дополнительные
local function rows()
    local l = L()
    local list = {}
    local bl = shown("MultiBarBottomLeft") and "MultiBarBottomLeft" or nil
    local br = shown("MultiBarBottomRight") and "MultiBarBottomRight" or nil
    if l.rowsSwap then bl, br = br, bl end
    if bl then list[#list + 1] = bl end
    if br then list[#list + 1] = br end
    if l.bar3 and shown("MultiBarRight") then list[#list + 1] = "MultiBarRight" end
    if l.bar4 and shown("MultiBarLeft") then list[#list + 1] = "MultiBarLeft" end
    return list
end

local function placeBars()
    local mmb = G("MainMenuBar")
    if not mmb then return 1 end
    mmb:ClearAllPoints()
    mmb:SetPoint("BOTTOMLEFT", wowSeg, "BOTTOMLEFT", -2, xpH + 1)   -- кнопка 1 оказывается в (6, xpH+5)
    if mmb.EnableMouse then mmb:EnableMouse(false) end
    local art = G("MainMenuBarArtFrame"); if art and art.EnableMouse then art:EnableMouse(false) end
    local prev = G("ActionButton1")
    local extra = rows()
    for _, name in ipairs(extra) do
        local fr, b1 = G(name), G(name .. "Button1")
        if fr and b1 and prev then
            if name == "MultiBarRight" or name == "MultiBarLeft" then
                fr:SetScale(root:GetScale() or 1)
                b1:ClearAllPoints(); b1:SetPoint("BOTTOMLEFT", prev, "TOPLEFT", 0, 6)
                for i = 2, 12 do local b = G(name .. "Button" .. i); if b then b:ClearAllPoints(); b:SetPoint("LEFT", G(name .. "Button" .. (i - 1)), "RIGHT", 6, 0) end end
                fr.simsHorizontal = true
            else
                fr:ClearAllPoints(); fr:SetPoint("BOTTOMLEFT", prev, "TOPLEFT", 0, 6)
            end
            prev = b1
        end
    end
    -- боковые панели снова вертикальные, если их убрали из строк
    for _, v in ipairs({ { "MultiBarRight", "bar3" }, { "MultiBarLeft", "bar4" } }) do
        local fr = G(v[1])
        if fr and fr.simsHorizontal and not L()[v[2]] then
            for i = 1, 12 do
                local b = G(v[1] .. "Button" .. i)
                if b then b:ClearAllPoints()
                    if i == 1 then b:SetPoint("TOPRIGHT", fr, "TOPRIGHT", -2, -3) else b:SetPoint("TOP", G(v[1] .. "Button" .. (i - 1)), "BOTTOM", 0, -6) end
                end
            end
            fr.simsHorizontal = nil
        end
    end
    return 1 + #extra
end

-- меню и сумки — в отдельном блоке
local function placeMenu()
    if not active or InCombatLockdown() then return end
    local c = G("CharacterMicroButton")
    if c and c:GetParent() == G("MainMenuBarArtFrame") then
        c:ClearAllPoints(); c:SetPoint("BOTTOMLEFT", menuSeg, "BOTTOMLEFT", 6, 3)
    end
    local bp = G("MainMenuBarBackpackButton")
    if bp then bp:ClearAllPoints(); bp:SetPoint("TOPRIGHT", menuSeg, "TOPRIGHT", -7, -5) end
end

local function topY()
    local t = root:GetTop()
    if not t then return 140 end
    return t * (root:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
end

-- то, что игра ставит сама от низа экрана: стойки, питомец, тотемы, полоса заклинаний, чат, сумки, правые панели
local function fixManaged()
    if not active or InCombatLockdown() then return end
    local top = topY()
    local above = (wowSeg.h or 60) - xpH - 1
    local stance = shown("ShapeshiftBarFrame") or shown("MultiCastActionBarFrame") or shown("PossessBarFrame")
    for _, n in ipairs({ "ShapeshiftBarFrame", "PossessBarFrame", "MultiCastActionBarFrame" }) do
        local f = G(n)
        if f then f:ClearAllPoints(); f:SetPoint("BOTTOMLEFT", wowSeg, "BOTTOMLEFT", 0, (wowSeg.h or 60) + 2) end
    end
    PETACTIONBAR_XPOS = stance and 230 or 36
    PETACTIONBAR_YPOS = above + 46
    local pet = G("PetActionBarFrame")
    if pet and pet:IsShown() then
        pet:ClearAllPoints(); pet:SetPoint("TOPLEFT", G("MainMenuBar"), "BOTTOMLEFT", PETACTIONBAR_XPOS, PETACTIONBAR_YPOS)
    end
    local extraUp = (stance or shown("PetActionBarFrame")) and 46 or 6
    local cb = G("CastingBarFrame")
    if cb then cb:ClearAllPoints(); cb:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, top + extraUp + 26) end
    if L().moveChat then
        local need = top + extraUp + 6
        for _, n in ipairs({ "ChatFrame1" }) do
            local ch = G(n)
            if ch and ch.GetBottom and ch:GetBottom() and ch:GetBottom() < need then
                local x = ch:GetLeft() or 32
                ch:ClearAllPoints(); ch:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, need)
            end
        end
    end
    local mr, ml = G("MultiBarRight"), G("MultiBarLeft")
    local mrV = mr and mr:IsShown() and not mr.simsHorizontal
    if mrV then mr:ClearAllPoints(); mr:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, top + 6) end
    if ml and ml:IsShown() and not ml.simsHorizontal then
        ml:ClearAllPoints()
        if mrV then ml:SetPoint("BOTTOMRIGHT", mr, "BOTTOMLEFT", -5, 0) else ml:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, top + 6) end
    end
    CONTAINER_OFFSET_Y = top + 6
    if updateContainerFrameAnchors then updateContainerFrameAnchors() end
end

---------------------------------------------------------------------
-- СБОРКА ПАНЕЛИ ПО НАСТРОЙКАМ
---------------------------------------------------------------------
local function visible(key)
    local l = L()
    if not l.show[key] then return false end
    if key == "sims" and (SimsCraftDB.hidden or SimsCraftDB.ui == "classic") then return false end
    return true
end

local applyLook
local function hideBlizzFrames()
    if not L().hideBlizzFrames then return end
    for _, f in ipairs({ PlayerFrame, TargetFrame }) do
        if f then f:UnregisterAllEvents(); f:Hide() end
    end
    if UnregisterUnitWatch and TargetFrame then UnregisterUnitWatch(TargetFrame) end
    local cf = G("ComboFrame")
    if cf then cf:SetParent(tUnit); cf:ClearAllPoints(); cf:SetPoint("TOPRIGHT", tUnit, "TOPRIGHT", 4, 8) end
    local sb = G("TargetFrameSpellBar")
    if sb then sb:SetParent(tUnit); sb:ClearAllPoints(); sb:SetPoint("BOTTOMLEFT", tUnit, "TOPLEFT", 26, 70) end
end

---------------------------------------------------------------------
-- ВНЕШНИЙ ВИД: стиль блоков, рамка, прозрачность, полоски, текст
---------------------------------------------------------------------
local TT_BG, TT_EDGE = "Interface\\Tooltips\\UI-Tooltip-Background", "Interface\\Tooltips\\UI-Tooltip-Border"
local DLG_BG, DLG_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Background", "Interface\\DialogFrame\\UI-DialogBox-Border"
local FLAT = "Interface\\Buttons\\WHITE8X8"
local STYLES = {
    { LS"Тёмный (как подсказки)", TT_BG, TT_EDGE, 14, 3 },
    { LS"Окно WoW (рамка диалога)", DLG_BG, DLG_EDGE, 16, 4 },
    { LS"Плоский (тонкая линия)", FLAT, FLAT, 1, 1 },
    { LS"Плоский, толстая рамка", FLAT, FLAT, 3, 3 },
    { LS"Без рамки, только фон", TT_BG, nil, 0, 0 },
    { LS"Прозрачный (без фона)", nil, nil, 0, 0 },
}
local BORDERS = {
    { LS"Серебро", 0.6, 0.6, 0.6 }, { LS"Золото", 1, 0.78, 0.1 }, { LS"Зелёный Sims", 0.3, 1, 0.45 },
    { LS"Цвет класса" }, { LS"Чёрный", 0, 0, 0 }, { LS"Бирюза", 0.3, 0.8, 1 },
}
local BAR_TEX = {
    { LS"Как в WoW", "Interface\\TargetingFrame\\UI-StatusBar" }, { LS"Плоская", FLAT },
    { LS"Рейдовая", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" }, { LS"Навыки (персонаж)", "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar" },
}
local BAR_TEXT = { "500 / 1000", "50%", "500 (50%)", LS"без текста" }
local HP_COLOR = { LS"Зелёное здоровье", LS"Цвет класса у игроков" }

local function borderColor(l)
    local b = BORDERS[l.border] or BORDERS[1]
    if not b[2] then
        local _, cls = UnitClass("player")
        local c = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
        if c then return c.r, c.g, c.b end
        return 0.6, 0.6, 0.6
    end
    return b[2], b[3], b[4]
end
applyLook = function()
    local l = L()
    local st = STYLES[l.style] or STYLES[1]
    local r, g, b = borderColor(l)
    local a = l.alpha or 0.85
    local bd = (st[2] or st[3]) and { bgFile = st[2], edgeFile = st[3], tile = st[2] ~= FLAT, tileSize = 16, edgeSize = st[4],
        insets = { left = st[5], right = st[5], top = st[5], bottom = st[5] } } or nil
    for key, f in pairs(segs) do
        f:SetBackdrop(bd)
        if bd then
            if st[2] == FLAT then f:SetBackdropColor(0.05, 0.05, 0.07, a) else f:SetBackdropColor(key == "wow" and 0.02 or 0.03, 0.03, 0.05, a) end
            if st[3] then f:SetBackdropBorderColor(r, g, b, math.max(a, 0.6)) end
        end
    end
    local tex = (BAR_TEX[l.barTex] or BAR_TEX[1])[2]
    local bars = { pUnit.hp, pUnit.mp, tUnit.hp, tUnit.mp, tF, tR }
    for _, bar in pairs(dockBars) do bars[#bars + 1] = bar end
    for _, bar in ipairs(bars) do bar:SetStatusBarTexture(tex) end
    local font = l.bigNames and "GameFontNormalLarge" or "GameFontNormal"
    pUnit.name:SetFontObject(font); tUnit.name:SetFontObject(font)
end

local busy = false
local function doLayout()
    if InCombatLockdown() then pending = true; return end
    if busy then return end
    busy = true
    local l = L()
    GAP = l.gap or 4
    if not l.enabled then
        if UnregisterStateDriver then UnregisterStateDriver(root, "visibility") end
        root:Hide(); fly:Hide()
        if active then DEFAULT_CHAT_FRAME:AddMessage(LS"SimsCraft: стандартный интерфейс WoW вернётся после /reload.") end
        active = false
        busy = false
        return
    end
    if not active and RegisterStateDriver then RegisterStateDriver(root, "visibility", "[bonusbar:5] hide; show") end
    active = true
    root:Show()
    -- размеры блока панелей WoW
    stripArt()
    applyLook()
    placeXP()
    local n = placeBars()
    wowSeg.h = xpH + 8 + n * BTN
    wowSeg:SetHeight(wowSeg.h)
    wowSeg.padL = l.hideGryphons and 0 or GRYPH
    wowSeg.padR = wowSeg.padL
    -- столбцы
    local cols = {}
    for _, key in ipairs(l.order) do
        local f = segs[key]
        if f then
            if visible(key) then
                if key == "target" then RegisterUnitWatch(tUnit) else f:Show() end
                if l.stack[key] and #cols > 0 then table.insert(cols[#cols], key) else cols[#cols + 1] = { key } end
            else
                if key == "target" then UnregisterUnitWatch(tUnit) end
                f:Hide()
            end
        end
    end
    local W, H, colW = 0, 0, {}
    for i, col in ipairs(cols) do
        local w, h = 0, 0
        for _, key in ipairs(col) do
            local f = segs[key]
            w = math.max(w, (f.w or 100) + (f.padL or 0) + (f.padR or 0)); h = h + (f.h or 60) + GAP
        end
        colW[i] = w; W = W + w + (i > 1 and GAP or 0); H = math.max(H, h)
    end
    local uw = (UIParent.GetWidth and UIParent:GetWidth()) or 1024
    local s = math.min(l.scale or 1, (uw - 6) / math.max(W, 1))
    root:SetScale(s)
    root:SetWidth(math.max(W, 10)); root:SetHeight(math.max(H, 10))
    root:ClearAllPoints(); root:SetPoint("BOTTOM", UIParent, "BOTTOM", (l.x or 0) / s, (l.y or 0) / s)
    local x = 0
    for i, col in ipairs(cols) do
        local y = 0
        for _, key in ipairs(col) do
            local f = segs[key]
            local fw = (f.w or 100) + (f.padL or 0) + (f.padR or 0)
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", x + (colW[i] - fw) / 2 + (f.padL or 0), y)
            y = y + (f.h or 60) + GAP
        end
        x = x + colW[i] + GAP
    end
    -- Blizzard-рамки того же масштаба
    for _, n in ipairs({ "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight" }) do
        local f = G(n)
        if f and f.SetScale and (n == "MainMenuBar" or f:GetParent() ~= G("MainMenuBar")) then f:SetScale(s) end
    end
    if not l.hideGryphons then
        local lc, rc = G("MainMenuBarLeftEndCap"), G("MainMenuBarRightEndCap")
        if lc then lc:ClearAllPoints(); lc:SetPoint("BOTTOMRIGHT", wowSeg, "BOTTOMLEFT", 30, 0) end
        if rc then rc:ClearAllPoints(); rc:SetPoint("BOTTOMLEFT", wowSeg, "BOTTOMRIGHT", -30, 0) end
    end
    placeMenu()
    hideBlizzFrames()
    if l.lock then SimsCraftMover:Hide() else SimsCraftMover:Show() end
    fixManaged()
    busy = false
end
local function requestLayout()
    if InCombatLockdown() then pending = true else doLayout() end
end
SimsCraftUI_Layout = requestLayout

-- перетаскивание всей панели, когда она не закреплена
local mover = CreateFrame("Frame", "SimsCraftMover", root)
mover:SetAllPoints(root)
mover:SetFrameStrata("DIALOG")
mover:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
mover:SetBackdropColor(0.2, 0.6, 1, 0.25)
mover:EnableMouse(true)
mover:RegisterForDrag("LeftButton")
local moverText = fs(mover, "GameFontNormalLarge"); moverText:SetPoint("CENTER")
moverText:SetText(LS"SimsCraft: перетащите панель. Закрепить — в настройках (/scui config)")
mover:Hide()
mover:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    local l = L()
    local cx, cy = GetCursorPosition()
    local es = UIParent:GetEffectiveScale() or 1
    self.sx, self.sy, self.ox, self.oy = cx / es, cy / es, l.x or 0, l.y or 0
    self:SetScript("OnUpdate", function()
        local mx, my = GetCursorPosition()
        l.x = math.floor(self.ox + mx / es - self.sx); l.y = math.max(0, math.floor(self.oy + my / es - self.sy))
        local s = root:GetScale() or 1
        root:ClearAllPoints(); root:SetPoint("BOTTOM", UIParent, "BOTTOM", l.x / s, l.y / s)
    end)
end)
mover:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil); requestLayout() end)

if hooksecurefunc then
    if UIParent_ManageFramePositions then hooksecurefunc("UIParent_ManageFramePositions", fixManaged) end
    for _, fn in ipairs({ "ReputationWatchBar_Update", "MultiActionBar_Update", "MainMenuBar_ToPlayerArt", "MainMenuBar_UpdateExperienceBars" }) do
        if _G[fn] then hooksecurefunc(fn, requestLayout) end
    end
    if MoveMicroButtons then hooksecurefunc("MoveMicroButtons", placeMenu) end
end

---------------------------------------------------------------------
-- РАМКИ: ауры цели, эмоция у игрока, обновление полосок
---------------------------------------------------------------------
local auras = {}
for i = 1, 18 do
    local a = CreateFrame("Button", nil, tUnit)
    a:SetWidth(19); a:SetHeight(19)
    a.icon = a:CreateTexture(nil, "ARTWORK"); a.icon:SetAllPoints(a)
    a.count = fs(a, "NumberFontNormalSmall"); a.count:SetPoint("BOTTOMRIGHT", 2, -1)
    a.cd = CreateFrame("Cooldown", nil, a, "CooldownFrameTemplate"); a.cd:SetAllPoints(a)
    a:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetUnitAura("target", self.index, self.filter); GameTooltip:Show()
    end)
    a:SetScript("OnLeave", function() GameTooltip:Hide() end)
    a:Hide()
    auras[i] = a
end
local function updateAuras()
    local n = 0
    for _, filter in ipairs({ "HARMFUL", "HELPFUL" }) do
        for i = 1, 40 do
            if n >= #auras then break end
            local name, _, icon, count, _, dur, expires = UnitAura("target", i, filter)
            if not name then break end
            n = n + 1
            local a = auras[n]
            a.index, a.filter = i, filter
            a.icon:SetTexture(icon)
            a.count:SetText(count and count > 1 and count or "")
            if dur and dur > 0 and expires and a.cd.SetCooldown then a.cd:SetCooldown(expires - dur, dur) end
            a:Show()
        end
    end
    for i = n + 1, #auras do auras[i]:Hide() end
    local base = tQuick:IsShown() and 22 or 2
    for i = 1, n do
        local a = auras[i]
        a:ClearAllPoints()
        a:SetPoint("BOTTOMLEFT", tUnit, "TOPLEFT", 4 + ((i - 1) % 9) * 21, base + math.floor((i - 1) / 9) * 21)
    end
end

local emoBtn = CreateFrame("Button", nil, pUnit)
emoBtn:SetPoint("TOPLEFT", pUnit.extra, "TOPLEFT", 0, 2); emoBtn:SetWidth(146); emoBtn:SetHeight(13)
local plumbBtn = CreateFrame("Button", nil, pUnit)
plumbBtn:SetAllPoints(plumbTex)
for _, b in ipairs({ emoBtn, plumbBtn }) do
    b:SetScript("OnClick", function(self) SimsCraftUI_Open(6, self) end)
    b:SetScript("OnEnter", function(self)
        local e = EMOS[data.emo] or EMOS[1]
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine(emoLine:GetText() or e[1], e[2], e[3], e[4])
        for i = 1, math.min(#data.moodlets, 6) do
            local m = data.moodlets[i]
            local me = EMOS[m.e] or EMOS[1]
            GameTooltip:AddDoubleLine(m.n, (m.e >= 9 and "-" or "+") .. m.w, 1, 1, 1, me[2], me[3], me[4])
        end
        GameTooltip:AddLine(LS"Щелчок — эмоции и мудлеты", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local acc, acc2 = 0, 0
root:SetScript("OnUpdate", function(self, el)
    acc = acc + el; acc2 = acc2 + el
    if acc >= 0.1 then
        acc = 0
        updateUnit(pUnit)
        if UnitExists("target") then updateUnit(tUnit) end
    end
    if acc2 >= 1 then
        acc2 = 0
        subLine:SetText(A.clockLine() .. "  " .. A.moneyText(GetMoney()))
        if fly:IsShown() and currentTab == 3 then refreshNeeds() end
    end
end)

---------------------------------------------------------------------
-- КНОПКА У МИНИКАРТЫ: ездит по краю карты, как у других аддонов
---------------------------------------------------------------------
local mm = CreateFrame("Button", "SimsCraftMinimapButton", Minimap)
mm:SetWidth(31); mm:SetHeight(31)
mm:SetFrameStrata("MEDIUM"); mm:SetFrameLevel(8)
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local mmBg = mm:CreateTexture(nil, "BACKGROUND")
mmBg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
mmBg:SetWidth(20); mmBg:SetHeight(20); mmBg:SetPoint("TOPLEFT", 7, -5)
local mmIcon = mm:CreateTexture(nil, "ARTWORK")
mmIcon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Emerald_02")
mmIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
mmIcon:SetWidth(18); mmIcon:SetHeight(18); mmIcon:SetPoint("TOPLEFT", 7, -6)
local mmBorder = mm:CreateTexture(nil, "OVERLAY")
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mmBorder:SetWidth(53); mmBorder:SetHeight(53); mmBorder:SetPoint("TOPLEFT")
local function placeMinimapButton()
    local a = math.rad(SimsCraftDB and SimsCraftDB.mmAngle or 200)
    mm:ClearAllPoints()
    mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
end
mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mm:RegisterForDrag("LeftButton")
mm:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        if not (mx and cx and scale) then return end
        SimsCraftDB.mmAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
        placeMinimapButton()
    end)
end)
mm:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
mm:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        if IsShiftKeyDown and IsShiftKeyDown() then SimsCraftUI_Toggle() else SimsCraftUI_Options() end
    else
        SimsCraftDB.hidden = not SimsCraftDB.hidden
        SimsCraftUI_Apply()
    end
end)
mm:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff4fc3f7Sims|rCraft")
    GameTooltip:AddLine(LS"Левый щелчок: показать / спрятать блок SimsCraft", 1, 1, 1)
    GameTooltip:AddLine(LS"Правый щелчок: настройки и внешний вид панели", 1, 1, 1)
    GameTooltip:AddLine(LS"Shift + правый щелчок: последний раздел SimsCraft", 1, 1, 1)
    GameTooltip:AddLine(LS"Перетащите, чтобы передвинуть по краю карты", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)

---------------------------------------------------------------------
-- НАСТРОЙКИ (Интерфейс → Модификации → SimsCraft)
---------------------------------------------------------------------
local SEG_NAMES = { player = LS"Рамка персонажа", wow = LS"Панели действий WoW", menu = LS"Меню и сумки", sims = LS"Блок SimsCraft", target = LS"Рамка цели" }
local PAGE_W, LOOK_Y = 390, -650
-- страницы настроек прокручиваются: всё лежит в прокручиваемой области шириной 560
local function scrollPage(panel, name, h)
    local sf = CreateFrame("ScrollFrame", name, panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 4)
    local c = CreateFrame("Frame", name .. "Child", sf)
    c:SetWidth(PAGE_W); c:SetHeight(h)
    sf:SetScrollChild(c)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local bar = G(name .. "ScrollBar")
        if bar then bar:SetValue(bar:GetValue() - d * 40) end
    end)
    c.scroll = sf
    return c
end
local optPanel = CreateFrame("Frame", "SimsCraftOptions", UIParent)
optPanel.name = "SimsCraft"
optPanel:Hide()
local opt = scrollPage(optPanel, "SimsCraftOptionsScroll", 1100)
local optTitle = fs(opt, "GameFontNormalLarge"); optTitle:SetPoint("TOPLEFT", 16, -16)
optTitle:SetText(LS"SimsCraft — нижняя панель")
local function scrollTo(v)
    local bar = G("SimsCraftOptionsScrollScrollBar")
    if bar then bar:SetValue(v) elseif opt.scroll.SetVerticalScroll then opt.scroll:SetVerticalScroll(v) end
end
A.makeButton(opt, LS"Расположение блоков", 180, 24, function() scrollTo(0) end):SetPoint("TOPLEFT", 16, -42)
A.makeButton(opt, LS"Внешний вид панелей", 180, 24, function() scrollTo(-LOOK_Y - 10) end):SetPoint("TOPLEFT", 200, -42)
local optSub = fs(opt, "GameFontHighlightSmall"); optSub:SetPoint("TOPLEFT", 16, -72); optSub:SetWidth(370); optSub:SetJustifyH("LEFT")
optSub:SetText(LS"Блоки идут слева направо в этом порядке. «Над соседом» ставит блок в тот же столбец поверх предыдущего. Всё применяется сразу.")
local optControls = {}
local function check(name, label, x, y, get, set)
    local c = CreateFrame("CheckButton", "SimsCraftOpt" .. name, opt, "UICheckButtonTemplate")
    c:SetWidth(24); c:SetHeight(24)
    c:SetPoint("TOPLEFT", x, y)
    local t = G("SimsCraftOpt" .. name .. "Text")
    if t then t:SetText(label); t:SetFontObject(GameFontHighlightSmall); t:SetWidth(340); t:SetJustifyH("LEFT") end
    c.label = label
    c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false); requestLayout(); opt.refresh() end)
    c.get = get
    optControls[#optControls + 1] = c
    return c
end
local orderRows = {}
for i = 1, 5 do
    local y = -118 - (i - 1) * 28
    local r = {}
    r.num = fs(opt, "GameFontNormal"); r.num:SetPoint("TOPLEFT", 6, y - 5)
    r.show = CreateFrame("CheckButton", "SimsCraftOptShow" .. i, opt, "UICheckButtonTemplate")
    r.show:SetWidth(24); r.show:SetHeight(24); r.show:SetPoint("TOPLEFT", 76, y)
    r.text = fs(opt, "GameFontHighlight"); r.text:SetPoint("TOPLEFT", 102, y - 5); r.text:SetWidth(150); r.text:SetJustifyH("LEFT")
    r.left = A.makeButton(opt, "<", 26, 22, function() local o = L().order; if i > 1 then o[i], o[i - 1] = o[i - 1], o[i] end; requestLayout(); opt.refresh() end)
    r.left:SetPoint("TOPLEFT", 22, y - 1)
    r.right = A.makeButton(opt, ">", 26, 22, function() local o = L().order; if i < #o then o[i], o[i + 1] = o[i + 1], o[i] end; requestLayout(); opt.refresh() end)
    r.right:SetPoint("TOPLEFT", 48, y - 1)
    r.stack = CreateFrame("CheckButton", "SimsCraftOptStack" .. i, opt, "UICheckButtonTemplate")
    r.stack:SetWidth(24); r.stack:SetHeight(24); r.stack:SetPoint("TOPLEFT", 256, y)
    local st = G("SimsCraftOptStack" .. i .. "Text"); if st then st:SetText(LS"над соседом"); st:SetFontObject(GameFontHighlightSmall) end
    r.show:SetScript("OnClick", function(self) local k = L().order[i]; L().show[k] = self:GetChecked() and true or false; requestLayout() end)
    r.stack:SetScript("OnClick", function(self) local k = L().order[i]; L().stack[k] = self:GetChecked() and true or false; requestLayout() end)
    orderRows[i] = r
end
local oy = -118 - 5 * 28 - 10
check("Gryph", LS"Убрать грифонов (драконов) по краям панели действий", 16, oy, function() return L().hideGryphons end, function(v) L().hideGryphons = v end)
check("Blizz", LS"Скрыть стандартные рамки игрока и цели WoW (вернуть — снять и /reload)", 16, oy - 26, function() return L().hideBlizzFrames end, function(v) L().hideBlizzFrames = v end)
check("Chat", LS"Поднимать чат над панелью, чтобы ничего не налезало", 16, oy - 52, function() return L().moveChat end, function(v) L().moveChat = v end)
check("Bar3", LS"3-я доп. панель: правая панель WoW — горизонтально над остальными", 16, oy - 78, function() return L().bar3 end, function(v) L().bar3 = v end)
check("Bar4", LS"4-я доп. панель: правая панель 2 WoW — горизонтально над остальными", 16, oy - 104, function() return L().bar4 end, function(v) L().bar4 = v end)
check("Swap", LS"Поменять местами нижние доп. панели (левую и правую)", 16, oy - 130, function() return L().rowsSwap end, function(v) L().rowsSwap = v end)
check("P3D", LS"Живой 3D-портрет (лицо персонажа и цели крупным планом)", 16, oy - 156, function() return L().portrait3d end, function(v) L().portrait3d = v; updatePortrait(pUnit); updatePortrait(tUnit) end)
check("Lock", LS"Закрепить панель (снимите, чтобы перетащить мышью)", 16, oy - 182, function() return L().lock end, function(v) L().lock = v end)
check("On", LS"Встроить SimsCraft в нижнюю панель WoW (выключено — старый вид, нужен /reload)", 16, oy - 208, function() return L().enabled end, function(v) L().enabled = v end)
local scale = CreateFrame("Slider", "SimsCraftOptScale", opt, "OptionsSliderTemplate")
scale:SetWidth(200); scale:SetHeight(16)
scale:SetPoint("TOPLEFT", 24, oy - 258)
scale:SetMinMaxValues(0.6, 1.3); scale:SetValueStep(0.05)
local function sliderText(n, t, lo, hi)
    local a = G(n .. "Text"); if a then a:SetText(t) end
    local b = G(n .. "Low"); if b then b:SetText(lo) end
    local c = G(n .. "High"); if c then c:SetText(hi) end
end
sliderText("SimsCraftOptScale", LS"Масштаб панели", "60%", "130%")
scale:SetScript("OnValueChanged", function(self, v)
    if opt.loading then return end
    L().scale = math.floor(v * 20 + 0.5) / 20; requestLayout()
end)
local hint = fs(opt, "GameFontDisableSmall"); hint:SetPoint("TOPLEFT", 16, oy - 330); hint:SetWidth(370); hint:SetJustifyH("LEFT")
hint:SetText(LS"Если всё не помещается по ширине, панель сама немного уменьшится. Включить доп. панели WoW: Интерфейс → Панели команд.")
A.makeButton(opt, LS"Сбросить расположение", 180, 24, function()
    SimsCraftDB.layout = nil; initLayout(); requestLayout(); opt.refresh()
end):SetPoint("TOPLEFT", 16, oy - 298)
A.makeButton(opt, LS"Показать / скрыть блок Sims", 180, 24, function() SimsCraftDB.hidden = not SimsCraftDB.hidden; SimsCraftUI_Apply() end):SetPoint("TOPLEFT", 200, oy - 298)

function opt.refresh()
    if not SimsCraftDB or not SimsCraftDB.layout then return end
    local l = L()
    for i, r in ipairs(orderRows) do
        local k = l.order[i]
        if k then
            r.num:SetText(i .. ".")
            r.text:SetText(SEG_NAMES[k] or k)
            r.show:SetChecked(l.show[k] and true or false)
            r.stack:SetChecked(l.stack[k] and true or false)
        end
    end
    for _, c in ipairs(optControls) do c:SetChecked(c.get() and true or false) end
    opt.loading = true; scale:SetValue(l.scale or 1); opt.loading = false
end
optPanel:SetScript("OnShow", function() opt.refresh(); if SimsCraftOptionsLook and SimsCraftOptionsLook.refresh then SimsCraftOptionsLook.refresh() end end)
optPanel.default = function() SimsCraftDB.layout = nil; initLayout(); requestLayout(); opt.refresh() end
optPanel.okay = function() end
optPanel.cancel = function() end
if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(optPanel) end

-- вторая страница настроек: «Внешний вид»
-- раздел «Внешний вид» — на той же странице, ниже (кнопка вверху прокручивает к нему)
local look = CreateFrame("Frame", "SimsCraftOptionsLook", opt)
look:SetPoint("TOPLEFT", opt, "TOPLEFT", 0, LOOK_Y)
look:SetWidth(PAGE_W); look:SetHeight(440)
local lookLine = look:CreateTexture(nil, "ARTWORK")
lookLine:SetTexture(1, 0.82, 0, 0.4); lookLine:SetHeight(1); lookLine:SetWidth(370); lookLine:SetPoint("TOPLEFT", 10, -6)
local lookTitle = fs(look, "GameFontNormalLarge"); lookTitle:SetPoint("TOPLEFT", 16, -16)
lookTitle:SetText(LS"Внешний вид панелей")
local lookSub = fs(look, "GameFontHighlightSmall"); lookSub:SetPoint("TOPLEFT", lookTitle, "BOTTOMLEFT", 0, -6); lookSub:SetWidth(370); lookSub:SetJustifyH("LEFT")
lookSub:SetText(LS"Щёлкайте по кнопке, чтобы перебрать варианты (правый щелчок — назад). Всё применяется сразу.")
local cyclers = {}
local function cycler(name, label, list, key, y, after)
    local t = fs(look, "GameFontNormalSmall"); t:SetPoint("TOPLEFT", 16, y - 6); t:SetWidth(130); t:SetJustifyH("LEFT"); t:SetText(label)
    local b = A.makeButton(look, "", 220, 24, nil)
    b:SetPoint("TOPLEFT", 150, y)
    _G["SimsCraftLook" .. name] = b
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(self, button)
        local l = L()
        local v = (l[key] or 1) + (button == "RightButton" and -1 or 1)
        if v > #list then v = 1 elseif v < 1 then v = #list end
        l[key] = v
        if after then after() end
        requestLayout(); look.refresh()
    end)
    b.refresh = function() local v = list[L()[key] or 1] or list[1]; b:SetText(type(v) == "table" and v[1] or v) end
    cyclers[#cyclers + 1] = b
    return b
end
cycler("Style", LS"Стиль блоков", STYLES, "style", -64)
cycler("Border", LS"Цвет рамки", BORDERS, "border", -94)
cycler("BarTex", LS"Текстура полосок", BAR_TEX, "barTex", -124)
cycler("BarText", LS"Текст на полосках", BAR_TEXT, "barText", -154, function() updateUnit(pUnit); if UnitExists("target") then updateUnit(tUnit) end end)
cycler("HpColor", LS"Цвет здоровья", HP_COLOR, "hpColor", -184)
local function lookSlider(name, label, lo, hi, step, key, y, fmt)
    local sl = CreateFrame("Slider", "SimsCraftLook" .. name, look, "OptionsSliderTemplate")
    sl:SetWidth(200); sl:SetHeight(16); sl:SetPoint("TOPLEFT", 160, y)
    sl:SetMinMaxValues(lo, hi); sl:SetValueStep(step)
    local t = fs(look, "GameFontNormalSmall"); t:SetPoint("TOPLEFT", 16, y - 2); t:SetWidth(130); t:SetJustifyH("LEFT"); t:SetText(label)
    local lowT, highT = G("SimsCraftLook" .. name .. "Low"), G("SimsCraftLook" .. name .. "High")
    if lowT then lowT:SetText(fmt(lo)) end
    if highT then highT:SetText(fmt(hi)) end
    sl:SetScript("OnValueChanged", function(self, v)
        if look.loading then return end
        L()[key] = math.floor(v / step + 0.5) * step; requestLayout()
        local tt = G("SimsCraftLook" .. name .. "Text"); if tt then tt:SetText(fmt(L()[key])) end
    end)
    sl.key, sl.fmt, sl.tname = key, fmt, "SimsCraftLook" .. name .. "Text"
    return sl
end
local sliders = {
    lookSlider("Alpha", LS"Непрозрачность фона", 0, 1, 0.05, "alpha", -226, function(v) return math.floor(v * 100 + 0.5) .. "%" end),
    lookSlider("Gap", LS"Промежуток между блоками", 0, 20, 1, "gap", -266, function(v) return v .. " px" end),
}
local bigCheck = CreateFrame("CheckButton", "SimsCraftLookBig", look, "UICheckButtonTemplate")
bigCheck:SetWidth(24); bigCheck:SetHeight(24); bigCheck:SetPoint("TOPLEFT", 16, -300)
local bigT = G("SimsCraftLookBigText"); if bigT then bigT:SetText(LS"Крупные имена на рамках"); bigT:SetFontObject(GameFontHighlightSmall) end
bigCheck:SetScript("OnClick", function(self) L().bigNames = self:GetChecked() and true or false; requestLayout() end)
local presets = {
    { LS"Классика WoW", { style = 2, border = 2, alpha = 0.9, barTex = 1, barText = 1, hpColor = 1, gap = 2 } },
    { LS"Тёмный минимал", { style = 3, border = 5, alpha = 0.75, barTex = 2, barText = 2, hpColor = 2, gap = 2 } },
    { "Sims", { style = 4, border = 3, alpha = 0.8, barTex = 3, barText = 3, hpColor = 1, gap = 6 } },
    { LS"Прозрачный", { style = 6, border = 1, alpha = 0, barTex = 1, barText = 1, hpColor = 2, gap = 4 } },
}
local presetT = fs(look, "GameFontNormal"); presetT:SetPoint("TOPLEFT", 18, -342); presetT:SetText(LS"Готовые наборы:")
for i, pr in ipairs(presets) do
    A.makeButton(look, pr[1], 180, 24, function()
        for k, v in pairs(pr[2]) do L()[k] = v end
        requestLayout(); look.refresh(); updateUnit(pUnit)
    end):SetPoint("TOPLEFT", 16 + ((i - 1) % 2) * 186, -362 - math.floor((i - 1) / 2) * 30)
end
function look.refresh()
    if not SimsCraftDB or not SimsCraftDB.layout then return end
    for _, b in ipairs(cyclers) do b.refresh() end
    look.loading = true
    for _, sl in ipairs(sliders) do
        sl:SetValue(L()[sl.key] or 0)
        local tt = G(sl.tname); if tt then tt:SetText(sl.fmt(L()[sl.key] or 0)) end
    end
    look.loading = false
    bigCheck:SetChecked(L().bigNames and true or false)
end
look.default = function() for k, v in pairs(DEFAULT_LAYOUT) do if type(v) ~= "table" then L()[k] = v end end; requestLayout(); look.refresh() end


function SimsCraftUI_Options()
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(optPanel); InterfaceOptionsFrame_OpenToCategory(optPanel)
    else
        optPanel:Show()
    end
end

---------------------------------------------------------------------
-- ПОКАЗ, СОБЫТИЯ, КОМАНДЫ
---------------------------------------------------------------------
function SimsCraftUI_Apply()
    if SimsCraftDB.ui == "classic" and not SimsCraftDB.hidden then A.classic:Show() else A.classic:Hide() end
    if SimsCraftDB.hidden then fly:Hide() end
    requestLayout()
end
A.applyUI = SimsCraftUI_Apply
A.toggle = function() SimsCraftDB.hidden = not SimsCraftDB.hidden; SimsCraftUI_Apply() end

-- раса выбранного NPC по его модели (сервер не знает расу NPC, а ребёнок наследует расу одного из родителей)
local raceProbe = CreateFrame("PlayerModel", nil, UIParent)
raceProbe:SetWidth(2); raceProbe:SetHeight(2); raceProbe:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -20, -20); raceProbe:SetAlpha(0)
local MODEL_RACE = { human = 1, orc = 2, dwarf = 3, nightelf = 4, scourge = 5, tauren = 6, gnome = 7, troll = 8, goblin = 9, bloodelf = 10, draenei = 11 }
local function probeRace()
    if not UnitExists("target") or UnitIsPlayer("target") or UnitCanAttack("player", "target") then return end
    local name = UnitName("target")
    raceProbe:SetUnit("target")
    A.after(0.6, function()
        if UnitName("target") ~= name then return end
        local ok, m = pcall(raceProbe.GetModel, raceProbe)
        if ok and type(m) == "string" then
            local r = string.lower(m):match("character[\\/](%a+)[\\/]")
            if r and MODEL_RACE[r] then send("TRACE;" .. MODEL_RACE[r]) end
        end
    end)
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_TARGET_CHANGED", "UNIT_PORTRAIT_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    "UNIT_AURA", "UNIT_EXITED_VEHICLE", "PLAYER_LEVEL_UP", "UPDATE_FACTION", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do ev:RegisterEvent(e) end
ev:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        updateTarget()
        if UnitExists("target") then updatePortrait(tUnit); updateUnit(tUnit) end
        probeRace()
        updateAuras()
    elseif event == "UNIT_AURA" then
        if unit == "target" then updateAuras() end
    elseif event == "UNIT_PORTRAIT_UPDATE" then
        if unit == "player" then updatePortrait(pUnit) end
        if unit == "target" then updatePortrait(tUnit) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pending then pending = false; doLayout() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        updatePortrait(pUnit)
        updateUnit(pUnit)
        SimsCraftUI_Apply()
        updateTarget()
        A.after(3, function() send("INFO") end)
    else
        requestLayout()
    end
end)

A.onLoad = function()
    if SimsCraftDB.ui ~= "classic" then SimsCraftDB.ui = "wow" end
    initLayout()
    if SimsCraftDB.hideBlizz then L().hideBlizzFrames = true; SimsCraftDB.hideBlizz = nil end
    placeMinimapButton()
    currentTab = SimsCraftDB.tab or 1
    SimsCraftUI_Apply()
end

local oldSlash = SlashCmdList["SIMSCRAFT"]
SlashCmdList["SIMSCRAFT"] = function(arg)
    arg = string.lower(arg or "")
    if arg == "config" or arg == "opt" or arg == "options" then return SimsCraftUI_Options()
    elseif arg == "wow" then
        L().hideBlizzFrames = not L().hideBlizzFrames
        requestLayout()
        DEFAULT_CHAT_FRAME:AddMessage(L().hideBlizzFrames and LS"SimsCraft: рамки WoW скрыты." or LS"SimsCraft: рамки WoW вернутся после /reload.")
        return
    elseif arg == "unlock" or arg == "lock" then
        L().lock = arg == "lock"; requestLayout(); return
    elseif arg == "reset" then
        SimsCraftDB.layout = nil; initLayout(); requestLayout(); return
    elseif arg == "" then
        return A.toggle()
    end
    return oldSlash(arg)
end
