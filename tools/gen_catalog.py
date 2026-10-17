#!/usr/bin/env python3
"""Генератор каталога SimsCraft 3.0.

Создаёт:
  * SQL мира: шаблоны объектов каталога (entry 600000+), детей и супругов;
  * SQL восстановления объектов WoW 190200..190599, испорченных версией 2.0;
  * SQL миграции купленной мебели со старых номеров на новые;
  * Lua-таблицу каталога для серверного скрипта.

Все модели (displayId) проверяются по GameObjectDisplayInfo.dbc клиента 3.3.5a.
Использование:
  gen_catalog.py <db_world base dir> <GameObjectDisplayInfo.json> <out_dir> <out_lua>
"""
import sys, os, json

sys.path.insert(0, os.path.dirname(__file__))
from parse_sql import rows

BASE, DISP_JSON, OUT, OUT_LUA = sys.argv[1:5]
DISP = {int(k): v for k, v in json.load(open(DISP_JSON)).items()}

GO_BASE = 600000
CATS = [
    ("bedroom", "Спальня"), ("kitchen", "Кухня"), ("bath", "Ванная"), ("living", "Гостиная"),
    ("light", "Свет"), ("fun", "Досуг"), ("garden", "Сад и двор"), ("build", "Стройка"), ("house", "Готовые дома"),
]

# (id, категория, название, displayId, цена в золоте, действие, тип объекта, доп.)
#  тип: None = декор (5); "seat" = стул (7); "src:<entry>" = копировать тип и данные настоящего объекта
#  доп. для домов: радиус в метрах (для режима «без стен»)
S = []
def add(i, c, n, d, p, k=None, t=None, r=0):
    S.append(dict(id=i, cat=c, name=n, disp=d, price=p, kind=k, t=t, r=r))

# --- спальня ---
add("bed1", "bedroom", "Кровать с балдахином", 392, 120, "bed")
add("bed2", "bedroom", "Кровать (Темнолесье)", 3471, 60, "bed")
add("bed3", "bedroom", "Кровать (Западный Край)", 9367, 50, "bed")
add("bed4", "bedroom", "Двухъярусная кровать", 463, 40, "bed")
add("bed5", "bedroom", "Каменное ложе", 7316, 80, "bed")
add("bed6", "bedroom", "Ложе друида", 7315, 70, "bed")
add("wardrobe1", "bedroom", "Резной шкаф", 1227, 25, "wardrobe")
add("wardrobe2", "bedroom", "Дворфийский шкаф", 4031, 20, "wardrobe")
add("wardrobe3", "bedroom", "Гардероб", 4, 15, "wardrobe")
add("dresser", "bedroom", "Тумбочка с зеркалом", 1568, 15, "vanity")
add("chest1", "bedroom", "Сундук", 1, 8, "chest")
add("chest2", "bedroom", "Кованый сундук", 41, 10, "chest")
add("chest3", "bedroom", "Сундук Альянса", 9280, 15, "chest")
add("chest4", "bedroom", "Сундук Орды", 9281, 15, "chest")
add("pillow", "bedroom", "Подушка", 5911, 2)
for i, (d, n) in enumerate([(159, "Ковёр Штормграда"), (6360, "Ковёр Штормграда (2)"), (6942, "Ковёр тауренов"),
                            (7757, "Узорный ковёр тауренов"), (7758, "Ковёр тауренов (3)"), (5113, "Ковёр тауренов (4)"),
                            (7542, "Длинный ковёр"), (7665, "Меховой ковёр"), (8399, "Даларанский ковёр"),
                            (8602, "Ковёр син'дорай"), (8603, "Большой ковёр син'дорай"), (9405, "Медвежья шкура")]):
    add("rug%d" % (i + 1), "bedroom", n, d, 6 + i)
# --- кухня ---
add("stove1", "kitchen", "Пузатая печка", 348, 30, "stove")
add("stove2", "kitchen", "Печка траппера", 8652, 35, "stove")
add("stove3", "kitchen", "Настенная печка", 679, 35, "stove")
add("stove4", "kitchen", "Орочий очаг", 4352, 25, "stove")
add("stove5", "kitchen", "Очаг с огнём", 331, 25, "stove")
for i, (d, n, p) in enumerate([(221, "Трактирный стол", 12), (581, "Маленький столик", 6), (6508, "Трактирный столик", 10),
                               (6356, "Резной дворфийский стол", 15), (3372, "Дворфийский стол", 15), (6612, "Маленький дворфийский стол", 10),
                               (6613, "Стол орков", 12), (6608, "Эльфийский стол", 15), (7209, "Круглый стол", 15),
                               (7443, "Стол Западного Края", 10), (7591, "Большой стол син'дорай", 25), (6916, "Столик син'дорай", 10),
                               (7838, "Столик из Каражана", 30), (7867, "Большой стол из Каражана", 60), (234, "Стол Темнолесья", 10)]):
    add("table%d" % (i + 1), "kitchen", n, d, p, "table")
for i, (d, n, p) in enumerate([(6036, "Трактирная бочка", 3), (32, "Бочка", 2), (6811, "Дворфийская бочка", 4),
                               (7970, "Бочка с фруктами", 4), (1727, "Пивной бочонок", 5), (7414, "Пивная стойка", 15),
                               (8338, "Пивные бочки", 20), (31, "Ящик", 2), (347, "Ящик с зерном", 2)]):
    add("kitchen%d" % (i + 1), "kitchen", n, d, p)
# --- ванная ---
add("tub", "bath", "Бочка-купель", 7483, 30, "tub")
add("basin", "bath", "Таз для умывания", 5112, 15, "washbasin")
add("toilet", "bath", "Уборная", 3332, 20, "toilet")
add("well2", "bath", "Даларанский колодец", 8503, 60, "washbasin")
# --- гостиная ---
for i, (d, n, p) in enumerate([(39, "Простой стул", 5), (91, "Стул", 6), (92, "Резное кресло", 10), (138, "Стул Западного Края", 5),
                               (648, "Дворфийское кресло", 12), (6357, "Стул Стальгорна", 8), (7070, "Резной стул Стальгорна", 12),
                               (7071, "Простой стул Стальгорна", 6), (6975, "Стул син'дорай", 10), (6980, "Кресло син'дорай", 12),
                               (8095, "Даларанское кресло", 15), (8205, "Даларанский стул", 10), (4678, "Стул гномов", 8),
                               (7460, "Бревно-сиденье", 4), (7504, "Стул врайкулов", 8), (7896, "Кресло цирюльника", 20),
                               (2810, "Трон Чёрного Железа", 300), (6713, "Трон Каражана", 250), (7744, "Трон вождя", 400),
                               (603, "Трактирная скамья", 8), (622, "Скамья Штормграда", 10), (682, "Скамья Темнолесья", 8),
                               (6362, "Скамья орков", 8), (6979, "Скамья син'дорай", 10), (8096, "Даларанская скамья", 15),
                               (8248, "Даларанская скамья (2)", 15), (4091, "Гномья скамья со столиком", 25)]):
    add("seat%d" % (i + 1), "living", n, d, p, None, "seat")
add("books1", "living", "Книжная полка", 187, 20, "books")
add("books2", "living", "Книжная полка (2)", 188, 20, "books")
add("books3", "living", "Книжная полка (3)", 137, 20, "books")
add("books4", "living", "Полка из аббатства", 189, 20, "books")
add("books5", "living", "Книжная полка Каражана", 7985, 30, "books")
add("readtable", "living", "Стол для чтения", 3371, 15, "books")
for i, (d, n, p) in enumerate([(43, "Стопка книг", 2), (107, "Стопка книг (низкая)", 2), (470, "Раскрытая книга", 3),
                               (7810, "Часы с кукушкой", 25), (5265, "Глобус", 30), (2850, "Картина", 15), (4731, "Картина (2)", 15),
                               (4733, "Картина (3)", 15), (6528, "Портрет героя-дворфа", 15), (6529, "Портрет героя-гнома", 15),
                               (6530, "Портрет героя-человека", 15), (6531, "Портрет героини-эльфийки", 15), (6532, "Портрет героя-орка", 15),
                               (6533, "Портрет Отрёкшегося", 15), (6534, "Портрет таурена", 15), (6535, "Портрет тролля", 15),
                               (624, "Знамя с грифоном", 10), (6388, "Знамя Отрёкшихся", 10), (6390, "Знамя ночных эльфов", 10),
                               (522, "Щит на стену", 8), (7262, "Меч на стену", 8), (393, "Бюст", 20), (7282, "Бюст (2)", 20)]):
    add("decor%d" % (i + 1), "living", n, d, p)
# --- свет ---
for i, (d, n, p) in enumerate([(5671, "Фонарный столб", 10), (8091, "Даларанский фонарь", 15), (365, "Фонарь Степей", 8),
                               (731, "Тауренский фонарь", 8), (8577, "Фонарь Дарнаса", 12), (7160, "Дренейский фонарь", 12),
                               (6038, "Фонарь", 5), (438, "Эльфийский фонарь", 5), (6913, "Эльфийский фонарь (2)", 5),
                               (7084, "Красный фонарь син'дорай", 6), (6538, "Праздничный фонарь Альянса", 6),
                               (6540, "Праздничный фонарь Орды", 6), (8092, "Настенная лампа Даларана", 8), (100, "Свеча", 1),
                               (6363, "Свеча (2)", 1), (6364, "Свечи", 2), (6644, "Романтическая свеча", 3), (7773, "Группа свечей", 3),
                               (3131, "Настенный канделябр", 8), (602, "Жаровня Штормграда", 12), (197, "Дворфийская жаровня", 10),
                               (654, "Жаровня", 8), (655, "Высокая жаровня", 10), (4094, "Факел", 3), (6370, "Факел (2)", 3),
                               (9464, "Северный факел", 4)]):
    add("light%d" % (i + 1), "light", n, d, p)
# --- досуг ---
add("drum1", "fun", "Тауренский барабан", 2572, 20, "music")
add("drum2", "fun", "Большой барабан", 3613, 35, "music")
add("drum3", "fun", "Барабан вуду", 7533, 15, "music")
add("toytrain", "fun", "Игрушечная железная дорога", 8529, 30, "toy")
add("doll1", "fun", "Тряпичная кукла", 4131, 5, "toy")
add("doll2", "fun", "Кукла", 7511, 5, "toy")
add("target1", "fun", "Мишень", 395, 10, "target")
add("target2", "fun", "Мишень Штормграда", 232, 12, "target")
add("target3", "fun", "Мишень дворфов", 7048, 12, "target")
add("target4", "fun", "Тир", 6149, 20, "target")
add("dummy", "fun", "Тренировочный манекен", 5171, 12, "target")
# --- сад и двор ---
add("fountain1", "garden", "Эльфийский фонтан", 439, 80, "fountain")
add("fountain2", "garden", "Даларанский фонтан", 8097, 150, "fountain")
add("moonwell", "garden", "Лунный колодец", 4691, 200, "fountain")
add("lightwell", "garden", "Источник Света", 6671, 120, "fountain")
add("mailbox1", "garden", "Почтовый ящик (рабочий)", 1907, 50, None, "src:32349")
add("mailbox2", "garden", "Почтовый ящик орков (рабочий)", 2128, 50, None, "src:32349")
add("campfire", "garden", "Костёр (для готовки)", 192, 5, None, "src:1798")
add("anvil", "garden", "Наковальня (рабочая)", 166, 25, None, "src:1744")
add("forge", "garden", "Горн (рабочий)", 197, 25, None, "src:1743")
add("bonfire", "garden", "Большой костёр", 5974, 10)
for i, (d, n, p) in enumerate([(6318, "Растение", 2), (6319, "Растение (2)", 2), (6320, "Растение (3)", 2), (6321, "Растение (4)", 2),
                               (683, "Растение (5)", 2), (6642, "Цветок в горшке", 3), (63, "Букет", 2), (6647, "Букет (2)", 2),
                               (6648, "Букет (3)", 2), (6662, "Цветы Элвиннского леса", 2), (8559, "Клумба син'дорай", 6),
                               (9006, "Ваза с цветами", 4), (6646, "Венок", 3), (5315, "Ёлка", 20), (5253, "Большая ёлка", 35),
                               (4951, "Саженец", 3), (5975, "Дерево Западного Края", 25), (7278, "Деревце Террокара", 15),
                               (280, "Куст", 2), (281, "Куст (2)", 2), (282, "Куст (3)", 2), (251, "Стог сена", 4),
                               (6133, "Стог сена (2)", 4), (6145, "Тюк сена", 3), (6146, "Тюк сена (2)", 3), (60, "Тыква", 1),
                               (6325, "Тыквенная грядка", 5), (8038, "Пугало", 8), (6410, "Пугало Темнолесья", 8),
                               (6, "Статуя льва", 60), (6815, "Статуя Утера", 200), (6820, "Статуя паладина", 120),
                               (1527, "Статуя жреца", 120), (6925, "Статуя орла", 60), (7592, "Статуя син'дорай", 100),
                               (6821, "Каменный медведь", 60), (6822, "Каменный олень", 60), (6823, "Каменная сова", 60),
                               (3678, "Телега Западного Края", 15), (7184, "Повозка", 15), (8029, "Телега с сеном", 15),
                               (5392, "Цыганская кибитка", 60), (727, "Вывеска трактира", 10), (2008, "Коновязь", 5)]):
    add("garden%d" % (i + 1), "garden", n, d, p)
# --- стройка ---
for i, (d, n, p) in enumerate([(6151, "Деревянный забор", 4), (6150, "Простой забор", 3), (6526, "Кованый забор", 4),
                               (8024, "Столб забора", 1), (8699, "Северный столб забора", 1), (9423, "Орочий забор", 4),
                               (8721, "Столб орочьего забора", 1), (6793, "Столб ограды син'дорай", 2),
                               (6717, "Стена дома", 25), (6718, "Стена дома (2)", 25), (3676, "Каменная стена (руины)", 15),
                               (6355, "Каменная стена (руины 2)", 15), (8251, "Каменная стена", 60), (8250, "Угловая башенка", 60),
                               (7914, "Крепостная стена", 300), (7915, "Крепостная башня", 300), (8997, "Ворота крепости", 300),
                               (13, "Дверь фермы", 10), (9208, "Деревянный помост", 15), (7439, "Мостки", 15),
                               (6556, "Пристань", 20), (6557, "Пристань (2)", 20), (7708, "Малый причал", 40),
                               (8459, "Платформа", 40), (7593, "Деревянная лестница", 10), (8030, "Каменная лестница", 15),
                               (8033, "Каменная лестница (2)", 15), (7194, "Палатка", 20), (7195, "Большая палатка", 30),
                               (8360, "Северная палатка", 20), (8698, "Палатка (2)", 20), (8184, "Орочий шатёр", 25),
                               (8421, "Шатёр Дуротара", 25), (8398, "Эльфийский шатёр", 25), (6738, "Павильон", 30),
                               (7499, "Пивной шатёр", 40), (7725, "Гоблинский шатёр", 25), (7727, "Гоблинский шатёр (2)", 25),
                               (9148, "Шатёр ночных эльфов", 40), (9149, "Шатёр ночных эльфов (2)", 40),
                               (7787, "Колонна", 20), (7854, "Основание колонны", 10), (7440, "Кирпичный мостик", 30)]):
    add("build%d" % (i + 1), "build", n, d, p)
# --- готовые дома (настоящие здания WoW) ---
for i, (d, n, p, r) in enumerate([
        (7465, "Фермерский дом (Западный Край)", 600, 13), (8010, "Фермерский дом (Красногорье)", 600, 13),
        (7432, "Фермерский дом (Темнолесье)", 600, 13), (7463, "Двухэтажный дом (Темнолесье)", 900, 14),
        (7832, "Северный дом", 800, 15), (7847, "Ферма Стратхольма", 500, 12), (467, "Дом игрока (прототип Blizzard)", 700, 14),
        (7667, "Дренейская хижина", 400, 10), (7807, "Хижина таунка", 350, 10), (9127, "Большой шатёр друидов", 900, 25),
        (8013, "Амбар (Красногорье)", 450, 16), (8014, "Амбар (Темнолесье)", 450, 16), (8011, "Конюшня (Красногорье)", 350, 14),
        (8016, "Конюшня (Темнолесье)", 350, 14), (7434, "Лесопилка", 500, 16), (7668, "Кузница", 500, 12),
        (7428, "Часовня (Красногорье)", 800, 14), (7449, "Часовня (Темнолесье)", 800, 14), (7450, "Часовня", 800, 14),
        (7433, "Гнездовье грифонов", 700, 16), (7595, "Сторожевая башня", 1000, 14), (7458, "Башня друида", 1200, 14),
        (7165, "Орочьи казармы", 900, 20), (7670, "Старый орочий зал", 900, 20), (7677, "Орочья псарня", 400, 12),
        (7676, "Орочья кузница", 500, 12), (7461, "Разрушенный дом", 100, 12), (7464, "Сгоревшая ферма", 150, 13),
        (7436, "Сгоревшая ферма (Темнолесье)", 150, 13)]):
    add("house%d" % (i + 1), "house", n, d, p, "house", None, r)
# 5.0 (новое добавляется только в конец, чтобы не сдвинуть номера уже купленного)
add("barber", "bath", "Кресло парикмахера", 7896, 40, None, "src:191028")
# 6.0
add("fridge", "kitchen", "Кладовая с припасами", 6606, 30, "fridge")
add("computer", "living", "Гномий терминал (компьютер)", 2091, 150, "computer")
add("tv", "living", "Хрустальный шар (телевизор)", 6964, 120, "tv")
add("easel", "fun", "Холст для рисования", 4731, 40, "easel")
add("chess", "fun", "Стол для шахмат", 3372, 35, "chess")
add("dummy2", "fun", "Тренировочное чучело (Штормград)", 518, 25, "fitness")
add("keg", "living", "Пивная бочка (бар)", 1727, 40, "bar")
add("globe", "living", "Глобус", 5265, 30, "globe")
add("cake", "kitchen", "Праздничный торт", 8232, 10, "cake")
add("clock", "living", "Часы с кукушкой", 7810, 15, "clock")
for i, (d, n) in enumerate([(269, "Грядка мироцвета"), (270, "Грядка сребролиста"), (268, "Грядка магороза"),
                            (272, "Грядка быстрорастки"), (358, "Грядка синячника"), (7844, "Грядка золотого клевера")]):
    add("herb%d" % (i + 1), "garden", n, d, 20 + i * 10, "plant")

# дети и супруги: displayId существа (из CreatureDisplayInfo.dbc)
KIDS = [(1, 0, "Сын", 221), (1, 1, "Дочь", 252), (2, 0, "Сын", 14589), (2, 1, "Дочь", 14616),
        (3, 0, "Сын", 19314), (3, 1, "Дочь", 19315), (4, 0, "Сын", 19092), (4, 1, "Дочь", 19091),
        (5, 0, "Сын", 23783), (5, 1, "Дочь", 23783)]
KID_BASE = 190110
SPOUSE = [(190120, "Супруг", 1291), (190121, "Супруга", 5444)]

# порядок предметов версии 2.0 (entry 190200 + индекс) -> id в 3.0 (для переноса купленного)
V2_IDS = ["bed", "stove", "tub", "toilet", "books", "table", "drums", "chair", "bed2", "bed3", "bed4", "dresser", "chest",
          "rug1", "rug2", "rug3", "rug4", "rug5", "stove2", "oven", "cauldron", "table2", "table3", "table4", "table5", "table6",
          "fruit", "fruit2", "corn", "barrel", "keg", "keg2", "basin", "basin2", "chair2", "chair3", "chair4", "chair5", "chair6",
          "bench1", "bench2", "bench3", "bench4", "couch", "stool", "throne", "throne2", "books2", "books3", "fireplace", "clock",
          "globe", "portrait1", "portrait2", "portrait3", "portrait4", "portrait5", "portrait6", "armor", "weapons", "warmap"]
V2_MAP = {"bed": "bed3", "stove": "stove1", "tub": "tub", "toilet": "toilet", "books": "books1", "table": "table4",
          "drums": "drum1", "chair": "seat1", "bed2": "bed1", "bed3": "bed5", "bed4": "bed4", "dresser": "wardrobe3",
          "chest": "chest1", "rug1": "rug2", "rug2": "rug3", "rug3": "rug4", "rug4": "rug5", "rug5": "rug1",
          "stove2": "stove2", "table2": "table7", "table3": "table12", "table4": "table3", "table6": "table1",
          "barrel": "kitchen1", "keg": "kitchen5", "keg2": "kitchen6", "chair2": "seat2", "chair3": "seat5",
          "chair4": "seat1", "chair5": "seat9", "bench1": "seat20", "bench2": "seat22", "bench3": "seat24",
          "bench4": "seat25", "couch": "seat27", "throne": "seat17", "books2": "books4", "clock": "decor4",
          "portrait1": "decor11", "portrait2": "decor12", "portrait3": "decor13", "portrait4": "decor14",
          "portrait5": "decor15", "portrait6": "decor16"}


def esc(s):
    return s.replace("\\", "\\\\").replace("'", "''")


def main():
    go = {}
    for r in rows(os.path.join(BASE, "gameobject_template.sql")):
        go[int(r[0])] = r
    os.makedirs(OUT, exist_ok=True)

    # ---------- восстановление испорченных объектов WoW ----------
    cols = "`entry`,`type`,`displayId`,`name`,`IconName`,`castBarCaption`,`unk1`,`size`," + \
        ",".join(f"`Data{i}`" for i in range(24)) + ",`AIName`,`ScriptName`,`VerifiedBuild`"

    def rowsql(r):
        vals = [r[0], r[1], r[2], "'%s'" % esc(r[3]), "'%s'" % esc(r[4]), "'%s'" % esc(r[5]), "'%s'" % esc(r[6]), r[7]] + \
            list(r[8:32]) + ["'%s'" % esc(r[32]), "'%s'" % esc(r[33]), (r[34] if r[34] not in ("", "NULL") else "NULL")]
        return "(" + ",".join(str(v) for v in vals) + ")"
    restore = [r for e, r in sorted(go.items()) if 190200 <= e <= 190599]
    sql = ["-- SimsCraft 3.0: восстановление настоящих объектов WoW (entry 190200..190599), испорченных версией 2.0",
           "SET NAMES utf8mb4;", "START TRANSACTION;",
           "DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 190200 AND 190599;",
           f"INSERT INTO `gameobject_template` ({cols}) VALUES", ",\n".join(rowsql(r) for r in restore) + ";",
           "UPDATE `gameobject_template` SET `Data1` = 5 WHERE `entry` = 190224;", "COMMIT;", ""]
    open(os.path.join(OUT, "world_restore_v3.sql"), "w", encoding="utf-8").write("\n".join(sql))
    print("восстанавливается объектов WoW:", len(restore))

    # ---------- каталог ----------
    ids = set()
    vals = []
    lua = ["local CATEGORIES = {"] + [f'    {{ key = "{k}", name = "{n}" }},' for k, n in CATS] + ["}", "local CATALOG = {"]
    for i, it in enumerate(S):
        assert it["id"] not in ids, it["id"]
        ids.add(it["id"])
        d = DISP.get(it["disp"])
        if not d:
            sys.exit("нет модели %d (%s)" % (it["disp"], it["name"]))
        entry = GO_BASE + i
        it["entry"] = entry
        data = [0] * 24
        gtype = 5
        if it["t"] == "seat":
            gtype = 7
            data[0], data[1] = 1, 1
            # если есть настоящий стул с этой моделью — берём его высоту и число мест
            for r in go.values():
                if int(r[1]) == 7 and int(r[2]) == it["disp"]:
                    data[0], data[1] = int(r[8]) or 1, int(r[9]); break
        elif it["t"] and it["t"].startswith("src:"):
            r = go[int(it["t"][4:])]
            gtype = int(r[1]); data = [int(x) for x in r[8:32]]
        elif it["kind"] == "house":
            # здания (WMO) клиент рисует только у «разрушаемых зданий» и транспорта; тип 5 даёт серый квадрат
            gtype = 33
            # данные точно как у простых построек Blizzard (например, 187895 «aaw», 190397):
            # без разрушаемых состояний, data6 = -1
            data[6] = -1
        elif it["kind"]:
            gtype = 2
        vals.append("(%d,%d,%d,'%s','','','',1,%s,'','',0)" % (entry, gtype, it["disp"], esc(it["name"]), ",".join(map(str, data))))
        dist = 18 if it["cat"] == "house" else (5 if it["cat"] == "build" else 2.5)
        kind = '"%s"' % it["kind"] if it["kind"] else "nil"
        extra = (", seat = true" if it["t"] == "seat" else "") + (", r = %d" % it["r"] if it["r"] else "")
        lua.append(f'    {{ id = "{it["id"]}", cat = "{it["cat"]}", name = "{it["name"]}", entry = {entry}, '
                   f'price = {it["price"] * 10000}, kind = {kind}, dist = {dist}{extra} }},')
    lua.append("}")
    # служебные объекты: пена и пар для ванны
    vals.append("(%d,5,5333,'Пена','','','',0.75,%s,'','',0)" % (GO_BASE + 990, ",".join(["0"] * 24)))
    vals.append("(%d,5,42,'Пузырьки','','','',1.5,%s,'','',0)" % (GO_BASE + 992, ",".join(["0"] * 24)))
    vals.append("(%d,5,431,'Пар','','','',0.5,%s,'','',0)" % (GO_BASE + 991, ",".join(["0"] * 24)))
    # 5.0: объекты для работы (тип 2 — по ним можно щёлкнуть) и табурет у зеркала (тип 32 — кресло парикмахера)
    for off, disp, name, size in [(1000, 1667, "Магический кристалл", 0.6), (1001, 8966, "Корзина с продуктами", 1.0),
                                  (1002, 31, "Ящик с товаром", 0.8), (1003, 4094, "Сигнальный факел", 1.0),
                                  (1004, 216, "Котёл повара", 1.0), (1005, 6400, "Шляпа для монет", 1.5),
                                  (1006, 343, "Рунный круг", 1.5), (1007, 159, "Уличная сцена", 0.8),
                                  (1008, 6139, "Прилавок", 1.0), (1009, 5191, "Знамя стражи", 1.0)]:
        vals.append("(%d,2,%d,'%s','','','',%s,%s,'','',0)" % (GO_BASE + off, disp, name, size, ",".join(["0"] * 24)))
    vals.append("(%d,32,7896,'Табурет у зеркала','','','',0.9,%s,'','',0)" % (GO_BASE + 1010, ",".join(["2"] + ["0"] * 23)))
    vals.append("(%d,5,437,'Дымка','','','',1.2,%s,'','',0)" % (GO_BASE + 1011, ",".join(["0"] * 24)))
    vals.append("(%d,2,6549,'Флажок трассы','','','',0.6,%s,'','',0)" % (GO_BASE + 1012, ",".join(["0"] * 24)))
    vals.append("(%d,2,5914,'Больной','','','',1.0,%s,'','',0)" % (GO_BASE + 1013, ",".join(["0"] * 24)))
    sql = ["-- SimsCraft 4.0: каталог (entry 600000+), дети, супруги", "SET NAMES utf8mb4;", "START TRANSACTION;",
           f"DELETE FROM `gameobject_template` WHERE `entry` BETWEEN {GO_BASE} AND {GO_BASE + 1099};",
           f"INSERT INTO `gameobject_template` ({cols}) VALUES", ",\n".join(vals) + ";", ""]
    # дети и супруги
    lo, hi = KID_BASE, SPOUSE[-1][0]
    sql += [f"DELETE FROM `creature_template` WHERE `entry` BETWEEN {lo} AND {hi};",
            f"DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN {lo} AND {hi};",
            "DROP TEMPORARY TABLE IF EXISTS `sc_kid`;",
            "CREATE TEMPORARY TABLE `sc_kid` AS SELECT * FROM `creature_template` WHERE `entry` = 14305;",
            "UPDATE `sc_kid` SET `subname` = 'Семья', `faction` = 35, `npcflag` = 1, `unit_flags` = 770, "
            "`gossip_menu_id` = 0, `AIName` = '', `ScriptName` = '', `minlevel` = 1, `maxlevel` = 1;"]
    lua.append("local KID_ENTRY = {}")
    models = []
    for g, sex, nm, disp in KIDS:
        e = KID_BASE + (g - 1) * 2 + sex
        sql += [f"UPDATE `sc_kid` SET `entry` = {e}, `name` = '{nm}';", "INSERT INTO `creature_template` SELECT * FROM `sc_kid`;"]
        models.append((e, disp))
    for e, nm, disp in SPOUSE:
        sql += [f"UPDATE `sc_kid` SET `entry` = {e}, `name` = '{nm}', `minlevel` = 80, `maxlevel` = 80;",
                "INSERT INTO `creature_template` SELECT * FROM `sc_kid`;"]
        models.append((e, disp))
    sql.append("DROP TEMPORARY TABLE `sc_kid`;")
    sql.append("INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`) VALUES " +
               ",".join(f"({e},0,{d},1,1,0)" for e, d in models) + ";")
    sql.append("COMMIT;")
    open(os.path.join(OUT, "world_simscraft_v3.sql"), "w", encoding="utf-8").write("\n".join(sql) + "\n")

    # ---------- перенос купленной мебели ----------
    by_id = {it["id"]: it for it in S}
    mig = ["-- SimsCraft 3.0: перенос купленной мебели со старых номеров на новые (выполнять в acore_world)",
           "SET NAMES utf8mb4;",
           "DROP TEMPORARY TABLE IF EXISTS `sc_map`;",
           "CREATE TEMPORARY TABLE `sc_map` (`old` INT UNSIGNED PRIMARY KEY, `new` INT UNSIGNED NOT NULL, `refund` INT UNSIGNED NOT NULL);"]
    pairs = []
    for i, oid in enumerate(V2_IDS):
        new = V2_MAP.get(oid)
        pairs.append("(%d,%d,%d)" % (190200 + i, by_id[new]["entry"] if new else 0, 0 if new else 100000))
    mig.append("INSERT INTO `sc_map` VALUES " + ",".join(pairs) + ";")
    F = "acore_characters.character_sims_furniture"
    mig += [
        # записи версии 1 без номера спавна: находим их в мире по координатам
        f"UPDATE {F} f JOIN `gameobject` g ON g.`id` = f.`entry` AND g.`map` = f.`map` AND ABS(g.`position_x` - f.`x`) < 1 "
        f"AND ABS(g.`position_y` - f.`y`) < 1 SET f.`spawn` = g.`guid` WHERE f.`spawn` = 0 AND f.`entry` BETWEEN 190200 AND 190599;",
        f"DELETE g FROM `gameobject` g JOIN {F} f ON g.`guid` = f.`spawn` JOIN `sc_map` m ON m.`old` = f.`entry` WHERE m.`new` = 0 AND f.`spawn` > 0;",
        f"UPDATE `gameobject` g JOIN {F} f ON g.`guid` = f.`spawn` JOIN `sc_map` m ON m.`old` = f.`entry` SET g.`id` = m.`new` WHERE m.`new` > 0 AND f.`spawn` > 0;",
        f"UPDATE {F} f JOIN `sc_map` m ON m.`old` = f.`entry` SET f.`refund` = m.`refund`, f.`entry` = IF(m.`new` = 0, f.`entry`, m.`new`);",
        f"UPDATE {F} SET `refund` = 100000 WHERE `entry` BETWEEN 190200 AND 190599 AND `refund` = 0;",
        "DROP TEMPORARY TABLE `sc_map`;", ""]
    open(os.path.join(OUT, "world_migrate_v3.sql"), "w", encoding="utf-8").write("\n".join(mig))
    open(OUT_LUA, "w", encoding="utf-8").write("\n".join(lua) + "\n")
    print("предметов в каталоге:", len(S), "entry", GO_BASE, "..", GO_BASE + len(S) - 1)


main()
