-- SimsCraft 4.0: изменения базы ПЕРСОНАЖЕЙ. Запускать с mysql --force (повторы безопасны).
-- где супруг-NPC работает (его место в мире), чтобы он ходил на работу и домой
ALTER TABLE `character_sims_relations` ADD COLUMN `spawn` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `wmap` INT NOT NULL DEFAULT -1;
ALTER TABLE `character_sims_relations` ADD COLUMN `wx` FLOAT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `wy` FLOAT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `wz` FLOAT NOT NULL DEFAULT 0;
ALTER TABLE `character_sims_relations` ADD COLUMN `wo` FLOAT NOT NULL DEFAULT 0;
-- игровые часы (общие для мира)
CREATE TABLE IF NOT EXISTS `character_sims_world` (
    `k` VARCHAR(32) NOT NULL,
    `v` VARCHAR(64) NOT NULL DEFAULT '',
    PRIMARY KEY (`k`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- старые записи о детях (ребёнок числился «знакомым» по номеру существа) больше не нужны
DELETE FROM `character_sims_relations` WHERE `target_key` IN ('C190110','C190111','C190112','C190113','C190114','C190115','C190116','C190117','C190118','C190119');
-- двойник супруга из 3.0 больше не используется
DELETE FROM `character_sims_relations` WHERE `target_key` IN ('C190120','C190121');
