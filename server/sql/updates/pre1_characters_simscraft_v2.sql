-- SimsCraft 2.0: изменения базы ПЕРСОНАЖЕЙ (acore_characters).
-- Запускать с mysql --force: при повторном запуске ошибки «колонка уже есть» безопасно пропускаются.

CREATE TABLE IF NOT EXISTS `character_sims` (
  `guid` INT UNSIGNED NOT NULL,
  `hunger` FLOAT NOT NULL DEFAULT 80, `energy` FLOAT NOT NULL DEFAULT 80, `hygiene` FLOAT NOT NULL DEFAULT 80,
  `fun` FLOAT NOT NULL DEFAULT 70, `social` FLOAT NOT NULL DEFAULT 70, `bladder` FLOAT NOT NULL DEFAULT 90,
  `traits` VARCHAR(64) NOT NULL DEFAULT '',
  `career` TINYINT UNSIGNED NOT NULL DEFAULT 0, `career_rank` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `career_perf` INT UNSIGNED NOT NULL DEFAULT 0, `shifts` INT UNSIGNED NOT NULL DEFAULT 0,
  `home_map` INT NOT NULL DEFAULT -1, `home_x` FLOAT NOT NULL DEFAULT 0, `home_y` FLOAT NOT NULL DEFAULT 0,
  `home_z` FLOAT NOT NULL DEFAULT 0, `home_o` FLOAT NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `character_sims` ADD COLUMN `preg_until` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims` ADD COLUMN `preg_partner` VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE `character_sims` ADD COLUMN `preg_pname` VARCHAR(64) NOT NULL DEFAULT '';

ALTER TABLE `character_sims_relations` ADD COLUMN `status` VARCHAR(16) NOT NULL DEFAULT '';

ALTER TABLE `character_sims_furniture` ADD COLUMN `o` FLOAT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_furniture` ADD COLUMN `spawn` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_furniture` ADD COLUMN `item` VARCHAR(16) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `character_sims_children` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid`          INT UNSIGNED NOT NULL COMMENT 'родитель',
  `name`          VARCHAR(64) NOT NULL DEFAULT '',
  `gender`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `grp`           TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'внешность: 1 человек, 2 орк, 3 эльф крови, 4 дреней, 5 таурен',
  `born`          INT UNSIGNED NOT NULL DEFAULT 0,
  `happy`         FLOAT NOT NULL DEFAULT 80,
  `skill`         FLOAT NOT NULL DEFAULT 0,
  `coparent_name` VARCHAR(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `idx_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SimsCraft: дети';
