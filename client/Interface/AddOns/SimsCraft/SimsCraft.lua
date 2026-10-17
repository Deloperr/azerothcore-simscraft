local LS = SimsCraftLS or function(s) return s end   -- перевод (Locale.lua)
-- SimsCraft 1.0.0: клиентская часть для WoW 3.3.5a (https://github.com/Deloperr/azerothcore-simscraft)
-- Панель потребностей, каталог и расстановка мебели, общение, семья, камера «как в Симс».

local PREFIX = "SIMSC"
local ADDON = "SimsCraft"

local NEEDS = {
    { key = "hunger",  name = LS"Голод",   color = { 0.95, 0.65, 0.20 }, tip = LS"Ешьте еду, готовьте на плите, обедайте за столом." },
    { key = "energy",  name = LS"Энергия", color = { 0.30, 0.60, 1.00 }, tip = LS"Сидите, спите (/sleep) или ложитесь в кровать." },
    { key = "hygiene", name = LS"Гигиена", color = { 0.40, 0.90, 0.90 }, tip = LS"Плавайте, примите ванну или умойтесь." },
    { key = "fun",     name = LS"Веселье", color = { 0.95, 0.40, 0.80 }, tip = LS"Сражайтесь, танцуйте, читайте, играйте с детьми." },
    { key = "social",  name = LS"Общение", color = { 0.55, 0.90, 0.35 }, tip = LS"Окно «Общение», группа, семья." },
    { key = "bladder", name = LS"Туалет",  color = { 0.85, 0.85, 0.40 }, tip = LS"Воспользуйтесь уборной." },
}
local MOODS = {
    { name = LS"Вдохновлён", r = 0.25, g = 1.00, b = 0.25 },
    { name = LS"Счастлив",   r = 0.61, g = 1.00, b = 0.31 },
    { name = LS"Спокоен",    r = 0.90, g = 0.90, b = 0.90 },
    { name = LS"Не в духе",  r = 1.00, g = 0.69, b = 0.25 },
    { name = LS"Несчастен",  r = 1.00, g = 0.25, b = 0.25 },
}
local TRAITS = { LS"Обжора", LS"Энергичный", LS"Неряха", LS"Душа компании", LS"Одиночка", LS"Активный",
    LS"Чистюля", LS"Романтик", LS"Трудоголик", LS"Лентяй", LS"Книжный червь", LS"Семьянин" }
local CAREERS = {
    { LS"Кулинария", { LS"Поварёнок", LS"Помощник повара", LS"Повар", LS"Шеф-повар", LS"Легенда кухни Азерота" } },
    { LS"Стража",    { LS"Новобранец", LS"Стражник", LS"Сержант", LS"Капитан стражи", LS"Командор" } },
    { LS"Магия",     { LS"Ученик", LS"Подмастерье", LS"Чародей", LS"Магистр", LS"Архимаг" } },
    { LS"Торговля",  { LS"Подсобник", LS"Лоточник", LS"Торговец", LS"Купец", LS"Торговый барон" } },
    { LS"Искусство", { LS"Уличный музыкант", LS"Менестрель", LS"Бард", LS"Маэстро", LS"Звезда таверн" } },
    { LS"Медицина",  { LS"Санитар", LS"Медбрат", LS"Лекарь", LS"Целитель", LS"Главный целитель" } },
    { LS"Спорт",     { LS"Новичок", LS"Атлет", LS"Чемпион города", LS"Звезда арены", LS"Легенда Азерота" } },
}
local KID_STAGES = { LS"Младенец", LS"Малыш", LS"Ребёнок", LS"Подросток", LS"Взрослый" }
local SOCIAL = {
    { "talk", LS"Поболтать" }, { "joke", LS"Пошутить" }, { "compliment", LS"Комплимент" },
    { "hug", LS"Обнять" }, { "gift", LS"Подарок" }, { "flirt", LS"Флиртовать" },
    { "kiss", LS"Поцеловать" }, { "date", LS"Встречаться?" }, { "propose", LS"Предложение" },
    { "woohoo", LS"Романт. вечер" }, { "baby", LS"Завести ребёнка" }, { "argue", LS"Поспорить" },
    { "insult", LS"Оскорбить" }, { "slap", LS"Пощёчина" }, { "breakup", LS"Расстаться" },
}

local clock = {}
local state = { values = {}, mood = 3, career = 0, rank = 1, perf = 0, workEnd = nil, sleeping = false, traits = "", comfort = 0, pregEnd = nil }
local catalog = { cats = {}, items = {}, loaded = false }
local family = { partner = "", status = "", kids = {} }
local lastWarn = {}
local gotData = false

local function send(text) SendAddonMessage(PREFIX, text, "WHISPER", UnitName("player")) end

local function moneyText(c)
    c = tonumber(c) or 0
    local g, s, m = math.floor(c / 10000), math.floor((c % 10000) / 100), c % 100
    local out = ""
    if g > 0 then out = out .. g .. LS"|cffffd700з|r " end
    if s > 0 then out = out .. s .. LS"|cffc7c7cfс|r " end
    if m > 0 or out == "" then out = out .. m .. LS"|cffeda55fм|r" end
    return out
end
local function fmtTime(sec)
    sec = math.max(0, math.floor(sec))
    if sec >= 3600 then return string.format("%d:%02d:%02d", math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60) end
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

---------------------------------------------------------------------
-- Общие строители интерфейса
---------------------------------------------------------------------
-- окна в стиле диалогов WoW
local BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local function savePos(frame)
    local point, _, relPoint, x, y = frame:GetPoint()
    SimsCraftDB.pos = SimsCraftDB.pos or {}
    SimsCraftDB.pos[frame:GetName()] = { point, relPoint, x, y }
end

local function makeWindow(name, w, h, title)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetWidth(w); f:SetHeight(h)
    f:SetPoint("CENTER")
    f:SetBackdrop(BACKDROP)
    f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); savePos(self) end)
    f:SetFrameStrata("DIALOG")
    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(320); header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)
    local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOP", header, "TOP", 0, -14)
    t:SetText(title)
    f.title = t
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    f:Hide()
    tinsert(UISpecialFrames, name)
    return f
end

local function makeButton(parent, label, w, h, onClick, tip)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(w); b:SetHeight(h or 20)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    local fs = b:GetFontString()
    if fs then fs:SetFontObject(GameFontHighlightSmall) end
    if tip then
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return b
end

local function makeBar(parent, w, h, r, g, b)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetWidth(w); bar:SetHeight(h)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(r, g, b)
    bar:SetMinMaxValues(0, 100)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar); bg:SetTexture(0, 0, 0, 0.5)
    bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.label:SetPoint("LEFT", 4, 0)
    bar.value = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.value:SetPoint("RIGHT", -4, 0)
    return bar
end

-- простой таймер
local timers = {}
local timerFrame = CreateFrame("Frame")
timerFrame:SetScript("OnUpdate", function(self, el)
    for i = #timers, 1, -1 do
        local t = timers[i]
        t.left = t.left - el
        if t.left <= 0 then table.remove(timers, i); t.fn() end
    end
end)
local function after(sec, fn) timers[#timers + 1] = { left = sec, fn = fn } end

---------------------------------------------------------------------
-- КАМЕРА
---------------------------------------------------------------------
local camMode = "normal"
local indoor = false
local INDOOR_DIST = 4      -- камера сверху внутри дома: под потолком, крышу не видно
local camSaved
local CAM_NAMES = { normal = LS"Камера: обычная", top = LS"Камера: сверху", shoulder = LS"Камера: из-за плеча", first = LS"Камера: от 1-го лица" }
local CAM_SHORT = { normal = LS"Камера", top = LS"Сверху", shoulder = LS"Плечо", first = LS"1-е лицо" }
local CAM_NEXT = { normal = "top", top = "shoulder", shoulder = "first", first = "normal" }

local function restoreCam()
    if camSaved then
        for k, v in pairs(camSaved) do SetCVar(k, v) end
        camSaved = nil
    end
end

local function setCam(mode)
    MoveViewUpStop(); MoveViewDownStop()
    if mode == "top" then
        if not camSaved then
            camSaved = {}
            for _, k in ipairs({ "cameraDistanceMax", "cameraDistanceMaxFactor", "cameraSmoothStyle", "autointeract" }) do
                camSaved[k] = GetCVar(k)
            end
        end
        local far = indoor and INDOOR_DIST or 50
        SetCVar("cameraDistanceMax", far)
        SetCVar("cameraDistanceMaxFactor", indoor and 1 or 4)
        SetCVar("cameraSmoothStyle", 0)  -- камера не разворачивается за спину
        SetCVar("autointeract", 1)       -- ходьба по клику мыши
        if indoor then CameraZoomIn(50) end
        CameraZoomOut(far)
        MoveViewUpStart(3)
        after(1.6, function() MoveViewUpStop() end)
    elseif mode == "shoulder" then
        -- вплотную за головой: видно плечи, руки, оружие и тело, но смотрим «глазами» героя
        restoreCam()
        CameraZoomIn(50)
        CameraZoomOut(1.6)
        MoveViewDownStart(1)
        after(0.25, function() MoveViewDownStop() end)
    elseif mode == "first" then
        restoreCam()
        CameraZoomIn(50)
    else
        restoreCam()
        CameraZoomIn(50)
        CameraZoomOut(12)
        MoveViewDownStart(2)
        after(0.8, function() MoveViewDownStop() end)
    end
    camMode = mode
    send("CAM;" .. mode)
    if SimsCraftCamButton then SimsCraftCamButton:SetText(CAM_SHORT[mode] or LS"Камера") end
end

local function nextCam() setCam(CAM_NEXT[camMode] or "normal") end

local wallsMode = "auto"
local WALLS_NEXT = { auto = "down", down = "up", up = "auto" }
local WALLS_LABEL = { auto = LS"Дом: А", down = LS"Без дома", up = LS"Дом" }
local function nextWalls() send("WALLS;" .. WALLS_NEXT[wallsMode]) end

---------------------------------------------------------------------
-- ГЛАВНАЯ ПАНЕЛЬ
---------------------------------------------------------------------
local f = CreateFrame("Frame", "SimsCraftFrame", UIParent)
f:SetWidth(300); f:SetHeight(300)
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -180)
f:SetBackdrop(BACKDROP)
f:SetBackdropColor(0.05, 0.07, 0.10, 0.88)
f:SetBackdropBorderColor(0.31, 0.76, 0.97, 0.9)
f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function(self) if not SimsCraftDB.locked then self:StartMoving() end end)
f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); savePos(self) end)

local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", 12, -10)
title:SetText("|cff4fc3f7Sims|rCraft")
local gem = f:CreateTexture(nil, "OVERLAY")
gem:SetWidth(22); gem:SetHeight(22)
gem:SetTexture("Interface\\Icons\\INV_Misc_Gem_Emerald_02")
gem:SetTexCoord(0.08, 0.92, 0.08, 0.92)
gem:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -6)
local moodText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
moodText:SetPoint("RIGHT", gem, "LEFT", -6, 0)
moodText:SetText(LS"ожидание сервера...")

local bars = {}
for i, n in ipairs(NEEDS) do
    local bar = makeBar(f, 234, 14, n.color[1], n.color[2], n.color[3])
    bar:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -34 - (i - 1) * 19)
    bar.label:SetText(n.name); bar.value:SetText("—")
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(n.name, n.color[1], n.color[2], n.color[3])
        GameTooltip:AddLine(n.tip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bars[n.key] = bar
end

local info = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
info:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -150)
info:SetWidth(234); info:SetJustifyH("LEFT")
local traitsText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
traitsText:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -3)
traitsText:SetWidth(234); traitsText:SetJustifyH("LEFT")

-- окна объявим заранее
local Catalog, Place, Social, Family

local row1 = {
    { LS"Сон", function() DoEmote("SLEEP") end, LS"Лечь спать прямо здесь" },
    { LS"Танец", function() DoEmote("DANCE") end, LS"Потанцевать: +веселье" },
    { LS"Смена", function() send("WORK") end, LS"Выйти на рабочую смену" },
    { LS"Домой", function() send("HOME") end, LS"Телепорт домой (откат 30 мин)" },
    { LS"Действие", function() send("USE") end, LS"Использовать ближайшую мебель (свою или встроенную в готовый дом)" },
    { LS"Позвать", function() send("PHONE") end, LS"Телефон" },
}
local row2 = {
    { LS"Каталог", function() Catalog:Toggle() end, LS"Мебель, стройка и готовые дома" },
    { LS"Общение", function() Social:Toggle() end, LS"Взаимодействие с выделенным персонажем" },
    { LS"Семья", function() Family:Toggle() end, LS"Партнёр и дети" },
    { LS"Камера", function() nextCam() end, LS"Сменить камеру" },
    { LS"Вещи", function() send("MOVE") end, LS"Переставить ближайший свой предмет" },
    { LS"Обустр.", function() send("SPOTS") end, LS"Обустроить готовый дом: отметить встроенную кровать, плиту, ванну и т. д., чтобы ими можно было пользоваться" },
}
for i, b in ipairs(row1) do
    local btn = makeButton(f, b[1], 46, 20, b[2], b[3])
    btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6 + (i - 1) * 48, 32)
    if i == 6 then SimsCraftWallsButton = btn end
end
for i, b in ipairs(row2) do
    local btn = makeButton(f, b[1], 46, 20, b[2], b[3])
    btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6 + (i - 1) * 48, 9)
    if i == 4 then SimsCraftCamButton = btn end
end

local function refreshInfo()
    local lines = {}
    local c = CAREERS[state.career]
    lines[#lines + 1] = c and string.format("|cffffd100%s:|r %s (%d%%)", c[1], c[2][state.rank] or "?", math.min(state.perf, 100))
        or LS"|cffffd100Карьера:|r нет (Хранитель жизни)"
    lines[#lines + 1] = LS"|cffffd100Уют:|r " .. state.comfort .. (state.comfort >= 10 and LS" — как дома!" or "")
    if state.workEnd then lines[#lines + 1] = LS"|cff40ff40На смене:|r " .. fmtTime(state.workEnd - GetTime()) end
    if state.sleeping then lines[#lines + 1] = LS"|cff8080ffСпит... Zzz|r" end
    if state.pregEnd then lines[#lines + 1] = LS"|cffff80ffМалыш появится через|r " .. fmtTime(state.pregEnd - GetTime()) end
    info:SetText(table.concat(lines, "\n"))
    local names = {}
    for id in string.gmatch(state.traits or "", "%d+") do
        local t = TRAITS[tonumber(id)]
        if t then names[#names + 1] = t end
    end
    traitsText:SetText(#names > 0 and (LS"Черты: " .. table.concat(names, ", ")) or LS"Черты: не выбраны")
end

local function applyHud(p)
    for i, n in ipairs(NEEDS) do
        local v = tonumber(p[i + 1]) or 0
        state.values[n.key] = v
        local bar = bars[n.key]
        bar:SetValue(v); bar.value:SetText(v)
        if v < 25 then bar.value:SetTextColor(1, 0.3, 0.3) else bar.value:SetTextColor(1, 1, 1) end
        if v < 15 and not lastWarn[n.key] then
            lastWarn[n.key] = true
            PlaySound("RaidWarning")
            UIErrorsFrame:AddMessage(n.name .. LS": критически низко!", 1, 0.3, 0.3, 1, 3)
        elseif v >= 30 then lastWarn[n.key] = nil end
    end
    state.mood = tonumber(p[8]) or 3
    state.career = tonumber(p[9]) or 0
    state.rank = tonumber(p[10]) or 1
    state.perf = tonumber(p[11]) or 0
    local left = tonumber(p[12]) or 0
    state.workEnd = left > 0 and (GetTime() + left) or nil
    state.sleeping = p[13] == "1"
    state.comfort = tonumber(p[14]) or 0
    local pl = tonumber(p[15]) or -1
    state.pregEnd = pl >= 0 and (GetTime() + pl) or nil
    state.traits = p[16] or ""
    local m = MOODS[state.mood] or MOODS[3]
    moodText:SetText(m.name); moodText:SetTextColor(m.r, m.g, m.b)
    gem:SetVertexColor(m.r, m.g, m.b)
    refreshInfo()
end

local WEEKDAYS = { LS"пн", LS"вт", LS"ср", LS"чт", LS"пт", LS"сб", LS"вс" }
local PHASES = { { 0, LS"ночь" }, { 6, LS"утро" }, { 11, LS"день" }, { 18, LS"вечер" }, { 23, LS"ночь" } }
local function clockLine()
    if not clock.at then return "" end
    local sec = (clock.sec + (GetTime() - clock.at) * clock.speed) % 86400
    local h, m = math.floor(sec / 3600), math.floor(sec % 3600 / 60)
    local ph = LS"ночь"
    for _, p in ipairs(PHASES) do if h >= p[1] then ph = p[2] end end
    return string.format("|cffffffff%02d:%02d|r |cffaaaaaa%s, %s|r", h, m, WEEKDAYS[(clock.day or 0) % 7 + 1], ph)
end
local elapsedTotal, infoTimer = 0, 0
f:SetScript("OnUpdate", function(self, el)
    elapsedTotal = elapsedTotal + el
    gem:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -6 + math.sin(elapsedTotal * 2.5) * 2)
    infoTimer = infoTimer + el
    if infoTimer >= 1 then
        infoTimer = 0
        title:SetText("|cff4fc3f7Sims|rCraft " .. clockLine())
        if state.workEnd or state.pregEnd then refreshInfo() end
    end
end)

---------------------------------------------------------------------
-- КАТАЛОГ
---------------------------------------------------------------------
Catalog = makeWindow("SimsCraftCatalog", 560, 430, LS"|cff4fc3f7SimsCraft|r — каталог")
Catalog.cat = "bedroom"
Catalog.page = 1
local ROWS = 14
Catalog.catButtons = {}
Catalog.rows = {}

for i = 1, ROWS do
    local r = CreateFrame("Frame", nil, Catalog)
    r:SetWidth(400); r:SetHeight(22)
    r:SetPoint("TOPLEFT", Catalog, "TOPLEFT", 148, -36 - (i - 1) * 24)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints(r); r.bg:SetTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0.08)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.name:SetPoint("LEFT", 6, 0); r.name:SetWidth(210); r.name:SetJustifyH("LEFT")
    r.price = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.price:SetPoint("LEFT", 220, 0); r.price:SetWidth(110); r.price:SetJustifyH("LEFT")
    r.buy = makeButton(r, LS"Купить", 60, 18, function(self)
        if r.idx then send("BUY;" .. r.idx); Catalog:Hide() end
    end)
    r.buy:SetPoint("RIGHT", -4, 0)
    Catalog.rows[i] = r
end

local pageText = Catalog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
pageText:SetPoint("BOTTOMRIGHT", Catalog, "BOTTOMRIGHT", -80, 42)
local prev = makeButton(Catalog, "<", 24, 20, function() Catalog.page = math.max(1, Catalog.page - 1); Catalog:Refresh() end)
prev:SetPoint("RIGHT", pageText, "LEFT", -6, 0)
local nextb = makeButton(Catalog, ">", 24, 20, function() Catalog.page = Catalog.page + 1; Catalog:Refresh() end)
nextb:SetPoint("LEFT", pageText, "RIGHT", 6, 0)

makeButton(Catalog, LS"Переставить ближайшее", 150, 22, function() send("MOVE"); Catalog:Hide() end,
    LS"Взять свой ближайший предмет (до 12 м, здания до 45 м) и передвинуть"):SetPoint("BOTTOMLEFT", Catalog, "BOTTOMLEFT", 12, 12)
makeButton(Catalog, LS"Продать ближайшее", 130, 22, function() send("SELL") end,
    LS"Продать свой ближайший предмет за половину цены"):SetPoint("BOTTOMLEFT", Catalog, "BOTTOMLEFT", 168, 12)
local hint = Catalog:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint:SetPoint("BOTTOMLEFT", Catalog, "BOTTOMLEFT", 306, 18)
hint:SetText(LS"Предмет появится перед вами — его можно двигать.")

function Catalog:BuildCats()
    for _, b in ipairs(self.catButtons) do b:Hide() end
    for i, c in ipairs(catalog.cats) do
        local b = self.catButtons[i]
        if not b then
            b = makeButton(self, "", 126, 24)
            b:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -36 - (i - 1) * 28)
            self.catButtons[i] = b
        end
        b:SetText(c.name)
        b:SetScript("OnClick", function() Catalog.cat = c.key; Catalog.page = 1; Catalog:Refresh() end)
        b:Show()
    end
end

function Catalog:Refresh()
    if not catalog.loaded then
        for _, r in ipairs(self.rows) do r:Hide() end
        pageText:SetText(LS"загрузка...")
        return
    end
    local list = {}
    for idx, it in pairs(catalog.items) do if it.cat == self.cat then list[#list + 1] = it end end
    table.sort(list, function(a, b) return a.idx < b.idx end)
    local pages = math.max(1, math.ceil(#list / ROWS))
    if self.page > pages then self.page = pages end
    pageText:SetText(self.page .. " / " .. pages)
    for i, r in ipairs(self.rows) do
        local it = list[(self.page - 1) * ROWS + i]
        if it then
            r.idx = it.idx
            r.name:SetText(it.name .. (it.kind ~= "" and it.kind ~= "house" and " |cff80ff80*|r" or ""))
            r.price:SetText(moneyText(it.price))
            if GetMoney() >= it.price then r.price:SetTextColor(1, 1, 1) else r.price:SetTextColor(1, 0.3, 0.3) end
            r:Show()
        else
            r.idx = nil; r:Hide()
        end
    end
    for i, c in ipairs(catalog.cats) do
        local b = self.catButtons[i]
        if b then if c.key == self.cat then b:LockHighlight() else b:UnlockHighlight() end end
    end
end

function Catalog:Toggle()
    if self:IsShown() then self:Hide() return end
    self:Show()
    if not catalog.loaded then send("CAT") end
    self:Refresh()
end
local legend = Catalog:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
legend:SetPoint("TOPRIGHT", Catalog, "TOPRIGHT", -36, -14)
legend:SetText(LS"|cff80ff80*|r — с этим можно взаимодействовать")

---------------------------------------------------------------------
-- РАССТАНОВКА
---------------------------------------------------------------------
Place = makeWindow("SimsCraftPlace", 260, 250, LS"Расстановка")
Place:SetPoint("CENTER", UIParent, "CENTER", 300, -60)
Place.step = 1
local placeInfo = Place:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
placeInfo:SetPoint("TOPLEFT", 12, -30); placeInfo:SetWidth(236); placeInfo:SetJustifyH("LEFT")

local function pm(dir, mult) return function() send("PM;" .. dir .. ";" .. (Place.step * (mult or 1))) end end
local grid = {
    { LS"Поворот <", pm("rl"), 12, -64 }, { LS"Вперёд", pm("f"), 92, -64 }, { LS"Поворот >", pm("rr"), 172, -64 },
    { LS"Влево", pm("l"), 12, -88 }, { LS"К себе", function() send("PM;here;0") end, 92, -88 }, { LS"Вправо", pm("r"), 172, -88 },
    { LS"Выше", pm("u", 0.5), 12, -112 }, { LS"Назад", pm("b"), 92, -112 }, { LS"Ниже", pm("d", 0.5), 172, -112 },
}
for _, g in ipairs(grid) do
    makeButton(Place, g[1], 76, 22, g[2]):SetPoint("TOPLEFT", Place, "TOPLEFT", g[3], g[4])
end
local stepText = Place:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
stepText:SetPoint("TOPLEFT", 12, -144)
stepText:SetText(LS"Шаг:")
local stepButtons = {}
for i, v in ipairs({ 0.25, 1, 5 }) do
    local b = makeButton(Place, tostring(v), 44, 20, function()
        Place.step = v
        for _, sb in ipairs(stepButtons) do sb:UnlockHighlight() end
        stepButtons[i]:LockHighlight()
    end, LS"Шаг сдвига в метрах (поворот: 1 = 15°)")
    b:SetPoint("TOPLEFT", Place, "TOPLEFT", 50 + (i - 1) * 48, -140)
    stepButtons[i] = b
end
stepButtons[2]:LockHighlight()
makeButton(Place, LS"Перед собой", 115, 22, function() send("PM;front;0") end):SetPoint("TOPLEFT", Place, "TOPLEFT", 12, -170)
makeButton(Place, LS"Повернуть ко мне", 115, 22, function() send("PM;face;0") end):SetPoint("TOPLEFT", Place, "TOPLEFT", 133, -170)
local okb = makeButton(Place, LS"Поставить", 115, 26, function() send("PO") end)
okb:SetPoint("BOTTOMLEFT", Place, "BOTTOMLEFT", 12, 12)
makeButton(Place, LS"Отмена", 115, 26, function() send("PC") end):SetPoint("BOTTOMRIGHT", Place, "BOTTOMRIGHT", -12, 12)
Place:SetScript("OnHide", function(self) if self.active then send("PC") end end)

---------------------------------------------------------------------
-- ОБЩЕНИЕ
---------------------------------------------------------------------
Social = makeWindow("SimsCraftSocial", 330, 300, LS"Общение")
Social:SetPoint("CENTER", UIParent, "CENTER", -250, 0)
local sName = Social:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
sName:SetPoint("TOPLEFT", 12, -32)
local sStatus = Social:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sStatus:SetPoint("TOPLEFT", 12, -54); sStatus:SetWidth(300); sStatus:SetJustifyH("LEFT")
local fBar = makeBar(Social, 300, 14, 0.4, 0.9, 0.4)
fBar:SetPoint("TOPLEFT", 12, -72); fBar:SetMinMaxValues(-100, 100); fBar.label:SetText(LS"Дружба")
local rBar = makeBar(Social, 300, 14, 1, 0.45, 0.8)
rBar:SetPoint("TOPLEFT", 12, -90); rBar.label:SetText(LS"Романтика")
Social.buttons = {}
for i, a in ipairs(SOCIAL) do
    local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
    local b = makeButton(Social, a[2], 100, 22, function() send("SOC;" .. a[1]) end)
    b:SetPoint("TOPLEFT", Social, "TOPLEFT", 12 + col * 103, -114 - row * 26)
    Social.buttons[i] = b
end
local sToday = Social:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
sToday:SetPoint("TOPRIGHT", Social, "TOPRIGHT", -34, -36)
local sHint = Social:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
sHint:SetPoint("BOTTOMLEFT", 12, 12); sHint:SetWidth(306); sHint:SetJustifyH("LEFT")
sHint:SetText(LS"Выделите персонажа, NPC или бота и подойдите ближе.")

function Social:SetRel(p)
    local name = p[2] or ""
    if name == "" then
        sName:SetText(LS"Никто не выделен"); sStatus:SetText(""); sToday:SetText("")
        fBar:SetValue(0); fBar.value:SetText(""); rBar:SetValue(0); rBar.value:SetText("")
        for _, b in ipairs(self.buttons) do b:Disable() end
        return
    end
    for _, b in ipairs(self.buttons) do b:Enable() end
    local fv, rv = tonumber(p[3]) or 0, tonumber(p[4]) or 0
    sName:SetText(name)
    local kind = ({ [0] = "NPC", [1] = LS"игрок", [2] = LS"бот" })[tonumber(p[7]) or 0] or ""
    sStatus:SetText((p[5] or "") .. "  |cff888888(" .. kind .. ")|r")
    fBar:SetValue(fv); fBar.value:SetText(fv)
    fBar:SetStatusBarColor(fv >= 0 and 0.4 or 1, fv >= 0 and 0.9 or 0.35, 0.35)
    rBar:SetValue(rv); rBar.value:SetText(rv)
    local gf, gr, cf, cr = tonumber(p[8]) or 0, tonumber(p[9]) or 0, tonumber(p[10]) or 30, tonumber(p[11]) or 20
    sToday:SetText(string.format(LS"сегодня: дружба +%d/%d, романтика +%d/%d", gf, cf, gr, cr))
end
function Social:Toggle()
    if self:IsShown() then self:Hide() else self:Show(); send("REL") end
end

---------------------------------------------------------------------
-- СЕМЬЯ
---------------------------------------------------------------------
Family = makeWindow("SimsCraftFamily", 340, 330, LS"Семья")
local famPartner = Family:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
famPartner:SetPoint("TOPLEFT", 12, -32); famPartner:SetWidth(316); famPartner:SetJustifyH("LEFT")
local famPreg = Family:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
famPreg:SetPoint("TOPLEFT", 12, -50)
Family.rows = {}
for i = 1, 8 do
    local r = CreateFrame("Frame", nil, Family)
    r:SetWidth(316); r:SetHeight(22)
    r:SetPoint("TOPLEFT", Family, "TOPLEFT", 12, -70 - (i - 1) * 24)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.text:SetPoint("LEFT", 4, 0); r.text:SetWidth(230); r.text:SetJustifyH("LEFT")
    r.rename = makeButton(r, LS"Имя", 60, 18, function()
        if r.id then
            local d = StaticPopup_Show("SIMSCRAFT_NAME", r.kname or LS"ребёнка")
            if d then d.data = r.id end
        end
    end)
    r.rename:SetPoint("RIGHT", -2, 0)
    Family.rows[i] = r
end
makeButton(Family, LS"Позвать детей", 100, 22, function() send("FAM;call") end):SetPoint("BOTTOMLEFT", 12, 12)
makeButton(Family, LS"Отправить домой", 110, 22, function() send("FAM;home") end):SetPoint("BOTTOMLEFT", 116, 12)
makeButton(Family, LS"Обновить", 90, 22, function() send("FAM;") end):SetPoint("BOTTOMRIGHT", -12, 12)

function Family:Refresh()
    local st = family.status == "married" and LS"супруг(а)" or (family.status == "dating" and LS"встречаетесь" or "")
    famPartner:SetText(family.partner ~= "" and (LS"Партнёр: |cffff80ff" .. family.partner .. "|r (" .. st .. ")") or LS"Партнёра нет. Познакомьтесь с кем-нибудь в окне «Общение».")
    famPreg:SetText(state.pregEnd and (LS"|cffff80ffМалыш появится через " .. fmtTime(state.pregEnd - GetTime()) .. "|r") or "")
    for i, r in ipairs(self.rows) do
        local k = family.kids[i]
        if k then
            r.id, r.kname = k.id, k.name
            local hc = k.happy >= 60 and "40ff40" or (k.happy >= 30 and "ffd100" or "ff4040")
            r.text:SetText(string.format(LS"%s %s — %s, счастье |cff%s%d%%|r, развитие %d%%%s",
                k.gender == 1 and LS"|cffff9ad5Дочь|r" or LS"|cff8ac8ffСын|r", k.name, KID_STAGES[k.stage] or "?", hc, k.happy, k.skill, k.out and LS" |cff80c0ff(с вами)|r" or (k.home and LS" |cff80ff80(дома)|r" or (k.moved and (LS" |cffffb0ff(живёт своей семьёй " .. k.moved .. ")|r") or ""))))
            r:Show()
        else
            r.id = nil; r:Hide()
        end
    end
    if #family.kids == 0 then self.rows[1].text:SetText(LS"Детей пока нет."); self.rows[1].rename:Hide(); self.rows[1]:Show()
    else self.rows[1].rename:Show() end
end
function Family:Toggle()
    if self:IsShown() then self:Hide() else self:Show(); send("FAM;") end
end

---------------------------------------------------------------------
-- ВСПЛЫВАЮЩИЕ ОКНА
---------------------------------------------------------------------
StaticPopupDialogs["SIMSCRAFT_REQ"] = {
    text = LS"%s предлагает: «%s».",
    button1 = LS"Согласиться", button2 = LS"Отказаться",
    OnAccept = function() send("ANS;1") end,
    OnCancel = function() send("ANS;0") end,
    timeout = 90, whileDead = 1, hideOnEscape = 1,
}
StaticPopupDialogs["SIMSCRAFT_NAME"] = {
    text = LS"Как назовём %s?",
    button1 = LS"Готово", button2 = LS"Отмена",
    hasEditBox = 1, maxLetters = 20,
    OnShow = function(self) local eb = _G[self:GetName() .. "EditBox"]; if eb then eb:SetText(""); eb:SetFocus() end end,
    OnAccept = function(self, data)
        local eb = _G[self:GetName() .. "EditBox"]
        local name = eb and eb:GetText() or ""
        if name ~= "" and data then send("CNAME;" .. data .. ";" .. name) end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = self:GetText()
        if name ~= "" and parent.data then send("CNAME;" .. parent.data .. ";" .. name) end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}

---------------------------------------------------------------------
-- СООБЩЕНИЯ СЕРВЕРА
---------------------------------------------------------------------
local pendingKids

local HANDLERS = {
    S = function(p) gotData = true; applyHud(p) end,
    T = function(p)
        -- игровые часы: секунда суток, скорость (игровых сек в реальную), день
        clock.sec = tonumber(p[2]) or 0
        clock.speed = tonumber(p[3]) or 30
        clock.day = tonumber(p[4]) or 1
        clock.at = GetTime()
    end,
    CC = function(p)
        if not catalog.building then catalog.cats = {}; catalog.items = {}; catalog.building = true end
        catalog.cats[#catalog.cats + 1] = { key = p[2], name = p[3] }
    end,
    C = function(p)
        local idx = tonumber(p[2])
        if idx then catalog.items[idx] = { idx = idx, cat = p[3], price = tonumber(p[4]) or 0, name = p[5] or "?", kind = p[6] or "" } end
    end,
    CE = function(p)
        catalog.building = nil; catalog.loaded = true
        Catalog:BuildCats(); Catalog:Refresh()
    end,
    OPEN = function(p)
        if p[2] == "CAT" then Catalog:Show(); Catalog:Refresh()
        elseif p[2] == "FAM" then Family:Show(); Family:Refresh() end
    end,
    P = function(p)
        Place.active = true
        Place.title:SetText((p[8] == "1" and LS"Перестановка: " or LS"Покупка: ") .. (p[2] or ""))
        placeInfo:SetText(string.format(LS"x %s  y %s  z %s  поворот %s°\n%s", p[3] or "", p[4] or "", p[5] or "", p[6] or "",
            p[8] == "1" and LS"Бесплатно" or (LS"Цена: " .. moneyText(p[7]))))
        Place:Show()
    end,
    PX = function() Place.active = false; Place:Hide() end,
    IN = function(p)
        local was = indoor
        indoor = p[2] == "1"
        if camMode == "top" and was ~= indoor then
            MoveViewUpStop(); MoveViewDownStop()
            SetCVar("cameraDistanceMax", indoor and INDOOR_DIST or 50)
            SetCVar("cameraDistanceMaxFactor", indoor and 1 or 4)
            if indoor then CameraZoomIn(50); CameraZoomOut(INDOOR_DIST) else CameraZoomOut(50) end
        end
    end,
    WALLS = function(p)
        wallsMode = p[2] or "auto"
        if SimsCraftWallsButton then SimsCraftWallsButton:SetText(WALLS_LABEL[wallsMode] or LS"Стены") end
    end,
    R = function(p) Social:SetRel(p) end,
    Q = function(p) StaticPopup_Show("SIMSCRAFT_REQ", p[3] or "?", p[4] or "?") end,
    NAME = function(p)
        PlaySound("LEVELUPSOUND")
        local d = StaticPopup_Show("SIMSCRAFT_NAME", p[3] == "1" and LS"дочку" or LS"сына")
        if d then d.data = p[2] end
    end,
    FP = function(p)
        family.partner, family.status = p[2] or "", p[3] or ""
        pendingKids = {}
    end,
    FK = function(p)
        pendingKids = pendingKids or {}
        pendingKids[#pendingKids + 1] = { id = p[2], name = p[3] or "?", gender = tonumber(p[4]) or 0, stage = tonumber(p[5]) or 1,
            happy = tonumber(p[6]) or 0, skill = tonumber(p[7]) or 0, out = p[8] == "1", home = p[8] == "2", moved = p[8] == "3" and (p[9] or ""), grade = p[10] }
    end,
    FE = function()
        family.kids = pendingKids or {}
        pendingKids = nil
        Family:Refresh()
    end,
}

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("CHAT_MSG_ADDON")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("PLAYER_MONEY")
ev:SetScript("OnEvent", function(self, event, a1, a2, a3, a4)
    if event == "ADDON_LOADED" and a1 == ADDON then
        SimsCraftDB = SimsCraftDB or {}
        if type(SimsCraftDB.pos) == "table" and SimsCraftDB.pos[1] then SimsCraftDB.pos = nil end -- формат v1
        for name, p in pairs(SimsCraftDB.pos or {}) do
            local fr = _G[name]
            if fr then fr:ClearAllPoints(); fr:SetPoint(p[1], UIParent, p[2], p[3], p[4]) end
        end
        if SimsCraftDB.hidden or SimsCraftDB.ui ~= "classic" then f:Hide() end
        if SimsCraftAPI.onLoad then SimsCraftAPI.onLoad() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        after(2, function() send("LOC;" .. (GetLocale and GetLocale() or "enUS")); send("SYNC"); send("CAM;" .. camMode) end)
    elseif event == "PLAYER_TARGET_CHANGED" then
        if Social:IsShown() then send("REL") end
    elseif event == "PLAYER_MONEY" then
        if Catalog:IsShown() then Catalog:Refresh() end
    elseif event == "CHAT_MSG_ADDON" and a1 == PREFIX then
        if a4 ~= UnitName("player") then return end
        local p = { strsplit(";", a2) }
        local h = HANDLERS[p[1]]
        if h then h(p) end
        local ext = SimsCraftAPI.handlers[p[1]]
        if ext then for _, fn in ipairs(ext) do fn(p) end end
    end
end)

---------------------------------------------------------------------
-- ДЛЯ ПАНЕЛИ «КАК В СИМС» (SimsUI.lua)
---------------------------------------------------------------------
SimsCraftAPI = {
    send = send, state = state, clock = clock, family = family, catalog = catalog,
    makeBar = makeBar, makeButton = makeButton, makeWindow = makeWindow, BACKDROP = BACKDROP, moneyText = moneyText, fmtTime = fmtTime,
    NEEDS = NEEDS, CAREERS = CAREERS, KID_STAGES = KID_STAGES, TRAITS = TRAITS, SOCIAL = SOCIAL,
    setCam = setCam, nextCam = nextCam, nextWalls = nextWalls, clockLine = clockLine, after = after,
    Catalog = Catalog, Social = Social, Family = Family, classic = f, handlers = {},
    on = function(cmd, fn) SimsCraftAPI.handlers[cmd] = SimsCraftAPI.handlers[cmd] or {}; table.insert(SimsCraftAPI.handlers[cmd], fn) end,
}

---------------------------------------------------------------------
-- КОМАНДЫ
---------------------------------------------------------------------
SLASH_SIMSCRAFT1 = "/simscraft"
SLASH_SIMSCRAFT2 = "/scui"
SlashCmdList["SIMSCRAFT"] = function(arg)
    arg = string.lower(arg or "")
    if arg == "lock" then
        SimsCraftDB.locked = not SimsCraftDB.locked
        DEFAULT_CHAT_FRAME:AddMessage(LS"SimsCraft: панель " .. (SimsCraftDB.locked and LS"закреплена" or LS"откреплена"))
    elseif arg == "reset" then
        SimsCraftDB.pos = nil
        f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -180)
    elseif arg == "sync" then send("SYNC")
    elseif arg == "cat" then Catalog:Toggle()
    elseif arg == "soc" then Social:Toggle()
    elseif arg == "fam" then Family:Toggle()
    elseif arg == "top" then setCam("top")
    elseif arg == "first" then setCam("first")
    elseif arg == "shoulder" then setCam("shoulder")
    elseif arg == "cam" then setCam("normal")
    elseif arg == "classic" or arg == "sims" or arg == "wow" then
        SimsCraftDB.ui = (arg == "classic") and "classic" or "wow"
        if SimsCraftAPI.applyUI then SimsCraftAPI.applyUI() end
    elseif SimsCraftAPI.toggle and SimsCraftDB.ui ~= "classic" then
        SimsCraftAPI.toggle()
    else
        if f:IsShown() then f:Hide() else f:Show() end
        SimsCraftDB.hidden = not f:IsShown()
        if f:IsShown() and not gotData then send("SYNC") end
    end
end
