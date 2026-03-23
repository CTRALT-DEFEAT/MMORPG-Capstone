# Lookup Data

-- RACES
INSERT INTO races (race_name) VALUES
('Human'), ('Elf'), ('Orc'), ('Dwarf'), ('Goblin');

-- CLASSES
INSERT INTO classes (class_name) VALUES
('Warrior'), ('Mage'), ('Hunter'), ('Rogue'), ('Priest');

-- SPECIALIZATIONS
INSERT INTO specializations (specialization_name) VALUES
('Ranger'), ('Berserker'), ('Arcanist'), ('Thaumaturge'),
('Oracle'), ('Spellthief'), ('Brawler'), ('Noble'),
('Monk'), ('Assassin'), ('Tamer'), ('Collector'), ('Exorcist');

-- CLASS ↔ SPECIALIZATION
INSERT INTO class_specialization VALUES
(1,1),(3,1),
(1,2),
(2,3),
(2,4),(5,4),
(5,5),
(2,6),(4,6),
(1,7),(4,7),
(4,8),
(4,9),(5,9),
(4,10),(3,10),
(3,11),
(3,12),(2,12),
(3,13),(5,13),(2,13);

-- LEVELS
INSERT INTO levels VALUES
(1,0),(2,1000),(3,2500),(4,4500),(5,7000),
(6,10000),(7,15000),(8,25000),(9,50000),(10,100000);

-- SLOTS
INSERT INTO slots (slot_name) VALUES
('Head'),('Chest'),('Legs'),('Feet'),
('Hands'),('Main Hand'),('Off-hand'),('Trinket');


# Items - inlcuding custom ones

INSERT INTO items (item_name, sell_price, max_durability) VALUES
('Meurig''s Flute', 5, 15),
('Old Dagger', 20, 40),
('Pendant of Avarice', 700, 30),
('Holy Sword', 4500, 100),
('Axe of the First Moon', 8000, 120);

-- filler items
INSERT INTO items (item_name, sell_price, max_durability)
SELECT CONCAT('Item_', n), FLOOR(RAND()*500), FLOOR(RAND()*100)
FROM (
    SELECT @row := @row + 1 AS n FROM
    (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
    (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2,
    (SELECT @row:=0) t0
) numbers LIMIT 50;

# Accounts and Characters

DELIMITER $$

CREATE PROCEDURE generate_players()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 200 DO
        INSERT INTO accounts (username, created_at)
        VALUES (CONCAT('user_', i), NOW());

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_players();



# Characters

DELIMITER $$

CREATE PROCEDURE generate_characters()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 500 DO
        INSERT INTO characters (name, class_id, race_id, specialization_id, level_id)
        VALUES (
            CONCAT('Char_', i),
            FLOOR(1 + RAND()*5),
            FLOOR(1 + RAND()*5),
            IF(RAND() > 0.5, FLOOR(1 + RAND()*13), NULL),
            FLOOR(1 + RAND()*10)
        );

        INSERT INTO character_info (character_id, account_id, created_at)
        VALUES (i, FLOOR(1 + RAND()*200), NOW());

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_characters();


# Inventories

INSERT INTO inventories (character_id)
SELECT character_id FROM characters;

INSERT INTO inventory_items (inventory_id, item_id, quantity)
SELECT 
    inventory_id,
    FLOOR(1 + RAND()*55),
    FLOOR(1 + RAND()*5)
FROM inventories
LIMIT 800;


# NPC's and Quests

INSERT INTO regions (region_name) VALUES ('Solanthrop');
INSERT INTO zones (region_id, zone_name) VALUES (1, 'Solanthrop Peak');

INSERT INTO npcs (npc_name, zone_id) VALUES
('Meurig',1),
('Jauffley',1),
('Skorvald',1);

INSERT INTO quests (quest_name) VALUES
('Introductions'),
('Some friendly competition'),
('Not-so-friendly competition'),
('Betrayal at Solanthrop Peak'),
('All hands on deck');

INSERT INTO quest_prerequisites VALUES
(2,1),
(3,2),
(4,3),
(4,5);

INSERT INTO quest_rewards VALUES
(1,NULL,50,0),
(2,NULL,100,20),
(3,1,100,100),
(4,2,250,0);


# Guilds

INSERT INTO guilds (guild_name) VALUES
('IronLegion'), ('ShadowClan'), ('MoonGuard');

INSERT INTO guild_members (guild_id, character_id)
SELECT FLOOR(1 + RAND()*3), character_id
FROM characters
LIMIT 300;


  
# Member Activity

INSERT INTO member_activity (character_id, log_on, log_off)
SELECT 
    character_id,
    NOW() - INTERVAL FLOOR(RAND()*7) DAY,
    NOW()
FROM characters
LIMIT 400;


# Trades

-- Create Thalor & Morissey
INSERT INTO characters (name, class_id, race_id, specialization_id, level_id)
VALUES ('Thalor',2,4,13,5), ('Morissey',1,1,NULL,5);

-- Trade
INSERT INTO trades (trade_time)
VALUES ('2025-08-20 11:47:21');

INSERT INTO trade_participants VALUES (1,501),(1,502);

INSERT INTO trade_items VALUES
(1,4,501,12000), -- Holy Sword from Thalor
(1,5,502,0);     -- Axe from Morissey

