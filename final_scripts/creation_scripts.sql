# Core Lookup Tables

CREATE TABLE races (
    race_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    race_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE classes (
    class_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE specializations (
    specialization_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    specialization_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE levels (
    level_id INT UNSIGNED PRIMARY KEY,
    xp_required INT UNSIGNED NOT NULL
);

CREATE TABLE stats (
    stat_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stat_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE slots (
    slot_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slot_name VARCHAR(50) NOT NULL UNIQUE
);

# Class Specialization

CREATE TABLE class_specialization (
    class_id INT UNSIGNED,
    specialization_id INT UNSIGNED,
    PRIMARY KEY (class_id, specialization_id),
    FOREIGN KEY (class_id) REFERENCES classes(class_id) ON DELETE CASCADE,
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id) ON DELETE CASCADE
);

# Accounts and Characters

CREATE TABLE accounts (
    account_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL
);

CREATE TABLE characters (
    character_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    class_id INT UNSIGNED NOT NULL,
    race_id INT UNSIGNED NOT NULL,
    specialization_id INT UNSIGNED NULL,
    level_id INT UNSIGNED NOT NULL,
    FOREIGN KEY (class_id) REFERENCES classes(class_id) ON DELETE RESTRICT,
    FOREIGN KEY (race_id) REFERENCES races(race_id) ON DELETE RESTRICT,
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id) ON DELETE SET NULL,
    FOREIGN KEY (level_id) REFERENCES levels(level_id) ON DELETE RESTRICT
);

CREATE TABLE character_info (
    character_id INT UNSIGNED PRIMARY KEY,
    account_id INT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE CASCADE
);

# Character Stats

CREATE TABLE character_stats (
    character_id INT UNSIGNED,
    stat_id INT UNSIGNED,
    value INT NOT NULL,
    PRIMARY KEY (character_id, stat_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE,
    FOREIGN KEY (stat_id) REFERENCES stats(stat_id) ON DELETE CASCADE
);

# Items and Inventory

CREATE TABLE items (
    item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    sell_price DECIMAL(10,2),
    max_durability INT UNSIGNED
);

CREATE TABLE inventories (
    inventory_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id INT UNSIGNED NOT NULL,
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE
);

CREATE TABLE inventory_items (
    inventory_id INT UNSIGNED,
    item_id INT UNSIGNED,
    quantity INT UNSIGNED DEFAULT 1,
    PRIMARY KEY (inventory_id, item_id),
    FOREIGN KEY (inventory_id) REFERENCES inventories(inventory_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE CASCADE
);

CREATE TABLE equipped_items (
    character_id INT UNSIGNED,
    slot_id INT UNSIGNED,
    item_id INT UNSIGNED,
    PRIMARY KEY (character_id, slot_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES slots(slot_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE SET NULL
);

# Restriction System

CREATE TABLE restrictions (
    restriction_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    restriction_type ENUM('require','exclude') NOT NULL,
    min_level INT UNSIGNED,
    race_id INT UNSIGNED,
    class_id INT UNSIGNED,
    specialization_id INT UNSIGNED,
    FOREIGN KEY (race_id) REFERENCES races(race_id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES classes(class_id) ON DELETE CASCADE,
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id) ON DELETE CASCADE
);

CREATE TABLE item_restrictions (
    item_id INT UNSIGNED,
    restriction_id INT UNSIGNED,
    PRIMARY KEY (item_id, restriction_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE CASCADE,
    FOREIGN KEY (restriction_id) REFERENCES restrictions(restriction_id) ON DELETE CASCADE
);

# WORLD (REGIONS / ZONES / NPCs)

CREATE TABLE regions (
    region_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(100)
);

CREATE TABLE zones (
    zone_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    region_id INT UNSIGNED,
    zone_name VARCHAR(100),
    FOREIGN KEY (region_id) REFERENCES regions(region_id) ON DELETE CASCADE
);

CREATE TABLE npcs (
    npc_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    npc_name VARCHAR(100),
    zone_id INT UNSIGNED,
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id) ON DELETE CASCADE
);

CREATE TABLE npc_roles (
    npc_role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50)
);

CREATE TABLE npc_role_map (
    npc_id INT UNSIGNED,
    npc_role_id INT UNSIGNED,
    PRIMARY KEY (npc_id, npc_role_id),
    FOREIGN KEY (npc_id) REFERENCES npcs(npc_id) ON DELETE CASCADE,
    FOREIGN KEY (npc_role_id) REFERENCES npc_roles(npc_role_id) ON DELETE CASCADE
);

# Dialog System

CREATE TABLE dialogs (
    dialog_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dialog_text TEXT NOT NULL
);

CREATE TABLE npc_dialogs (
    npc_id INT UNSIGNED,
    dialog_id INT UNSIGNED,
    PRIMARY KEY (npc_id, dialog_id),
    FOREIGN KEY (npc_id) REFERENCES npcs(npc_id) ON DELETE CASCADE,
    FOREIGN KEY (dialog_id) REFERENCES dialogs(dialog_id) ON DELETE CASCADE
);

# Quest System
  
CREATE TABLE quests (
    quest_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    quest_name VARCHAR(100),
    quest_description TEXT
);

CREATE TABLE quest_prerequisites (
    quest_id INT UNSIGNED,
    required_quest_id INT UNSIGNED,
    PRIMARY KEY (quest_id, required_quest_id),
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id) ON DELETE CASCADE,
    FOREIGN KEY (required_quest_id) REFERENCES quests(quest_id) ON DELETE CASCADE
);

CREATE TABLE quest_rewards (
    quest_id INT UNSIGNED,
    item_id INT UNSIGNED,
    xp_reward INT,
    gold_reward DECIMAL(10,2),
    PRIMARY KEY (quest_id, item_id),
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE SET NULL
);

CREATE TABLE quest_history (
    character_id INT UNSIGNED,
    quest_id INT UNSIGNED,
    status ENUM('not_started','in_progress','completed'),
    updated_at DATETIME,
    PRIMARY KEY (character_id, quest_id),
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE,
    FOREIGN KEY (quest_id) REFERENCES quests(quest_id) ON DELETE CASCADE
);

# Trading System

CREATE TABLE trades (
    trade_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trade_time DATETIME NOT NULL
);

CREATE TABLE trade_participants (
    trade_id INT UNSIGNED,
    character_id INT UNSIGNED,
    PRIMARY KEY (trade_id, character_id),
    FOREIGN KEY (trade_id) REFERENCES trades(trade_id) ON DELETE CASCADE,
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE
);

CREATE TABLE trade_items (
    trade_id INT UNSIGNED,
    item_id INT UNSIGNED,
    sender_character_id INT UNSIGNED,
    gold_amount DECIMAL(10,2),
    PRIMARY KEY (trade_id, item_id, sender_character_id),
    FOREIGN KEY (trade_id) REFERENCES trades(trade_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE SET NULL,
    FOREIGN KEY (sender_character_id) REFERENCES characters(character_id) ON DELETE CASCADE
);

# Guilds
CREATE TABLE guilds (
    guild_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    guild_name VARCHAR(100)
);

CREATE TABLE guild_members (
    guild_id INT UNSIGNED,
    character_id INT UNSIGNED UNIQUE,
    PRIMARY KEY (guild_id, character_id),
    FOREIGN KEY (guild_id) REFERENCES guilds(guild_id) ON DELETE CASCADE,
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE
);

CREATE TABLE roles (
    role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50)
);

CREATE TABLE member_history (
    character_id INT UNSIGNED,
    role_id INT UNSIGNED,
    changed_at DATETIME,
    PRIMARY KEY (character_id, role_id, changed_at),
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE
);

CREATE TABLE member_activity (
    activity_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    character_id INT UNSIGNED,
    log_on DATETIME,
    log_off DATETIME,
    FOREIGN KEY (character_id) REFERENCES characters(character_id) ON DELETE CASCADE
);

