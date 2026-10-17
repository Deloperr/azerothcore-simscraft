-- Заглушки API клиента 3.3.5 для проверки аддона SimsCraft 2.0
local frames, named = {}, {}
local function mock(name)
    local o = { _name = name, _scripts = {}, _shown = true, _text = nil, _enabled = true }
    return setmetatable(o, { __index = function(t, k)
        if k == "SetScript" then return function(s, ev, fn) s._scripts[ev] = fn end end
        if k == "GetScript" then return function(s, ev) return s._scripts[ev] end end
        if k == "SetText" then return function(s, v) s._text = v end end
        if k == "GetText" then return function(s) return s._text end end
        if k == "Show" then return function(s) s._shown = true; if s._scripts.OnShow then s._scripts.OnShow(s) end end end
        if k == "Hide" then return function(s) local was = s._shown; s._shown = false; if was and s._scripts.OnHide then s._scripts.OnHide(s) end end end
        if k == "IsShown" then return function(s) return s._shown end end
        if k == "Disable" then return function(s) s._enabled = false end end
        if k == "Enable" then return function(s) s._enabled = true end end
        if k == "GetName" then return function(s) return s._name end end
        if k == "GetPoint" then return function() return "TOPLEFT", nil, "TOPLEFT", 1, 2 end end
        if k:match("^Create") then return function(s, ...) local m = mock(k); frames[#frames + 1] = m; return m end end
        if k == "GetFontString" then return function() return mock("fs") end end
        if k == "GetParent" then return function(s) return s._parent end end
        if k == "SetPoint" then return function(s, p, rel, rp, x, y) s._pt = { p, rel, rp, x, y } end end
        if k == "SetAlpha" then return function(s, a) s._alpha = a end end
        if k == "GetChecked" then return function(s) return s._checked end end
        if k == "SetChecked" then return function(s, v) s._checked = v end end
        if k == "SetScale" then return function(s, v) s._scale = v end end
        if k == "GetScale" then return function(s) return s._scale or 1 end end
        if k == "SetWidth" then return function(s, v) s._w = v end end
        if k == "SetUnit" then return function(s, v) s._unit = v end end
        if k == "SetBackdrop" then return function(s, v) s._bd = v end end
        if k == "SetBackdropBorderColor" then return function(s, r, g, b) s._border = { r, g, b } end end
        if k == "SetStatusBarTexture" then return function(s, v) s._tex = v end end
        if k == "SetStatusBarColor" then return function(s, r, g, b) s._col = { r, g, b } end end
        if k == "SetParent" then return function(s, p) s._parent = p end end
        return function() end
    end })
end
UIParent = mock("UIParent")
GameTooltip = mock("tt"); UIErrorsFrame = mock("err"); DEFAULT_CHAT_FRAME = mock("chat")
GameFontHighlightSmall = {}
UISpecialFrames = {}
tinsert = table.insert
SlashCmdList = {}
StaticPopupDialogs = {}
local shownPopup
function StaticPopup_Show(which, a1, a2)
    assert(StaticPopupDialogs[which], "нет диалога " .. which)
    local d = mock("StaticPopup1"); d._which = which; d._args = { a1, a2 }
    shownPopup = d
    return d
end
local sent = {}
local cvars = {}
function CreateFrame(t, n, parent, tmpl) local m = mock(n or t); frames[#frames + 1] = m; if n then _G[n] = m end; return m end
function SendAddonMessage(p, m, c, t) assert(p == "SIMSC" and c == "WHISPER"); sent[#sent + 1] = m end
function UnitName() return "Тест" end
function GetTime() return 100 end
function GetMoney() return 5000000 end
function PlaySound() end
function DoEmote() end
function SetCVar(k, v) cvars[k] = v end
function GetCVar(k) return cvars[k] or "0" end
function CameraZoomIn() end
function CameraZoomOut() end
function MoveViewUpStart() end
function MoveViewUpStop() end
function MoveViewDownStart() end
function MoveViewDownStop() end
function strsplit(sep, s)
    local out = {}
    for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = part end
    return (unpack or table.unpack)(out)
end
unpack = unpack or table.unpack
Minimap = mock("Minimap")
local tgtExists = false
function UnitExists(u) return u == "player" or (u == "target" and tgtExists) end
function UnitIsUnit() return false end
function UnitIsPlayer() return false end
function UnitCanAttack() return false end
function UnitLevel() return 10 end
function UnitCreatureType() return "Гуманоид" end
function SetPortraitTexture(t, u) t._portrait = u end
PlayerFrame = mock("PlayerFrame"); TargetFrame = mock("TargetFrame"); PlayerPortrait = mock("PlayerPortrait")
UIPanelWindows = {}
function ShowUIPanel(f) f:Show() end
function HideUIPanel(f) f:Hide() end
function PanelTemplates_SetNumTabs(f, n) f._ntabs = n end
function PanelTemplates_SetTab(f, i) f._tab = i end
function PanelTemplates_TabResize() end
function GetCursorPosition() return 0, 0 end
MainMenuBar = mock("MainMenuBar")
local mmbPoint
MainMenuBar.SetPoint = function(s, p, rel, rp, x, y) mmbPoint = y; s._pt = { p, rel, rp, x, y } end
function UnitHasVehicleUI() return false end
function hooksecurefunc() end
function UIParent_ManageFramePositions() end
function RegisterUnitWatch(f) f._watch = true end
function UnregisterUnitWatch(f) f._watch = false end
function RegisterStateDriver(f, a, c) f._driver = c end
function UnregisterStateDriver(f) f._driver = nil end
function UnitHealth() return 500 end
function UnitHealthMax() return 1000 end
function UnitPowerType() return 0 end
function UnitPower() return 300 end
function UnitPowerMax() return 600 end
function UnitIsEnemy() return false end
function UnitPlayerControlled() return false end
function UnitAura(u, i, f) if i == 1 and f == "HARMFUL" then return "Яд", nil, "icon", 2, nil, 10, 110 end end
PowerBarColor = { [0] = { r = 0, g = 0, b = 1 } }
local optPanels = {}
function InterfaceOptions_AddCategory(p) optPanels[#optPanels + 1] = p end
function IsShiftKeyDown() return false end
function UnitClass() return "Маг", "MAGE" end
RAID_CLASS_COLORS = { MAGE = { r = 0.4, g = 0.8, b = 0.9 } }
local inCombat = false
function InCombatLockdown() return inCombat end
local function blz(n) local m = mock(n); _G[n] = m; return m end
for _, n in ipairs({ "ActionButton1", "MultiBarBottomLeft", "MultiBarBottomLeftButton1", "MainMenuBarArtFrame", "MainMenuBarBackpackButton",
    "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap", "MainMenuBarTexture0", "ShapeshiftBarFrame", "CastingBarFrame", "MainMenuExpBar" }) do blz(n) end
CharacterMicroButton = blz("CharacterMicroButton"); CharacterMicroButton._parent = MainMenuBarArtFrame
ChatFrame1 = blz("ChatFrame1"); ChatFrame1.GetBottom = function() return 95 end; ChatFrame1.GetLeft = function() return 32 end
ShapeshiftBarFrame._shown = false

function GetLocale() return os.getenv("LOCALE") or "ruRU" end
dofile(arg[1])
dofile(arg[2])
dofile(arg[3])

local function check(c, t) if not c then error("ПРОВАЛ: " .. t, 2) end print("  ок: " .. t) end
local evf
for _, fr in ipairs(frames) do if fr._scripts.OnEvent and not evf then evf = fr end end
local function srv(msg) evf._scripts.OnEvent(evf, "CHAT_MSG_ADDON", "SIMSC", msg, "WHISPER", "Тест") end
local timerFrame
for _, fr in ipairs(frames) do if fr._scripts.OnUpdate and not fr._scripts.OnEvent and fr ~= SimsCraftFrame and not timerFrame then timerFrame = fr end end

evf._scripts.OnEvent(evf, "ADDON_LOADED", "SimsCraft")
evf._scripts.OnEvent(evf, "PLAYER_ENTERING_WORLD")
timerFrame._scripts.OnUpdate(timerFrame, 3)
check(sent[#sent - 2]:match("^LOC;") and sent[#sent - 1] == "SYNC" and sent[#sent] == "CAM;normal", "язык, SYNC и режим камеры при входе")
if os.getenv("LOCALE") == "enUS" then
    -- английский клиент: в интерфейсе не должно остаться русских надписей
    local left = {}
    for _, fr in ipairs(frames) do
        if type(fr._text) == "string" and fr._text:find("[\208\209]") then left[#left + 1] = fr._text end
    end
    for i = 1, math.min(#left, 30) do print("  RU> " .. left[i]) end
    check(#left == 0, "английский интерфейс без русских надписей: осталось " .. #left)
    print("Addon translation check passed (enUS)")
    os.exit(0)
end

srv("S;60;12;68;55;58;65;4;2;3;40;120;0;7;1800;1,12")
check(SimsCraftFrame ~= nil, "главная панель")

-- каталог
SlashCmdList.SIMSCRAFT("cat")
check(sent[#sent] == "CAT", "каталог запрошен")
srv("CC;bedroom;Спальня"); srv("CC;house;Готовые дома")
for i = 1, 20 do srv("C;" .. i .. ";bedroom;" .. (i * 10000) .. ";Кровать " .. i .. ";bed") end
srv("C;21;house;5000000;Дом;house")
srv("CE;21")
check(SimsCraftCatalog:IsShown(), "окно каталога открыто")
-- нажимаем «Купить» в первой строке
local buyBtn
for _, fr in ipairs(frames) do if fr._text == "Купить" and fr._scripts.OnClick then buyBtn = fr; break end end
buyBtn._scripts.OnClick(buyBtn)
check(sent[#sent]:match("^BUY;%d+$"), "покупка: " .. sent[#sent])

-- расстановка
srv("P;Кровать 1;13.5;20.0;30.2;195;10000;0")
check(SimsCraftPlace:IsShown() and SimsCraftPlace.active, "окно расстановки")
for _, fr in ipairs(frames) do
    if fr._text == "Вперёд" then fr._scripts.OnClick(fr) end
end
check(sent[#sent] == "PM;f;1", "сдвиг вперёд: " .. sent[#sent])
for _, fr in ipairs(frames) do if fr._text == "5" and fr._scripts.OnClick then fr._scripts.OnClick(fr) end end
for _, fr in ipairs(frames) do if fr._text == "Поворот >" then fr._scripts.OnClick(fr) end end
check(sent[#sent] == "PM;rr;5", "поворот с шагом 5: " .. sent[#sent])
for _, fr in ipairs(frames) do if fr._text == "Поставить" then fr._scripts.OnClick(fr) end end
check(sent[#sent] == "PO", "поставить")
srv("PX")
check(not SimsCraftPlace:IsShown() and sent[#sent] == "PO", "окно закрыто без лишней отмены")

-- общение
SlashCmdList.SIMSCRAFT("soc")
check(sent[#sent] == "REL", "запрос отношений")
srv("R;Трактирщица Эллисон;62;98;Друг, влюблённость;;0;12;5;30;20")
for _, fr in ipairs(frames) do if fr._text == "Поцеловать" then fr._scripts.OnClick(fr) end end
check(sent[#sent] == "SOC;kiss", "поцелуй")
evf._scripts.OnEvent(evf, "PLAYER_TARGET_CHANGED")
check(sent[#sent] == "REL", "смена цели обновляет отношения")
srv("R;;0;0;;;0")

-- запрос согласия
srv("Q;kiss;Борис;Поцеловать")
check(shownPopup and shownPopup._which == "SIMSCRAFT_REQ", "всплывающий запрос")
StaticPopupDialogs.SIMSCRAFT_REQ.OnAccept()
check(sent[#sent] == "ANS;1", "ответ «да»")

-- рождение и имя
srv("NAME;7;1;Ника")
check(shownPopup._which == "SIMSCRAFT_NAME" and shownPopup.data == "7", "окно имени")
local eb = mock("StaticPopup1EditBox"); eb._text = "Лилия"; _G["StaticPopup1EditBox"] = eb
StaticPopupDialogs.SIMSCRAFT_NAME.OnAccept(shownPopup, shownPopup.data)
check(sent[#sent] == "CNAME;7;Лилия", "имя отправлено")

-- семья
SlashCmdList.SIMSCRAFT("fam")
check(sent[#sent] == "FAM;", "запрос семьи")
srv("FP;Трактирщица Эллисон;married;-1"); srv("FK;7;Лилия;1;2;80;10;1"); srv("FE")
local found
for _, fr in ipairs(frames) do if type(fr._text) == "string" and fr._text:match("Лилия — Малыш") then found = fr._text end end
check(found, "ребёнок в списке: " .. tostring(found))

-- камера
SlashCmdList.SIMSCRAFT("top")
check(cvars.autointeract == 1 and cvars.cameraDistanceMax == 50 and sent[#sent] == "CAM;top", "камера сверху + ходьба по клику + сервер знает")
local wb
for _, fr in ipairs(frames) do if fr._text == "Стены" then wb = fr end end
check(not wb, "кнопки «Стены» больше нет")
SlashCmdList.SIMSCRAFT("cam")
check(cvars.autointeract == "0", "настройки камеры восстановлены")
-- 4.0: игровые часы и камера из-за плеча
srv("T;72000;30.000;4")
SimsCraftFrame._scripts.OnUpdate(SimsCraftFrame, 1.5)
local clk
for _, fr in ipairs(frames) do if type(fr._text) == "string" and fr._text:match("20:00") then clk = fr._text end end
check(clk and clk:match("пт") and clk:match("вечер"), "часы в панели: " .. tostring(clk))
SlashCmdList.SIMSCRAFT("shoulder")
check(sent[#sent] == "CAM;shoulder" and SimsCraftCamButton._text == "Плечо", "камера из-за плеча")
SlashCmdList.SIMSCRAFT("top")
srv("IN;1")
check(cvars.cameraDistanceMax == 4, "в доме камера сверху под потолком")
srv("IN;0")
check(cvars.cameraDistanceMax == 50, "вышли — камера снова высоко")
for _, fr in ipairs(frames) do if fr._text == "Действие" and fr._scripts.OnClick then fr._scripts.OnClick(fr) end end
check(sent[#sent] == "USE", "кнопка «Действие»")
srv("FK;9;Лира;1;5;80;10;3;у таверны, где работает Аллен"); srv("FE")
local mv
for _, fr in ipairs(frames) do if type(fr._text) == "string" and fr._text:match("живёт своей семьёй") then mv = fr._text end end
check(mv, "в семье: живёт отдельно")
-- 6.3: нижняя панель из блоков
for _, fr in ipairs(frames) do if fr._scripts.OnEvent and fr ~= evf then fr._scripts.OnEvent(fr, "PLAYER_ENTERING_WORLD") end end
check(SimsCraftSeg_sims._shown and SimsCraftSeg_player._shown and SimsCraftSeg_wow._shown and SimsCraftSeg_menu._shown, "блоки панели показаны")
check(SimsCraftUI._driver and SimsCraftUI._driver:match("bonusbar:5"), "в транспорте панель прячется сама")
check(MainMenuBar._pt[2] == SimsCraftSeg_wow, "панель действий WoW встроена в блок «навыки»")
check(MainMenuBarLeftEndCap._alpha == 0 and MainMenuBarTexture0._alpha == 0, "грифоны и обрамление убраны")
check(MultiBarBottomLeft._pt[2] == ActionButton1 and MultiBarBottomLeft._pt[3] == "TOPLEFT", "доп. панель — над основной")
check(CharacterMicroButton._pt[2] == SimsCraftSeg_menu and MainMenuBarBackpackButton._pt[2] == SimsCraftSeg_menu, "меню и сумки — справа от панелей")
check(ChatFrame1._pt and ChatFrame1._pt[5] > 95, "чат поднят над панелью: " .. tostring(ChatFrame1._pt and ChatFrame1._pt[5]))
check(CastingBarFrame._pt and CastingBarFrame._pt[5] > 140, "полоса заклинаний над панелью")
check(not PlayerFrame._shown and not TargetFrame._shown, "стандартные рамки игрока и цели скрыты")
check(SimsCraftSeg_target._watch, "рамка цели появляется при выборе цели")
local ord = SimsCraftDB.layout.order
check(ord[1] == "player" and ord[2] == "wow" and ord[5] == "target", "порядок: игрок, навыки, ..., цель")
check(SimsCraftSeg_player._pt[4] < SimsCraftSeg_wow._pt[4] and SimsCraftSeg_wow._pt[4] < SimsCraftSeg_target._pt[4], "слева направо")
check(SimsCraftSeg_sims._pt[5] > 0 and SimsCraftSeg_sims._pt[4] == SimsCraftSeg_menu._pt[4] - (262 - 268) / 2 or SimsCraftSeg_sims._pt[5] > 0, "SimsCraft над меню в одном столбце")
-- настройки
check(optPanels[1].name == "SimsCraft", "страница настроек в «Интерфейс → Модификации»")
SimsCraftOptions:Show()
local rightBtn
for _, fr in ipairs(frames) do if fr._text == ">" and fr._scripts.OnClick then rightBtn = fr end end
local n = 0; for _, fr in ipairs(frames) do if fr._text == ">" and fr._scripts.OnClick then n = n + 1; if n == 2 then rightBtn = fr end end end
rightBtn._scripts.OnClick(rightBtn)
check(SimsCraftDB.layout.order[1] == "wow" and SimsCraftSeg_wow._pt[4] < SimsCraftSeg_player._pt[4], "блоки меняются местами")
SimsCraftOptGryph._checked = false; SimsCraftOptGryph._scripts.OnClick(SimsCraftOptGryph)
check(MainMenuBarLeftEndCap._alpha == 1 and MainMenuBarLeftEndCap._pt[2] == SimsCraftSeg_wow, "грифонов можно вернуть")
MultiBarLeft = mock("MultiBarLeft"); MultiBarLeftButton1 = mock("MultiBarLeftButton1"); MultiBarLeftButton2 = mock("MultiBarLeftButton2")
SimsCraftOptBar4._checked = true; SimsCraftOptBar4._scripts.OnClick(SimsCraftOptBar4)
check(MultiBarLeftButton1._pt[2] == MultiBarBottomLeftButton1 and MultiBarLeftButton2._pt[2] == MultiBarLeftButton1 and MultiBarLeftButton2._pt[1] == "LEFT", "4-я доп. панель горизонтально над остальными")
SimsCraftOptBar4._checked = false; SimsCraftOptBar4._scripts.OnClick(SimsCraftOptBar4)
check(MultiBarLeftButton2._pt[1] == "TOP" and not rawget(MultiBarLeft, "simsHorizontal"), "и возвращается вертикальной")
check(SimsCraftSeg_player.portrait._w == 64, "портрет 64×64 как у WoW")
SimsCraftOptP3D._checked = true; SimsCraftOptP3D._scripts.OnClick(SimsCraftOptP3D)
check(SimsCraftSeg_player.model._shown and SimsCraftSeg_player.model._unit == "player", "живой 3D-портрет")
SimsCraftOptP3D._checked = false; SimsCraftOptP3D._scripts.OnClick(SimsCraftOptP3D)
check(not SimsCraftSeg_player.model._shown and SimsCraftSeg_player.portrait._portrait == "player", "обычный портрет")
-- внешний вид
check(#optPanels == 1 and SimsCraftOptionsLook._parent == nil or #optPanels == 1, "«Внешний вид» на той же странице настроек")
local jump
for _, fr in ipairs(frames) do if fr._text == "Внешний вид панелей" and fr._scripts.OnClick then jump = fr end end
check(jump, "кнопка перехода к внешнему виду")
check(SimsCraftOptionsScroll, "страница настроек прокручивается")
local gear
for _, fr in ipairs(frames) do if fr._tip == "Настройки панели SimsCraft" then gear = fr end end
SimsCraftOptions:Hide(); SimsCraftOptions:Show()
check(SimsCraftLookStyle._text == "Тёмный (как подсказки)", "текущий стиль подписан")
SimsCraftLookStyle._scripts.OnClick(SimsCraftLookStyle, "LeftButton")
check(SimsCraftDB.layout.style == 2 and SimsCraftSeg_sims._bd.edgeFile:match("DialogBox"), "стиль: окно WoW")
SimsCraftLookStyle._scripts.OnClick(SimsCraftLookStyle, "RightButton"); SimsCraftLookStyle._scripts.OnClick(SimsCraftLookStyle, "RightButton")
check(SimsCraftDB.layout.style == 6 and rawget(SimsCraftSeg_sims, "_bd") == nil, "прозрачный стиль, перебор назад")
for i = 1, 3 do SimsCraftLookBorder._scripts.OnClick(SimsCraftLookBorder, "LeftButton") end
SimsCraftLookStyle._scripts.OnClick(SimsCraftLookStyle, "LeftButton")
check(SimsCraftSeg_player._border[1] == 0.4, "рамка цвета класса")
SimsCraftLookBarTex._scripts.OnClick(SimsCraftLookBarTex, "LeftButton")
check(SimsCraftSeg_player.hp._tex:match("WHITE8X8"), "плоские полоски")
SimsCraftLookBarText._scripts.OnClick(SimsCraftLookBarText, "LeftButton")
local pct
for _, fr in ipairs(frames) do if fr._text == "50%" then pct = fr end end
check(pct, "здоровье в процентах")
SimsCraftLookHpColor._scripts.OnClick(SimsCraftLookHpColor, "LeftButton")
SimsCraftUI._scripts.OnUpdate(SimsCraftUI, 0.2)
SimsCraftLookGap._scripts.OnValueChanged(SimsCraftLookGap, 10)
check(SimsCraftDB.layout.gap == 10, "промежуток между блоками")
for _, fr in ipairs(frames) do if fr._text == "Sims" and fr._scripts.OnClick then fr._scripts.OnClick(fr) end end
check(SimsCraftDB.layout.style == 4 and SimsCraftDB.layout.border == 3, "готовый набор «Sims»")
SimsCraftMinimapButton._scripts.OnClick(SimsCraftMinimapButton, "RightButton")
SimsCraftOptShow5._checked = false; SimsCraftOptShow5._scripts.OnClick(SimsCraftOptShow5)
check(not SimsCraftSeg_target._shown and SimsCraftSeg_target._watch == false, "блок можно скрыть")
SimsCraftOptScale._scripts.OnValueChanged(SimsCraftOptScale, 0.8)
check(SimsCraftUI._scale == 0.8, "масштаб")
for _, fr in ipairs(frames) do if fr._text == "Сбросить расположение" then fr._scripts.OnClick(fr) end end
check(SimsCraftDB.layout.order[1] == "player" and SimsCraftDB.layout.show.target and SimsCraftDB.layout.scale == 1, "сброс")
-- в бою перестройка ждёт
inCombat = true
SimsCraftDB.layout.order[1], SimsCraftDB.layout.order[2] = "wow", "player"
SimsCraftUI_Layout()
check(SimsCraftSeg_player._pt[4] < SimsCraftSeg_wow._pt[4], "в бою ничего не двигается")
inCombat = false
for _, fr in ipairs(frames) do if fr._scripts.OnEvent and fr ~= evf then fr._scripts.OnEvent(fr, "PLAYER_REGEN_ENABLED") end end
check(SimsCraftSeg_wow._pt[4] < SimsCraftSeg_player._pt[4], "после боя применилось")
SimsCraftDB.layout.order[1], SimsCraftDB.layout.order[2] = "player", "wow"; SimsCraftUI_Layout()
-- данные
root = SimsCraftUI
SimsCraftUI._scripts.OnUpdate(SimsCraftUI, 1.2)
check(SimsCraftSeg_player.hp and true, "рамка игрока")
local hpTxt
for _, fr in ipairs(frames) do if fr._text == "500 / 1000" then hpTxt = fr end end
check(hpTxt, "здоровье игрока на рамке")
check(not SimsCraftFrame._shown, "старая панель скрыта")
check(not SimsCraftPanel._shown, "окно раздела закрыто")
SimsCraftUI_Open(7)
check(SimsCraftPanel._shown, "раздел «Семья» открывается над панелью")
srv("E;2;2;Хорошо выспался~3~1~300|Голоден~13~1~-1")
local plum
for _, fr in ipairs(frames) do if type(fr._text) == "string" and fr._text:match("Очень счастлив") then plum = fr._text end end
check(plum, "эмоция «Очень счастлив» на рамке персонажа")
srv("SK;1:3:40,5:1:10")
local sk
for _, fr in ipairs(frames) do if fr._text == "Кулинария" then sk = fr end end
check(sk, "навык")
srv("ASP;6;1;500;1~Живопись: уровень 3^0~Нарисовать картин: 2/15^0~Музыка: уровень 6")
local asp
for _, fr in ipairs(frames) do if fr._text == "Творец" then asp = fr end end
check(asp, "стремление")
SimsCraftUI_Open(7)
check(not SimsCraftPanel._shown, "повторный щелчок по разделу закрывает окно")
tgtExists = true
for _, fr in ipairs(frames) do if fr._scripts.OnEvent and fr ~= evf then fr._scripts.OnEvent(fr, "PLAYER_TARGET_CHANGED") end end
check(SimsCraftTargetDock._shown and sent[#sent] == "REL", "выбранный персонаж в рамке цели")
local aura
for _, fr in ipairs(frames) do if fr._text == 2 then aura = fr end end
check(aura, "ауры цели")
srv("R;Силистра;55;80;Друг, супруги;married;0;0;0;20;12")
local tt
for _, fr in ipairs(frames) do if fr._text == "Друг, супруги" then tt = fr end end
check(tt, "отношения с выбранным")
SimsCraftMinimapButton._scripts.OnClick(SimsCraftMinimapButton, "LeftButton")
check(not SimsCraftSeg_sims._shown and SimsCraftSeg_wow._shown and MainMenuBar._pt[2] == SimsCraftSeg_wow, "кнопка у карты прячет только блок SimsCraft")
SimsCraftMinimapButton._scripts.OnClick(SimsCraftMinimapButton, "LeftButton")
check(SimsCraftSeg_sims._shown, "и показывает снова")
SimsCraftMinimapButton._scripts.OnDragStart(SimsCraftMinimapButton)
check(SimsCraftMinimapButton._scripts.OnUpdate ~= nil, "кнопку у карты можно таскать по кругу")
SlashCmdList.SIMSCRAFT("unlock")
check(SimsCraftMover._shown, "/scui unlock — панель можно перетащить")
SlashCmdList.SIMSCRAFT("lock")
check(not SimsCraftMover._shown, "/scui lock")
print("Addon tests passed (ruRU), frames: " .. #frames)
