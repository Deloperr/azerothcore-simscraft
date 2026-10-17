-- SimsCraft 6.0: изменения базы ПЕРСОНАЖЕЙ. Запускать с mysql --force (повторы безопасны).
ALTER TABLE `character_sims` ADD COLUMN `asp` VARCHAR(16) NOT NULL DEFAULT '';
ALTER TABLE `character_sims` ADD COLUMN `asp_stage` TINYINT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims` ADD COLUMN `sp` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims` ADD COLUMN `perks` VARCHAR(255) NOT NULL DEFAULT '';
ALTER TABLE `character_sims` ADD COLUMN `cnt` VARCHAR(1024) NOT NULL DEFAULT '';
ALTER TABLE `character_sims` ADD COLUMN `ill` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims` ADD COLUMN `bill` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims` ADD COLUMN `bill_due` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims` ADD COLUMN `royalty` VARCHAR(512) NOT NULL DEFAULT '';
ALTER TABLE `character_sims` ADD COLUMN `power_off` TINYINT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_children` ADD COLUMN `grade` FLOAT NOT NULL DEFAULT 60;
CREATE TABLE IF NOT EXISTS `character_sims_skills` (
    `guid` INT UNSIGNED NOT NULL,
    `skill` VARCHAR(16) NOT NULL,
    `xp` FLOAT NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`, `skill`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
