# Bonus MongoDB Queries
### MMORPG Database — SQL to MongoDB Conversion Reference

This document shows 5 example queries converted from MySQL to MongoDB. Each one is taken from the MMORPG capstone database. Use these as a reference when picking queries to include in your group presentation. The MongoDB versions are written so you can type them directly into the **mongosh shell** — they will also work in MongoDB Compass by pasting just the filter `{ ... }` part into the Filter box.

---

## Query 1: Find All Characters Belonging to a Specific Account

**What it does:** Returns the name, gold balance, and experience of every character linked to account ID 1.

**Original SQL:**
```sql
SELECT c.name, c.gold_balance, c.experience
FROM characters c
JOIN character_info ci ON c.character_id = ci.character_id
WHERE ci.account_id = 1;
```

**MongoDB (mongosh):**
```js
db.characters.find(
  { "info.account_id": 1 },
  { name: 1, gold_balance: 1, experience: 1 }
)
```

**Key Difference:** In SQL, account information lives in a separate `character_info` table, so you need a JOIN to connect the two. In MongoDB, that same information is stored inside the character document itself under an `info` field, so you can filter on it directly using dot notation (`"info.account_id"`). No JOIN needed.

---

## Query 2: Find All Members of a Specific Guild and Their Roles

**What it does:** Returns the character ID and role of every member in guild ID 1.

**Original SQL:**
```sql
SELECT c.name, r.name AS role
FROM guild_members gm
JOIN characters c ON gm.character_id = c.character_id
JOIN roles r ON gm.role_id = r.role_id
WHERE gm.guild_id = 1;
```

**MongoDB (mongosh):**
```js
db.guilds.find(
  { _id: 1 },
  { "members.character_id": 1, "members.role": 1 }
)
```

**Key Difference:** The SQL version requires two JOINs across three tables just to get a guild's member list. In MongoDB, the members are stored as an array inside the guild document, so you find the guild by its `_id` and project (select) only the fields you want from that array. Everything is already in one place.

---

## Query 3: Find All Repeatable Quests

**What it does:** Returns the name, description, and location of every quest that players can repeat.

**Original SQL:**
```sql
SELECT name, description, location
FROM quests
WHERE repeatable = 1;
```

**MongoDB (mongosh):**
```js
db.quests.find(
  { repeatable: true },
  { name: 1, description: 1, location: 1 }
)
```

**Key Difference:** This is one of the closest comparisons between SQL and MongoDB — the structure is nearly identical. The main difference is that SQL uses `1` (an integer) to represent a true/false value, while MongoDB uses an actual boolean (`true` or `false`). The second argument in `find()` works just like `SELECT` in SQL — it lists which fields you want back.

---

## Query 4: Find All Characters Who Have Completed a Specific Quest

**What it does:** Returns the character ID, state, and completion time for every character who has completed quest ID 5.

**Original SQL:**
```sql
SELECT DISTINCT character_id, state, time
FROM quest_history
WHERE quest_id = 5
AND state = 'completed';
```

**MongoDB (mongosh):**
```js
db.quest_history.find(
  { quest_id: 5, state: "completed" },
  { character_id: 1, state: 1, time: 1 }
)
```

**Key Difference:** In SQL, `AND` is used to combine multiple conditions. In MongoDB, you just add both conditions inside the same filter object separated by a comma — MongoDB treats them as AND automatically. You also don't need `DISTINCT` here because each quest history entry is its own document, so duplicates aren't a concern the same way they are in relational tables.

---

## Query 5: Find All Combats Where a Character Won

**What it does:** Returns the mob ID, time, and result for every combat where character ID 1 won.

**Original SQL:**
```sql
SELECT c.combat_id, c.mob_id, ci.time, ci.result
FROM combats c
JOIN combat_info ci ON c.combat_id = ci.combat_id
WHERE c.character_id = 1
AND ci.result = 'win';
```

**MongoDB (mongosh):**
```js
db.combats.find(
  { character_id: 1, result: "win" },
  { mob_id: 1, time: 1, result: 1 }
)
```

**Key Difference:** In SQL, the combat result and time are stored in a separate `combat_info` table, which requires a JOIN. In MongoDB, that information is embedded directly inside each combat document, so both conditions (`character_id` and `result`) can be filtered in one go. This is a common pattern in MongoDB — related data gets stored together so you don't have to combine tables.

---

## Discussion Points

Use these talking points during your instructor meeting to show you understand the difference between SQL and MongoDB queries:

- **JOINs vs. embedded documents:** SQL links data across multiple tables using JOINs. MongoDB avoids this by storing related data inside the same document (for example, storing `combat_info` fields directly on the combat document). This makes reads faster and queries simpler.

- **SELECT vs. projection:** In SQL you list the columns you want after `SELECT`. In MongoDB you pass a second argument to `find()` called a projection, where `1` means "include this field." The idea is the same, just written differently.

- **WHERE vs. the filter object:** SQL uses a `WHERE` clause to filter rows. MongoDB uses a filter object (the first argument in `find()`) where each key-value pair is a condition. Multiple conditions in the same object are treated as AND automatically.

- **Data types matter more in MongoDB:** SQL often stores true/false values as `0` and `1` integers. MongoDB stores them as actual booleans (`true`/`false`). Using the wrong type in your query (like `1` instead of `true`) will cause the query to return no results, so it's important to match the type stored in the document.

- **One document, one record:** In a relational database, a single "thing" (like a guild with its members) can be spread across several tables. In MongoDB, the goal is to store everything about that thing in one document. This is why queries in MongoDB are often shorter and don't need JOINs — the data is already together.
