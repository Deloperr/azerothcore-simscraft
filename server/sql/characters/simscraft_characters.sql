-- SimsCraft 1.0.0 — characters database (usually `acore_characters`).
-- Creates all SimsCraft tables. Safe to run again: existing tables and data are kept.
-- SimsCraft 1.0.0 — база персонажей (обычно `acore_characters`). Повторный запуск безопасен.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `character_sims` (
  `guid`         INT UNSIGNED NOT NULL,
  `hunger`       FLOAT NOT NULL DEFAULT 80,
  `energy`       FLOAT NOT NULL DEFAULT 80,
  `hygiene`      FLOAT NOT NULL DEFAULT 80,
  `fun`          FLOAT NOT NULL DEFAULT 70,
  `social`       FLOAT NOT NULL DEFAULT 70,
  `bladder`      FLOAT NOT NULL DEFAULT 90,
  `traits`       VARCHAR(64) NOT NULL DEFAULT '',
  `career`       TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `career_rank`  TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `career_perf`  INT UNSIGNED NOT NULL DEFAULT 0,
  `shifts`       INT UNSIGNED NOT NULL DEFAULT 0,
  `home_map`     INT NOT NULL DEFAULT -1,
  `home_x`       FLOAT NOT NULL DEFAULT 0,
  `home_y`       FLOAT NOT NULL DEFAULT 0,
  `home_z`       FLOAT NOT NULL DEFAULT 0,
  `home_o`       FLOAT NOT NULL DEFAULT 0,
  `preg_until`   INT UNSIGNED NOT NULL DEFAULT 0,
  `preg_partner` VARCHAR(32) NOT NULL DEFAULT '',
  `preg_pname`   VARCHAR(64) NOT NULL DEFAULT '',
  `outfit`       VARCHAR(512) NOT NULL DEFAULT '',
  `outfits`      VARCHAR(1600) NOT NULL DEFAULT '',
  `asp`          VARCHAR(16) NOT NULL DEFAULT '',
  `asp_stage`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `sp`           INT UNSIGNED NOT NULL DEFAULT 0,
  `perks`        VARCHAR(255) NOT NULL DEFAULT '',
  `cnt`          VARCHAR(1024) NOT NULL DEFAULT '',
  `ill`          INT UNSIGNED NOT NULL DEFAULT 0,
  `bill`         INT UNSIGNED NOT NULL DEFAULT 0,
  `bill_due`     INT UNSIGNED NOT NULL DEFAULT 0,
  `royalty`      VARCHAR(512) NOT NULL DEFAULT '',
  `power_off`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SimsCraft: needs, traits, career, home';

CREATE TABLE IF NOT EXISTS `character_sims_relations` (
  `guid`        INT UNSIGNED NOT NULL,
  `target_key`  VARCHAR(32) NOT NULL COMMENT 'P<guid> player, C<entry> NPC',
  `target_name` VARCHAR(64) NOT NULL DEFAULT '',
  `friendship`  INT NOT NULL DEFAULT 0,
  `romance`     INT NOT NULL DEFAULT 0,
  `status`      VARCHAR(16) NOT NULL DEFAULT '',
  `met`         INT UNSIGNED NOT NULL DEFAULT 0,
  `since`       INT UNSIGNED NOT NULL DEFAULT 0,
  `day`         INT UNSIGNED NOT NULL DEFAULT 0,
  `gf`          INT NOT NULL DEFAULT 0,
  `gr`          INT NOT NULL DEFAULT 0,
  `display`     INT UNSIGNED NOT NULL DEFAULT 0,
  `gender`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `kind`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `spawn`       INT UNSIGNED NOT NULL DEFAULT 0,
  `wmap`        INT NOT NULL DEFAULT -1,
  `wx`          FLOAT NOT NULL DEFAULT 0,
  `wy`          FLOAT NOT NULL DEFAULT 0,
  `wz`          FLOAT NOT NULL DEFAULT 0,
  `wo`          FLOAT NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `target_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SimsCraft: relationships';

CREATE TABLE IF NOT EXISTS `character_sims_furniture` (
  `id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid`   INT UNSIGNED NOT NULL,
  `entry`  INT UNSIGNED NOT NULL,
  `map`    INT UNSIGNED NOT NULL,
  `x`      FLOAT NOT NULL,
  `y`      FLOAT NOT NULL,
  `z`      FLOAT NOT NULL,
  `o`      FLOAT NOT NULL DEFAULT 0,
  `spawn`  INT UNSIGNED NOT NULL DEFAULT 0,
  `item`   VARCHAR(16) NOT NULL DEFAULT '',
  `refund` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SimsCraft: player furniture';

CREATE TABLE IF NOT EXISTS `character_sims_children` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid`          INT UNSIGNED NOT NULL COMMENT 'parent',
  `name`          VARCHAR(64) NOT NULL DEFAULT '',
  `gender`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `grp`           TINYINT UNSIGNED NOT NULL DEFAULT 101 COMMENT '100 + race',
  `born`          INT UNSIGNED NOT NULL DEFAULT 0,
  `happy`         FLOAT NOT NULL DEFAULT 80,
  `skill`         FLOAT NOT NULL DEFAULT 0,
  `coparent_name` VARCHAR(64) NOT NULL DEFAULT '',
  `moved`         TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `mmap`          INT NOT NULL DEFAULT -1,
  `mx`            FLOAT NOT NULL DEFAULT 0,
  `my`            FLOAT NOT NULL DEFAULT 0,
  `mz`            FLOAT NOT NULL DEFAULT 0,
  `partner`       VARCHAR(40) NOT NULL DEFAULT '',
  `place`         VARCHAR(120) NOT NULL DEFAULT '',
  `stay`          TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `grade`         FLOAT NOT NULL DEFAULT 60,
  PRIMARY KEY (`id`),
  KEY `idx_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SimsCraft: children';

CREATE TABLE IF NOT EXISTS `character_sims_world` (
  `k` VARCHAR(32) NOT NULL,
  `v` VARCHAR(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`k`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SimsCraft: world clock and shared values';

CREATE TABLE IF NOT EXISTS `character_sims_spots` (
  `id`   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid` INT UNSIGNED NOT NULL,
  `kind` VARCHAR(16) NOT NULL,
  `map`  INT UNSIGNED NOT NULL,
  `x`    FLOAT NOT NULL,
  `y`    FLOAT NOT NULL,
  `z`    FLOAT NOT NULL,
  `o`    FLOAT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SimsCraft: built-in furniture marks in ready-made houses';

CREATE TABLE IF NOT EXISTS `character_sims_skills` (
  `guid`  INT UNSIGNED NOT NULL,
  `skill` VARCHAR(16) NOT NULL,
  `xp`    FLOAT NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `skill`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SimsCraft: skills';
