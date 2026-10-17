-- SimsCraft 3.0: изменения базы ПЕРСОНАЖЕЙ. Запускать с mysql --force (повторы безопасны).
ALTER TABLE `character_sims_relations` ADD COLUMN `met` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `since` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `day` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `gf` INT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `gr` INT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `display` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `gender` TINYINT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `kind` TINYINT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_furniture` ADD COLUMN `refund` INT UNSIGNED NOT NULL DEFAULT 0;
-- отношения, накопленные в 2.0 без ограничений: знакомство считаем давним
UPDATE `character_sims_relations` SET `met` = UNIX_TIMESTAMP() - 86400 * 3 WHERE `met` = 0;
UPDATE `character_sims_relations` SET `since` = UNIX_TIMESTAMP() - 86400 * 3 WHERE `since` = 0 AND `status` <> '';
