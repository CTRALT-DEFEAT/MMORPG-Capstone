DROP TABLE IF EXISTS npc_dialog;
DROP TABLE IF EXISTS dialogs;
DROP TABLE IF EXISTS quest_restrictions;
DROP TABLE IF EXISTS item_restrictions;
DROP TABLE IF EXISTS restriction;
DROP TABLE IF EXISTS character_faction_rep;
DROP TABLE IF EXISTS loot_table_items;
DROP TABLE IF EXISTS quest_transaction;
DROP TABLE IF EXISTS quests;
DROP TABLE IF EXISTS item_trade;
DROP TABLE IF EXISTS npc_trade;
DROP TABLE IF EXISTS player_trade;
DROP TABLE IF EXISTS combat;
DROP TABLE IF EXISTS member_activity;
DROP TABLE IF EXISTS member_history;
DROP TABLE IF EXISTS guild_members;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS guilds;
DROP TABLE IF EXISTS chat_filters;
DROP TABLE IF EXISTS filters;
DROP TABLE IF EXISTS message_history;
DROP TABLE IF EXISTS chat_members;
DROP TABLE IF EXISTS npcs;
DROP TABLE IF EXISTS zone_mobs;
DROP TABLE IF EXISTS mobs;
DROP TABLE IF EXISTS loot_table;
DROP TABLE IF EXISTS zones;
DROP TABLE IF EXISTS factions;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS chat;
DROP TABLE IF EXISTS class_specialization;
DROP TABLE IF EXISTS specializations;
DROP TABLE IF EXISTS race_modifiers;
DROP TABLE IF EXISTS class_modifiers;
DROP TABLE IF EXISTS item_modifiers;
DROP TABLE IF EXISTS modifiers;
DROP TABLE IF EXISTS equipped_items;
DROP TABLE IF EXISTS character_stats;
DROP TABLE IF EXISTS character_info;
DROP TABLE IF EXISTS characters;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS inventories;
DROP TABLE IF EXISTS item_rarities;
DROP TABLE IF EXISTS stats;
DROP TABLE IF EXISTS levels;
DROP TABLE IF EXISTS races;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS accounts;

-- =========================
-- CORE TABLES
-- =========================

CREATE TABLE IF NOT EXISTS accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    account_name VARCHAR(50),
    creation_date DATETIME,
    character_limit TINYINT,
    character_count TINYINT
);

CREATE TABLE IF NOT EXISTS classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15),
    description TINYTEXT
);

CREATE TABLE IF NOT EXISTS races (
    race_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15),
    description TINYTEXT
);

CREATE TABLE IF NOT EXISTS levels (
    level_id INT AUTO_INCREMENT PRIMARY KEY,
    xp_requirement SMALLINT
);

CREATE TABLE IF NOT EXISTS stats (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS item_rarities (
    rarity_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15),
    color VARCHAR(6)
);

CREATE TABLE IF NOT EXISTS inventories (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    max_size TINYINT UNSIGNED
);

CREATE TABLE IF NOT EXISTS items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT,
    name VARCHAR(25),
    durability_max SMALLINT UNSIGNED,
    durability_current SMALLINT UNSIGNED,
    sell_price SMALLINT UNSIGNED,
    repair_cost SMALLINT UNSIGNED,
    two_handed BIT,
    rarity_id INT,
    FOREIGN KEY (inventory_id) REFERENCES inventories(inventory_id),
    FOREIGN KEY (rarity_id) REFERENCES item_rarities(rarity_id)
);

-- =========================
-- CHARACTER SYSTEM
-- =========================

CREATE TABLE IF NOT EXISTS characters (
    character_id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT,
    race_id INT,
    level_id INT,
    inventory_id INT,
    name VARCHAR(25),
    gold_balance MEDIUMINT UNSIGNED,
    experience MEDIUMINT UNSIGNED,
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (race_id) REFERENCES races(race_id),
    FOREIGN KEY (level_id) REFERENCES levels(level_id),
    FOREIGN KEY (inventory_id) REFERENCES inventories(inventory_id)
);

CREATE TABLE IF NOT EXISTS character_info (
    info_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT,
    character_id INT UNIQUE,
    active BIT,
    create_date DATETIME,
    last_played DATETIME,
    time_played TIME,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id)
);

CREATE TABLE IF NOT EXISTS character_stats (
    character_id INT,
    stat_id INT,
    amount TINYINT UNSIGNED,
    PRIMARY KEY (character_id, stat_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (stat_id) REFERENCES stats(stat_id)
);

-- =========================
-- EQUIPMENT / MODIFIERS
-- =========================

CREATE TABLE IF NOT EXISTS equipped_items (
    equipped_id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT,
    item_id INT,
    slot_name VARCHAR(15),
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

CREATE TABLE IF NOT EXISTS modifiers (
    modifier_id INT AUTO_INCREMENT PRIMARY KEY,
    stat_id INT,
    amount TINYINT,
    FOREIGN KEY (stat_id) REFERENCES stats(stat_id)
);

CREATE TABLE IF NOT EXISTS item_modifiers (
    item_id INT,
    modifier_id INT,
    PRIMARY KEY (item_id, modifier_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id),
    FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id)
);

CREATE TABLE IF NOT EXISTS class_modifiers (
    class_id INT,
    modifier_id INT,
    PRIMARY KEY (class_id, modifier_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id)
);

CREATE TABLE IF NOT EXISTS race_modifiers (
    race_id INT,
    modifier_id INT,
    PRIMARY KEY (race_id, modifier_id),
    FOREIGN KEY (race_id) REFERENCES races(race_id),
    FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id)
);

CREATE TABLE specializations (
    specialization_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS class_specialization (
    class_id INT,
    specialization_id INT,
    PRIMARY KEY (class_id, specialization_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id)
);

-- =========================
-- WORLD
-- =========================

CREATE TABLE IF NOT EXISTS chat (
    chat_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS regions (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20),
    chat_id INT UNIQUE,
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id)
);

CREATE TABLE IF NOT EXISTS factions (
    faction_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(25),
    region_id INT UNIQUE,
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

CREATE TABLE IF NOT EXISTS zones (
    zone_id INT AUTO_INCREMENT PRIMARY KEY,
    region_id INT,
    name VARCHAR(20),
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- =========================
-- NPC / MOBS
-- =========================

CREATE TABLE IF NOT EXISTS loot_table (
    loot_table_id INT AUTO_INCREMENT PRIMARY KEY,
    gold_min TINYINT,
    gold_max TINYINT,
    exp SMALLINT
);

CREATE TABLE IF NOT EXISTS mobs (
    mob_id INT AUTO_INCREMENT PRIMARY KEY,
    loot_table_id INT,
    name VARCHAR(25),
    is_boss BIT,
    pathing BIT,
    FOREIGN KEY (loot_table_id) REFERENCES loot_table(loot_table_id)
);

CREATE TABLE IF NOT EXISTS zone_mobs (
    zone_id INT,
    mob_id INT,
    amount TINYINT UNSIGNED,
    PRIMARY KEY (zone_id, mob_id),
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id),
    FOREIGN KEY (mob_id) REFERENCES mobs(mob_id)
);

CREATE TABLE IF NOT EXISTS npcs (
    npc_id INT AUTO_INCREMENT PRIMARY KEY,
    zone_id INT,
    name VARCHAR(25),
    description TINYTEXT,
    killable BIT,
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
);

-- =========================
-- CHAT SYSTEM
-- =========================

CREATE TABLE IF NOT EXISTS chat_members (
    chat_id INT,
    character_id INT,
    PRIMARY KEY (chat_id, character_id),
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id)
);


CREATE TABLE IF NOT EXISTS message_history (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    chat_id INT,
    sender_id INT,
    message TINYTEXT,
    time DATETIME,
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id),
    FOREIGN KEY (sender_id) REFERENCES characters(character_id)
);

CREATE TABLE IF NOT EXISTS filters (
    filter_id INT AUTO_INCREMENT PRIMARY KEY,
    word VARCHAR(45),
    filtered_word VARCHAR(45)
);

CREATE TABLE IF NOT EXISTS chat_filters (
    filter_id INT,
    chat_id INT,
    PRIMARY KEY (filter_id, chat_id),
    FOREIGN KEY (filter_id) REFERENCES filters(filter_id),
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id)
);

-- =========================
-- GUILDS
-- =========================

CREATE TABLE IF NOT EXISTS guilds (
    guild_id INT AUTO_INCREMENT PRIMARY KEY,
    chat_id INT,
    creation_date DATETIME,
    motd TINYTEXT,
    member_count TINYINT UNSIGNED,
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id)
);

CREATE TABLE IF NOT EXISTS roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(10),
    can_invite BIT,
    can_kick BIT,
    can_edit_roles BIT,
    can_edit_motd BIT
);

CREATE TABLE IF NOT EXISTS guild_members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT UNIQUE,
    guild_id INT,
    role_id INT,
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (guild_id) REFERENCES guilds(guild_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE IF NOT EXISTS member_history (
    member_history_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    guild_id INT,
    role_id INT,
    time DATETIME,
    FOREIGN KEY (member_id) REFERENCES guild_members(member_id),
    FOREIGN KEY (guild_id) REFERENCES guilds(guild_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE IF NOT EXISTS member_activity (
    activity_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    log_on DATETIME,
    log_off DATETIME,
    FOREIGN KEY (member_id) REFERENCES guild_members(member_id)
);

-- =========================
-- COMBAT
-- =========================
CREATE TABLE IF NOT EXISTS combat (
    combat_id INT AUTO_INCREMENT PRIMARY KEY,
    mob_id INT,
    character_id INT,
    time DATETIME,
    FOREIGN KEY (mob_id) REFERENCES mobs(mob_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id)
);

-- =========================
-- ECONOMY
-- =========================

CREATE TABLE IF NOT EXISTS player_trade (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    character1_id INT,
    character2_id INT,
    time DATETIME,
    FOREIGN KEY (character1_id) REFERENCES characters(character_id),
    FOREIGN KEY (character2_id) REFERENCES characters(character_id)
);

CREATE TABLE IF NOT EXISTS npc_trade (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT,
    npc_id INT,
    time DATETIME,
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (npc_id) REFERENCES npcs(npc_id)
);

CREATE TABLE IF NOT EXISTS item_trade (
    item_trade_id INT AUTO_INCREMENT PRIMARY KEY,
    player_trade_id INT,
    npc_trade_id INT,
    sender_id INT,
    receiver_id INT,
    item_id INT,
    gold_amount MEDIUMINT UNSIGNED,
    FOREIGN KEY (player_trade_id) REFERENCES player_trade(trade_id),
    FOREIGN KEY (npc_trade_id) REFERENCES npc_trade(trade_id),
    FOREIGN KEY (sender_id) REFERENCES characters(character_id),
    FOREIGN KEY (receiver_id) REFERENCES characters(character_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

-- =========================
-- QUESTS
-- =========================

CREATE TABLE IF NOT EXISTS quests (
    quest_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    repeatable BIT,
    location CHAR(10),
    npc_id INT,
    FOREIGN KEY (npc_id) REFERENCES npcs(npc_id)
);

CREATE TABLE IF NOT EXISTS quest_transaction (
    quest_transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    quest_id INT,
    character_id INT,
    state ENUM('started','completed','failed'),
    time DATETIME,
    loot_table_id INT,
    FOREIGN KEY (loot_table_id) REFERENCES loot_table(loot_table_id),
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id)
);

-- =========================
-- LOOT
-- =========================

CREATE TABLE IF NOT EXISTS loot_table_items (
    loot_table_id INT,
    item_id INT,
    drop_rate DECIMAL(11,10),
    PRIMARY KEY (loot_table_id, item_id),
    FOREIGN KEY (loot_table_id) REFERENCES loot_table(loot_table_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

-- =========================
-- FACTIONS
-- =========================

CREATE TABLE IF NOT EXISTS character_faction_rep (
    character_id INT,
    faction_id INT,
    reputation TINYINT,
    PRIMARY KEY (character_id, faction_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (faction_id) REFERENCES factions(faction_id)
);

-- =========================
-- RESTRICTIONS
-- =========================

CREATE TABLE IF NOT EXISTS restriction (
    restriction_id INT AUTO_INCREMENT PRIMARY KEY,
    restriction_type ENUM('requirement', 'restriction'),
    class_id INT,
    race_id INT,
    level_id INT,
    specialization_id INT,
    quest_id INT,
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (race_id) REFERENCES races(race_id),
    FOREIGN KEY (level_id) REFERENCES levels(level_id),
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id)
);

CREATE TABLE IF NOT EXISTS item_restrictions (
    item_id INT,
    restriction_id INT,
    can_equip BIT,
    PRIMARY KEY (item_id, restriction_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id),
    FOREIGN KEY (restriction_id) REFERENCES restriction(restriction_id)
);

CREATE TABLE IF NOT EXISTS quest_restrictions (
    quest_id INT,
    restriction_id INT,
    PRIMARY KEY (quest_id, restriction_id),
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id),
    FOREIGN KEY (restriction_id) REFERENCES restriction(restriction_id)
);

-- =========================
-- DIALOG SYSTEM
-- =========================

CREATE TABLE IF NOT EXISTS dialogs (
    dialog_id INT AUTO_INCREMENT PRIMARY KEY,
    dialog TEXT
);

CREATE TABLE IF NOT EXISTS npc_dialog (
    npc_id INT,
    dialog_id INT,
    PRIMARY KEY (npc_id, dialog_id),
    FOREIGN KEY (npc_id) REFERENCES npcs(npc_id),
    FOREIGN KEY (dialog_id) REFERENCES dialogs(dialog_id)
);
