DROP DATABASE IF EXISTS capstone_mmorpg;
CREATE DATABASE IF NOT EXISTS capstone_mmorpg;
USE capstone_mmorpg;

DROP TABLE IF EXISTS specialization_resctrictions;
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
    creatoin_date DATETIME,
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
    state ENUM('complete','accepted','failed'),
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