-- SimsCraft 5.0: изменения базы ПЕРСОНАЖЕЙ. Запускать с mysql --force (повторы безопасны).
-- наряды (только внешний вид)
ALTER TABLE `character_sims` ADD COLUMN `outfit` VARCHAR(512) NOT NULL DEFAULT '';
ALTER TABLE `character_sims` ADD COLUMN `outfits` VARCHAR(1600) NOT NULL DEFAULT '';
-- взрослые дети, живущие своей семьёй
ALTER TABLE `character_sims_children` ADD COLUMN `moved` TINYINT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_children` ADD COLUMN `mmap` INT NOT NULL DEFAULT -1;
ALTER TABLE `character_sims_children` ADD COLUMN `mx` FLOAT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_children` ADD COLUMN `my` FLOAT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_children` ADD COLUMN `mz` FLOAT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_children` ADD COLUMN `partner` VARCHAR(40) NOT NULL DEFAULT '';
ALTER TABLE `character_sims_children` ADD COLUMN `place` VARCHAR(120) NOT NULL DEFAULT '';
ALTER TABLE `character_sims_children` ADD COLUMN `stay` TINYINT UNSIGNED NOT NULL DEFAULT 0;
-- встроенная мебель готовых домов (метки)
CREATE TABLE IF NOT EXISTS `character_sims_spots` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `guid` INT UNSIGNED NOT NULL,
    `kind` VARCHAR(16) NOT NULL,
    `map` INT UNSIGNED NOT NULL,
    `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL, `o` FLOAT NOT NULL,
    PRIMARY KEY (`id`), KEY `guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
