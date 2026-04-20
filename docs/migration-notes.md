# MMORPG Capstone — MongoDB Migration

This folder contains the migration project for converting the `capstone_mmorpg` MySQL database to MongoDB.

---

## Files

| File | Purpose |
|---|---|
| `migrate_to_mongodb.py` | Python script that reads from MySQL and writes to MongoDB |
| `migration_plan.md` | Part 1 — schema analysis, collection design, trade-offs, SQL vs NoSQL comparison, and step-by-step instructions |
| `bonus_queries.md` | Bonus — 5 SQL queries converted to MongoDB with explanations |
| `README.md` | This file — project overview and bug fix log |

---

## How to Run the Migration

1. Make sure MySQL/MariaDB is running and `capstone_mmorpg` is populated
2. Make sure MongoDB is running (`net start MongoDB` in admin PowerShell)
3. Install dependencies:
```bash
pip install mysql-connector-python pymongo
```
4. Edit the credentials at the top of `migrate_to_mongodb.py` if needed:
```python
MYSQL_PASSWORD = 'your_password_here'
```
5. Run the script:
```bash
python migrate_to_mongodb.py
```
6. Open MongoDB Compass → connect to `mongodb://localhost:27017` → browse `capstone_nosql`

> The script automatically drops and recreates all collections on each run, so it is safe to re-run at any time.

---

## Collections Created (18 total)

| Collection | Documents | Notes |
|---|---|---|
| accounts | 750 | Login history embedded as array |
| races | 9 | Modifiers embedded |
| classes | 7 | Modifiers embedded |
| specializations | 15 | Modifiers + allowed classes embedded |
| characters | 2,000 | Stats, info, and equipped items embedded |
| items | 2,500 | Rarity, modifiers, restrictions embedded |
| guilds | 50 | Roles and members (with activity) embedded |
| chats | 1,055 | Members and filters embedded |
| messages | 49 | Flat — high volume kept separate |
| regions | 5 | Faction name denormalized in |
| zones | 114 | Mob spawn list embedded |
| npcs | 1,000 | Dialog strings embedded |
| quests | 101 | Reward and restrictions embedded |
| mobs | 500 | Full loot table embedded |
| combats | 10,000 | Result and equipment used embedded |
| player_trades | 1,750 | Trade info embedded |
| npc_trades | 1,750 | Trade info embedded |
| quest_history | 58,668 | Flat event log |

---

## Bug Fix Log

During development, 12 bugs were identified and fixed in the migration script. All were caused by mismatches between the generated script and the actual schema column names.

---

### Bug 1 — Wrong JOIN column on `inventories`
**Error:** `Unknown column 'i.character_id' in 'ON'`
**Cause:** `inventories` has no `character_id` column. The link goes through `characters.inventory_id`.
```python
# Wrong
LEFT JOIN inventories i ON c.character_id = i.character_id
# Fixed
LEFT JOIN inventories i ON c.inventory_id = i.inventory_id
```

---

### Bug 2 — Typo in column name `ammount`
**Error:** `Unknown column 'cs.amount' in 'SELECT'`
**Cause:** The `character_stats` table has a typo in the schema — the column is `ammount` (two m's).
```python
# Wrong
SELECT s.name AS stat, cs.amount
# Fixed
SELECT s.name AS stat, cs.ammount
```

---

### Bug 3 — `name` column is in `item_info`, not `items`
**Error:** `Unknown column 'i.name' in 'SELECT'`
**Cause:** `items` only has `item_id`, `inventory_id`, and `info_id`. The item name lives in `item_info`.
```python
# Wrong
i.name,
LEFT JOIN item_info ii ON i.item_id = ii.item_id
# Fixed
ii.name,
LEFT JOIN item_info ii ON i.info_id = ii.info_id
```

---

### Bug 4 — `guild_members` has no `role` column
**Error:** `Unknown column 'gm.role' in 'SELECT'`
**Cause:** `guild_members` stores `role_id` only. The role name requires a JOIN to `roles`.
```python
# Wrong
SELECT gm.member_id, gm.character_id, gm.role
FROM guild_members gm
# Fixed
SELECT gm.member_id, gm.character_id, ro.name AS role
FROM guild_members gm
JOIN roles ro ON gm.role_id = ro.role_id
```

---

### Bug 5 — Same issue in `member_history`
**Error:** Same as Bug 4
**Cause:** `member_history` also stores `role_id`, not the role name.
```python
# Wrong
SELECT role, time FROM member_history WHERE member_id = %s
# Fixed
SELECT ro.name AS role, mh.time
FROM member_history mh
JOIN roles ro ON mh.role_id = ro.role_id
WHERE mh.member_id = %s
```

---

### Bug 6 — Wrong JOIN column on `factions`
**Error:** `Unknown column 'r.faction_id' in 'ON'`
**Cause:** `regions` has no `faction_id`. It is `factions` that holds a `region_id` foreign key pointing back to `regions`.
```python
# Wrong
LEFT JOIN factions f ON r.faction_id = f.faction_id
# Fixed
LEFT JOIN factions f ON r.region_id = f.region_id
```

---

### Bug 7 — Wrong column name in `dialogs` table
**Error:** `Unknown column 'd.text' in 'SELECT'`
**Cause:** The dialog text column is named `dialog`, not `text`.
```python
# Wrong
SELECT d.text
# Fixed
SELECT d.dialog
```

---

### Bug 8 — Non-existent `dialog_order` column
**Error:** `Unknown column 'nd.dialog_order' in 'ORDER BY'`
**Cause:** `npc_dialog` has no `dialog_order` column.
```python
# Wrong
ORDER BY nd.dialog_order
# Fixed — line removed entirely
```

---

### Bug 9 — Typo in `player_trades` column name
**Error:** `Unknown column 'pt.receiver_id' in 'SELECT'`
**Cause:** The schema spells it `reciever_id` (missing the second 'e').
```python
# Wrong
pt.receiver_id,
# Fixed
pt.reciever_id,
```

---

### Bug 10 — Wrong JOIN column on `trade_info` (player trades)
**Error:** `Unknown column 'ti.trade_id' in 'ON'`
**Cause:** `trade_info` has no generic `trade_id`. It uses two separate nullable columns: `player_trade_id` and `npc_trade_id`.
```python
# Wrong
LEFT JOIN trade_info ti ON pt.trade_id = ti.trade_id
# Fixed
LEFT JOIN trade_info ti ON pt.trade_id = ti.player_trade_id
```

---

### Bug 11 — Same issue for NPC trades
**Error:** Same as Bug 10
```python
# Wrong
LEFT JOIN trade_info ti ON nt.trade_id = ti.trade_id
# Fixed
LEFT JOIN trade_info ti ON nt.trade_id = ti.npc_trade_id
```

---

### Bug 12 — Duplicate key error on re-runs
**Error:** `E11000 duplicate key error`
**Cause:** Partial data from a crashed run stayed in MongoDB. Re-running tried to insert the same `_id` values again.
**Fix:** Added a cleanup loop at the start of `main()` that drops all 18 collections before every run.

---

## Bug Summary

| # | Collection | Root Cause |
|---|---|---|
| 1 | characters | Wrong JOIN column |
| 2 | characters | Typo in schema (`ammount`) |
| 3 | items | Column in wrong table |
| 4 | guilds | Missing JOIN to get role name |
| 5 | guilds | Missing JOIN in history query |
| 6 | regions | Reversed FK direction |
| 7 | npcs | Wrong column name (`text` vs `dialog`) |
| 8 | npcs | Non-existent column in ORDER BY |
| 9 | player_trades | Typo in schema (`reciever`) |
| 10 | player_trades | Nullable FK design misunderstood |
| 11 | npc_trades | Same as #10 |
| 12 | all | No cleanup between runs |

