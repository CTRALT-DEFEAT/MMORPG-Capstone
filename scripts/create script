-- =========================
-- CORE TABLES
-- =========================

CREATE TABLE accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    account_name VARCHAR(50),
    creation_date DATETIME,
    character_limit INT,
    character_count INT
);

CREATE TABLE classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    description TEXT
);

CREATE TABLE races (
    race_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    description TEXT
);

CREATE TABLE levels (
    level_id INT AUTO_INCREMENT PRIMARY KEY,
    xp_requirement INT
);

CREATE TABLE stats (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE item_rarities (
    rarity_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    color VARCHAR(20)
);

CREATE TABLE inventories (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    max_size INT
);

CREATE TABLE items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT,
    name VARCHAR(100),
    durability_max INT,
    durability_current INT,
    sell_price INT,
    repair_cost INT,
    two_handed BOOLEAN,
    rarity_id INT,
    FOREIGN KEY (inventory_id) REFERENCES inventories(inventory_id),
    FOREIGN KEY (rarity_id) REFERENCES item_rarities(rarity_id)
);

-- =========================
-- CHARACTER SYSTEM
-- =========================

CREATE TABLE characters (
    character_id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT,
    race_id INT,
    level_id INT,
    inventory_id INT,
    name VARCHAR(50),
    gold_balance INT,
    experience INT,
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (race_id) REFERENCES races(race_id),
    FOREIGN KEY (level_id) REFERENCES levels(level_id),
    FOREIGN KEY (inventory_id) REFERENCES inventories(inventory_id)
);

CREATE TABLE character_info (
    info_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT,
    character_id INT UNIQUE,
    active BOOLEAN,
    create_date DATETIME,
    last_played DATETIME,
    time_played INT,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id)
);

CREATE TABLE character_stats (
    character_id INT,
    stat_id INT,
    amount INT,
    PRIMARY KEY (character_id, stat_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (stat_id) REFERENCES stats(stat_id)
);

-- =========================
-- EQUIPMENT / MODIFIERS
-- =========================

CREATE TABLE equipped_items (
    equipped_id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT,
    item_id INT,
    slot_name VARCHAR(50),
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

CREATE TABLE modifiers (
    modifier_id INT AUTO_INCREMENT PRIMARY KEY,
    stat_id INT,
    amount INT,
    FOREIGN KEY (stat_id) REFERENCES stats(stat_id)
);

CREATE TABLE item_modifiers (
    item_id INT,
    modifier_id INT,
    PRIMARY KEY (item_id, modifier_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id),
    FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id)
);

CREATE TABLE class_modifiers (
    class_id INT,
    modifier_id INT,
    PRIMARY KEY (class_id, modifier_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id)
);

CREATE TABLE race_modifiers (
    race_id INT,
    modifier_id INT,
    PRIMARY KEY (race_id, modifier_id),
    FOREIGN KEY (race_id) REFERENCES races(race_id),
    FOREIGN KEY (modifier_id) REFERENCES modifiers(modifier_id)
);

CREATE TABLE specializations (
    specialization_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE class_specialization (
    class_id INT,
    specialization_id INT,
    PRIMARY KEY (class_id, specialization_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id)
);

-- =========================
-- WORLD
-- =========================

CREATE TABLE chat (
    chat_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE regions (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    chat_id INT UNIQUE,
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id)
);

CREATE TABLE factions (
    faction_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    region_id INT UNIQUE,
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

CREATE TABLE zones (
    zone_id INT AUTO_INCREMENT PRIMARY KEY,
    region_id INT,
    name VARCHAR(50),
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- =========================
-- NPC / MOBS
-- =========================

CREATE TABLE loot_table (
    loot_table_id INT AUTO_INCREMENT PRIMARY KEY,
    gold_min INT,
    gold_max INT,
    exp INT
);

CREATE TABLE mobs (
    mob_id INT AUTO_INCREMENT PRIMARY KEY,
    loot_table_id INT,
    name VARCHAR(50),
    is_boss BOOLEAN,
    pathing VARCHAR(50),
    FOREIGN KEY (loot_table_id) REFERENCES loot_table(loot_table_id)
);

CREATE TABLE zone_mobs (
    zone_id INT,
    mob_id INT,
    amount INT,
    PRIMARY KEY (zone_id, mob_id),
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id),
    FOREIGN KEY (mob_id) REFERENCES mobs(mob_id)
);

CREATE TABLE npcs (
    npc_id INT AUTO_INCREMENT PRIMARY KEY,
    zone_id INT,
    name VARCHAR(50),
    description TEXT,
    killable BOOLEAN,
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
);

-- =========================
-- CHAT SYSTEM
-- =========================

CREATE TABLE chat_members (
    chat_id INT,
    character_id INT,
    PRIMARY KEY (chat_id, character_id),
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id)
);

CREATE TABLE message_history (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    chat_id INT,
    sender_id INT,
    message TEXT,
    time DATETIME,
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id),
    FOREIGN KEY (sender_id) REFERENCES characters(character_id)
);

CREATE TABLE filters (
    filter_id INT AUTO_INCREMENT PRIMARY KEY,
    word VARCHAR(50),
    filtered_word VARCHAR(50)
);

CREATE TABLE chat_filters (
    filter_id INT,
    chat_id INT,
    PRIMARY KEY (filter_id, chat_id),
    FOREIGN KEY (filter_id) REFERENCES filters(filter_id),
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id)
);

-- =========================
-- GUILDS
-- =========================

CREATE TABLE guilds (
    guild_id INT AUTO_INCREMENT PRIMARY KEY,
    chat_id INT,
    creation_date DATETIME,
    motd TEXT,
    member_count INT,
    FOREIGN KEY (chat_id) REFERENCES chat(chat_id)
);

CREATE TABLE roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    can_invite BOOLEAN,
    can_kick BOOLEAN,
    can_edit_roles BOOLEAN,
    can_edit_motd BOOLEAN
);

CREATE TABLE guild_members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT UNIQUE,
    guild_id INT,
    role_id INT,
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (guild_id) REFERENCES guilds(guild_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE member_history (
    member_history_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    guild_id INT,
    role_id INT,
    time DATETIME,
    FOREIGN KEY (member_id) REFERENCES guild_members(member_id),
    FOREIGN KEY (guild_id) REFERENCES guilds(guild_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

CREATE TABLE member_activity (
    activity_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    log_on DATETIME,
    log_off DATETIME,
    FOREIGN KEY (member_id) REFERENCES guild_members(member_id)
);

-- =========================
-- COMBAT
-- =========================

CREATE TABLE combat (
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

CREATE TABLE player_trade (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    character1_id INT,
    character2_id INT,
    time DATETIME,
    FOREIGN KEY (character1_id) REFERENCES characters(character_id),
    FOREIGN KEY (character2_id) REFERENCES characters(character_id)
);

CREATE TABLE npc_trade (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    character_id INT,
    npc_id INT,
    time DATETIME,
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (npc_id) REFERENCES npcs(npc_id)
);

CREATE TABLE item_trade (
    item_trade_id INT AUTO_INCREMENT PRIMARY KEY,
    player_trade_id INT,
    npc_trade_id INT,
    sender_id INT,
    receiver_id INT,
    item_id INT,
    gold_amount INT,
    FOREIGN KEY (player_trade_id) REFERENCES player_trade(trade_id),
    FOREIGN KEY (npc_trade_id) REFERENCES npc_trade(trade_id),
    FOREIGN KEY (sender_id) REFERENCES characters(character_id),
    FOREIGN KEY (receiver_id) REFERENCES characters(character_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

-- =========================
-- QUESTS
-- =========================

CREATE TABLE quests (
    quest_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    repeatable BOOLEAN,
    location VARCHAR(100),
    npc_id INT,
    FOREIGN KEY (npc_id) REFERENCES npcs(npc_id)
);

CREATE TABLE quest_transaction (
    quest_transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    quest_id INT,
    character_id INT,
    state ENUM('started','completed','failed'),
    time DATETIME,
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id)
);

-- =========================
-- LOOT
-- =========================

CREATE TABLE loot_table_items (
    loot_table_id INT,
    item_id INT,
    drop_rate DECIMAL(5,2),
    PRIMARY KEY (loot_table_id, item_id),
    FOREIGN KEY (loot_table_id) REFERENCES loot_table(loot_table_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

-- =========================
-- FACTIONS
-- =========================

CREATE TABLE character_faction_rep (
    character_id INT,
    faction_id INT,
    reputation INT,
    PRIMARY KEY (character_id, faction_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id),
    FOREIGN KEY (faction_id) REFERENCES factions(faction_id)
);

-- =========================
-- RESTRICTIONS
-- =========================

CREATE TABLE restriction (
    restriction_id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT,
    race_id INT,
    level_id INT,
    specialization_id INT,
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (race_id) REFERENCES races(race_id),
    FOREIGN KEY (level_id) REFERENCES levels(level_id),
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id)
);

CREATE TABLE item_restrictions (
    item_id INT,
    restriction_id INT,
    PRIMARY KEY (item_id, restriction_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id),
    FOREIGN KEY (restriction_id) REFERENCES restriction(restriction_id)
);

CREATE TABLE quest_restrictions (
    quest_id INT,
    restriction_id INT,
    PRIMARY KEY (quest_id, restriction_id),
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id),
    FOREIGN KEY (restriction_id) REFERENCES restriction(restriction_id)
);

-- =========================
-- DIALOG SYSTEM
-- =========================

CREATE TABLE dialogs (
    dialog_id INT AUTO_INCREMENT PRIMARY KEY,
    dialog TEXT
);

CREATE TABLE npc_dialog (
    npc_id INT,
    dialog_id INT,
    PRIMARY KEY (npc_id, dialog_id),
    FOREIGN KEY (npc_id) REFERENCES npcs(npc_id),
    FOREIGN KEY (dialog_id) REFERENCES dialogs(dialog_id)
);
