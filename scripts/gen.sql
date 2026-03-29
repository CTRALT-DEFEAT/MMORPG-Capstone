
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
        SET max_members = 15 + FLOOR(1 + RAND() * 45);
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

-- add chat_members

-- add message history

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

-- add loot_tables

-- add loot_table_items

-- add quest_rewards

-- add quest_history

-- add mobs

-- add zone_mobs

-- add player_trades

-- add npc_trades

-- add trade_info

-- add combats

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
