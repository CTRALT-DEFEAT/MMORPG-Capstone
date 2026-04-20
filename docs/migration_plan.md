# MongoDB Migration Plan — MMORPG Capstone Project
## Part 1: Planning

---

## Table of Contents

1. [Schema Analysis](#1-schema-analysis)
2. [Collection Design](#2-collection-design)
3. [Design Trade-offs](#3-design-trade-offs)
4. [SQL vs MongoDB Differences](#4-sql-vs-mongodb-differences)

---

## 1. Schema Analysis

### 1.1 Database Scale

The following table summarizes the scale of the existing SQL dataset being migrated:

| Entity | Record Count |
|---|---|
| Accounts | 750 |
| Characters | 2,000 |
| Item Templates | 500+ |
| Items (instances) | 2,500 |
| Guilds | 50 |
| Regions | 5 |
| Zones | 114 |
| NPCs | 1,000 |
| Quests | 101 |
| Mobs | 500 |
| Loot Tables | 250 |

This is a medium-scale game database. The record counts are small enough that document size limits (MongoDB's 16MB per document cap) are unlikely to be a concern for most collections — with one important exception: **chat message history**, discussed in Section 3.

---

### 1.2 SQL Table Inventory

The original relational schema contains the following categories of tables:

**Core entity tables** (direct MongoDB collection candidates):
`accounts`, `characters`, `items`, `guilds`, `chats`, `zones`, `npcs`, `quests`, `combats`

**Lookup / reference tables** (small, rarely updated):
`races`, `classes`, `specializations`, `levels`, `regions`, `mobs`, `loot_tables`

**Junction / association tables** (relationship glue in SQL):
`account_history`, `character_info`, `character_stats`, `equipped_items`,
`guild_roles`, `guild_members`, `guild_member_activity`, `member_history`,
`chat_filters`, `chat_members`, `message_history`,
`zone_mobs`, `npc_dialog`, `npc_roles`,
`quest_rewards`, `quest_restrictions`,
`item_info`, `item_modifiers`, `item_restrictions`,
`combat_info`, `combat_equipment`,
`loot_table_items`

**Transaction / event tables** (append-only records):
`player_trades`, `npc_trades`, `quest_history`

Junction tables are the heart of the SQL-to-NoSQL translation problem. In a relational database, they exist because SQL can't store arrays — every one-to-many relationship requires a separate table and a JOIN. In MongoDB, most of these collapse into embedded arrays.

---

### 1.3 Relationship Type Analysis

Understanding the cardinality of each relationship determines whether to **embed** or **reference**.

| Relationship | Type | SQL Mechanism | MongoDB Approach |
|---|---|---|---|
| Account → Login History | One-to-Many | `account_history` table | Embed as array |
| Character → Stats | One-to-Many | `character_stats` table | Embed as array |
| Character → Equipped Items | One-to-Many (bounded, max ~20 slots) | `equipped_items` table | Embed as array |
| Character → Account | Many-to-One | Foreign key `account_id` | Reference (store `account_id`) |
| Item → Modifiers | One-to-Many | `item_modifiers` table | Embed as array |
| Item → Restrictions | One-to-Many | `item_restrictions` table | Embed as array |
| Guild → Members | One-to-Many | `guild_members` table | Embed as array |
| Guild → Roles | One-to-Many (small, ~5 roles) | `guild_roles` table | Embed as array |
| Chat → Filters | One-to-Many (small) | `chat_filters` table | Embed as array |
| Chat → Messages | One-to-Many (unbounded, high volume) | `message_history` table | **Separate collection** |
| Zone → Mobs | One-to-Many | `zone_mobs` table | Embed as array |
| NPC → Dialog | One-to-Many | `npc_dialog` table | Embed as strings array |
| Quest → Reward | One-to-One | `quest_rewards` table | Embed as subdocument |
| Quest → Restrictions | One-to-Many | `quest_restrictions` table | Embed as array |
| Mob → Loot Table | One-to-One | `loot_tables` + `loot_table_items` | Embed inside mob document |
| Combat → Equipment Used | One-to-Many | `combat_equipment` table | Embed as array |
| Player Trades | Event record | `trade_info` with nullable FKs | Two clean separate collections |

---

### 1.4 Key JOIN Patterns in SQL (and Their MongoDB Replacements)

The following are the most expensive JOIN operations in the SQL schema, and how MongoDB eliminates them:

**Character Profile Load (on game login):**
```sql
-- SQL requires 5 joins:
SELECT * FROM characters c
JOIN character_info ci ON c.character_id = ci.character_id
JOIN character_stats cs ON c.character_id = cs.character_id
JOIN equipped_items ei ON c.character_id = ei.character_id
JOIN items i ON ei.item_id = i.item_id
WHERE c.character_id = ?;
```
In MongoDB, a single `db.characters.findOne({ _id: character_id })` returns the full profile including `info`, `stats`, and `equipped` in one round trip.

**Guild Dashboard Load:**
```sql
-- SQL requires 3 joins:
SELECT * FROM guilds g
JOIN guild_members gm ON g.guild_id = gm.guild_id
JOIN guild_roles gr ON gm.role_id = gr.role_id
WHERE g.guild_id = ?;
```
In MongoDB, the guild document contains embedded `roles` and `members` arrays — one read, no joins.

**Item Details:**
```sql
-- SQL requires 3 joins:
SELECT * FROM items i
JOIN item_info ii ON i.item_id = ii.item_id
JOIN item_modifiers im ON i.item_id = im.item_id
JOIN item_restrictions ir ON i.item_id = ir.item_id
WHERE i.item_id = ?;
```
In MongoDB, all fields are on the item document itself.

---

## 2. Collection Design

The final MongoDB schema uses **10 main collections** plus supporting reference and event collections.

### Decision Framework

For each relationship, the guiding questions are:

- **Is the data always queried together?** → Lean toward embed
- **Can the embedded array grow without bound?** → Lean toward reference (avoid the 16MB doc limit)
- **Is the child data updated frequently and independently?** → Lean toward reference
- **Is it a one-to-one or bounded one-to-few relationship?** → Almost always embed

---

### Collection 1: `accounts`

**Purpose:** Stores player account credentials and session history.

**Embedded:**
- `account_history` as an array of `{ log_on, log_off }` objects

**Why embed account_history?** Session logs are always loaded with the account for authentication and session tracking. The number of login entries grows slowly over time and won't realistically approach the 16MB limit for a 750-account dataset.

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "username": "dragonslayer99",
  "email": "player@example.com",
  "password_hash": "...",
  "account_history": [
    { "log_on": ISODate("2024-11-01T14:00:00Z"), "log_off": ISODate("2024-11-01T16:30:00Z") },
    { "log_on": ISODate("2024-11-02T09:00:00Z"), "log_off": ISODate("2024-11-02T11:00:00Z") }
  ]
}
```

---

### Collection 2: `characters`

**Purpose:** The central player-facing entity. Needs to load fully and fast at login.

**Embedded:**
- `info` subdocument: `{ account_id, active, creation_date, last_played, time_played }`
- `stats` array: `[{ stat_name, amount }]`
- `equipped` array: `[{ slot_name, item_id, durability_lost_last_combat }]`

**Referenced (by ID):**
- `class_id`, `race_id`, `specialization_id`, `level_id`, `inventory_id`

**Why this split?** `info`, `stats`, and `equipped` are always needed together at login — embedding them means one document fetch returns everything needed to render the character. The referenced fields (`class_id`, `race_id`, etc.) point to lookup collections that rarely change and are shared across many characters; referencing avoids duplicating that data in every character document.

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "name": "Aerindel",
  "class_id": ObjectId("..."),
  "race_id": ObjectId("..."),
  "specialization_id": ObjectId("..."),
  "level_id": ObjectId("..."),
  "inventory_id": ObjectId("..."),
  "info": {
    "account_id": ObjectId("..."),
    "active": true,
    "creation_date": ISODate("2024-01-15T00:00:00Z"),
    "last_played": ISODate("2024-11-10T20:00:00Z"),
    "time_played": 14320
  },
  "stats": [
    { "stat_name": "strength", "amount": 45 },
    { "stat_name": "agility", "amount": 38 }
  ],
  "equipped": [
    { "slot_name": "main_hand", "item_id": ObjectId("..."), "durability_lost_last_combat": 3 },
    { "slot_name": "chest", "item_id": ObjectId("..."), "durability_lost_last_combat": 1 }
  ]
}
```

---

### Collection 3: `items`

**Purpose:** Represents individual item instances (not templates) in the game world.

**Embedded (denormalized from item_info and related tables):**
- Item info fields directly on the document: `name`, `durability_max`, `sell_price`, `repair_cost`, `two_handed`
- `rarity` subdocument: `{ name, color }`
- `modifiers` array: `[{ stat_name, amount, type }]`
- `restrictions` array: `[{ type, class_id?, race_id?, specialization_id?, level_id?, quest_id? }]`

**Referenced:**
- `inventory_id` (nullable — null when item is equipped or being traded)

**Why denormalize item_info into items?** When an item is displayed — in a player's inventory, in a tooltip, or in a trade window — all its properties are needed simultaneously. Embedding eliminates a join. The trade-off (discussed in Section 3) is that template changes must be propagated to all instances.

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "name": "Iron Longsword",
  "durability_max": 100,
  "sell_price": 50,
  "repair_cost": 10,
  "two_handed": false,
  "inventory_id": ObjectId("..."),
  "rarity": { "name": "Common", "color": "#FFFFFF" },
  "modifiers": [
    { "stat_name": "attack_power", "amount": 25, "type": "flat" }
  ],
  "restrictions": [
    { "type": "class", "class_id": ObjectId("...") },
    { "type": "level", "level_id": ObjectId("...") }
  ]
}
```

---

### Collection 4: `guilds`

**Purpose:** Represents player guilds with their membership and role structure.

**Embedded:**
- `roles` array: `[{ role_id, name, can_invite, can_kick, can_edit_roles, can_edit_motd }]`
- `members` array, each member embedding:
  - `character_id`, `role_name`
  - `activity` array: `[{ day, time_played }]`
  - `member_history` array: `[{ role_name, time }]`

**Referenced:**
- `chat_id` (the guild's associated chat channel)

**Why embed members?** The guild roster, roles, and activity are almost always viewed together on the guild management screen. This collapses what was a 3-table join (`guilds` + `guild_members` + `guild_roles`) into one document read. The trade-off (discussed in Section 3) is larger documents for active guilds.

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "name": "Crimson Order",
  "motd": "For the Alliance!",
  "chat_id": ObjectId("..."),
  "roles": [
    { "role_id": 1, "name": "Officer", "can_invite": true, "can_kick": true, "can_edit_roles": false, "can_edit_motd": true }
  ],
  "members": [
    {
      "character_id": ObjectId("..."),
      "role_name": "Officer",
      "activity": [
        { "day": ISODate("2024-11-10T00:00:00Z"), "time_played": 120 }
      ],
      "member_history": [
        { "role_name": "Member", "time": ISODate("2024-09-01T00:00:00Z") }
      ]
    }
  ]
}
```

---

### Collection 5: `chats`

**Purpose:** Represents chat channels (guild chat, zone chat, private messages, etc.).

**Embedded:**
- `filters` array: `[{ word, filtered_word }]` — only populated when `is_private = false`
- `members` array of `character_id` values

**Not embedded:**
- Message history → **see Collection 6**

**Referenced:**
- Message history accessed via `chat_id` on the `messages` collection

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "name": "Zone: Ashenvale",
  "is_private": false,
  "filters": [
    { "word": "badword", "filtered_word": "****" }
  ],
  "members": [ ObjectId("..."), ObjectId("..."), ObjectId("...") ]
}
```

---

### Collection 6: `messages`

**Purpose:** Stores all chat messages as individual documents.

**Fields:** `chat_id`, `sender_id`, `message`, `time`

**Why a separate collection?** This is one of the most important architectural decisions in the schema. A single active chat channel could accumulate thousands of messages. If messages were embedded in the `chats` document, a busy public channel could easily breach MongoDB's 16MB document limit, and loading a chat room would require loading the entire message history. Keeping messages in their own collection allows:
- Independent pagination and querying (`db.messages.find({ chat_id: ... }).sort({ time: -1 }).limit(50)`)
- Efficient writes (just insert a new document, no array update)
- No risk of hitting the document size limit

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "chat_id": ObjectId("..."),
  "sender_id": ObjectId("..."),
  "message": "Is anyone running the dungeon tonight?",
  "time": ISODate("2024-11-10T21:15:00Z")
}
```

---

### Collection 7: `zones`

**Purpose:** Represents geographic zones within the game world.

**Embedded:**
- `mobs` array: `[{ mob_id, amount }]`

**Referenced:**
- `region_id`

**Why embed zone_mobs?** When a zone loads, the game engine needs to know which mobs spawn there and in what quantities — it always queries this together. Embedding eliminates the `zone_mobs` junction table entirely.

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "name": "Darkwood Forest",
  "region_id": ObjectId("..."),
  "mobs": [
    { "mob_id": ObjectId("..."), "amount": 15 },
    { "mob_id": ObjectId("..."), "amount": 8 }
  ]
}
```

---

### Collection 8: `npcs`

**Purpose:** Represents non-player characters including vendors, quest givers, and ambient characters.

**Embedded (denormalized):**
- `dialogs` array of dialog strings (the actual text, not IDs)
- `role` name (denormalized from `npc_roles`)
- `race` name (denormalized from `races`)

**Referenced:**
- `zone_id`

**Why embed dialog strings instead of IDs?** When a player interacts with an NPC, the game immediately needs to display the dialog text. Storing IDs would require a second lookup. Since dialog text is fixed per NPC and doesn't change often, embedding the strings directly trades a small amount of storage for faster reads. The role and race names are denormalized for the same reason — rendering an NPC's nameplate doesn't need a lookup join.

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "name": "Merchant Brogdan",
  "zone_id": ObjectId("..."),
  "role": "Vendor",
  "race": "Dwarf",
  "dialogs": [
    "What can I get for ye, adventurer?",
    "Finest wares in the kingdom, I tell ye!",
    "Come back anytime!"
  ]
}
```

---

### Collection 9: `quests`

**Purpose:** Represents quest definitions including rewards and eligibility restrictions.

**Embedded:**
- `reward` subdocument: `{ item_id, gold, experience }`
- `restrictions` array: `[{ type, class_id?, race_id?, specialization_id?, level_id?, quest_id? }]`

**Referenced:**
- `npc_id` (the NPC who gives this quest)

**Why embed the reward?** Every quest has exactly one reward — it's a one-to-one relationship. Embedding a subdocument is cleaner and faster than a separate join. The restrictions array collapses what were multiple rows in a SQL junction table into a self-describing array on the quest document.

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "title": "The Missing Shipment",
  "description": "Find the lost trading post supplies...",
  "npc_id": ObjectId("..."),
  "reward": {
    "item_id": ObjectId("..."),
    "gold": 200,
    "experience": 1500
  },
  "restrictions": [
    { "type": "level", "level_id": ObjectId("...") },
    { "type": "quest", "quest_id": ObjectId("...") }
  ]
}
```

---

### Collection 10: `combats`

**Purpose:** Records individual combat encounters between a character and a mob.

**Embedded:**
- `time` and `result` (`"win"` or `"loss"`) directly on the document
- `equipment_used` array: `[{ equipped_id, durability_lost }]`

**Referenced:**
- `character_id`, `mob_id`

**Why embed combat_info?** Time and result are single scalar values — they belong directly on the document, not in a separate table. Equipment usage during combat is always reviewed together with the combat record (for durability calculations and post-combat summaries), so embedding it makes sense.

**Example document structure:**
```json
{
  "_id": ObjectId("..."),
  "character_id": ObjectId("..."),
  "mob_id": ObjectId("..."),
  "time": ISODate("2024-11-10T19:45:00Z"),
  "result": "win",
  "equipment_used": [
    { "equipped_id": ObjectId("..."), "durability_lost": 5 },
    { "equipped_id": ObjectId("..."), "durability_lost": 2 }
  ]
}
```

---

### Reference / Lookup Collections

These collections are small, rarely updated, and referenced by ID from other documents. They do not need complex embedding.

| Collection | Key Fields | Notes |
|---|---|---|
| `races` | `name`, `description`, `modifiers: [{stat_name, amount, type}]` | Shared by characters and NPCs |
| `classes` | `name`, `description`, `modifiers: [{stat_name, amount, type}]` | Referenced by characters and items |
| `specializations` | `name`, `allowed_classes: [class_name]`, `modifiers: [{stat_name, amount, type}]` | Referenced by characters |
| `levels` | `level_id`, `xp_requirement` | Threshold lookup table |
| `mobs` | `name`, `is_boss`, `loot_table: {min_gold, max_gold, min_exp, max_exp, items: [{item_id, drop_rate}]}` | Loot table embedded since always read together |
| `regions` | `name`, `faction_name`, `zones: [zone_id]` | Small — 5 records |
| `player_trades` | `sender_id`, `receiver_id`, `item_id`, `gold`, `time` | Append-only event log |
| `npc_trades` | `character_id`, `npc_id`, `item_id`, `gold`, `time` | Append-only event log |
| `quest_history` | `character_id`, `quest_id`, `reward_id`, `state`, `time` | Append-only event log |

> **Note on loot tables:** In the original SQL schema, `loot_tables` and `loot_table_items` are separate tables. In MongoDB, the loot table is embedded directly inside each mob document because loot data is always read together with mob data during a combat resolution event. There is no use case for querying loot table items independently of their mob.

> **Note on trade collections:** The original SQL `trade_info` table used nullable foreign keys — either `player_trade_id` or `npc_trade_id` was NULL depending on trade type. This is a code smell in SQL and awkward to query. MongoDB allows a clean split into two purpose-specific collections with no nullable fields.

---

## 3. Design Trade-offs

Every embedding vs. reference decision involves trade-offs. The following are the most significant ones in this schema.

---

### Trade-off 1: Embedding Guild Members Creates Large Documents

**Decision:** Embed `guild_members`, `guild_roles`, `guild_member_activity`, and `member_history` inside each guild document.

**Benefit:** Loading a guild dashboard requires one document read instead of a 3-table join. Role lookups during permission checks are in-memory.

**Cost:** In an active guild with many members who have long histories, the guild document can grow large. If a guild had 500 members each with 365 days of activity records, that document could become unwieldy.

**Mitigation:** For this project's scale (50 guilds, 2,000 characters), this is not a realistic concern. In a production game, you would likely move `activity` logs to a separate time-series collection after a rolling window (e.g., keep only 30 days embedded).

---

### Trade-off 2: Embedding Character Stats/Info Optimizes Login

**Decision:** Embed `character_info`, `character_stats`, and `equipped_items` inside the character document.

**Benefit:** Game login requires a complete character profile. One document read replaces what was a 5-table join in SQL.

**Cost:** If you need to query stats independently across all characters (e.g., "find all characters with strength > 50"), you must scan every character document and filter the embedded `stats` array. This is less efficient than a separate indexed `character_stats` collection.

**Why the trade-off is worth it here:** The character profile load is the most frequent operation in the entire system. Cross-character stat queries are an infrequent analytics operation. Optimizing for the hot path is the right call.

---

### Trade-off 3: Messages NOT Embedded in Chats

**Decision:** Keep message history as a separate `messages` collection, referenced by `chat_id`.

**Benefit:** Prevents document size limit violations (MongoDB's hard cap is 16MB per document). Allows efficient message queries with pagination. Inserts are simple appends rather than array pushes on the chat document.

**Cost:** Reading a chat room now requires two operations: fetch the `chats` document for metadata/members, then query `messages` for recent history. This is a deliberate reference relationship.

**The rule of thumb this illustrates:** Never embed data that can grow without a practical upper bound.

---

### Trade-off 4: Item Info Denormalized into Each Item Instance

**Decision:** Copy `item_info` fields (`name`, `durability_max`, `sell_price`, `repair_cost`, `two_handed`) directly onto each item document, rather than referencing a shared template.

**Benefit:** Displaying an item in an inventory, tooltip, or trade window requires no additional lookup. All item data is in one document.

**Cost:** If an item template changes (e.g., the sell price of "Iron Longsword" is rebalanced), every single item instance in the `items` collection must be updated. With 2,500 items, this means a multi-document update operation. In a live game, this could be thousands of documents across multiple updates over the game's lifecycle.

**Why it's still acceptable:** Item reads vastly outnumber item template changes. A patch that changes item stats happens rarely; players checking their inventory happens constantly.

---

### Trade-off 5: Dialog Embedded as Strings (Denormalized)

**Decision:** Embed NPC dialog as an array of string literals rather than referencing a separate dialog table.

**Benefit:** When a player interacts with an NPC, the dialog is immediately available — no secondary lookup required. The in-memory document has everything needed to render the interaction.

**Cost:** If the same dialog phrase is shared across multiple NPCs (e.g., a generic greeting), it must be stored redundantly in each NPC document. Updating a shared phrase requires updating every NPC that uses it.

**Why it's acceptable:** NPC dialog text for a capstone project is fixed content. Redundant storage of a few string values is trivial at this scale, and the read simplicity is worth it.

---

### Trade-off 6: Restriction Junction Tables Collapsed into Embedded Arrays

**Decision:** Replace SQL junction tables (`item_restrictions`, `quest_restrictions`) with embedded `restrictions` arrays on each item/quest document.

**Benefit:** In SQL, checking whether a character can equip an item required joining `items` → `item_restrictions` → filtering by type. In MongoDB, this is a single document read followed by an in-application filter on the embedded array.

**Cost:** If you need to find all quests that are restricted to a specific class, you must scan the entire `quests` collection filtering on the nested array. In SQL, you could query the `quest_restrictions` table directly with an index on `class_id`.

**Mitigation:** For 101 quests, a collection scan is trivially fast. If the quest count grew to millions, you would add an index on `restrictions.class_id`.

---

### Trade-off 7: Loot Table Items Embedded in Mobs

**Decision:** Embed the loot table (min/max gold, min/max exp, item drop rates) directly inside each mob document.

**Benefit:** During combat resolution, the game engine needs the mob's stats and its loot table simultaneously. Embedding eliminates a join that would otherwise occur at the end of every combat encounter — the most frequent write event in the game.

**Cost:** Loot tables cannot be easily shared between mobs. If two mob types share an identical loot table, the data must be duplicated in both documents.

**Why it's acceptable:** Mob loot tables in MMORPGs are intentionally mob-specific. Shared loot tables are the exception, not the rule, and the read performance gain is significant.

---

## 4. SQL vs MongoDB Differences

This section highlights the key conceptual differences between the relational SQL model and the MongoDB document model, illustrated with examples from this project.

---

### 4.1 JOINs vs Embedded Documents

In relational databases, data is normalized into separate tables to eliminate redundancy, and JOINs reassemble it at query time. This is elegant for storage but costly at scale.

In MongoDB, related data that is always accessed together is stored together. The document model lets you design your schema around your **query patterns** rather than normalization rules.

| Scenario | SQL | MongoDB |
|---|---|---|
| Load character at login | 5-table JOIN | Single `findOne` |
| Load guild dashboard | 3-table JOIN | Single `findOne` |
| Load item tooltip | 3-table JOIN | Single `findOne` |
| Load zone mob spawns | 2-table JOIN | Single `findOne` |
| Load NPC dialog | 2-table JOIN | Single `findOne` |

---

### 4.2 Junction Tables vs Nested Arrays

SQL uses junction tables to represent many-to-many or one-to-many relationships because tables are flat. MongoDB documents can contain arrays, so most junction tables simply disappear.

| SQL Junction Table | MongoDB Equivalent |
|---|---|
| `account_history` | `account.account_history[]` |
| `character_stats` | `character.stats[]` |
| `equipped_items` | `character.equipped[]` |
| `guild_roles` | `guild.roles[]` |
| `guild_members` | `guild.members[]` |
| `chat_filters` | `chat.filters[]` |
| `chat_members` | `chat.members[]` |
| `zone_mobs` | `zone.mobs[]` |
| `npc_dialog` | `npc.dialogs[]` |
| `item_modifiers` | `item.modifiers[]` |
| `item_restrictions` | `item.restrictions[]` |
| `quest_restrictions` | `quest.restrictions[]` |
| `loot_table_items` | `mob.loot_table.items[]` |
| `combat_equipment` | `combat.equipment_used[]` |

---

### 4.3 Nullable Foreign Keys vs Clean Separate Collections

The original SQL `trade_info` table used nullable foreign keys to represent two different kinds of trades:

```sql
-- SQL: one table, two nullable FK columns
trade_info (
  trade_id    INT PRIMARY KEY,
  player_trade_id  INT NULL REFERENCES player_trades(trade_id),
  npc_trade_id     INT NULL REFERENCES npc_trades(trade_id)
)
```

This forces the application to check which FK is not null on every read. It also makes it impossible to enforce referential integrity cleanly.

In MongoDB, this pattern is replaced with two purpose-specific collections:

- **`player_trades`**: `{ sender_id, receiver_id, item_id, gold, time }`
- **`npc_trades`**: `{ character_id, npc_id, item_id, gold, time }`

Each collection has a clear, consistent schema. No null checks needed. Queries against player trades never touch NPC trades and vice versa.

---

### 4.4 Schema Flexibility

SQL enforces a fixed schema at the database level — every row in a table must have the same columns. MongoDB collections have no enforced schema by default; documents in the same collection can have different shapes.

**Practical example from this schema:** The `restrictions` arrays on items and quests use a flexible structure:

```json
{ "type": "class",           "class_id": ObjectId("...") }
{ "type": "level",           "level_id": ObjectId("...") }
{ "type": "race",            "race_id": ObjectId("...") }
{ "type": "prerequisite_quest", "quest_id": ObjectId("...") }
```

In SQL, this would require either separate columns for each restriction type (sparse columns with many NULLs) or a polymorphic association pattern. In MongoDB, the varying fields per restriction type are natural.

---

### 4.5 No Referential Integrity Enforcement

This is an important limitation to understand. SQL foreign key constraints prevent orphaned records automatically:

```sql
-- SQL prevents this at the DB level:
INSERT INTO equipped_items (character_id, item_id)
VALUES (999, 1); -- ERROR: character 999 doesn't exist
```

MongoDB does not enforce referential integrity. If a character is deleted, the application must:
- Remove the character from any guilds they belong to
- Clean up their entries in `quest_history`
- Handle their combat records appropriately
- Unassign any items they owned

**Implication for this project:** The application layer must implement cascading delete logic and orphan prevention. This is a standard responsibility in MongoDB application design.

---

### 4.6 Summary Comparison Table

| Concept | SQL (Relational) | MongoDB (Document) |
|---|---|---|
| Data organization | Tables with rows and columns | Collections with JSON-like documents |
| Relationships | Foreign keys + JOINs | Embedding or `_id` references |
| One-to-many | Junction table | Embedded array |
| Schema enforcement | Rigid (DDL-defined) | Flexible (application-defined) |
| Referential integrity | Enforced by DB engine | Enforced by application code |
| Query language | SQL (`SELECT ... JOIN ...`) | MQL (`find`, `aggregate`) |
| Null handling | NULL columns for missing data | Fields simply absent from document |
| Optimization strategy | Normalize first, index joins | Design around query patterns |
| Horizontal scaling | Difficult (sharding is complex) | Built-in sharding support |

---

*Document version 1.0 — Part 1: Planning complete.*

---

## 5. Step-by-Step Migration Instructions

These instructions cover Parts 2, 3, and 4 of the assignment.

---

### Part 2: Export from MySQL

Make sure your `capstone_mmorpg` database is running and populated before starting.

**Option A — Export the whole database as a SQL dump (backup/reference):**
```bash
mysqldump -u root -p capstone_mmorpg > capstone_mmorpg_backup.sql
```
This gives you a full backup. You won't import this into MongoDB — it's just a safety net.

**Option B — Export individual tables as CSV (optional manual approach):**
```sql
SELECT * FROM accounts
INTO OUTFILE 'C:/temp/accounts.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```
Repeat for any table you want to inspect in Excel. This is optional — the Python script (Part 3) reads directly from MySQL, so you don't need CSV files unless you want to inspect the data manually first.

---

### Part 3: Run the Python Migration Script

**Step 1 — Install the required Python libraries.**
Open a terminal (or your WSL/Ubuntu shell) and run:
```bash
pip install mysql-connector-python pymongo
```

**Step 2 — Open `migrate_to_mongodb.py` in VS Code.**
Edit the connection settings at the very top of the file (lines 21–27):
```python
MYSQL_HOST     = 'localhost'
MYSQL_USER     = 'root'
MYSQL_PASSWORD = ''          # <-- put your MySQL password here if you have one
MYSQL_DB       = 'capstone_mmorpg'

MONGO_URI = 'mongodb://localhost:27017/'
MONGO_DB  = 'capstone_nosql'
```

**Step 3 — Make sure both database servers are running.**
- MySQL: should already be running if your capstone DB works normally.
- MongoDB: open a terminal and run `mongod` (or start it from MongoDB Compass).

**Step 4 — Run the script:**
```bash
python migrate_to_mongodb.py
```
You will see output like:
```
Migrating races...
Inserted 9 documents into races.
Migrating classes...
Inserted 7 documents into classes.
...
Migration complete.
```
If you see an error, the most common causes are:
- Wrong MySQL password → update `MYSQL_PASSWORD`
- MongoDB not running → start `mongod` first
- Missing library → re-run `pip install mysql-connector-python pymongo`

---

### Part 4: Import and Verify in MongoDB Compass

**Step 1 — Open MongoDB Compass.**
If you don't have it installed: [https://www.mongodb.com/try/download/compass](https://www.mongodb.com/try/download/compass)

**Step 2 — Connect to your local server.**
In the connection bar at the top, enter:
```
mongodb://localhost:27017
```
Click **Connect**.

**Step 3 — Find your database.**
In the left sidebar you should see `capstone_nosql`. Click it to expand and see all 18 collections.

**Step 4 — Browse and verify.**
Click any collection (e.g. `characters`) to see the documents. Check the document count in the top right matches what the script printed.

Key collections to verify:
| Collection | Expected approx. count |
|---|---|
| accounts | 750 |
| characters | 2,000 |
| items | 2,500 |
| guilds | 50 |
| npcs | 1,000 |
| messages | varies (5–13 per chat) |
| combats | ~10,000 (5 per character) |

**Step 5 — If you need to re-run the script.**
The script will fail on a second run because documents already exist. To reset:
1. In Compass, right-click `capstone_nosql` → **Drop Database**
2. Re-run the Python script

---

### Part 5: Preparing for Your Group Evaluation

Bring the following to your instructor meeting:

1. **This migration plan document** — walk through Section 2 (Collection Design) and Section 3 (Trade-offs)
2. **MongoDB Compass open** — show the collection list, then open and scroll through at least:
   - `characters` — point out the embedded `stats`, `info`, and `equipped` arrays
   - `guilds` — point out the nested `members` array with `activity` inside each member
3. **Be ready to explain one trade-off** — a good one is: *"We embedded character stats directly in the character document instead of a separate collection because every time a player logs in the game needs all of that data at once, so one document read replaces a 5-table JOIN."*
