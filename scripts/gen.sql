
DROP PROCEDURE IF EXISTS random_guilds;
DROP PROCEDURE IF EXISTS chat_filters;
DROP PROCEDURE IF EXISTS random_zones;
DROP PROCEDURE IF EXISTS new_chat;
DROP PROCEDURE IF EXISTS random_factions;
DROP PROCEDURE IF EXISTS random_equiped;
DROP PROCEDURE IF EXISTS random_items;
DROP PROCEDURE IF EXISTS random_item_info;
DROP PROCEDURE IF EXISTS random_character_stats;
DROP PROCEDURE IF EXISTS random_character_info;
DROP PROCEDURE IF EXISTS random_character;
DROP PROCEDURE IF EXISTS random_account_history;
DROP PROCEDURE IF EXISTS random_account;
DROP PROCEDURE IF EXISTS random_datetime;
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

CREATE PROCEDURE IF NOT EXISTS chat_filters(
    
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

    WHILE i <= num_of_guilds DO
        CALL random_datetime(
            start_date, end_date, @guild_date
        );
        CALL new_chat(
            CONCAT('guild_', i, ' chat'),
            0,
            @new_chat_id
        );

        INSERT INTO guilds(
            chat_id,
            creation_date,
            motd,
            member_limit
        )
        VALUES(
            @new_chat_id,
            @guild_date,
            NULL,
            15 + FLOOR(1 + RAND() * 45)
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
    END WHILE;
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
    500,
    NOW(),
    '2005-06-07 15:54:02',
    5,
    100
);

CALL random_character(
    1000
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

INSERT INTO regions(name)
VALUES
    ('Feywild'),
    ('Gondor'),
    ('The Rift'),
    ('Garden City'),
    ('The End');

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

