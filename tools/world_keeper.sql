-- SimsCraft: данные для базы МИРА (обычно acore_world)
-- Скрипт копирует существующие строки-образцы, поэтому не зависит от точного набора
-- столбцов вашей версии AzerothCore. Повторный запуск безопасен.

SET NAMES utf8mb4;

-- ============================================================
-- 1. Текст меню
-- ============================================================
DELETE FROM `npc_text` WHERE `ID` = 190100;
DROP TEMPORARY TABLE IF EXISTS `sc_tmp_text`;
CREATE TEMPORARY TABLE `sc_tmp_text` AS
  SELECT * FROM `npc_text` ORDER BY (`ID` = 1) DESC, `ID` LIMIT 1;
UPDATE `sc_tmp_text` SET
  `ID` = 190100,
  `text0_0` = 'Каждая жизнь — история, $N. Голод, сон, друзья, работа, уютный дом... Чем займёмся?',
  `text0_1` = 'Каждая жизнь — история, $N. Голод, сон, друзья, работа, уютный дом... Чем займёмся?',
  `Probability0` = 1,
  `Probability1` = 0, `Probability2` = 0, `Probability3` = 0,
  `Probability4` = 0, `Probability5` = 0, `Probability6` = 0, `Probability7` = 0;
INSERT INTO `npc_text` SELECT * FROM `sc_tmp_text`;
DROP TEMPORARY TABLE `sc_tmp_text`;

-- ============================================================
-- 2. NPC «Хранитель жизни» (entry 190100)
--    Образец внешности: трактирщица Эллисон (6740), иначе стражник Штормграда (68)
-- ============================================================
SET @sc_src := (SELECT `entry` FROM `creature_template` WHERE `entry` IN (6740, 68, 3296)
                ORDER BY FIELD(`entry`, 6740, 68, 3296) LIMIT 1);

DELETE FROM `creature_template` WHERE `entry` = 190100;
DROP TEMPORARY TABLE IF EXISTS `sc_tmp_ct`;
CREATE TEMPORARY TABLE `sc_tmp_ct` AS SELECT * FROM `creature_template` WHERE `entry` = @sc_src;
UPDATE `sc_tmp_ct` SET
  `entry` = 190100,
  `name` = 'Хранитель жизни',
  `subname` = 'SimsCraft',
  `npcflag` = 1,
  `faction` = 35,
  `gossip_menu_id` = 0,
  `AIName` = '',
  `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `sc_tmp_ct`;
DROP TEMPORARY TABLE `sc_tmp_ct`;

-- 3. Мебель теперь создаётся каталогом SimsCraft 3.0 (world_simscraft_v3.sql, номера 600000+).

-- ============================================================
-- 4. Модель NPC (таблица creature_template_model, есть в актуальном AzerothCore).
-- ============================================================
DELETE FROM `creature_template_model` WHERE `CreatureID` = 190100;
DROP TEMPORARY TABLE IF EXISTS `sc_tmp_ctm`;
CREATE TEMPORARY TABLE `sc_tmp_ctm` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = @sc_src;
UPDATE `sc_tmp_ctm` SET `CreatureID` = 190100;
INSERT INTO `creature_template_model` SELECT * FROM `sc_tmp_ctm`;
DROP TEMPORARY TABLE `sc_tmp_ctm`;
