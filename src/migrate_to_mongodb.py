"""
MySQL to MongoDB Migration Script — MMORPG Database
=====================================================
Requirements: pip install mysql-connector-python pymongo

This script reads data from a MySQL database (capstone_mmorpg) and migrates it
into a MongoDB database (capstone_nosql) using an embedded/denormalized document
model suited for NoSQL.

Each migrate_* function handles one MongoDB collection. Related tables are joined
and/or embedded so that MongoDB documents are self-contained and efficient to query.
"""

import mysql.connector
from pymongo import MongoClient
import datetime

# ---------------------------------------------------------------------------
# Connection defaults — change these to match your environment
# ---------------------------------------------------------------------------
MYSQL_HOST     = 'localhost'
MYSQL_USER     = 'root'
MYSQL_PASSWORD = '121781'
MYSQL_DB       = 'capstone_mmorpg'

MONGO_URI = 'mongodb://localhost:27017/'
MONGO_DB  = 'capstone_nosql'
# ---------------------------------------------------------------------------


# ===========================================================================
# Utility helpers
# ===========================================================================

def to_str(value):
    """
    Convert datetime, date, timedelta, and bytearray/bytes values to plain
    strings so they are JSON-serialisable in MongoDB.
    Everything else is returned unchanged (including None → null in MongoDB).
    """
    if isinstance(value, (datetime.datetime, datetime.date)):
        return value.isoformat()
    if isinstance(value, datetime.timedelta):
        # Store as total seconds or as HH:MM:SS string — we use HH:MM:SS
        total_seconds = int(value.total_seconds())
        h = total_seconds // 3600
        m = (total_seconds % 3600) // 60
        s = total_seconds % 60
        return f"{h:02d}:{m:02d}:{s:02d}"
    if isinstance(value, (bytearray, bytes)):
        # BIT(1) columns come back as bytearray — treat as bool
        return bool(int.from_bytes(value, 'big'))
    return value


def row_to_dict(cursor, row):
    """
    Zip a cursor's column names with a result row, converting special types
    along the way. Returns an ordinary Python dict.
    """
    columns = [col[0] for col in cursor.description]
    return {col: to_str(val) for col, val in zip(columns, row)}


def get_modifiers(cursor, entity_type, entity_id):
    """
    Generic helper: fetch modifiers for any entity (race, class, spec, item).

    Tables involved:
        <entity_type>_modifiers  — join table between entity and modifiers
        modifiers                — stores the numeric amount and modifier type
        stats                    — stores the stat name (Strength, Dex, …)

    Returns a list of dicts: [{"stat": "...", "amount": ..., "type": "..."}]
    """
    query = f"""
        SELECT s.name AS stat, m.amount, m.type
        FROM   {entity_type}_modifiers em
        JOIN   modifiers m ON em.modifier_id = m.modifier_id
        JOIN   stats     s ON m.stat_id      = s.stat_id
        WHERE  em.{entity_type}_id = %s
    """
    cursor.execute(query, (entity_id,))
    return [{"stat": r[0], "amount": r[1], "type": r[2]} for r in cursor.fetchall()]


def get_restrictions(cursor, entity_type, entity_id):
    """
    Generic helper: fetch restrictions for any entity (item, quest, spec).

    Tables involved:
        <entity_type>_restrictions  — join table between entity and restrictions
        restrictions                — stores restriction type and optional class_id

    Returns a list of dicts: [{"type": "...", "class_id": ...}]
    """
    query = f"""
        SELECT r.type, r.class_id
        FROM   {entity_type}_restrictions er
        JOIN   restrictions r ON er.restriction_id = r.restriction_id
        WHERE  er.{entity_type}_id = %s
    """
    cursor.execute(query, (entity_id,))
    results = []
    for row in cursor.fetchall():
        d = {"type": row[0]}
        if row[1] is not None:
            d["class_id"] = row[1]
        results.append(d)
    return results


# ===========================================================================
# Migration functions — one per MongoDB collection
# ===========================================================================

def migrate_accounts(mysql_cur, mongo_db):
    """
    Collection: accounts
    Tables: accounts  +  account_history

    Each account document embeds its full login history as an array so we
    never need a separate query to look up when someone logged in/out.
    """
    print("Migrating accounts...")

    mysql_cur.execute("SELECT account_id, username, creation_date, max_characters, current_characters FROM accounts")
    accounts = mysql_cur.fetchall()

    docs = []
    for row in accounts:
        account_id, username, creation_date, max_chars, cur_chars = row

        # Fetch login/logout history for this account
        mysql_cur.execute(
            "SELECT log_on, log_off FROM account_history WHERE account_id = %s",
            (account_id,)
        )
        history = [
            {"log_on": to_str(r[0]), "log_off": to_str(r[1])}
            for r in mysql_cur.fetchall()
        ]

        docs.append({
            "_id":                account_id,
            "username":           username,
            "creation_date":      to_str(creation_date),
            "max_characters":     max_chars,
            "current_characters": cur_chars,
            "login_history":      history,
        })

    if docs:
        mongo_db.accounts.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into accounts")


def migrate_characters(mysql_cur, mongo_db):
    """
    Collection: characters
    Tables: characters + character_info + character_stats + equipped_items
            + slots + stats + classes + races + specializations + levels
            + inventories

    Core character data stays at the top level.  Per-stat rows from
    character_stats are embedded as an array; equipped-item rows from
    equipped_items are embedded as an array.  Foreign keys to class, race,
    specialization, and level are kept as IDs (references) for look-ups.
    """
    print("Migrating characters...")

    mysql_cur.execute("""
        SELECT c.character_id,
               c.name,
               c.class_id,
               c.race_id,
               c.specialization_id,
               c.level_id,
               c.gold_balance,
               c.experience,
               i.max_size        AS inventory_max_size,
               ci.account_id,
               ci.active,
               ci.creation_date,
               ci.last_played,
               ci.time_played
        FROM   characters     c
        LEFT JOIN character_info ci ON c.character_id = ci.character_id
        LEFT JOIN inventories    i  ON c.inventory_id = i.inventory_id
    """)
    characters = mysql_cur.fetchall()
    col_names  = [d[0] for d in mysql_cur.description]

    docs = []
    for row in characters:
        r = dict(zip(col_names, row))
        char_id = r["character_id"]

        # --- embedded stats ---
        mysql_cur.execute("""
            SELECT s.name AS stat, cs.ammount
            FROM   character_stats cs
            JOIN   stats s ON cs.stat_id = s.stat_id
            WHERE  cs.character_id = %s
        """, (char_id,))
        stats = [{"stat": x[0], "amount": x[1]} for x in mysql_cur.fetchall()]

        # --- embedded equipped items ---
        mysql_cur.execute("""
            SELECT sl.name AS slot, ei.item_id
            FROM   equipped_items ei
            JOIN   slots sl ON ei.slot_id = sl.slot_id
            WHERE  ei.character_id = %s
        """, (char_id,))
        equipped = [{"slot": x[0], "item_id": x[1]} for x in mysql_cur.fetchall()]

        docs.append({
            "_id":                char_id,
            "name":               r["name"],
            "class_id":           r["class_id"],
            "race_id":            r["race_id"],
            "specialization_id":  r["specialization_id"],
            "level_id":           r["level_id"],
            "gold_balance":       r["gold_balance"],
            "experience":         r["experience"],
            "inventory_max_size": r["inventory_max_size"],
            "info": {
                "account_id":    r["account_id"],
                "active":        to_str(r["active"]),   # BIT(1) → bool
                "creation_date": to_str(r["creation_date"]),
                "last_played":   to_str(r["last_played"]),
                "time_played":   to_str(r["time_played"]),
            },
            "stats":    stats,
            "equipped": equipped,
        })

    if docs:
        mongo_db.characters.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into characters")


def migrate_items(mysql_cur, mongo_db):
    """
    Collection: items
    Tables: items + item_info + item_rarities + item_modifiers + modifiers
            + stats + item_restrictions + restrictions

    Rarity is embedded as a sub-document; modifiers and restrictions each
    become embedded arrays so a single document tells us everything about
    an item.
    """
    print("Migrating items...")

    mysql_cur.execute("""
        SELECT i.item_id,
               i.inventory_id,
               i.info_id,
               ii.name,
               ii.durability_max,
               ii.sell_price,
               ii.repair_cost,
               ii.two_handed,
               ir.name  AS rarity_name,
               ir.color AS rarity_color
        FROM   items      i
        LEFT JOIN item_info     ii ON i.info_id    = ii.info_id
        LEFT JOIN item_rarities ir ON ii.rarity_id = ir.rarity_id
    """)
    items     = mysql_cur.fetchall()
    col_names = [d[0] for d in mysql_cur.description]

    docs = []
    for row in items:
        r       = dict(zip(col_names, row))
        item_id = r["item_id"]
        info_id = r.get("info_id", item_id)

        modifiers    = get_modifiers(mysql_cur, "item", info_id)
        restrictions = get_restrictions(mysql_cur, "item", info_id)

        docs.append({
            "_id":          item_id,
            "inventory_id": r["inventory_id"],
            "name":         r["name"],
            "durability_max": r["durability_max"],
            "sell_price":   r["sell_price"],
            "repair_cost":  r["repair_cost"],
            "two_handed":   to_str(r["two_handed"]),  # BIT(1) → bool
            "rarity": {
                "name":  r["rarity_name"],
                "color": r["rarity_color"],
            } if r["rarity_name"] else None,
            "modifiers":    modifiers,
            "restrictions": restrictions,
        })

    if docs:
        mongo_db.items.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into items")


def migrate_guilds(mysql_cur, mongo_db):
    """
    Collection: guilds
    Tables: guilds + guild_roles + roles + guild_members + characters
            + member_activity + member_history

    A guild document embeds its full role list and full member list.  Each
    member sub-document itself embeds daily activity and role-change history
    so that guild management queries need only touch one collection.
    """
    print("Migrating guilds...")

    mysql_cur.execute("""
        SELECT guild_id, chat_id, creation_date, motd, member_limit
        FROM   guilds
    """)
    guilds    = mysql_cur.fetchall()
    col_names = [d[0] for d in mysql_cur.description]

    docs = []
    for row in guilds:
        r        = dict(zip(col_names, row))
        guild_id = r["guild_id"]

        # --- embedded roles ---
        mysql_cur.execute("""
            SELECT gr.role_id,
                   ro.name,
                   ro.can_invite,
                   ro.can_kick,
                   ro.can_edit_roles,
                   ro.can_edit_motd
            FROM   guild_roles gr
            JOIN   roles ro ON gr.role_id = ro.role_id
            WHERE  gr.guild_id = %s
        """, (guild_id,))
        roles = []
        for role_row in mysql_cur.fetchall():
            roles.append({
                "role_id":       role_row[0],
                "name":          role_row[1],
                "can_invite":    to_str(role_row[2]),
                "can_kick":      to_str(role_row[3]),
                "can_edit_roles": to_str(role_row[4]),
                "can_edit_motd": to_str(role_row[5]),
            })

        # --- embedded members (with nested activity + history) ---
        mysql_cur.execute("""
            SELECT gm.member_id, gm.character_id, ro.name AS role
            FROM   guild_members gm
            JOIN   roles ro ON gm.role_id = ro.role_id
            WHERE  gm.guild_id = %s
        """, (guild_id,))
        members = []
        for mem_row in mysql_cur.fetchall():
            member_id, character_id, role = mem_row

            # daily activity for this member
            mysql_cur.execute(
                "SELECT day, time_played FROM member_activity WHERE member_id = %s",
                (member_id,)
            )
            activity = [
                {"day": to_str(a[0]), "time_played": to_str(a[1])}
                for a in mysql_cur.fetchall()
            ]

            # role-change history for this member
            mysql_cur.execute("""
                SELECT ro.name AS role, mh.time
                FROM   member_history mh
                JOIN   roles ro ON mh.role_id = ro.role_id
                WHERE  mh.member_id = %s
            """, (member_id,))
            history = [
                {"role": h[0], "time": to_str(h[1])}
                for h in mysql_cur.fetchall()
            ]

            members.append({
                "member_id":    member_id,
                "character_id": character_id,
                "role":         role,
                "activity":     activity,
                "history":      history,
            })

        docs.append({
            "_id":          guild_id,
            "chat_id":      r["chat_id"],
            "creation_date": to_str(r["creation_date"]),
            "motd":         r["motd"],
            "member_limit": r["member_limit"],
            "roles":        roles,
            "members":      members,
        })

    if docs:
        mongo_db.guilds.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into guilds")


def migrate_chats(mysql_cur, mongo_db):
    """
    Collection: chats
    Tables: chats + chat_members + chat_filters + filters

    Members are stored as a plain array of character IDs.
    Filters (banned / replaced words) are only embedded for public chats
    (is_private = 0); private chats have no filter list.
    """
    print("Migrating chats...")

    mysql_cur.execute("SELECT chat_id, name, is_private FROM chats")
    chats     = mysql_cur.fetchall()
    col_names = [d[0] for d in mysql_cur.description]

    docs = []
    for row in chats:
        r       = dict(zip(col_names, row))
        chat_id = r["chat_id"]

        # member IDs
        mysql_cur.execute(
            "SELECT character_id FROM chat_members WHERE chat_id = %s",
            (chat_id,)
        )
        members = [m[0] for m in mysql_cur.fetchall()]

        # filters — only for public chats
        is_private = to_str(r["is_private"])   # BIT(1) → bool
        filters    = []
        if not is_private:
            mysql_cur.execute("""
                SELECT f.word, f.filtered_word
                FROM   chat_filters cf
                JOIN   filters f ON cf.filter_id = f.filter_id
                WHERE  cf.chat_id = %s
            """, (chat_id,))
            filters = [
                {"word": x[0], "filtered_word": x[1]}
                for x in mysql_cur.fetchall()
            ]

        docs.append({
            "_id":        chat_id,
            "name":       r["name"],
            "is_private": is_private,
            "members":    members,
            "filters":    filters,
        })

    if docs:
        mongo_db.chats.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into chats")


def migrate_messages(mysql_cur, mongo_db):
    """
    Collection: messages
    Tables: message_history  (no embedding needed — already flat)

    Each row becomes one document.  We use the MySQL primary key as _id.
    """
    print("Migrating messages...")

    mysql_cur.execute("""
        SELECT message_id, chat_id, sender_id, message, time
        FROM   message_history
    """)
    rows = mysql_cur.fetchall()

    docs = [
        {
            "_id":       r[0],
            "chat_id":   r[1],
            "sender_id": r[2],
            "message":   r[3],
            "time":      to_str(r[4]),
        }
        for r in rows
    ]

    if docs:
        mongo_db.messages.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into messages")


def migrate_zones(mysql_cur, mongo_db):
    """
    Collection: zones
    Tables: zones + zone_mobs

    Each zone document embeds the list of mobs that spawn in it (mob_id +
    amount) so that zone population queries don't need a join.
    """
    print("Migrating zones...")

    mysql_cur.execute("SELECT zone_id, region_id, name FROM zones")
    zones     = mysql_cur.fetchall()
    col_names = [d[0] for d in mysql_cur.description]

    docs = []
    for row in zones:
        r       = dict(zip(col_names, row))
        zone_id = r["zone_id"]

        mysql_cur.execute(
            "SELECT mob_id, amount FROM zone_mobs WHERE zone_id = %s",
            (zone_id,)
        )
        mobs = [{"mob_id": m[0], "amount": m[1]} for m in mysql_cur.fetchall()]

        docs.append({
            "_id":       zone_id,
            "region_id": r["region_id"],
            "name":      r["name"],
            "mobs":      mobs,
        })

    if docs:
        mongo_db.zones.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into zones")


def migrate_npcs(mysql_cur, mongo_db):
    """
    Collection: npcs
    Tables: npcs + npc_roles + races + npc_dialog + dialogs

    Role name and race name are denormalized into the document.  Dialog
    strings (not IDs) are embedded as a plain string array — no need to
    look up a separate dialogs collection at runtime.
    """
    print("Migrating npcs...")

    mysql_cur.execute("""
        SELECT n.npc_id,
               n.zone_id,
               n.name,
               nr.name       AS role,
               rc.name       AS race,
               n.description,
               n.killable
        FROM   npcs      n
        LEFT JOIN npc_roles nr ON n.role_id = nr.role_id
        LEFT JOIN races     rc ON n.race_id = rc.race_id
    """)
    npcs      = mysql_cur.fetchall()
    col_names = [d[0] for d in mysql_cur.description]

    docs = []
    for row in npcs:
        r      = dict(zip(col_names, row))
        npc_id = r["npc_id"]

        # dialog strings
        mysql_cur.execute("""
            SELECT d.dialog
            FROM   npc_dialog nd
            JOIN   dialogs    d  ON nd.dialog_id = d.dialog_id
            WHERE  nd.npc_id = %s
        """, (npc_id,))
        dialogs = [x[0] for x in mysql_cur.fetchall()]

        docs.append({
            "_id":         npc_id,
            "zone_id":     r["zone_id"],
            "name":        r["name"],
            "role":        r["role"],
            "race":        r["race"],
            "description": r["description"],
            "killable":    to_str(r["killable"]),  # BIT(1) → bool
            "dialogs":     dialogs,
        })

    if docs:
        mongo_db.npcs.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into npcs")


def migrate_quests(mysql_cur, mongo_db):
    """
    Collection: quests
    Tables: quests + quest_rewards + items + quest_restrictions + restrictions

    Reward details are embedded as a sub-document.  Class/level restrictions
    are embedded as an array.
    """
    print("Migrating quests...")

    mysql_cur.execute("""
        SELECT q.quest_id,
               q.npc_id,
               q.name,
               q.description,
               q.repeatable,
               q.location,
               qr.item_id,
               qr.gold,
               qr.experience,
               qr.reward_id
        FROM   quests        q
        LEFT JOIN quest_rewards qr ON q.quest_id = qr.quest_id
    """)
    quests    = mysql_cur.fetchall()
    col_names = [d[0] for d in mysql_cur.description]

    docs = []
    for row in quests:
        r        = dict(zip(col_names, row))
        quest_id = r["quest_id"]

        restrictions = get_restrictions(mysql_cur, "quest", quest_id)

        docs.append({
            "_id":        quest_id,
            "npc_id":     r["npc_id"],
            "name":       r["name"],
            "description": r["description"],
            "repeatable": to_str(r["repeatable"]),  # BIT(1) → bool
            "location":   r["location"],
            "reward": {
                "reward_id":  r["reward_id"],
                "item_id":    r["item_id"],
                "gold":       r["gold"],
                "experience": r["experience"],
            } if r["reward_id"] else None,
            "restrictions": restrictions,
        })

    if docs:
        mongo_db.quests.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into quests")


def migrate_mobs(mysql_cur, mongo_db):
    """
    Collection: mobs
    Tables: mobs + loot_tables + loot_table_items

    The loot table (gold range, exp range, and item drop list) is embedded
    as a sub-document so loot calculations need only read this one document.
    """
    print("Migrating mobs...")

    mysql_cur.execute("""
        SELECT m.mob_id,
               m.name,
               m.is_boss,
               lt.loot_table_id,
               lt.min_gold,
               lt.max_gold,
               lt.min_exp,
               lt.max_exp
        FROM   mobs         m
        LEFT JOIN loot_tables lt ON m.loot_table_id = lt.loot_table_id
    """)
    mobs      = mysql_cur.fetchall()
    col_names = [d[0] for d in mysql_cur.description]

    docs = []
    for row in mobs:
        r      = dict(zip(col_names, row))
        mob_id = r["mob_id"]

        # loot items
        loot_items = []
        if r["loot_table_id"] is not None:
            mysql_cur.execute("""
                SELECT item_id, drop_rate
                FROM   loot_table_items
                WHERE  loot_table_id = %s
            """, (r["loot_table_id"],))
            loot_items = [
                {"item_id": x[0], "drop_rate": float(x[1])}
                for x in mysql_cur.fetchall()
            ]

        loot_table = None
        if r["loot_table_id"] is not None:
            loot_table = {
                "min_gold": r["min_gold"],
                "max_gold": r["max_gold"],
                "min_exp":  r["min_exp"],
                "max_exp":  r["max_exp"],
                "items":    loot_items,
            }

        docs.append({
            "_id":        mob_id,
            "name":       r["name"],
            "is_boss":    to_str(r["is_boss"]),  # BIT(1) → bool
            "loot_table": loot_table,
        })

    if docs:
        mongo_db.mobs.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into mobs")


def migrate_combats(mysql_cur, mongo_db):
    """
    Collection: combats
    Tables: combats + combat_info + combat_equipment

    Combat metadata (character, mob, time, result) and the equipment used
    during that combat (with durability loss) are combined into one document.
    """
    print("Migrating combats...")

    mysql_cur.execute("""
        SELECT c.combat_id,
               c.character_id,
               c.mob_id,
               ci.time,
               ci.result
        FROM   combats      c
        LEFT JOIN combat_info ci ON c.combat_id = ci.combat_id
    """)
    combats   = mysql_cur.fetchall()
    col_names = [d[0] for d in mysql_cur.description]

    docs = []
    for row in combats:
        r         = dict(zip(col_names, row))
        combat_id = r["combat_id"]

        mysql_cur.execute("""
            SELECT equipped_id, durability_lost
            FROM   combat_equipment
            WHERE  combat_id = %s
        """, (combat_id,))
        equipment_used = [
            {"equipped_id": x[0], "durability_lost": x[1]}
            for x in mysql_cur.fetchall()
        ]

        docs.append({
            "_id":            combat_id,
            "character_id":   r["character_id"],
            "mob_id":         r["mob_id"],
            "time":           to_str(r["time"]),
            "result":         r["result"],
            "equipment_used": equipment_used,
        })

    if docs:
        mongo_db.combats.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into combats")


def migrate_player_trades(mysql_cur, mongo_db):
    """
    Collection: player_trades
    Tables: player_trades + trade_info

    Each trade is one document.  trade_info holds the item, gold, and
    timestamp so we join it in to make the document self-contained.
    """
    print("Migrating player_trades...")

    mysql_cur.execute("""
        SELECT pt.trade_id,
               pt.sender_id,
               pt.reciever_id,
               ti.item_id,
               ti.gold,
               ti.time
        FROM   player_trades pt
        LEFT JOIN trade_info ti ON pt.trade_id = ti.player_trade_id
    """)
    rows = mysql_cur.fetchall()

    docs = [
        {
            "_id":         r[0],
            "sender_id":   r[1],
            "receiver_id": r[2],
            "item_id":     r[3],
            "gold":        r[4],
            "time":        to_str(r[5]),
        }
        for r in rows
    ]

    if docs:
        mongo_db.player_trades.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into player_trades")


def migrate_npc_trades(mysql_cur, mongo_db):
    """
    Collection: npc_trades
    Tables: npc_trades + trade_info

    Same pattern as player_trades but with character_id + npc_id instead
    of two character IDs.
    """
    print("Migrating npc_trades...")

    mysql_cur.execute("""
        SELECT nt.trade_id,
               nt.character_id,
               nt.npc_id,
               ti.item_id,
               ti.gold,
               ti.time
        FROM   npc_trades nt
        LEFT JOIN trade_info ti ON nt.trade_id = ti.npc_trade_id
    """)
    rows = mysql_cur.fetchall()

    docs = [
        {
            "_id":          r[0],
            "character_id": r[1],
            "npc_id":       r[2],
            "item_id":      r[3],
            "gold":         r[4],
            "time":         to_str(r[5]),
        }
        for r in rows
    ]

    if docs:
        mongo_db.npc_trades.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into npc_trades")


def migrate_quest_history(mysql_cur, mongo_db):
    """
    Collection: quest_history
    Tables: quest_history  (already flat — no embedding needed)

    Each row maps directly to a document.  We keep reward_id as a reference
    so callers can look up reward details from the quests collection if needed.
    """
    print("Migrating quest_history...")

    mysql_cur.execute("""
        SELECT history_id, character_id, quest_id, reward_id, state, time
        FROM   quest_history
    """)
    rows = mysql_cur.fetchall()

    docs = [
        {
            "_id":          r[0],
            "character_id": r[1],
            "quest_id":     r[2],
            "reward_id":    r[3],
            "state":        r[4],
            "time":         to_str(r[5]),
        }
        for r in rows
    ]

    if docs:
        mongo_db.quest_history.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into quest_history")


def migrate_races(mysql_cur, mongo_db):
    """
    Collection: races
    Tables: races + race_modifiers + modifiers + stats

    Stat modifiers (e.g. +5 Strength for Humans) are embedded as an array
    using the shared get_modifiers() helper.
    """
    print("Migrating races...")

    mysql_cur.execute("SELECT race_id, name, description FROM races")
    rows = mysql_cur.fetchall()

    docs = []
    for row in rows:
        race_id, name, description = row
        modifiers = get_modifiers(mysql_cur, "race", race_id)
        docs.append({
            "_id":         race_id,
            "name":        name,
            "description": description,
            "modifiers":   modifiers,
        })

    if docs:
        mongo_db.races.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into races")


def migrate_classes(mysql_cur, mongo_db):
    """
    Collection: classes
    Tables: classes + class_modifiers + modifiers + stats

    Same pattern as races — stat bonuses are embedded.
    """
    print("Migrating classes...")

    mysql_cur.execute("SELECT class_id, name, description FROM classes")
    rows = mysql_cur.fetchall()

    docs = []
    for row in rows:
        class_id, name, description = row
        modifiers = get_modifiers(mysql_cur, "class", class_id)
        docs.append({
            "_id":         class_id,
            "name":        name,
            "description": description,
            "modifiers":   modifiers,
        })

    if docs:
        mongo_db.classes.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into classes")


def migrate_specializations(mysql_cur, mongo_db):
    """
    Collection: specializations
    Tables: specializations + specialization_modifiers + modifiers + stats
            + specialization_restrictions + restrictions + classes

    Modifiers and restrictions are embedded.  The allowed_classes list is
    built by looking up which classes are listed in the restrictions table
    (type = 'allowed_class') and resolving their names from the classes table.
    """
    print("Migrating specializations...")

    mysql_cur.execute("SELECT specialization_id, name FROM specializations")
    rows = mysql_cur.fetchall()

    docs = []
    for row in rows:
        spec_id, name = row

        modifiers    = get_modifiers(mysql_cur, "specialization", spec_id)
        restrictions = get_restrictions(mysql_cur, "specialization", spec_id)

        # Build a human-readable allowed_classes list from restriction class_ids
        allowed_classes = []
        for res in restrictions:
            if res.get("class_id") is not None:
                mysql_cur.execute(
                    "SELECT name FROM classes WHERE class_id = %s",
                    (res["class_id"],)
                )
                result = mysql_cur.fetchone()
                if result:
                    allowed_classes.append(result[0])

        docs.append({
            "_id":             spec_id,
            "name":            name,
            "modifiers":       modifiers,
            "restrictions":    restrictions,
            "allowed_classes": allowed_classes,
        })

    if docs:
        mongo_db.specializations.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into specializations")


def migrate_regions(mysql_cur, mongo_db):
    """
    Collection: regions
    Tables: regions + factions

    The faction name is denormalized directly into the region document.
    """
    print("Migrating regions...")

    mysql_cur.execute("""
        SELECT r.region_id,
               r.name,
               f.name AS faction
        FROM   regions  r
        LEFT JOIN factions f ON r.region_id = f.region_id
    """)
    rows = mysql_cur.fetchall()

    docs = [
        {
            "_id":     r[0],
            "name":    r[1],
            "faction": r[2],
        }
        for r in rows
    ]

    if docs:
        mongo_db.regions.insert_many(docs)
    print(f"  Inserted {len(docs)} documents into regions")


# ===========================================================================
# Main entry point
# ===========================================================================

def main():
    # --- connect to MySQL ---
    print("Connecting to MySQL...")
    mysql_conn = mysql.connector.connect(
        host     = MYSQL_HOST,
        user     = MYSQL_USER,
        password = MYSQL_PASSWORD,
        database = MYSQL_DB,
    )
    mysql_cur = mysql_conn.cursor()
    print(f"  Connected to MySQL database '{MYSQL_DB}'")

    # --- connect to MongoDB ---
    print("Connecting to MongoDB...")
    mongo_client = MongoClient(MONGO_URI)
    mongo_db     = mongo_client[MONGO_DB]
    print(f"  Connected to MongoDB database '{MONGO_DB}'")

    print("\n--- Dropping existing collections (clean slate) ---")
    for col in ['accounts','races','classes','specializations','characters',
                'items','guilds','chats','messages','regions','zones',
                'npcs','quests','mobs','combats','player_trades',
                'npc_trades','quest_history']:
        mongo_db[col].drop()
    print("  Done.\n")

    print("--- Starting migration ---\n")

    # Run all migrations in a logical order (referenced collections first)
    migrate_accounts(mysql_cur, mongo_db)
    migrate_races(mysql_cur, mongo_db)
    migrate_classes(mysql_cur, mongo_db)
    migrate_specializations(mysql_cur, mongo_db)
    migrate_characters(mysql_cur, mongo_db)
    migrate_items(mysql_cur, mongo_db)
    migrate_guilds(mysql_cur, mongo_db)
    migrate_chats(mysql_cur, mongo_db)
    migrate_messages(mysql_cur, mongo_db)
    migrate_regions(mysql_cur, mongo_db)
    migrate_zones(mysql_cur, mongo_db)
    migrate_npcs(mysql_cur, mongo_db)
    migrate_quests(mysql_cur, mongo_db)
    migrate_mobs(mysql_cur, mongo_db)
    migrate_combats(mysql_cur, mongo_db)
    migrate_player_trades(mysql_cur, mongo_db)
    migrate_npc_trades(mysql_cur, mongo_db)
    migrate_quest_history(mysql_cur, mongo_db)

    print("\n--- Migration complete ---")

    # Clean up connections
    mysql_cur.close()
    mysql_conn.close()
    mongo_client.close()


if __name__ == "__main__":
    main()
