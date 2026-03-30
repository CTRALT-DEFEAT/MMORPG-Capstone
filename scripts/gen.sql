DROP DATABASE IF EXISTS capstone_mmorpg;
CREATE DATABASE IF NOT EXISTS capstone_mmorpg;
USE capstone_mmorpg;
DROP TABLE IF EXISTS specialization_restrictions;
DROP TABLE IF EXISTS item_restrictions;
DROP TABLE IF EXISTS quest_restrictions;
DROP TABLE IF EXISTS restrictions;
DROP TABLE IF EXISTS class_modifiers;
DROP TABLE IF EXISTS specialization_modifier;
DROP TABLE IF EXISTS race_modifiers;
DROP TABLE IF EXISTS item_modifiers;
DROP TABLE IF EXISTS modifiers;
DROP TABLE IF EXISTS combat_equipment;
DROP TABLE IF EXISTS combat_info;
DROP TABLE IF EXISTS combats;
DROP TABLE IF EXISTS trade_info;
DROP TABLE IF EXISTS npc_trades;
DROP TABLE IF EXISTS player_trades;
DROP TABLE IF EXISTS zone_mobs;
DROP TABLE IF EXISTS mobs;
DROP TABLE IF EXISTS quest_history;
DROP TABLE IF EXISTS quest_rewards;
DROP TABLE IF EXISTS loot_table_items;
DROP TABLE IF EXISTS loot_tables;
DROP TABLE IF EXISTS quests;
DROP TABLE IF EXISTS npc_dialogs;
DROP TABLE IF EXISTS npcs;
DROP TABLE IF EXISTS npc_roles;
DROP TABLE IF EXISTS zones;
DROP TABLE IF EXISTS factions;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS guild_history;
DROP TABLE IF EXISTS guild_activity;
DROP TABLE IF EXISTS guild_members;
DROP TABLE IF EXISTS guild_roles;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS guilds;
DROP TABLE IF EXISTS message_history;
DROP TABLE IF EXISTS chat_members;
DROP TABLE IF EXISTS chat_filters;
DROP TABLE IF EXISTS filters;
DROP TABLE IF EXISTS chats;
DROP TABLE IF EXISTS equipped_items;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS item_info;
DROP TABLE IF EXISTS item_rarities;
DROP TABLE IF EXISTS inventories;
DROP TABLE IF EXISTS character_stats;
DROP TABLE IF EXISTS character_info;
DROP TABLE IF EXISTS characters;
DROP TABLE IF EXISTS account_history;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS slots;
DROP TABLE IF EXISTS stats;
DROP TABLE IF EXISTS levels;
DROP TABLE IF EXISTS specializations;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS races;

CREATE TABLE IF NOT EXISTS races (
    race_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15),
    description TINYTEXT
);

CREATE TABLE IF NOT EXISTS classes (
    class_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15),
    description TINYTEXT
);

CREATE TABLE IF NOT EXISTS specializations (
    specialization_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS levels (
    level_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    xp_requirement MEDIUMINT UNSIGNED
);

CREATE TABLE IF NOT EXISTS stats (
    stat_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS slots (
    slot_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS inventories (
    inventory_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    max_size TINYINT UNSIGNED
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    creation_date DATETIME,
    max_characters TINYINT UNSIGNED,
    current_characters TINYINT UNSIGNED
);

CREATE TABLE IF NOT EXISTS account_history (
    history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id INT UNSIGNED,
    log_on DATETIME,
    log_off DATETIME,

    FOREIGN KEY (account_id)
    REFERENCES accounts(account_id)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS characters (
    character_id INT UNSIGNED PRIMARY KEY,
    class_id INT UNSIGNED NOT NULL,
    specialization_id INT UNSIGNED NOT NULL,
    race_id INT UNSIGNED NOT NULL,
    level_id INT UNSIGNED NOT NULL,
    inventory_id INT UNSIGNED UNIQUE NOT NULL,
    name VARCHAR(25),
    gold_balance MEDIUMINT UNSIGNED,
    experience MEDIUMINT UNSIGNED,

    FOREIGN KEY (class_id)
    REFERENCES classes(class_id),
    FOREIGN KEY (specialization_id)
    REFERENCES specializations(specialization_id),
    FOREIGN KEY (race_id)
    REFERENCES races(race_id),
    FOREIGN KEY (level_id)
    REFERENCES levels(level_id),
    FOREIGN KEY (inventory_id)
    REFERENCES inventories(inventory_id)
);

CREATE TABLE IF NOT EXISTS character_info (
    character_id INT UNSIGNED PRIMARY KEY,
    account_id INT UNSIGNED,
    active BIT,
    creation_date DATETIME,
    last_played DATE,
    time_played TIME,

    FOREIGN KEY (character_id)
    REFERENCES characters(character_id),
    FOREIGN KEY (account_id)
    REFERENCES accounts(account_id)
);

CREATE TABLE IF NOT EXISTS character_stats (
    character_id INT UNSIGNED,
    stat_id INT UNSIGNED,
    ammount TINYINT UNSIGNED,

    PRIMARY KEY (character_id, stat_id),

    FOREIGN KEY (character_id)
    REFERENCES characters(character_id)
    ON DELETE CASCADE,
    FOREIGN KEY (stat_id)
    REFERENCES stats(stat_id)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS item_rarities (
    rarity_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15),
    color CHAR(6)
);

CREATE TABLE IF NOT EXISTS item_info (
    info_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rarity_id INT UNSIGNED,
    name VARCHAR(25),
    durability_max SMALLINT UNSIGNED,
    sell_price SMALLINT UNSIGNED,
    repair_cost SMALLINT UNSIGNED,
    two_handed BIT,

    FOREIGN KEY (rarity_id)
    REFERENCES item_rarities(rarity_id)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS items (
    item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT UNSIGNED,
    info_id INT UNSIGNED,

    FOREIGN KEY (inventory_id)
    REFERENCES inventories(inventory_id)
    ON DELETE CASCADE,

    FOREIGN KEY (info_id)
    REFERENCES item_info(info_id)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS equipped_items (
    equipped_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id INT UNSIGNED,
    slot_id INT UNSIGNED,
    item_id INT UNSIGNED,

    FOREIGN KEY(character_id) 
    REFERENCES characters(character_id)
    ON DELETE CASCADE,

    FOREIGN KEY(slot_id)
    REFERENCES slots(slot_id)
    ON DELETE CASCADE,

    FOREIGN KEY (item_id)
    REFERENCES items(item_id)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS chats (
    chat_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    is_private BIT
);

CREATE TABLE IF NOT EXISTS filters (
    filter_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    word VARCHAR(45),
    filtered_word VARCHAR(45) 
);

CREATE TABLE IF NOT EXISTS chat_filters (
    filter_id INT UNSIGNED,
    chat_id INT UNSIGNED,

    PRIMARY KEY (filter_id, chat_id),

    FOREIGN KEY (filter_id)
    REFERENCES filters(filter_id),
    FOREIGN KEY (chat_id)
    REFERENCES chats(chat_id)
);

CREATE TABLE IF NOT EXISTS chat_members (
    chat_id INT UNSIGNED,
    character_id INT UNSIGNED,

    PRIMARY KEY (chat_id, character_id),

    FOREIGN KEY (chat_id)
    REFERENCES chats(chat_id),
    FOREIGN KEY (character_id) 
    REFERENCES characters(character_id)
);

CREATE TABLE IF NOT EXISTS message_history (
    message_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    chat_id INT UNSIGNED,
    sender_id INT UNSIGNED,
    message TINYTEXT,
    time DATETIME,

    FOREIGN KEY (chat_id, sender_id)
    REFERENCES chat_members(chat_id, character_id)
);

CREATE TABLE IF NOT EXISTS guilds (
    guild_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    chat_id INT UNSIGNED UNIQUE,
    creation_date DATETIME,
    motd TINYTEXT,
    member_limit TINYINT UNSIGNED,

    FOREIGN Key (chat_id)
    REFERENCES chats(chat_id)
);
CREATE TABLE IF NOT EXISTS roles (
    role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(10),
    can_invite BIT,
    can_kick BIT,
    can_edit_roles BIT,
    can_edit_motd BIT
);

CREATE TABLE IF NOT EXISTS guild_roles (
    guild_id INT UNSIGNED,
    role_id INT UNSIGNED,

    PRIMARY KEY (guild_id, role_id),
    FOREIGN KEY (guild_id)
    REFERENCES guilds(guild_id),
    FOREIGN KEY (role_id)
    REFERENCES roles(role_id)
);

CREATE TABLE IF NOT EXISTS guild_members (
    member_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id INT UNSIGNED,
    guild_id INT UNSIGNED,
    character_id INT UNSIGNED,

    UNIQUE KEY (guild_id, character_id),
    FOREIGN KEY (role_id)
    REFERENCES guild_roles(role_id),
    FOREIGN KEY (guild_id)
    REFERENCES guilds(guild_id),
    FOREIGN KEY (character_id)
    REFERENCES characters(character_id)
);

CREATE TABLE IF NOT EXISTS member_activity (
    activity_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    member_id INT UNSIGNED,
    day DATE,
    time_played TIME,

    FOREIGN KEY (member_id)
    REFERENCES guild_members(member_id)
);

CREATE TABLE IF NOT EXISTS member_history (
    member_history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id INT UNSIGNED,
    member_id INT UNSIGNED,
    time DATETIME,

    FOREIGN KEY (role_id)
    REFERENCES roles(role_id),
    FOREIGN KEY (member_id)
    REFERENCES guild_members(member_id)
);

CREATE TABLE IF NOT EXISTS regions (
    region_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    chat_id INT UNSIGNED UNIQUE,
    name VARCHAR(20),

    FOREIGN KEY (chat_id)
    REFERENCES chats(chat_id)
);

CREATE TABLE IF NOT EXISTS factions (
    faction_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    region_id INT UNSIGNED UNIQUE,
    name VARCHAR(25),

    FOREIGN KEY (region_id)
    REFERENCES regions(region_id)
);

CREATE TABLE IF NOT EXISTS zones (
    zone_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    region_id INT UNSIGNED,
    name VARCHAR(20),

    FOREIGN KEY (region_id)
    REFERENCES regions(region_id)
);


CREATE TABLE IF NOT EXISTS dialogs (
    dialog_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dialog TEXT
);

CREATE TABLE IF NOT EXISTS npc_roles (
    role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS npcs (
    npc_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    zone_id INT UNSIGNED,
    role_id INT UNSIGNED,
    race_id INT UNSIGNED,
    name VARCHAR(25),
    description TINYTEXT,
    killable BIT,

    FOREIGN KEY (zone_id)
    REFERENCES zones(zone_id),
    FOREIGN KEY (role_id)
    REFERENCES npc_roles(role_id),
    FOREIGN KEY (race_id)
    REFERENCES races(race_id)
);

CREATE TABLE IF NOT EXISTS npc_dialog (
    dialog_id INT UNSIGNED,
    npc_id INT UNSIGNED,

    PRIMARY KEY (dialog_id, npc_id),
    FOREIGN KEY (dialog_id)
    REFERENCES dialogs(dialog_id),
    FOREIGN KEY (npc_id)
    REFERENCES npcs(npc_id)
);

CREATE TABLE IF NOT EXISTS quests (
    quest_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    npc_id INT UNSIGNED,
    name VARCHAR(100),
    description TEXT,
    repeatable BIT,
    location CHAR(10),

    FOREIGN KEY (npc_id)
    REFERENCES npcs(npc_id)
);

CREATE TABLE IF NOT EXISTS loot_tables (
    loot_table_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    min_gold TINYINT UNSIGNED,
    max_gold TINYINT UNSIGNED,
    min_exp TINYINT UNSIGNED,
    max_exp TINYINT UNSIGNED
);

CREATE TABLE IF NOT EXISTS loot_table_items (
    item_id INT UNSIGNED,
    loot_table_id INT UNSIGNED,
    drop_rate DECIMAL(11,10),

    PRIMARY KEY (item_id, loot_table_id),
    FOREIGN KEY (item_id)
    REFERENCES items(item_id),
    FOREIGN KEY (loot_table_id)
    REFERENCES loot_tables(loot_table_id)
);

CREATE TABLE IF NOT EXISTS quest_rewards (
    reward_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    item_id INT UNSIGNED,
    quest_id INT UNSIGNED,
    gold MEDIUMINT UNSIGNED,
    experience MEDIUMINT UNSIGNED,

    FOREIGN KEY (item_id)
    REFERENCES items(item_id),
    FOREIGN KEY (quest_id)
    REFERENCES quests(quest_id)
);

CREATE TABLE IF NOT EXISTS quest_history (
    history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id INT UNSIGNED,
    quest_id INT UNSIGNED,
    reward_id INT UNSIGNED,
    state ENUM('completed','accepted','failed'),
    time DATETIME,

    FOREIGN KEY (character_id)
    REFERENCES characters(character_id),
    FOREIGN KEY (quest_id)
    REFERENCES quests(quest_id),
    FOREIGN KEY (reward_id)
    REFERENCES quest_rewards(reward_id)
);

CREATE TABLE IF NOT EXISTS mobs (
    mob_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    loot_table_id INT UNSIGNED,
    name VARCHAR(25),
    is_boss BIT,

    FOREIGN KEY (loot_table_id)
    REFERENCES loot_tables(loot_table_id)
);

CREATE TABLE IF NOT EXISTS zone_mobs (
    zone_id INT UNSIGNED,
    mob_id INT UNSIGNED,
    amount TINYINT UNSIGNED,

    PRIMARY KEY(zone_id, mob_id),
    FOREIGN KEY (zone_id)
    REFERENCES zones(zone_id),
    FOREIGN KEY (mob_id)
    REFERENCES mobs(mob_id)
);

CREATE TABLE IF NOT EXISTS player_trades (
    trade_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sender_id INT UNSIGNED,
    reciever_id INT UNSIGNED,

    FOREIGN KEY (sender_id)
    REFERENCES characters(character_id),
    FOREIGN KEY (reciever_id)
    REFERENCES characters(character_id)
);

CREATE TABLE IF NOT EXISTS npc_trades (
    trade_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id INT UNSIGNED,
    npc_id INT UNSIGNED,

    FOREIGN KEY (character_id)
    REFERENCES characters(character_id),
    FOREIGN KEY (npc_id)
    REFERENCES npcs(npc_id)
);

CREATE TABLE IF NOT EXISTS trade_info (
    info_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    player_trade_id INT UNSIGNED,
    npc_trade_id INT UNSIGNED,
    item_id INT UNSIGNED,
    gold MEDIUMINT UNSIGNED,
    time DATETIME,

    FOREIGN KEY (player_trade_id)
    REFERENCES player_trades(trade_id),
    FOREIGN KEY (npc_trade_id)
    REFERENCES npc_trades(trade_id),
    FOREIGN KEY (item_id)
    REFERENCES items(item_id)
);

CREATE TABLE IF NOT EXISTS combats (
    combat_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id INT UNSIGNED,
    mob_id INT UNSIGNED,

    FOREIGN KEY (character_id)
    REFERENCES characters(character_id),
    FOREIGN KEY (mob_id)
    REFERENCES mobs(mob_id)
);

CREATE TABLE IF NOT EXISTS combat_info (
    info_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    combat_id INT UNSIGNED UNIQUE,
    time DATETIME,
    result ENUM('win','loss'),

    FOREIGN KEY (combat_id)
    REFERENCES combats(combat_id)
);

CREATE TABLE IF NOT EXISTS combat_equipment (
    equipped_id INT UNSIGNED,
    combat_id INT UNSIGNED,
    durability_lost SMALLINT UNSIGNED,

    PRIMARY KEY (equipped_id, combat_id),
    FOREIGN KEY (combat_id)
    REFERENCES combats(combat_id),
    FOREIGN KEY (equipped_id)
    REFERENCES equipped_items(equipped_id) 
);

CREATE TABLE IF NOT EXISTS modifiers (
    modifier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stat_id INT UNSIGNED,
    amount TINYINT UNSIGNED,
    type ENUM('add','reduce'),

    FOREIGN KEY (stat_id)
    REFERENCES stats(stat_id)
);

CREATE TABLE IF NOT EXISTS item_modifiers (
    modifier_id INT UNSIGNED,
    item_id INT UNSIGNED,

    PRIMARY KEY (modifier_id, item_id),
    FOREIGN KEY (modifier_id)
    REFERENCES modifiers(modifier_id),
    FOREIGN KEY (item_id)
    REFERENCES items(item_id)
);

CREATE TABLE IF NOT EXISTS race_modifier(
    modifier_id INT UNSIGNED,
    race_id INT UNSIGNED,

    PRIMARY KEY (modifier_id, race_id),
    FOREIGN KEY (modifier_id)
    REFERENCES modifiers(modifier_id),
    FOREIGN KEY (race_id)
    REFERENCES races(race_id)
);

CREATE TABLE IF NOT EXISTS specialization_modifiers (
    modifier_id INT UNSIGNED,
    specialization_id INT UNSIGNED,

    PRIMARY KEY (modifier_id, specialization_id),
    FOREIGN KEY (modifier_id)
    REFERENCES modifiers(modifier_id),
    FOREIGN KEY (specialization_id)
    REFERENCES specializations(specialization_id)
);

CREATE TABLE IF NOT EXISTS class_modifier (
    modifier_id INT UNSIGNED,
    class_id INT UNSIGNED,

    PRIMARY KEY (modifier_id, class_id),
    FOREIGN KEY (modifier_id)
    REFERENCES modifiers(modifier_id),
    FOREIGN KEY (class_id)
    REFERENCES classes(class_id)
);

CREATE TABLE IF NOT EXISTS restrictions (
    restriction_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id INT UNSIGNED,
    specialization_id INT UNSIGNED,
    race_id INT UNSIGNED,
    level_id INT UNSIGNED,
    quest_id INT UNSIGNED,
    type ENUM('requirement', 'restriction'),

    FOREIGN KEY (class_id)
    REFERENCES classes(class_id),
    FOREIGN KEY (specialization_id)
    REFERENCES specializations(specialization_id),
    FOREIGN KEY (race_id)
    REFERENCES races(race_id),
    FOREIGN KEY (level_id)
    REFERENCES levels(level_id),
    FOREIGN KEY (quest_id)
    REFERENCES quests(quest_id)
);

CREATE TABLE IF NOT EXISTS quest_restrictions (
    restriction_id INT UNSIGNED,
    quest_id INT UNSIGNED,

    PRIMARY KEY (restriction_id, quest_id),
    FOREIGN KEY (restriction_id)
    REFERENCES restrictions(restriction_id),
    FOREIGN KEY (quest_id)
    REFERENCES quests(quest_id)
);

CREATE TABLE IF NOT EXISTS item_restrictions (
    restriction_id INT UNSIGNED,
    item_id INT UNSIGNED,

    PRIMARY KEY (restriction_id, item_id),
    FOREIGN KEY (restriction_id)
    REFERENCES restrictions(restriction_id),
    FOREIGN KEY (item_id)
    REFERENCES items(item_id)
);

CREATE TABLE IF NOT EXISTS specialization_restrictions(
    restriction_id INT UNSIGNED,
    specialization_id INT UNSIGNED,

    PRIMARY KEY(restriction_id, specialization_id),
    FOREIGN KEY(restriction_id)
    REFERENCES restrictions(restriction_id),
    FOREIGN Key (specialization_id) 
    REFERENCES specializations(specialization_id)
);

DROP PROCEDURE IF EXISTS random_character_chats;
DROP PROCEDURE IF EXISTS random_npcs;
DROP PROCEDURE IF EXISTS random_member_activity;
DROP PROCEDURE IF EXISTS random_guild_members;
DROP PROCEDURE IF EXISTS random_guilds;
DROP PROCEDURE IF EXISTS chat_filters;
DROP PROCEDURE IF EXISTS random_zones;
DROP PROCEDURE IF EXISTS new_chat;
DROP PROCEDURE IF EXISTS random_equiped;
DROP PROCEDURE IF EXISTS random_items;
DROP PROCEDURE IF EXISTS random_item_info;
DROP PROCEDURE IF EXISTS random_character_stats;
DROP PROCEDURE IF EXISTS random_character_info;
DROP PROCEDURE IF EXISTS random_character;
DROP PROCEDURE IF EXISTS random_account_history;
DROP PROCEDURE IF EXISTS random_account;
DROP PROCEDURE IF EXISTS random_datetime;
DROP PROCEDURE IF EXISTS gen_chat_filters;
DROP PROCEDURE IF EXISTS gen_npc_dialog;
DROP PROCEDURE IF EXISTS random_message_history;
DROP PROCEDURE IF EXISTS random_loot_table;
DROP PROCEDURE IF EXISTS random_loot_table_items;
DROP PROCEDURE IF EXISTS random_quest_rewards;
DROP PROCEDURE IF EXISTS random_quest_history;
DROP PROCEDURE IF EXISTS random_mobs;
DROP PROCEDURE IF EXISTS random_zone_mobs;
DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS random_datetime(
    IN start_time DATETIME,
    IN end_time DATETIME,
    OUT random_date DATETIME)
BEGIN
    SET random_date = FROM_UNIXTIME(
        UNIX_TIMESTAMP(start_time) + FLOOR(
            RAND() * (UNIX_TIMESTAMP(end_time) - UNIX_TIMESTAMP(start_time))
        )
    );
END $$

CREATE PROCEDURE IF NOT EXISTS random_account_history (
    IN acc_id INT,
    IN history_count INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE start_date DATE;
    DECLARE off_time DATETIME;
    DECLARE newest_time DATETIME;

    SELECT creation_date INTO start_date FROM accounts
    WHERE acc_id = account_id;

    WHILE i <= history_count DO
        SELECT log_off INTO newest_time FROM account_history
        WHERE account_id = acc_id
        ORDER BY log_off DESC LIMIT 1;

        CAll random_datetime(
            IF(newest_time IS NULL, start_date, newest_time), 
            NOW(),
            @log_on_time
        );
        SET off_time = DATE_ADD(@log_on_time, INTERVAL FLOOR(RAND() * 86400)SECOND);

        INSERT INTO account_history(account_id, log_on, log_off)
        VALUES(acc_id, @log_on_time, off_time);

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_account(
    IN number_of_accounts INT,
    IN newest_date DATETIME,
    IN oldest_date DATETIME,
    IN max_char INT,
    IN num_of_history INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= number_of_accounts DO
        CALL random_datetime(newest_date, oldest_date, @creation_date);
        INSERT INTO accounts(account_id, username, creation_date, max_characters, current_characters)
        VALUES(i, CONCAT('usr_', i),@creation_date,max_char, 0);

        CALL random_account_history(i, num_of_history);

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_character_info(
    IN char_id INT
)
BEGIN
    DECLARE rand_account INT;
    DECLARE account_date DATETIME;
    DECLARE is_active BIT;

    SELECT account_id INTO rand_account FROM accounts
    WHERE account_id >= (
        SELECT FLOOR(MAX(account_id) * RAND()) 
        FROM accounts) 
    AND max_characters > current_characters
    ORDER BY account_id LIMIT 1;

    SELECT creation_date INTO account_date FROM accounts
    WHERE account_id = rand_account;

    CALL random_datetime(account_date, NOW(), @character_date);
    CALL random_datetime(@character_date, NOW(), @last_played);

    INSERT INTO character_info 
    (character_id, account_id, active, creation_date, 
    last_played, time_played)
    VALUES (
        char_id,
        rand_account,
        IF(RAND() < 0.9, TRUE, FALSE),
        @character_date,
        @last_played,
        SEC_TO_TIME(FLOOR(RAND() * 2880000))
    );

    UPDATE accounts
    SET current_characters = current_characters + 1
    WHERE account_id = rand_account;
END $$

CREATE PROCEDURE IF NOT EXISTS random_character_stats(
    IN char_id INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE stat_count INT;
    SELECT COUNT(*) INTO stat_count FROM stats;

    WHILE i <= stat_count DO
        INSERT INTO character_stats (
            character_id,
            stat_id,
            ammount
        )
        VALUES(
            char_id,
            i,
            FLOOR(1 + (RAND() * 50))
        );
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_character(
    IN number_of_characters INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE level INT;
    DECLARE level_count INT;
    SELECT COUNT(*) INTO level_count FROM levels;

    WHILE i <= number_of_characters DO
        SET level = FLOOR(1 + RAND()*level_count);

        INSERT INTO inventories (inventory_id, max_size)
        VALUES (
            i, 10 * level
        );

        INSERT INTO characters (character_id, name, class_id, race_id,
        specialization_id, level_id, inventory_id, gold_balance)
        VALUES (
            i,
            CONCAT('Char_', i),
            FLOOR(1+ RAND()*7),
            FLOOR(1+ RAND()*9),
            1,
            level,
            i,
            FLOOR(1+ RAND()*45000)
        );
        CALL random_character_info(i);
        CALL random_character_stats(i);

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_item_info (
    IN num_of_items INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE rarity_count INT;
    SELECT COUNT(*) INTO rarity_count FROM item_rarities;

    WHILE i <= num_of_items DO
        INSERT INTO item_info(
            rarity_id, 
            name,
            durability_max,
            sell_price,
            repair_cost,
            two_handed
        )
        VALUES (
            FLOOR(1 + RAND() * rarity_count),
            CONCAT('item_', i),
            FLOOR(1 + RAND() * 50000),
            FLOOR(1 + RAND() * 50000),
            FLOOR(1 + RAND() * 50000),
            IF(RAND() < 0.3, TRUE, FALSE)
        );

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_items(
    IN num_of_items INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE rand_inventory INT;
    DECLARE inventory_size INT;
    DECLARE item_count INT;
    DECLARE total_item_count INT;
    SELECT COUNT(*) INTO total_item_count FROM item_info;
    
    WHILE i <= num_of_items DO
        REPEAT
            SELECT inventory_id INTO rand_inventory FROM inventories
            WHERE inventory_id >= (
                SELECT FLOOR(MAX(inventory_id) * RAND())
                FROM inventories
            )
            ORDER BY inventory_id LIMIT 1;

            SELECT COUNT(*) INTO item_count FROM items
            WHERE inventory_id = rand_inventory;

            SELECT max_size INTO inventory_size FROM inventories
            WHERE inventory_id = rand_inventory;

        UNTIL item_count <= inventory_size
        END REPEAT;

        INSERT INTO items (inventory_id, info_id)
        VALUES (
            rand_inventory,
            FLOOR(1 + RAND() * total_item_count)
        );
        
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_equiped( 
)
BEGIN
    DECLARE num_of_characters INT;
    DECLARE num_of_slots INT;
    DECLARE i INT DEFAULT 1;
    DECLARE z INT DEFAULT 1;
    DECLARE character_inv INT;
    DECLARE slot_item INT;
    SELECT COUNT(*) INTO num_of_characters
    FROM characters;
    SELECT COUNT(*) INTO num_of_slots
    FROM slots;

    WHILE i <= num_of_characters DO
        SET z = 1;

        WHILE z <= num_of_slots DO
            SELECT inventory_id 
            INTO character_inv
            FROM characters
            WHERE character_id = i;

            SELECT item_id INTO slot_item
            FROM items
            WHERE inventory_id = character_inv
            ORDER BY RAND() LIMIT 1;
            
            INSERT INTO equipped_items(
                character_id,
                slot_id,
                item_id
            )
            VALUES(
                i,
                z,
                slot_item
            );
            UPDATE items
            SET inventory_id = NULL
            WHERE item_id = slot_item;
            
            SET slot_item = NULL;
            SET z = z + 1;
        END WHILE;
        
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_character_chats(
    IN number_of_chats INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE chat_member_1 INT;
    DECLARE chat_member_2 INT;
    DECLARE chat_name VARCHAR(50);

    WHILE i <= number_of_chats DO
        SET chat_member_1 = NULL;
        SET chat_member_2 = NULL;

        SELECT character_id INTO chat_member_1
        FROM characters
        ORDER BY RAND()
        LIMIT 1;

        SELECT character_id INTO chat_member_2
        FROM characters
        WHERE (character_id != chat_member_1)
        AND character_id NOT IN(
            SELECT character_id FROM chat_members
            WHERE character_id = chat_member_1
        )
        ORDER BY RAND()
        LIMIT 1;

        SET chat_name =
        CONCAT(
            (
                SELECT name 
                FROM characters
                WHERE character_id = chat_member_1
            ),
            '-',
            (
                SELECT name
                FROM characters
                WHERE character_id = chat_member_2
            )
        );
        CALL new_chat(
            chat_name,
            1,
            @new_chat_id
        );

        INSERT INTO chat_members(
            chat_id,
            character_id
        )
        VALUES
            (@new_chat_id, chat_member_1),
            (@new_chat_id, chat_member_2);
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS new_chat(
    IN chat_name VARCHAR(50),
    IN chat_private BIT,
    OUT out_id INT
)
BEGIN
    INSERT INTO chats(
        name, 
        is_private
    )
    VALUES (
        chat_name,
        chat_private
    );
    SELECT chat_id INTO out_id
    FROM chats
    WHERE `name` = chat_name;
END $$

CREATE PROCEDURE IF NOT EXISTS gen_chat_filters(
    
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE z INT DEFAULT 1;
    DECLARE num_of_chats INT;
    DECLARE prvt_chat BIT;
    DECLARE num_of_filters INT;
    SELECT COUNT(*) INTO num_of_chats
    FROM chats;
    SELECT COUNT(*) INTO num_of_filters
    FROM filters;

    WHILE i <= num_of_chats DO
        SET z = 1;
        SELECT is_private INTO prvt_chat FROM chats
        WHERE chat_id = i;

        IF prvt_chat = 0 THEN
            WHILE z <= num_of_filters DO
                INSERT INTO chat_filters(
                    filter_id,
                    chat_id
                )
                VALUES(
                    z,
                    i
                );
                SET z = z + 1;
            END WHILE;
        END IF;
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_guilds(
    IN num_of_guilds INT,
    IN start_date DATETIME,
    IN end_date DATETIME
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE z INT DEFAULT 1;
    DECLARE max_members INT;
    DECLARE num_of_roles INT;
    SELECT COUNT(*) INTO num_of_roles
    FROM roles;

    WHILE i <= num_of_guilds DO
        SET z = 1;
        SET max_members = 15 + FLOOR(1 + RAND() * 30);
        CALL random_datetime(
            start_date, end_date, @guild_date
        );
        CALL new_chat(
            CONCAT('guild_', i, ' chat'),
            0,
            @new_chat_id
        );

        INSERT INTO guilds(
            guild_id,
            chat_id,
            creation_date,
            motd,
            member_limit
        )
        VALUES(
            i,
            @new_chat_id,
            @guild_date,
            NULL,
            max_members
        );

        WHILE z <= num_of_roles DO
            INSERT INTO guild_roles(
                guild_id,
                role_id
            )
            VALUES(
                i,
                z
            );
            SET z = z + 1;
        END WHILE;

        CALL random_guild_members(
            i,
            max_members
        );
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE random_member_activity (
    IN num_of_history INT,
    IN mem_id INT,
    IN char_id INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE start_date DATETIME;

    SELECT creation_date INTO start_date 
    FROM character_info
    WHERE character_id = char_id;

    WHILE i <= num_of_history DO
        CALL random_datetime(
            start_date,
            NOW(),
            @log_on
        );
        INSERT INTO member_activity(
            member_id,
            `day`,
            time_played
        )
        VALUES(
            mem_id,
            @log_on,
            SEC_TO_TIME(FLOOR(RAND() * 82800))
        );
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_guild_members(
    IN new_guild_id INT,
    IN num_of_members INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE member_PK INT;
    DECLARE cur_member INT;
    DECLARE member_role INT;
    SET num_of_members 
    = num_of_members - FLOOR(RAND() * 15);

    WHILE i <= num_of_members DO
        SET cur_member = NULL;
        SELECT character_id INTO cur_member
        FROM characters
        WHERE character_id NOT IN(
            SELECT character_id
            FROM guild_members
        )
        ORDER BY RAND() LIMIT 1;
        
        IF i = 1 THEN
            SET member_role = 4;
        ELSEIF RAND() > 0.95 THEN
            SET member_role = 3;
        ELSEIF RAND() > 0.38 THEN
            SET member_role = 2;
        ELSE
            SET member_role = 1;
        END IF;

        INSERT INTO guild_members(
            role_id,
            guild_id,
            character_id
        )
        VALUES(
            member_role,
            new_guild_id,
            cur_member
        );
        SELECT member_id INTO member_PK
        FROM guild_members
        WHERE (character_id = cur_member) AND
        (guild_id = new_guild_id);
        CALL random_member_activity(
            15,
            member_PK,
            cur_member
        );

        INSERT INTO chat_members(
            chat_id,
            character_id
        )
        VALUES(
            (
                SELECT chat_id
                FROM guilds
                WHERE guild_id = new_guild_id
            ),
            cur_member
        );

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_zones (
    IN region INT,
    IN num_of_zones INT
)
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= num_of_zones DO
        INSERT INTO zones(
            region_id,
            name    
        )
        VALUES (
            region,
            CONCAT('Zone', i)
        );
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_npcs (
    IN num_of_npcs INT,
    IN dialog_per_npc INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE npc_zone INT;
    DECLARE npc_role INT;
    DEClARE npc_race INT;
    DECLARE npc_killable BIT;

    WHILE i <= num_of_npcs DO

        SELECT zone_id INTO npc_zone
        FROM zones
        ORDER BY RAND()
        LIMIT 1;

        SELECT role_id INTO npc_role
        FROM npc_roles
        ORDER BY RAND()
        LIMIT 1;

        SELECT race_id INTO npc_race
        FROM races
        ORDER BY RAND()
        LIMIT 1;

        SET npc_killable = IF(RAND() > 0.6,1,0);

        INSERT INTO npcs(
            zone_id,
            role_id,
            race_id,
            name,
            killable
        )
        VALUES(
            npc_zone,
            npc_role,
            npc_race,
            CONCAT('npc_',i),
            npc_killable
        );

        CALL gen_npc_dialog (
            dialog_per_npc,
            i
        );

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS gen_npc_dialog(
    IN dialog_per_npc INT,
    IN new_npc_id INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE npc_dialog INT;

    WHILE i <= dialog_per_npc DO
        SET npc_dialog = NULL;
        SELECT dialog_id INTO npc_dialog
        FROM dialogs
        WHERE dialog_id NOT IN(
            SELECT dialog_id
            FROM npc_dialog
            WHERE npc_id = new_npc_id
        )
        ORDER BY RAND()
        LIMIT 1;

        INSERT INTO npc_dialog(
            dialog_id,
            npc_id
        )
        VALUES(
            npc_dialog,
            new_npc_id
        );

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_message_history(
    IN min_history INT,
    IN max_history INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE z INT DEFAULT 1;
    DECLARE chat_member INT;
    DECLARE chat_count INT;
    DECLARE chat_message TINYTEXT;
    DECLARE num_of_history INT;
    SELECT COUNT(*) INTO chat_count
    FROM chats;

    CREATE TEMPORARY TABLE IF NOT EXISTS messages(
        message_id INT AUTO_INCREMENT PRIMARY KEY,
        message TINYTEXT
    );
    INSERT INTO messages(
        message
    )
    VALUES
        ('LFG for Sunken Temple, need healer and tank!'),
        ('Selling [Dragon-Slayer Greaves] - 500 gold OBO.'),
        ('Anyone know where the Blacksmith trainer is in this city?'),
        ('WTS Rare Herbs, whisper me for prices!'),
        ('Join the "Order of the Phoenix" guild! We do weekly raids.'),
        ('Is the server lagging for anyone else or just me?'),
        ('WTB [Void Crystals] x10, paying well!'),
        ('Helping new players with the starter quests, PST.'),
        ('Does anyone have a spare health potion?'),
        ('Watch out, there is a high-level rogue ganking in the forest!'),
        ('The world boss spawns in 5 minutes! Group up!'),
        ('Looking for a craftsperson to make some mithril plate.'),
        ('How do I reset my talent points?'),
        ('Trading [Phoenix Feather] for [Ice Essence].'),
        ('Can someone help me with the "Hidden Cave" quest?'),
        ('LF2M for Daily Dungeon run, link gear.'),
        ('Stop spamming the chat, please.'),
        ('Where is the best place to farm silk cloth?'),
        ('Selling mystery boxes! 50g each, guaranteed loot.'),
        ('Just hit level 60! Finally!'),
        ('GG on that last arena match, very close!'),
        ('Does anyone want to duel outside the main gates?'),
        ('LF Alchemist to brew some mana pots, I have mats.'),
        ('The auction house prices are insane today.'),
        ('Anyone want to trade a mount for a pet?'),
        ('I finally found the legendary sword!'),
        ('Looking for a steady raid group for Friday nights.'),
        ('What is the drop rate for the Skeleton King`s crown?'),
        ('Be careful, the guards here are aggressive.'),
        ('WTS [Heavy Leather] bulk stacks.'),
        ('Who is the best healer class right now?'),
        ('Can anyone port me to the capital city?'),
        ('LFM for the 10-man raid, need DPS.'),
        ('I love the music in this zone.'),
        ('How do you get the "Dragon Rider" title?'),
        ('Selling [Elixir of Fortitude] - 5g each.'),
        ('Does anyone need a tank for anything?'),
        ('Looking for friends to play with regularly!'),
        ('The hidden merchant is behind the waterfall.'),
        ('Anyone want to join my party for grinding mobs?'),
        ('Wait, how do I use the mail system?'),
        ('The server maintenance starts in 30 minutes.'),
        ('I am so lost in this dungeon, help!'),
        ('WTB [Ancient Map] for the treasure hunt.'),
        ('Is there a level cap for the trial version?'),
        ('The guild bank is finally full!'),
        ('WTS [Rare Mana Gem] - starting bid 200g.'),
        ('Looking for an Enchanter to glow my weapon.'),
        ('Does this quest chain ever end?'),
        ('I just got my first mount! It looks awesome.'),
        ('LF1M Healer for Heroic difficulty.'),
        ('Where do I turn in the "Lost Letter" quest?'),
        ('Selling [Golden Ore] - cheapest on the server!'),
        ('Anyone want to trade [Fire Resistance Potions]?'),
        ('The PvP ranking just reset.'),
        ('Who wants to go explore the Forbidden Island?'),
        ('I need a group for the escort quest.'),
        ('WTS [Silk Cloth] - 20 stacks available.'),
        ('How do I join a faction?'),
        ('The boss is at 10% health! Keep going!'),
        ('Looking for a mentor to teach me the game.'),
        ('Can anyone lend me 10 gold? I will pay you back.'),
        ('The graphics in this game are stunning.'),
        ('LF Mage for food and portals.'),
        ('What is the best way to get reputation with the Elves?'),
        ('WTS [Greater Healing Potion] - bulk discount.'),
        ('Anyone seen the rare spawn in this area?'),
        ('Looking for a guild that focuses on roleplay.'),
        ('How do I bind my hearthstone here?'),
        ('Selling [Tiger Claw] crafting materials.'),
        ('The arena queue is really long today.'),
        ('Who is the leader of the Horde?'),
        ('LF2M for a quick run of the Spider Queen.'),
        ('The community in this game is so helpful.'),
        ('Does anyone have the recipe for Savory Fish?'),
        ('WTS [Iron Bars] - 10g per stack.'),
        ('Looking for a group to take down the Elite Giant.'),
        ('How do I upgrade my bag space?'),
        ('The weather effect in this zone is cool.'),
        ('WTB [Wolf Pelts] x20.'),
        ('Anyone want to play some mini-games in the tavern?'),
        ('I found a secret room in the library!'),
        ('LFM for the world boss, invite for auto-accept.'),
        ('The new patch notes look promising.'),
        ('WTS [Enchanted Dust] - pst for price.'),
        ('How do I change my character`s appearance?'),
        ('Looking for a high-level player to carry me.'),
        ('The dungeon loot was terrible this time.'),
        ('Anyone want to join a casual guild?'),
        ('Where can I find the fishing trainer?'),
        ('WTS [Bear Meat] for cooking quests.'),
        ('The dragon mount is so hard to get.'),
        ('Looking for a partner for the 2v2 arena.'),
        ('How do I use the emote system?'),
        ('The sky looks amazing tonight.'),
        ('WTB [Moonstone] - urgent!'),
        ('Anyone want to help me clear my inventory?'),
        ('I just discovered a new flight point.'),
        ('LFM for the undead raid, need off-tank.'),
        ('The auction house is under maintenance.'),
        ('WTS [Rare Shield] - high armor rating.'),
        ('How do I get to the other continent?'),
        ('Looking for a group to farm experience.'),
        ('The monster spawn rate is too slow here.'),
        ('Anyone want to trade [Ruby] for [Emerald]?'),
        ('I just reached the level cap! What now?'),
        ('LFG for the weekly challenge.'),
        ('The guild leader is offline.'),
        ('WTS [Mana Oil] - great for casters.'),
        ('How do I link an item in chat?'),
        ('Looking for a group for the festival event.'),
        ('The sunset in this game is beautiful.'),
        ('WTB [Heavy Cloth] for tailoring.'),
        ('Anyone want to go on a world tour?'),
        ('I found a legendary chest!'),
        ('LFM for the final boss of the expansion.'),
        ('The game balance seems a bit off lately.'),
        ('WTS [Health Stones] - cheap!'),
        ('How do I start the "Hero`s Journey" quest?'),
        ('Looking for a friendly guild for beginners.'),
        ('The mountain peak view is incredible.'),
        ('Anyone want to trade [Pet Food]?'),
        ('I just won a duel against a higher level!'),
        ('LFG for the pirate cove dungeon.'),
        ('The server is going down for an update.'),
        ('WTS [Rare Ring] - +10 Intelligence.'),
        ('How do I increase my movement speed?'),
        ('Looking for a group to explore the ruins.'),
        ('The water physics are so realistic.'),
        ('WTB [Dragon Scales] x5.'),
        ('Anyone want to join my raiding team?'),
        ('I found a hidden quest NPC!'),
        ('LFM for the snowy mountain raid.'),
        ('The game lore is so deep.'),
        ('WTS [Enchanted Wood] - for crafting.'),
        ('How do I use the crafting table?'),
        ('Looking for a group for the PvP battleground.'),
        ('The forest is full of dangerous creatures.'),
        ('Anyone want to trade [Mystic Herbs]?'),
        ('I just got a new title: "The Brave"!'),
        ('LFG for the desert temple.'),
        ('The city guards are very strong.'),
        ('WTS [Rare Bow] - high damage.'),
        ('How do I get a pet?'),
        ('Looking for a group to farm gold.'),
        ('The music in the tavern is so catchy.'),
        ('WTB [Magic Ink] for scribing.'),
        ('Anyone want to go on a treasure hunt?'),
        ('I found a shortcut to the city!'),
        ('LFM for the volcanic dungeon.'),
        ('The game is so much fun with friends.'),
        ('WTS [Heavy Plate Armor] - full set.'),
        ('How do I join the arena queue?'),
        ('Looking for a group for the midnight raid.'),
        ('The stars in the night sky are moving.'),
        ('Anyone want to trade [Crafting Patterns]?'),
        ('I just completed a very difficult achievement!'),
        ('LFG for the jungle ruins.'),
        ('The npc dialogues are so funny.'),
        ('WTS [Rare Staff] - with fire damage.'),
        ('How do I use the auction house?'),
        ('Looking for a group for the weekend event.'),
        ('The clouds look so fluffy.'),
        ('WTB [Ancient Coins] - any amount.'),
        ('Anyone want to join my questing party?'),
        ('I found a secret passage in the castle!'),
        ('LFM for the underwater raid.'),
        ('The game community is really growing.'),
        ('WTS [Mana Potions] - bulk order.'),
        ('How do I get more bag slots?'),
        ('Looking for a group to take down the world boss.'),
        ('The lighting in this cave is spooky.'),
        ('Anyone want to trade [Rare Ores]?'),
        ('I just got a legendary drop!'),
        ('LFG for the crystal caves.'),
        ('The game world is so vast.'),
        ('WTS [Enchanted Cloak] - +5 Agility.'),
        ('How do I use the flight master?'),
        ('Looking for a group for the dungeon marathon.'),
        ('The trees are swaying in the wind.'),
        ('WTB [Exotic Spices] for cooking.'),
        ('Anyone want to join my guild`s discord?'),
        ('I found a rare mount in the wild!'),
        ('LFM for the sky castle raid.'),
        ('The game updates are always exciting.'),
        ('WTS [Rare Daggers] - fast attack speed.'),
        ('How do I reset my UI?'),
        ('Looking for a group for the nightmare dungeon.'),
        ('The flowers are blooming in the meadow.'),
        ('Selling [Phoenix Ash] for crafting.'),
        ('Anyone want to help me with the world quest?'),
        ('I just joined the highest-ranked guild!'),
        ('LFG for the haunted mansion.'),
        ('The game graphics are getting better.'),
        ('WTS [Rare Axe] - heavy hit chance.'),
        ('How do I earn more contribution points?'),
        ('Looking for a group for the sea monster hunt.'),
        ('The fire in the fireplace is cozy.'),
        ('WTB [Mystic Thread] x50.'),
        ('Anyone want to go on a dungeon crawl?'),
        ('I found a legendary recipe!'),
        ('LFM for the crystal fortress raid.'),
        ('The game music changes in battle.'),
        ('WTS [Mana Crystals] - high purity.'),
        ('How do I get the "Master Angler" title?'),
        ('Looking for a group for the boss rush.'),
        ('The wind is whistling through the canyon.'),
        ('Anyone want to trade [Epic Loot]?'),
        ('I just completed the main storyline!'),
        ('LFG for the frozen wastes.'),
        ('The game world feels so alive.'),
        ('WTS [Rare Shield] - indestructible.'),
        ('How do I use the talent tree?'),
        ('Looking for a group for the grand tournament.'),
        ('The shadows are lengthening as the sun sets.'),
        ('Hey, are you still selling that [Dragon-Slayer Greaves]?'),
        ('Yo, thanks for the carry earlier!'),
        ('Can you craft [Mithril Plate] if I bring the mats?'),
        ('You still looking for a guild? We have a raid spot open.'),
        ('I saw you in the arena, your rotation is insane.'),
        ('Invite me to the group when you have a slot.'),
        ('Do you mind if I tag along for this quest?'),
        ('Sorry, I didn`t mean to ninja that loot!'),
        ('Hey, can you port me to the capital? I will pay 1g.'),
        ('Are you guys still looking for a healer?'),
        ('Your transmog looks amazing, where did you get the helm?'),
        ('Stop following me, I am just trying to farm here.'),
        ('Do you have any spare [Silk Cloth] I could buy off you?'),
        ('Wanna duo some mobs for a bit? The XP is better.'),
        ('I think we met in a dungeon last week, right?'),
        ('Hey, I accidentally sent you a trade request, my bad.'),
        ('Can you help me with the elite mob at the cave entrance?'),
        ('Is your guild recruiting any more DPS?'),
        ('I will give you 200g for that pet you just posted.'),
        ('Are you going to be online for the raid tonight?'),
        ('GG! That was a really close duel.'),
        ('Hey, check your mail, I sent those potions over.'),
        ('Wanna join our Discord? We are more active there.'),
        ('How did you get that title under your name?'),
        ('Don`t go in there alone, the mobs are way too high level.'),
        ('I have a spare key for the dungeon if you want to run it.'),
        ('Can you lend me a few gold for my mount? I am so close.'),
        ('Hey, I think your gear needs repairing.'),
        ('Wait up! I need to drink for mana.'),
        ('Are you a professional crafter or just doing it for fun?'),
        ('I missed the invite, can you send it again?'),
        ('Do you know where the rare spawn is in this zone?'),
        ('I will trade you [Iron Ore] for [Copper Ore] 1:1.'),
        ('Hey, you left the party before I could say thanks!'),
        ('Are you the one who outbid me on the Auction House? lol'),
        ('Do you need a tank for the daily run?'),
        ('I found a secret spot, want to see it?'),
        ('I am logging off soon, but add me to your friends list.'),
        ('Can you tell me your build? You hit really hard.'),
        ('Is the world boss still up or did I miss it?'),
        ('Hey, I have those [Wolf Pelts] you were looking for.'),
        ('Are you interested in a trade for that [Rare Ring]?'),
        ('Can you help me find the quest giver for the legendaries?'),
        ('Sorry for the lag, my internet is acting up today.'),
        ('You want to run that dungeon again? I didn`t get my drop.'),
        ('Hey, do you know if the server reset happened yet?'),
        ('Wanna race to the next town on our mounts?'),
        ('I can make that armor for you for free if you have the mats.'),
        ('Are you guys doing the event later tonight?'),
        ('Hey, I saw you looking for a group in world chat.'),
        ('Do you have a spare [Hearthstone]? Just kidding.'),
        ('Can you pass lead to me so I can invite my friend?'),
        ('I will be back in 5 minutes, stay right here.'),
        ('Hey, did you ever finish that long quest chain?'),
        ('Can you show me where the hidden vendor is?'),
        ('Are you selling those herbs in bulk or just singles?'),
        ('I think I found a bug, want to come check it out?'),
        ('Hey, I have a quest to kill you in the arena, wanna help?'),
        ('Do you want to join our premade for the battlegrounds?'),
        ('Can you buff me before I head into the cave?'),
        ('Hey, you dropped this! Just kidding, it`s soulbound.'),
        ('Are you the guild leader or an officer?'),
        ('I finally got the mount! Look at this!'),
        ('Do you have any tips for a new player like me?'),
        ('Hey, I will pay you back as soon as I sell this loot.'),
        ('Are you farming that rare spawn? I can wait.'),
        ('Can you help me clear my inventory? I have too much stuff.'),
        ('Hey, I think we are on the same quest step.'),
        ('Wanna go explore the high-level zone for fun?'),
        ('Do you have an extra [Health Potion]? I am out.'),
        ('Hey, I saw your post on the forums earlier.'),
        ('Are you looking for a partner for the 2v2s?'),
        ('Can you tell me how to get to the other continent?'),
        ('Hey, I accidentally sold my quest item, what do I do?'),
        ('Do you want to trade some [Mana Gems] for [Health Stones]?'),
        ('I will be your personal healer if you help me level.'),
        ('Are you going to the festival in the city tonight?'),
        ('Hey, I love your guild tag, very clever.'),
        ('Can you invite me back? I got disconnected.'),
        ('Do you know the tactics for the final boss?'),
        ('Hey, I will trade you my mount for your rare pet.'),
        ('Are you still online or are you AFK?'),
        ('Can you help me get the achievement for this zone?'),
        ('Hey, I found a treasure map, want to help me find it?'),
        ('Do you have any spare [Heavy Leather]?'),
        ('Are you going to be in the same spot tomorrow?'),
        ('Hey, I think I just saw your twin in the tavern.'),
        ('Can you give me a ride on your multi-passenger mount?'),
        ('Do you want to join my group for the world event?'),
        ('Hey, I am trying to get my reputation up, any tips?'),
        ('Are you a fan of the lore in this game?'),
        ('Can you help me test out my new abilities?'),
        ('Hey, I saw you were looking for [Rare Ore].'),
        ('Do you have a recipe for [Savory Fish]?'),
        ('Are you going to the PvP tournament this weekend?'),
        ('Hey, I think your guild is really cool, can I join?'),
        ('Can you show me the way to the nearest flight point?'),
        ('Do you want to trade some [Mystic Herbs]?'),
        ('Hey, I just hit level 50! Only 10 more to go.'),
        ('Are you the one who helped me yesterday? Thanks again!'),
        ('Can you lend me a hand with this escort quest?'),
        ('Hey, I have some extra loot if you want it.'),
        ('Do you know if there is a level cap for this area?'),
        ('Are you still looking for a group for the raid?'),
        ('Hey, I will be in the city if you want to meet up.'),
        ('Can you help me get past these guards?'),
        ('Do you want to join our roleplay session?'),
        ('Hey, I think I found a shortcut to the mountain.'),
        ('Are you a high-level player or just well-geared?'),
        ('Can you tell me where to find the fishing trainer?'),
        ('Hey, I will trade you my [Rare Axe] for your [Rare Bow].'),
        ('Do you have any advice for the arena?'),
        ('Are you going to be at the auction house later?'),
        ('Hey, I saw you in the rankings, congrats!'),
        ('Can you help me find the entrance to the dungeon?'),
        ('Do you want to go on a world tour with me?'),
        ('Hey, I have a spare mount if you want it.'),
        ('Are you looking for a challenge? Duel me!'),
        ('Can you show me your talent tree?'),
        ('Hey, I think I just found a legendary item!'),
        ('Do you have any [Mana Potions] to spare?'),
        ('Are you going to the guild meeting tonight?'),
        ('Hey, I will be your tank for the next hour.'),
        ('Can you help me get the "Dragon Slayer" title?'),
        ('Do you want to trade some [Rare Gems]?'),
        ('Hey, I saw you in the cinematic! So cool.'),
        ('Are you a member of the opposing faction?'),
        ('Can you tell me how to use the auction house?'),
        ('Hey, I am looking for a mentor, are you interested?'),
        ('Do you have any spare [Silk Thread]?'),
        ('Are you going to the city for the holiday?'),
        ('Hey, I think I just saw a ghost in the graveyard.'),
        ('Can you help me find the rare mount spawn?'),
        ('Do you want to join my party for the daily quest?'),
        ('Hey, I saw your character in a YouTube video!'),
        ('Are you a fan of the game`s soundtrack?'),
        ('Can you tell me where to get the "Hero" title?'),
        ('Hey, I will trade you my [Iron Bars] for your [Gold Ore].'),
        ('Do you have any tips for the raiding scene?'),
        ('Are you going to the arena later tonight?'),
        ('Hey, I think your character looks really unique.'),
        ('Can you help me find the hidden quest NPC?'),
        ('Do you want to join our group for the dungeon marathon?'),
        ('Hey, I found a secret room in the library!'),
        ('Are you a master of the crafting arts?'),
        ('Can you show me the best place to farm gold?'),
        ('Hey, I will be your healer for the next raid.'),
        ('Do you have any [Health Stones] left?'),
        ('Are you going to the festival in the forest?'),
        ('Hey, I think I just found a new flight point!'),
        ('Can you help me get the achievement for the dungeon?'),
        ('Do you want to trade some [Rare Herbs]?'),
        ('Hey, I saw you in the world chat earlier.'),
        ('Are you a fan of the game`s graphics?'),
        ('Can you tell me where to find the mount trainer?'),
        ('Hey, I will trade you my [Rare Daggers] for your [Rare Staff].'),
        ('Do you have any advice for the PvP battlegrounds?'),
        ('Are you going to the auction house for the sale?'),
        ('Hey, I think your guild tag is really funny.'),
        ('Can you help me find the entrance to the cave?'),
        ('Do you want to go on a treasure hunt with me?'),
        ('Hey, I have an extra pet if you want it.'),
        ('Are you looking for a duel? I`m ready!'),
        ('Can you show me your gear? It looks awesome.'),
        ('Hey, I think I just found a rare mount!'),
        ('Do you have any [Mana Oil] to spare?'),
        ('Are you going to the guild event this weekend?'),
        ('Hey, I will be your DPS for the next dungeon.'),
        ('Can you help me get the "Master of the Arena" title?'),
        ('Do you want to trade some [Rare Ores]?'),
        ('Hey, I saw you in the city earlier today.'),
        ('Are you a member of the royal guard?'),
        ('Can you tell me how to get the "Legendary" title?'),
        ('Hey, I am looking for a group for the world boss.'),
        ('Do you have any spare [Heavy Cloth]?'),
        ('Are you going to the city for the parade?'),
        ('Hey, I think I just saw a dragon in the sky!'),
        ('Can you help me find the rare spawn in the forest?'),
        ('Do you want to join my party for the weekend quest?'),
        ('Hey, I saw your character in a fan art piece!'),
        ('Are you a fan of the game`s story?'),
        ('Can you tell me where to get the "Brave" title?'),
        ('Hey, I will trade you my [Silk Cloth] for your [Wool Cloth].'),
        ('Do you have any tips for the endgame content?'),
        ('Are you going to the arena for the finals?'),
        ('Hey, I think your transmog is the best I`ve seen.'),
        ('Can you help me find the hidden merchant?'),
        ('Do you want to join our group for the raid marathon?'),
        ('Hey, I found a secret passage in the castle!'),
        ('Are you a master of the combat arts?'),
        ('Can you show me the best place to farm XP?'),
        ('Hey, I will be your tank for the next world boss.'),
        ('Do you have any [Mana Gems] left?'),
        ('Are you going to the festival in the mountains?'),
        ('Hey, I think I just discovered a new zone!'),
        ('Can you help me get the achievement for the world event?'),
        ('Do you want to trade some [Rare Potions]?'),
        ('Hey, I saw you in the rankings for the arena!'),
        ('Are you a fan of the game`s community?'),
        ('Can you tell me where to find the skill trainer?'),
        ('Hey, I will trade you my [Rare Shield] for your [Rare Sword].'),
        ('Do you have any advice for the raid mechanics?'),
        ('Are you going to the auction house for the rare drop?'),
        ('Hey, I think your guild is one of the best.'),
        ('Can you help me find the exit to this dungeon?'),
        ('Do you want to go on a fishing trip with me?'),
        ('Are you fucking kidding me with that lag?'),
        ('Get good, you absolute trash loser.'),
        ('Imagine being level 60 and still being this pathetic at the game.'),
        ('Nice ganking, you coward asswipe.'),
        ('Stop running away like a little bitch and fight me!'),
        ('You only won because of that bullshit RNG.'),
        ('Your build is total garbage, go back to the starter zone.'),
        ('What a clusterfuck of a raid, you guys are idiots.'),
        ('I’m not healing you anymore, you’re a total moron.'),
        ('Get out of my farming spot, you dumbass.'),
        ('Go play something else, you’re dragging the whole team down.'),
        ('Wow, another death? You’re such a fuckup.'),
        ('Stop being an annoying smartass in global chat.'),
        ('That was a shitty play and you know it.'),
        ('You’re literally the worst tank I’ve ever seen, what a joke.'),
        ('Hell, even a bot plays better than you do.'),
        ('I’ve seen better gear on a level 10, you pathetic loser.'),
        ('Don’t tell me how to play, you arrogant dickhead.'),
        ('You’re just a lucky bastard, no skill involved.'),
        ('This whole match was a complete shitshow from the start.'),
        ('Why are you even in this guild? You’re a total liability.'),
        ('Your DPS is lower than the healer’s, you useless prick.'),
        ('Shut the hell up and just do your job.'),
        ('I’m tired of carrying this team of deadweight numpties.'),
        ('Keep talking and I’ll put you on ignore, you obnoxious twit.'),
        ('You’re acting like a real douchebag today.'),
        ('Is your brain made of mush? Move out of the fire, dipshit!'),
        ('That’s the most ridiculous excuse for a wipe I’ve ever heard.'),
        ('I can’t believe we lost to those wankers.'),
        ('You’re just a salty bitch because you got outplayed.'),
        ('Go cry to the devs, your class is still overpowered as hell.'),
        ('I’ve had enough of your horseshit for one night.'),
        ('Seriously, who invited this jackass to the party?'),
        ('You’re a waste of a raid slot, honestly.'),
        ('Stop spamming the chat with your crappy guild recruitment.'),
        ('What a dick move, ninjaing that loot.'),
        ('You’re a total arsehole for pulling the boss early.'),
        ('Get rekt, you absolute bottom-tier trash.'),
        ('I’m not helping you with that quest after what you said, sod off.'),
        ('Your rotation is a mess, you fucking amateur.'),
        ('Stop blaming the healer for your own stupid mistakes.'),
        ('This server is full of morons and losers.'),
        ('I’m done with this shitty dungeon group.'),
        ('You’re a bold-faced liar and a prick.'),
        ('Go back to the tutorial, you clueless git.'),
        ('I’ve seen better coordination in a kindergarten class.'),
        ('You’re just a spoiled little brat, aren’t you?'),
        ('Don’t give me that nonsense, you just messed up.'),
        ('You’re a disgrace to your faction, you weakling.'),
        ('I’m sick of your constant whining, it’s pathetic.'),
        ('You’re a real piece of work, you know that?'),
        ('I wouldn’t group with you again if you were the last player on earth.'),
        ('You’re just a try-hard loser with no life.'),
        ('That was the most lame attempt at a duel I’ve ever seen.'),
        ('You’re a total knobhead for thinking that would work.'),
        ('I’ve got no patience for your bullshit today.'),
        ('You’re just a bottom-feeder looking for easy kills.'),
        ('Stop acting like you’re some kind of badass, you’re not.'),
        ('You’re a total pillock if you think that’s a good build.'),
        ('I’m tired of your obnoxious attitude in Discord.'),
        ('You’re just a noob with a high level, nothing more.'),
        ('Go play a single-player game if you’re going to be this selfish.'),
        ('You’re a real jerk for making us wait this long.'),
        ('I’ve seen more skill from a disconnect than from you.'),
        ('You’re just a salty loser who can’t handle a loss.'),
        ('Stop being such a pussy and engage in the fight.'),
        ('You’re a total waste of space in this raid.'),
        ('I’m done with your crappy advice, it’s useless.'),
        ('You’re just a glory-hound with no respect for the team.'),
        ('Go back to the forums and complain some more, you bitch.'),
        ('I’ve had it with your shitty luck, it’s ruining the run.'),
        ('You’re a real dick for stealing that kill.'),
        ('I’m not listening to another word of your rubbish.'),
        ('You’re just a loudmouth with nothing to back it up.'),
        ('Stop being a dumbfuck and follow the plan.'),
        ('You’re a total loser for using that exploit.'),
        ('I’ve seen better gameplay from a toddler.'),
        ('You’re just a pathetic ganker with no real skill.'),
        ('Go find another group, you’re not welcome here.'),
        ('I’m sick of your elitist bullshit, it’s gross.'),
        ('You’re a real arse for making that comment.'),
        ('I’ve got better things to do than carry your lazy ass.'),
        ('You’re just a toxic prick who ruins the fun for everyone.'),
        ('Stop acting like a child and play the game.'),
        ('You’re a total fuckboy for trying to flex your gear.'),
        ('I’m done with this crappy server and its moronic players.'),
        ('You’re a real douche for ditching the party midway.'),
        ('I’ve seen more life in a cemetery than in your playstyle.'),
        ('You’re just a salty wanker who can’t take a joke.'),
        ('Go back to your cave, you antisocial weirdo.'),
        ('I’m sick of your constant begging for gold, it’s pathetic.'),
        ('You’re a real bastard for undercutting my prices.'),
        ('I’ve had enough of your arrogant nonsense.'),
        ('You’re just a little twit with a big ego.'),
        ('Stop being a shithead and help the group.'),
        ('You’re a total moron for falling for that trap.'),
        ('I’m done with your lame excuses for being bad.'),
        ('You’re a real prick for spoiling the quest for us.'),
        ('I’ve seen better mechanics from a rusty gear.'),
        ('You’re just a salty git who’s mad because he lost.'),
        ('Go cry to your mother, you big baby.'),
        ('I’m sick of your obnoxious bragging, nobody cares.'),
        ('You’re a real jerk for ignoring the raid mechanics.'),
        ('I’ve got no time for your shitty attitude.'),
        ('You’re just a pathetic loser who needs to touch grass.'),
        ('Stop acting like you’re better than us, you’re garbage.'),
        ('You’re a total knob for pulling those extra mobs.'),
        ('I’m done with this rubbish guild and its toxic leadership.'),
        ('You’re a real arsehole for spamming the trade chat.'),
        ('I’ve seen more intelligence in a rock than in you.'),
        ('You’re just a salty tosser who’s bad at PvP.'),
        ('Go play in traffic, you useless idiot.'),
        ('I’m sick of your constant drama, it’s exhausting.'),
        ('You’re a real bastard for tricking new players.'),
        ('I’ve had enough of your elitist crap.'),
        ('You’re just a little numpty who doesn’t know any better.'),
        ('Stop being a douchebag and share the loot.'),
        ('You’re a total fuckup for missing that save.'),
        ('I’m done with your pathetic attempts at being funny.'),
        ('You’re a real dickhead for body-blocking the NPC.'),
        ('I’ve seen more skill from a bot than from you.'),
        ('You’re just a salty loser who’s mad at the world.'),
        ('Go back to the starter zone where you belong.'),
        ('I’m sick of your shitty build and your shitty attitude.'),
        ('You’re a real jerk for pulling the boss while we were away.'),
        ('I’ve got better things to do than listen to your whining.'),
        ('You’re just a pathetic prick who wants attention.'),
        ('Stop acting like a smartass and just play.'),
        ('You’re a total loser for buying your account.'),
        ('I’m done with this crappy group of idiots.'),
        ('You’re a real arse for being so rude to the newcomers.'),
        ('I’ve seen more personality in a wall than in you.'),
        ('You’re just a salty wanker who’s upset about the nerf.'),
        ('Go away and stay away, you annoying git.'),
        ('I’m sick of your constant complaints about the game.'),
        ('You’re a real bastard for griefing our raid.'),
        ('I’ve had enough of your arrogant bullshit.'),
        ('You’re just a little twit who thinks he’s special.'),
        ('Stop being a shitlord and help out for once.'),
        ('You’re a total moron for getting scammed.'),
        ('I’m done with your lame defense for being trash.'),
        ('You’re a real prick for mocking the devs.'),
        ('I’ve seen better teamwork in a pile of ants.'),
        ('You’re just a salty git who’s jealous of my gear.'),
        ('Go cry in a corner, you pathetic loser.'),
        ('I’m sick of your obnoxious behavior in town.'),
        ('You’re a real jerk for baiting the guards.'),
        ('I’ve got no respect for your shitty playstyle.'),
        ('You’re just a pathetic douche who needs a life.'),
        ('Stop acting like a badass when you’re just trash.'),
        ('You’re a total pillock for deleting that item.'),
        ('I’m done with this rubbish game and its shitty community.'),
        ('You’re a real arsehole for being so toxic.'),
        ('I’ve seen more potential in a broken item than in you.'),
        ('You’re just a salty tosser who can’t handle the truth.'),
        ('Go take a hike, you useless moron.'),
        ('I’m sick of your constant ego-tripping.'),
        ('You’re a real bastard for camping the graveyard.'),
        ('I’ve had enough of your elitist nonsense.'),
        ('You’re just a little numpty who’s out of his league.'),
        ('Stop being a dickhead and follow the orders.'),
        ('You’re a total fuckup for failing the simplest quest.'),
        ('I’m done with your pathetic whining about the meta.'),
        ('You’re a real douche for being so unhelpful.'),
        ('I’ve seen more competence in a level 1 than in you.'),
        ('You’re just a salty loser who’s projecting his failure.'),
        ('Go back to your little hole, you antisocial prick.'),
        ('I’m sick of your shitty jokes and your shitty attitude.'),
        ('You’re a real jerk for making fun of my build.'),
        ('I’ve got no patience for your arrogant crap.'),
        ('You’re just a pathetic wanker who’s trying too hard.'),
        ('Stop acting like a diva and get in the group.'),
        ('You’re a total knobhead for wasting our time.'),
        ('I’m done with this crappy raid and its terrible lead.'),
        ('You’re a real arse for being so selfish.'),
        ('I’ve seen more talent in a disconnect screen.'),
        ('You’re just a salty git who’s mad because he’s bad.'),
        ('Go find someone who cares, you annoying loser.'),
        ('I’m sick of your constant bragging about your rank.'),
        ('You’re a real bastard for selling fake items.'),
        ('I’ve had enough of your elitist bullshit for one day.'),
        ('You’re just a little twit who’s trying to be edgy.'),
        ('Stop being a shitbag and contribute to the team.'),
        ('You’re a total moron for ignoring the warnings.'),
        ('I’m done with your lame excuses for your failure.'),
        ('You’re a real prick for being so condescending.'),
        ('I’ve seen better coordination in a pile of junk.'),
        ('You’re just a salty douche who’s upset about the drop.'),
        ('Go rot in the underworld, you pathetic idiot.'),
        ('I’m sick of your obnoxious presence in the guild.'),
        ('You’re a real jerk for taking advantage of the glitch.'),
        ('I’ve got better things to do than deal with your drama.'),
        ('You’re just a pathetic wanker who’s full of himself.'),
        ('Stop acting like a smartass when you’re actually dumb.'),
        ('You’re a total loser for trying to sabotage the raid.'),
        ('I’m done with this shitty game and its toxic players.'),
        ('You’re a real arsehole for being so mean to everyone.'),
        ('I’ve seen more skill in a lag spike than in you.'),
        ('You’re just a salty tosser who’s having a bad day.'),
        ('Go away and don’t come back, you useless prick.'),
        ('I’m sick of your constant negativity, it’s gross.'),
        ('You’re a real bastard for trying to manipulate the market.'),
        ('I’ve had enough of your elitist crap, honestly.'),
        ('You’re just a little numpty who doesn’t belong here.');

    WHILE i <= chat_count DO
        SET z = 1;
        SET num_of_history =
        FLOOR(min_history + RAND() * max_history);

        WHILE z <= num_of_history DO
            SELECT character_id INTO chat_member
            FROM chat_members
            WHERE chat_id = i
            ORDER BY RAND()
            LIMIT 1;

            SELECT message INTO chat_message
            FROM messages
            ORDER BY RAND()
            LIMIT 1;

            CALL random_datetime(
                (
                    SELECT creation_date 
                    FROM character_info
                    WHERE character_id = chat_member
                ),
                NOW(),
                @message_date
            );

            INSERT INTO message_history(
                chat_id,
                sender_id,
                message,
                time
            )
            VALUES(
                i,
                chat_member,
                chat_message,
                @message_date
            );

            SET z = z + 1;
        END WHILE;

        SET i = i + 1;
    END WHILE;
    
    DROP TEMPORARY TABLE IF EXISTS messages;
END $$

CREATE PROCEDURE IF NOT EXISTS random_loot_tables(
    IN num_of_tables INT
)
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE num_of_tables <= i DO

        INSERT INTO loot_tables(
            min_gold,
            max_gold,
            min_exp,
            max_exp
        )
        VALUES(
            FLOOR(1 + RAND() * 15),
            FLOOR(15 + RAND() * 100),
            FLOOR(25 + RAND() * 1000),
            FLOOR(1000 + RAND() * 10000)
        );
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_loot_table_items(
    IN min_items INT,
    IN max_items INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE z INT DEFAULT 1;
    DECLARE item_count INT;
    DECLARE loot_table_count INT;
    SELECT COUNT(*) INTO loot_table_count
    FROM loot_tables;

    WHILE i <= loot_table_count DO
        SET z = 1;
        SET item_count = 
        FLOOR(min_items + RAND() * max_items);

        WHILE z <= item_count DO

            INSERT INTO loot_table_items(
                item_id,
                loot_table_id,
                drop_rate
            )
            VALUES(
                (
                    SELECT info_id FROM item_info
                    WHERE info_id NOT IN(
                        SELECT item_id 
                        FROM loot_table_items
                        WHERE loot_table_id = i
                    )
                    ORDER BY RAND()
                    LIMIT 1
                ),
                i,
                (
                    SELECT ROUND(RAND(), 10)
                )
            );
            SET z = z + 1;
        END WHILE;
        
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_quest_rewards(

)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE quest_count INT;
    SELECT COUNT(*) INTO quest_count
    FROM quests;

    WHILE i < quest_count DO

        INSERT INTO quest_rewards(
            item_id,
            quest_id,
            gold,
            experience
        )
        VALUES(
            (
                SELECT item_id
                FROM items
                ORDER BY RAND()
                LIMIT 1
            ),
            i,
            FLOOR(1 + RAND() * 450),
            FLOOR(25 + RAND() * 50000)
        );
        
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_quest_history(
    IN min_history INT,
    IN max_history INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE z INT DEFAULT 1;
    DECLARE character_count INT;
    DECLARE history_count INT;
    DECLARE quest_state VARCHAR(9);
    DECLARE quest INT;
    SELECT COUNT(*) INTO character_count
    FROM characters;

    WHILE i <= character_count DO
        SET z = 1;

        SET history_count =
        FLOOR(min_history + RAND() * max_history);

        WHILE z <= history_count DO

            CALL random_datetime(
                (
                    SELECT creation_date
                    FROM character_info
                    WHERE character_id = i
                ),
                NOW(),
                @quest_time
            );

            IF RAND() > 0.89 THEN
                SET quest_state = 'failed';
            ELSEIF RAND() > 0.49 THEN
                SET quest_state = 'accepted';
            ELSE
                SET quest_state = 'completed';
            END IF;
            SELECT q.quest_id INTO quest
            FROM quests q
            WHERE q.quest_id NOT IN(
                SELECT qh.quest_id
                FROM quest_history qh
                JOIN quests q2 ON qh.quest_id = q2.quest_id
                WHERE qh.character_id = i
                    AND qh.state = 'completed'
                    AND q2.repeatable = 0
            )
            ORDER BY RAND()
            LIMIT 1;

            INSERT INTO quest_history(
                character_id,
                quest_id,
                reward_id,
                state,
                time
            )
            VALUES(
                i,
                quest,
                (
                    SELECT reward_id
                    FROM quest_rewards
                    WHERE quest_id = quest
                ),
                quest_state,
                @quest_time
            );

            SET z = z + 1;
        END WHILE;

        SET i = i + 1;
    END WHILE;

END $$

CREATE PROCEDURE IF NOT EXISTS random_mobs(
    IN mob_count INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE boss BIT;
    WHILE i <= mob_count DO

        SET boss = IF(RAND() > 0.94, 1, 0);

        INSERT INTO mobs(
            loot_table_id,
            name,
            is_boss
        )
        VALUES(
            (
                SELECT loot_table_id
                FROM loot_tables
                ORDER BY RAND()
                LIMIT 1
            ),
            CONCAT('mob_', i),
            boss
        );

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_zone_mobs(
    IN min_mobs INT,
    IN max_mobs INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE z INT DEFAULT 1;
    DECLARE mob_count INT;
    DECLARE zone_count INT;
    SELECT COUNT(*) INTO zone_count
    FROM zones;

    WHILE i <= zone_count DO
        SET z = 1;
        SET mob_count =
        FLOOR(min_mobs + RAND() * max_mobs);

        WHILE z <= mob_count DO

            INSERT INTO zone_mobs(
                zone_id,
                mob_id,
                amount
            )
            VALUES(
                i,
                (
                    SELECT mob_id
                    FROM mobs
                    WHERE mob_id NOT IN (
                        SELECT mob_id
                        FROM zone_mobs
                        WHERE zone_id = i
                    )
                    ORDER BY RAND()
                    LIMIT 1
                ),
                FLOOR(1 + RAND() * 25)
            );

            SET z = z + 1;
        END WHILE;

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_player_trades(
    IN number_of_trades INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE sender INT;
    DECLARE reciever INT;

    WHILE i < number_of_trades DO
        SELECT character_id INTO sender
        FROM characters
        ORDER BY RAND()
        LIMIT 1;

        SELECT character_id INTO reciever
        FROM characters
        WHERE character_id != sender
        ORDER BY RAND()
        LIMIT  1;

        INSERT INTO player_trades(
            sender_id,
            reciever_id
        )
        VALUES(
            sender,
            reciever
        );

        CALL gen_trade_info(
            i,
            NULL
        );

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_npc_trades(
    IN trade_count INT
)
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i < trade_count DO

        INSERT INTO npc_trades(
            character_id,
            npc_id
        )
        VALUES(
            (
                SELECT character_id
                FROM characters
                ORDER BY RAND()
                LIMIT 1
            ),
            (
                SELECT npc_id
                FROM npcs
                ORDER BY RAND()
                LIMIT 1
            )
        );
        
        CALL gen_trade_info(
            NULL,
            i
        );

        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS gen_trade_info(
    IN player_trade_id INT,
    IN npc_trade_id INT
)
BEGIN
    DECLARE trade_item INT;

    IF player_trade_id IS NULL THEN
        CALL random_datetime(
            (
                SELECT creation_date
                FROM character_info
                WHERE character_id IN (
                    SELECT character_id 
                    FROM npc_trade
                    WHERE trade_id = npc_trade_id
                )
            ),
            NOW(),
            @trade_time
        );

        SELECT item_id INTO trade_item
        FROM items
        WHERE inventory_id IN (
            SELECT inventory_id
            FROM characters
            WHERE character_id IN (
                SELECT character_id
                FROM npc_trade
                WHERE trade_id = npc_trade_id
            )
        )
        ORDER BY RAND()
        LIMIT 1;

        DELETE FROM items
        WHERE item_id = trade_item;

    ELSE
        CALL random_datetime(
            (
                SELECT creation_date
                FROM character_info
                WHERE character_id IN (
                    SELECT sender_id
                    FROM player_trade
                    WHERE trade_id = player_trade_id
                )
            ),
            NOW(),
            @trade_time
        );

        SELECT item_id INTO trade_item
        FROM items
        WHERE inventory_id IN (
            SELECT inventory_id
            FROM characters
            WHERE character_id IN (
                SELECT reciever_id
                FROM player_trade
                WHERE trade_id = player_trade_id
            )
        )
        ORDER BY RAND()
        LIMIT 1;

    END IF;

    INSERT INTO trade_info(
        player_trade_id,
        npc_trade_id,
        item_id,
        gold,
        time
    )
    VALUES(
        player_trade_id,
        npc_trade_id,
        trade_item,
        FLOOR(0 + RAND() * 150),
        @trade_time
    );
END $$

CREATE PROCEDURE IF NOT EXISTS random_combats(
    IN combat_count INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE z INT DEFAULT 1;
    DECLARE new_combat_id INT DEFAULT 0;
    DECLARE character_count INT;
    SELECT COUNT(*) INTO character_count
    FROM characters;

    WHILE i < character_count DO
        SET z = 1;
        WHILE z < combat_count DO

            SET new_combat_id = new_combat_id + 1;

            INSERT INTO combats(
                combat_id,
                character_id,
                mob_id
            )
            VALUES(
                new_combat_id,
                i,
                (
                    SELECT mob_id
                    FROM mobs
                    ORDER BY RAND()
                    LIMIT 1
                )
            );

            CALL random_combat_info(
                i
            );

            SET z = z + 1;
        END WHILE;
        SET i = i + 1;
    END WHILE;
END $$

CREATE PROCEDURE IF NOT EXISTS random_combat_info(
    IN new_combat_id INT
)
BEGIN
    DECLARE combat_result VARCHAR(4);
    IF RAND() > 0.09 THEN
        SET combat_result = 'win';
    ELSE
        SET combat_result = 'loss';
    END IF;

    CALL random_datetime(
        (
            SELECT creation_date
            FROM character_info
            WHERE character_id IN (
                SELECT character_id
                FROM combats
                WHERE combat_id = new_combat_id
            )
        ),
        NOW(),
        @combat_time
    );

    INSERT INTO combat_info(
        combat_id,
        time,
        result
    )
    VALUES(
        new_combat_id,
        @combat_time
    );
END $$







































DELIMITER ;

INSERT INTO races (name, description)
VALUES
        ('Human', 'Youngest and most common race. basic.'),
        ('Elf', 'Coolest race, good with magic and stuff, pick this if your cool.'),
        ('Orc', 'ugly and dumb.'),
        ('Dwarf', 'Short, Ugly, and Smart.'),
        ('Goblin', 'Short, Ugly, and Dumb'),
        ('Dragonborn', 'Human with dragon blood, very wise'),
        ('Halfling', 'Short, but not too short.'),
        ('Tortle', 'TMNT'),
        ('Githyanki', 'Ugly... But cool');

INSERT INTO classes (name, description)
VALUES
        ('Warrior', 'Swing sword'),
        ('Mage', 'Magic, but in a basic way'),
        ('Hunter', 'Uses bows and traps'),
        ('Rogue', 'Sneaky, likes to backstab'),
        ('Priest', 'heal people :D'),
        ('Paladin', 'heal people... but in a cool way'),
        ('Druid', 'best class, can be cat, or bear!');

INSERT INTO specializations (name)
VALUES
        ('Ranger'),
        ('Berserker'),
        ('Arcanist'),
        ('Thaumaturge'),
        ('Oracle'),
        ('Spelltheif'),
        ('Brawler'),
        ('Noble'),
        ('Monk'),
        ('Assassin'),
        ('Tamer'),
        ('Collector'),
        ('Exorcist'),
        ('Feral'),
        ('Holy');

INSERT INTO levels (xp_requirement)
VALUES
        (0),
        (1000),
        (2500),
        (4500),
        (7000),
        (10000),
        (15000),
        (25000),
        (50000),
        (100000),
        (125000),
        (150000),
        (175000),
        (225000),
        (270000);
    
INSERT INTO stats (name)
VALUES
        ('Strength'),
        ('Dexterity'),
        ('Constitutoin'),
        ('Intelligence'),
        ('Wisdom'),
        ('Charisma');

INSERT INTO slots(name)
VALUES
        ('Head'),
        ('Chest'),
        ('Legs'),
        ('Feet'),
        ('Gloves'),
        ('Main_Hand'),
        ('Off_Hand'),
        ('Trinket');

CALL random_account(
    1000,
    NOW(),
    '2005-06-07 15:54:02',
    5,
    100
);

CALL random_character(
    3000
);

INSERT INTO item_rarities(name, color)
VALUES
    ('common', '8f8f8f'),
    ('uncommon', '91d190'),
    ('rare', '214475'),
    ('epic', '6a31de'),
    ('legendary', 'e8e23c');

CALL random_item_info(
    500
);

CALL random_items (
    2500
);

CALL random_equiped(

);

INSERT INTO filters(
    word,
    filtered_word
)
VALUES
    ('damn','d***'),
    ('hell','h***'),
    ('shit','s***'),
    ('crap','c***'),
    ('ass','a**'),
    ('asshole','a******'),
    ('bitch','b****'),
    ('bastard','b******'),
    ('dick','d***'),
    ('piss','p***'),
    ('fuck','f***'),
    ('fucking','f******'),
    ('fucked','f*****'),
    ('motherfucker','m***********'),
    ('bullshit','b*******'),
    ('jackass','j******'),
    ('dumbass','d******'),
    ('shithead','s*******'),
    ('dipshit','d******'),
    ('horseshit','h********'),
    ('smartass','s*******'),
    ('badass','b******'),
    ('shitface','s*******'),
    ('asswipe','a*******'),
    ('asshat','a******'),
    ('shitstorm','s********'),
    ('fuckface','f*******'),
    ('fuckhead','f*******'),
    ('clusterfuck','c**********'),
    ('shitshow','s*******'),
    ('assclown','a********'),
    ('shitbag','s******'),
    ('fuckboy','f******'),
    ('shitfaced','s********'),
    ('assface','a******'),
    ('fuckup','f*****'),
    ('shitload','s*******'),
    ('assholeish','a*********'),
    ('dickhead','d*******'),
    ('fuckwad','f******'),
    ('shitbrain','s********'),
    ('assmonkey','a*********'),
    ('shitlord','s*******'),
    ('fuckstick','f********'),
    ('asslicker','a*********'),
    ('shitlicker','s*********'),
    ('douche','d*****'),
    ('douchebag','d********'),
    ('dumbfuck','d*******'),
    ('shitkicker','s*********'),
    ('asskicker','a*********'),
    ('fucknut','f******'),
    ('shitheel','s*******'),
    ('asshatery','a********'),
    ('fuckery','f******'),
    ('shitiness','s********'),
    ('crappy','c*****'),
    ('shitty','s*****'),
    ('freaking','f*******'),
    ('friggin','f******'),
    ('dang','d***'),
    ('bloodyhell','b*********'),
    ('arse','a***'),
    ('arsehole','a*******'),
    ('bugger','b*****'),
    ('bollocks','b*******'),
    ('tosser','t*****'),
    ('wanker','w*****'),
    ('git','g**'),
    ('numpty','n*****'),
    ('twit','t***'),
    ('prat','p***'),
    ('knobhead','k*******'),
    ('pillock','p******'),
    ('sodoff','s*****'),
    ('crud','c***'),
    ('jerk','j***'),
    ('moron','m****'),
    ('idiot','i****'),
    ('loser','l****'),
    ('screwup','s******'),
    ('dumb','d***'),
    ('stupid','s*****'),
    ('trash','t****'),
    ('garbage','g******'),
    ('nonsense','n*******'),
    ('rubbish','r******'),
    ('lame','l***'),
    ('pathetic','p********'),
    ('ridiculous','r*********'),
    ('annoying','a*******'),
    ('obnoxious','o********'),
    ('gross','g****'),
    ('yuck','y***'),
    ('ugh','u**'),
    ('bleh','b***'),
    ('meh','m**');

CALL new_chat(
    'feywild_chat',
    0,
    @feywild_chat
);
CALL new_chat(
    'gondor_chat',
    0,
    @gondor_chat
);
CALL new_chat(
    'rift_chat',
    0,
    @rift_chat
);
CALL new_chat(
    'garden_city_chat',
    0,
    @garden_city_chat
);
CALL new_chat(
    'end_chat',
    0,
    @end_chat
);

CALL random_message_history(
    5,
    13
);

INSERT INTO regions(
    chat_id,
    name
)
VALUES
    (@feywild_chat, 'Feywild'),
    (@gondor_chat, 'Gondor'),
    (@rift_chat, 'The Rift'),
    (@garden_city_chat, 'Garden City'),
    (@end_chat, 'The End');

INSERT INTO factions(
    region_id,
    name
)
VALUES
    (1, 'Night Fae Covenant'),
    (2, 'Gondor Knights'),
    (3, 'Voidlings'),
    (4, 'Shoppers'),
    (5, 'the Order of the Stone');

CALL random_zones(1, 21);
CALL random_zones(2, 18);
CALL random_zones(3, 28);
CALL random_zones(4, 15);
CALL random_zones(5, 32);

INSERT INTO roles(
    name, 
    can_invite, 
    can_kick, 
    can_edit_roles, 
    can_edit_motd
    )
VALUES
    ('rookie', 0, 0, 0, 0),
    ('member', 1, 0, 0, 0),
    ('officer', 1, 1, 0, 1),
    ('leader', 1, 1, 1, 1);

CALL random_guilds(
    100,
    '2005-05-03 05:03:35',
    NOW()
);

INSERT INTO dialogs(
    dialog_id,
    dialog
)
VALUES
    (1,'Hello there!'),
    (2,'How are you doing today?'),
    (3,'Nice to meet you.'),
    (4,'What can I help you with?'),
    (5,'That sounds interesting.'),
    (6,'Can you explain that again?'),
    (7,'I am not sure I understand.'),
    (8,'Could you give me more details?'),
    (9,'Thanks for sharing that.'),
    (10,'I appreciate your help.'),
    (11,'Let me think about that.'),
    (12,'That is a good question.'),
    (13,'I will look into it.'),
    (14,'Give me a moment please.'),
    (15,'I agree with you.'),
    (16,'I disagree with that.'),
    (17,'That makes sense.'),
    (18,'I am confused.'),
    (19,'Can you clarify?'),
    (20,'What do you mean by that?'),
    (21,'That sounds great!'),
    (22,'I am excited about this.'),
    (23,'This is frustrating.'),
    (24,'I understand now.'),
    (25,'Thanks for explaining.'),
    (26,'No problem at all.'),
    (27,'You are welcome.'),
    (28,'Anytime!'),
    (29,'Let us continue.'),
    (30,'What is next?'),
    (31,'Tell me more.'),
    (32,'I would like to know more.'),
    (33,'That is enough for now.'),
    (34,'Let us stop here.'),
    (35,'See you later.'),
    (36,'Goodbye!'),
    (37,'Have a nice day.'),
    (38,'Take care.'),
    (39,'Talk to you soon.'),
    (40,'I will get back to you.'),
    (41,'Can we revisit this later?'),
    (42,'This is important.'),
    (43,'Please pay attention.'),
    (44,'That is not correct.'),
    (45,'Try again.'),
    (46,'Good job!'),
    (47,'Well done.'),
    (48,'Keep going.'),
    (49,'Do not give up.'),
    (50,'You can do it.'),
    (51,'Let me check.'),
    (52,'I will verify that.'),
    (53,'That seems right.'),
    (54,'That seems wrong.'),
    (55,'Interesting point.'),
    (56,'I had not thought of that.'),
    (57,'That changes things.'),
    (58,'Let us try a different approach.'),
    (59,'What do you suggest?'),
    (60,'I need more time.'),
    (61,'This will take a while.'),
    (62,'Almost done.'),
    (63,'Just a second.'),
    (64,'Hold on.'),
    (65,'Please wait.'),
    (66,'Ready when you are.'),
    (67,'Let us begin.'),
    (68,'Starting now.'),
    (69,'Finished already.'),
    (70,'That was quick.'),
    (71,'That took longer than expected.'),
    (72,'Everything looks good.'),
    (73,'There is an issue.'),
    (74,'We need to fix this.'),
    (75,'Let us solve it.'),
    (76,'I found the problem.'),
    (77,'Here is the solution.'),
    (78,'Does this help?'),
    (79,'Let me know your thoughts.'),
    (80,'What do you think?'),
    (81,'I think this works.'),
    (82,'I am not convinced.'),
    (83,'Can you prove it?'),
    (84,'Show me an example.'),
    (85,'Here is an example.'),
    (86,'Try this instead.'),
    (87,'This might work better.'),
    (88,'I recommend this.'),
    (89,'It depends.'),
    (90,'That is optional.'),
    (91,'This is required.'),
    (92,'Please confirm.'),
    (93,'Confirmed.'),
    (94,'Cancelled.'),
    (95,'Processing your request.'),
    (96,'Request completed.'),
    (97,'Request failed.'),
    (98,'Please try again later.'),
    (99,'System is busy.'),
    (100,'All set.'),
    (101,'Let us review.'),
    (102,'Review completed.'),
    (103,'Changes applied.'),
    (104,'No changes needed.'),
    (105,'Saving progress.'),
    (106,'Progress saved.'),
    (107,'Loading data.'),
    (108,'Data loaded.'),
    (109,'Connection lost.'),
    (110,'Connection restored.'),
    (111,'Error occurred.'),
    (112,'No errors found.'),
    (113,'Debugging now.'),
    (114,'Issue resolved.'),
    (115,'Let us test it.'),
    (116,'Test successful.'),
    (117,'Test failed.'),
    (118,'Retrying.'),
    (119,'Retry successful.'),
    (120,'Retry failed.'),
    (121,'Moving forward.'),
    (122,'Going back.'),
    (123,'Step completed.'),
    (124,'Next step.'),
    (125,'Previous step.'),
    (126,'Final step.'),
    (127,'Process started.'),
    (128,'Process stopped.'),
    (129,'Process paused.'),
    (130,'Process resumed.'),
    (131,'Everything is under control.'),
    (132,'Something went wrong.'),
    (133,'We will handle it.'),
    (134,'Stay calm.'),
    (135,'Focus on the task.'),
    (136,'Keep it simple.'),
    (137,'That is complicated.'),
    (138,'Let us simplify it.'),
    (139,'Break it down.'),
    (140,'Piece by piece.'),
    (141,'Step by step.'),
    (142,'Almost there.'),
    (143,'Just one more thing.'),
    (144,'That is all.'),
    (145,'Nothing else to add.'),
    (146,'Any questions?'),
    (147,'Feel free to ask.'),
    (148,'I am here to help.'),
    (149,'Glad to assist.'),
    (150,'Happy to help.'),
    (151,'Let us wrap up.'),
    (152,'Wrapping up now.'),
    (153,'Session ended.'),
    (154,'Session started.'),
    (155,'Welcome back.'),
    (156,'Good to see you again.'),
    (157,'Long time no see.'),
    (158,'Hope you are well.'),
    (159,'Everything okay?'),
    (160,'Let me know if not.'),
    (161,'I can adjust.'),
    (162,'We can change that.'),
    (163,'That works for me.'),
    (164,'Sounds good.'),
    (165,'Perfect.'),
    (166,'Not perfect, but okay.'),
    (167,'Could be better.'),
    (168,'Needs improvement.'),
    (169,'Let us improve it.'),
    (170,'We are making progress.'),
    (171,'Slow but steady.'),
    (172,'Fast and efficient.'),
    (173,'Careful with that.'),
    (174,'Watch out.'),
    (175,'Be mindful.'),
    (176,'Take your time.'),
    (177,'No rush.'),
    (178,'Hurry up.'),
    (179,'Deadline is near.'),
    (180,'We made it.'),
    (181,'Success!'),
    (182,'Failure.'),
    (183,'Try a new way.'),
    (184,'Think differently.'),
    (185,'Be creative.'),
    (186,'Stay consistent.'),
    (187,'Keep learning.'),
    (188,'Never stop.'),
    (189,'Always improving.'),
    (190,'That is the goal.'),
    (191,'Mission accomplished.'),
    (192,'Work in progress.'),
    (193,'Under review.'),
    (194,'Approved.'),
    (195,'Rejected.'),
    (196,'Pending.'),
    (197,'Completed successfully.'),
    (198,'Completed with errors.'),
    (199,'Awaiting input.'),
    (200,'Done.'),
    (201,'Greetings, traveler.'),
    (202,'Welcome to the realm of Eldoria.'),
    (203,'The king awaits your presence.'),
    (204,'Beware the darkness beyond the forest.'),
    (205,'Have you come to accept the quest?'),
    (206,'Your journey begins here.'),
    (207,'The dragons have returned.'),
    (208,'I sense great power within you.'),
    (209,'You must gather your party.'),
    (210,'Danger lurks in every shadow.'),
    (211,'The tavern is full of rumors tonight.'),
    (212,'A bounty has been placed on the beast.'),
    (213,'Sharpen your blade before you leave.'),
    (214,'Magic flows strongly in this land.'),
    (215,'The guild is recruiting new members.'),
    (216,'Have you visited the marketplace?'),
    (217,'Potions are essential for survival.'),
    (218,'The healer can restore your strength.'),
    (219,'Your armor needs repair.'),
    (220,'You have gained a level.'),
    (221,'New skills are now available.'),
    (222,'The dungeon entrance is nearby.'),
    (223,'Only the brave enter there.'),
    (224,'Treasures await those who dare.'),
    (225,'The quest is not yet complete.'),
    (226,'Return when you have the relic.'),
    (227,'The relic is hidden deep underground.'),
    (228,'Monsters guard the treasure.'),
    (229,'Your reputation has increased.'),
    (230,'The villagers trust you now.'),
    (231,'A storm is coming.'),
    (232,'The skies darken with magic.'),
    (233,'Ancient runes glow on the walls.'),
    (234,'You feel a strange presence.'),
    (235,'The portal has opened.'),
    (236,'Step through if you dare.'),
    (237,'This land is cursed.'),
    (238,'Only a hero can lift the curse.'),
    (239,'Your destiny awaits.'),
    (240,'The prophecy speaks of you.'),
    (241,'Light your torch in the darkness.'),
    (242,'Listen closely to the spirits.'),
    (243,'The forest whispers secrets.'),
    (244,'You are not alone here.'),
    (245,'Enemies approach.'),
    (246,'Prepare for battle.'),
    (247,'Attack now!'),
    (248,'Defend yourself!'),
    (249,'Use your abilities wisely.'),
    (250,'Your mana is low.'),
    (251,'Your health is critical.'),
    (252,'Drink a potion quickly.'),
    (253,'You have been defeated.'),
    (254,'You have respawned at the shrine.'),
    (255,'Do not give up.'),
    (256,'Victory is within reach.'),
    (257,'You have slain the beast.'),
    (258,'Loot the treasure chest.'),
    (259,'You found a rare item.'),
    (260,'Equip your new gear.'),
    (261,'This weapon is powerful.'),
    (262,'Your inventory is full.'),
    (263,'Sell your items at the shop.'),
    (264,'Gold has been added to your pouch.'),
    (265,'You need more gold.'),
    (266,'Complete quests to earn rewards.'),
    (267,'The path splits ahead.'),
    (268,'Choose your direction carefully.'),
    (269,'A hidden passage reveals itself.'),
    (270,'You discovered a secret area.'),
    (271,'The boss has appeared.'),
    (272,'This foe is formidable.'),
    (273,'Call for assistance.'),
    (274,'Your allies have joined the fight.'),
    (275,'Together you are stronger.'),
    (276,'Coordinate your attacks.'),
    (277,'The enemy is weakened.'),
    (278,'Finish it now!'),
    (279,'The battle is won.'),
    (280,'Peace returns briefly.'),
    (281,'Darkness will rise again.'),
    (282,'Prepare for the next challenge.'),
    (283,'Your skills have improved.'),
    (284,'You feel stronger.'),
    (285,'Your magic has evolved.'),
    (286,'A new spell is unlocked.'),
    (287,'Channel your energy.'),
    (288,'Focus your mind.'),
    (289,'The ritual is complete.'),
    (290,'The summoning has begun.'),
    (291,'A creature emerges from the void.'),
    (292,'Stand your ground.'),
    (293,'Retreat if necessary.'),
    (294,'The gates are closing.'),
    (295,'Hurry before it is too late.'),
    (296,'You made it just in time.'),
    (297,'The artifact is yours.'),
    (298,'Guard it well.'),
    (299,'Its power is immense.'),
    (300,'Use it wisely.'),
    (301,'The council will hear of this.'),
    (302,'Your fame spreads across the land.'),
    (303,'Bards sing of your deeds.'),
    (304,'You are becoming a legend.'),
    (305,'But greater trials await.'),
    (306,'The north is in peril.'),
    (307,'Travel to the frozen wastes.'),
    (308,'The desert calls for aid.'),
    (309,'Sail across the great sea.'),
    (310,'Chart your own path.'),
    (311,'Adventure lies ahead.'),
    (312,'The journey never ends.'),
    (313,'Rest at the inn.'),
    (314,'Recover your strength.'),
    (315,'Dreams reveal hidden truths.'),
    (316,'Morning has come.'),
    (317,'Another day, another quest.'),
    (318,'The cycle continues.'),
    (319,'Will you rise to the challenge?'),
    (320,'Only time will tell.'),
    (321,'Your courage is admirable.'),
    (322,'Your fear is understandable.'),
    (323,'Even heroes falter.'),
    (324,'Stand back up.'),
    (325,'Try again, warrior.'),
    (326,'The enemy grows stronger.'),
    (327,'So must you.'),
    (328,'Seek better equipment.'),
    (329,'Train your abilities.'),
    (330,'Master your class.'),
    (331,'Choose your specialization.'),
    (332,'The path of magic awaits.'),
    (333,'The warrior path is yours.'),
    (334,'Stealth is your ally.'),
    (335,'Shadows conceal you.'),
    (336,'Strike from the darkness.'),
    (337,'Your target is unaware.'),
    (338,'Critical hit!'),
    (339,'That was effective.'),
    (340,'The enemy retaliates.'),
    (341,'Brace yourself.'),
    (342,'The ground trembles.'),
    (343,'Something massive approaches.'),
    (344,'This cannot be good.'),
    (345,'Stay alert.'),
    (346,'Trust your instincts.'),
    (347,'Follow the map.'),
    (348,'You are close.'),
    (349,'Just a little further.'),
    (350,'You have arrived.'),
    (351,'The temple stands before you.'),
    (352,'Enter with caution.'),
    (353,'Ancient guardians awaken.'),
    (354,'Solve the puzzle to proceed.'),
    (355,'The door unlocks.'),
    (356,'A hidden chamber opens.'),
    (357,'You feel rewarded.'),
    (358,'Treasure surrounds you.'),
    (359,'Take what you can carry.'),
    (360,'Leave nothing behind.'),
    (361,'Time is running out.'),
    (362,'Escape while you can.'),
    (363,'You barely made it out.'),
    (364,'That was intense.'),
    (365,'Well fought.'),
    (366,'Your legend grows.'),
    (367,'The realm is safer now.'),
    (368,'For the moment.'),
    (369,'Evil never rests.'),
    (370,'Nor should you.'),
    (371,'Prepare once more.'),
    (372,'The next quest awaits.'),
    (373,'Are you ready?'),
    (374,'Let us begin again.'),
    (375,'Your story continues.'),
    (376,'Write your own destiny.'),
    (377,'The world is vast.'),
    (378,'Explore every corner.'),
    (379,'Secrets are everywhere.'),
    (380,'Keep your eyes open.'),
    (381,'Your adventure is unique.'),
    (382,'No two paths are the same.'),
    (383,'Forge your legacy.'),
    (384,'Become a hero.'),
    (385,'Or something more.'),
    (386,'Power comes at a cost.'),
    (387,'Choose wisely.'),
    (388,'The balance must be kept.'),
    (389,'Light and dark collide.'),
    (390,'Which side will you choose?'),
    (391,'The final battle nears.'),
    (392,'All hope rests with you.'),
    (393,'Do not fail.'),
    (394,'The fate of the realm is in your hands.'),
    (395,'Stand tall, champion.'),
    (396,'This is your moment.'),
    (397,'Fight with honor.'),
    (398,'Victory or defeat awaits.'),
    (399,'The end is only the beginning.'),
    (400,'Legends never die.');

INSERT INTO npc_roles (
    name
)
VALUES
    ('Gaurd'),
    ('Blacksmith'),
    ('Inn Keeper'),
    ('Merchant'),
    ('Mage'),
    ('Archer'),
    ('Hermit'),
    ('Begger');

CALL random_npcs (
    1000,
    5
);

INSERT INTO quests(
    quest_id,
    npc_id,
    name,
    description,
    repeatable,
    location
)
VALUES
    (1,1,'Gather Herbs','Collect 10 healing herbs from the forest',1,'FOREST01'),
    (2,1,'Wolf Hunt','Eliminate 5 wild wolves near the village',1,'FOREST02'),
    (3,1,'Lost Necklace','Find the missing necklace by the river',0,'RIVER001'),
    (4,1,'Bandit Camp','Clear out the nearby bandit camp',1,'CAMP0001'),
    (5,1,'Fisherman''s Help','Catch 8 fish for the fisherman',1,'LAKE0001'),
    (6,1,'Ancient Relic','Retrieve a relic from the ruins',0,'RUINS001'),
    (7,1,'Escort Merchant','Escort the merchant to the next town',0,'ROAD0001'),
    (8,1,'Goblin Menace','Defeat 12 goblins in the hills',1,'HILL0001'),
    (9,1,'Lost Puppy','Find and return the lost puppy',0,'VILLAGE1'),
    (10,1,'Herbal Remedy','Deliver herbs to the healer',1,'VILLAGE2'),
    (11,1,'Ore Delivery','Mine and deliver 6 iron ores',1,'MINE0001'),
    (12,1,'Spider Infestation','Kill 10 cave spiders',1,'CAVE0001'),
    (13,1,'Hidden Treasure','Locate buried treasure in the desert',0,'DESERT01'),
    (14,1,'Guard Duty','Stand guard for the night',1,'FORT0001'),
    (15,1,'Missing Scout','Find the missing scout in the woods',0,'FOREST03'),
    (16,1,'Supply Run','Deliver supplies to outpost',1,'OUTPOST1'),
    (17,1,'Rat Problem','Eliminate 15 sewer rats',1,'SEWER001'),
    (18,1,'Magic Dust','Collect 5 magic dust from fairies',1,'FOREST04'),
    (19,1,'Ancient Book','Retrieve book from library ruins',0,'RUINS002'),
    (20,1,'Defend Village','Protect village from attackers',1,'VILLAGE3'),
    (21,1,'Golden Apple','Find the golden apple',0,'FOREST05'),
    (22,1,'Bridge Repair','Collect wood to fix the bridge',1,'RIVER002'),
    (23,1,'Hunting Boars','Hunt 7 wild boars',1,'FOREST06'),
    (24,1,'Rescue Farmer','Rescue trapped farmer',0,'FARM0001'),
    (25,1,'Crystal Shards','Collect 9 crystal shards',1,'CAVE0002'),
    (26,1,'Messenger Duty','Deliver a message to the king',0,'CASTLE01'),
    (27,1,'Firewood Gathering','Collect 12 firewood logs',1,'FOREST07'),
    (28,1,'Dark Ritual','Stop the cult ritual',0,'CULT0001'),
    (29,1,'Lost Map','Recover the lost map',0,'DESERT02'),
    (30,1,'Harvest Crops','Harvest 20 crops',1,'FARM0002'),
    (31,1,'Slay Dragon','Defeat the dragon',0,'MOUNT001'),
    (32,1,'Scout Area','Explore the marked region',1,'PLAINS01'),
    (33,1,'Water Delivery','Deliver fresh water barrels',1,'VILLAGE4'),
    (34,1,'Find Blacksmith','Locate missing blacksmith',0,'TOWN0001'),
    (35,1,'Guard Caravan','Protect caravan from raiders',1,'ROAD0002'),
    (36,1,'Ice Crystals','Collect ice crystals',1,'TUNDRA01'),
    (37,1,'Snow Wolves','Defeat 6 snow wolves',1,'TUNDRA02'),
    (38,1,'Hidden Cave','Explore hidden cave',0,'CAVE0003'),
    (39,1,'Magic Ring','Find enchanted ring',0,'RUINS003'),
    (40,1,'Alchemy Help','Collect ingredients for alchemist',1,'TOWN0002'),
    (41,1,'Clear Path','Remove obstacles from road',1,'ROAD0003'),
    (42,1,'Ancient Tree','Inspect the ancient tree',0,'FOREST08'),
    (43,1,'Fog Investigation','Investigate strange fog',0,'SWAMP001'),
    (44,1,'Swamp Beasts','Defeat swamp creatures',1,'SWAMP002'),
    (45,1,'Deliver Potion','Deliver potion to healer',1,'VILLAGE5'),
    (46,1,'Lost Soldier','Find lost soldier',0,'BATTLE01'),
    (47,1,'Weapon Test','Test new weapon on targets',1,'FIELD001'),
    (48,1,'Food Supplies','Bring food to camp',1,'CAMP0002'),
    (49,1,'Secret Letter','Deliver secret letter',0,'CITY0001'),
    (50,1,'Defeat Assassin','Eliminate hidden assassin',0,'CITY0002'),
    (51,1,'Training Session','Complete combat training',1,'ARENA001'),
    (52,1,'Mining Task','Mine 10 gold ores',1,'MINE0002'),
    (53,1,'Forest Patrol','Patrol forest perimeter',1,'FOREST09'),
    (54,1,'Capture Thief','Capture the thief',0,'CITY0003'),
    (55,1,'Rescue Child','Rescue lost child',0,'FOREST10'),
    (56,1,'Find Relics','Collect ancient relics',1,'RUINS004'),
    (57,1,'Ship Supplies','Deliver supplies to ship',1,'PORT0001'),
    (58,1,'Pirate Threat','Defeat pirates',1,'SEA00001'),
    (59,1,'Map Exploration','Explore unknown lands',1,'MAP00001'),
    (60,1,'Lost Artifact','Find lost artifact',0,'DESERT03'),
    (61,1,'Clean Well','Clean contaminated well',1,'VILLAGE6'),
    (62,1,'Guard Tower','Defend the tower',1,'TOWER001'),
    (63,1,'Ancient Puzzle','Solve ancient puzzle',0,'RUINS005'),
    (64,1,'Deliver Armor','Bring armor to knight',1,'CASTLE02'),
    (65,1,'Scout Enemy','Scout enemy camp',1,'CAMP0003'),
    (66,1,'Destroy Totem','Destroy cursed totem',0,'SWAMP003'),
    (67,1,'Collect Feathers','Collect 15 bird feathers',1,'FOREST11'),
    (68,1,'Hidden Enemy','Find hidden enemy agent',0,'CITY0004'),
    (69,1,'Escort Noble','Escort noble safely',0,'ROAD0004'),
    (70,1,'Train Horses','Train 3 horses',1,'FARM0003'),
    (71,1,'Clear Mine','Clear enemies from mine',1,'MINE0003'),
    (72,1,'Storm Investigation','Investigate magical storm',0,'PLAINS02'),
    (73,1,'Defend Gate','Defend city gate',1,'CITY0005'),
    (74,1,'Deliver Scroll','Deliver magic scroll',0,'TOWER002'),
    (75,1,'Find Herbs','Collect rare herbs',1,'FOREST12'),
    (76,1,'Hunt Bears','Hunt 4 bears',1,'FOREST13'),
    (77,1,'Lost Ring','Find lost ring',0,'VILLAGE7'),
    (78,1,'Repair Armor','Collect materials for armor',1,'TOWN0003'),
    (79,1,'Escort Prisoner','Escort captured prisoner',0,'ROAD0005'),
    (80,1,'Clear Ruins','Clear monsters from ruins',1,'RUINS006'),
    (81,1,'Magic Experiment','Assist mage experiment',0,'TOWER003'),
    (82,1,'Hidden Cache','Find hidden supply cache',0,'PLAINS03'),
    (83,1,'Scout River','Scout riverbank area',1,'RIVER003'),
    (84,1,'Deliver Message','Deliver urgent message',1,'CITY0006'),
    (85,1,'Protect Farm','Protect farm from pests',1,'FARM0004'),
    (86,1,'Defeat Ogre','Defeat the ogre',0,'HILL0002'),
    (87,1,'Collect Mushrooms','Collect 20 mushrooms',1,'CAVE0004'),
    (88,1,'Investigate Ruins','Investigate strange ruins',0,'RUINS007'),
    (89,1,'Lost Caravan','Find lost caravan',0,'DESERT04'),
    (90,1,'Guard Camp','Guard military camp',1,'CAMP0004'),
    (91,1,'Find Scroll','Locate ancient scroll',0,'TOWER004'),
    (92,1,'Eliminate Spies','Eliminate enemy spies',1,'CITY0007'),
    (93,1,'Collect Gems','Collect 10 gems',1,'MINE0004'),
    (94,1,'Rescue Knight','Rescue captured knight',0,'CASTLE03'),
    (95,1,'Patrol Border','Patrol borderlands',1,'BORDER01'),
    (96,1,'Slay Harpies','Defeat harpies',1,'MOUNT002'),
    (97,1,'Ancient Shrine','Visit ancient shrine',0,'SHRINE01'),
    (98,1,'Deliver Food','Deliver food supplies',1,'VILLAGE8'),
    (99,1,'Clear Forest','Clear forest threats',1,'FOREST14'),
    (100,1,'Final Battle','Defeat the final boss',0,'BOSS0001');


CALL random_loot_tables(
    250
);

CALL random_loot_table_items(
    1,
    10
);


CALL random_quest_rewards(

);

CALL random_quest_history(
    5,
    50
);

CALL random_mobs(
    500
);

CALL random_zone_mobs(
    3,
    15
);

CALL random_player_trades(
    1750
);

CALL random_npc_trades(
    1750
);

CALL random_combats(
    150
);

-- add combat_info

-- add combat_equipment

-- add modifiers

-- add item_modifiers

-- add race_modifiers

-- add specialization_modifiers

-- add class_modifiers

-- add restrictions

-- add quest_restrictions

-- add item_restrictions

-- add specialization_restrictions
