# MMORPG-Capstone
> The projects goal was to create a MySQL database modeled after a
> massively multiplayer online role-playing game (MMORPG).

## The Business Needs:
* Players create characters that belong to their account.
    * Players may have multiple characters.
    * Characters have attributes like race, class, level, experience, and           specialization.
        * Specialization is like a “class upgrade”. Not all characters will             have one, but the ones they’re allowed to select are dependent on             their class.
        * Characters may only have up to one specialization.
        * There is some specialization overlap. Characters with the “Hunter”            or “Warrior” class are both allowed to choose the “Ranger”                    specialization, but Hunters aren’t allowed to choose the                      “Berserker” specialization because it’s only available to Warriors.
* Characters can belong to a guild.
    * Guilds have names, messages of the day, and ranks.
    * All guilds have a “Guild leader” rank, which can only be held by one          member.
    * The other ranks are “Officer”, “Member”, and “Recruit”. Any number of         guild members can have these ranks.
    * Guild membership and rank history should be preserved.
* Characters gain experience points (XP) through game play, which is used to    determine their level.
    * Each level has a fixed amount of XP required to attain the next level.
    * XP is earned through quests and combat.
    * Each XP-gaining activity should be tracked as a timestamped event for         auditing purposes.
* Quests can be accepted and completed by characters.
    * (For purposes of simplicity, you may assume that the only possible            quest states are “unaccepted”, “accepted”, and “completed”. If you want       to expand that list to include others such as “failed”, “repeatable”,         or others, you may but there’s no extra credit for it.)
    * Quests have names and descriptions.
    * To accept a quest, the character may have had to complete one or more         other quests first.
    * All quests are dispensed by a Non-Player-Character (NPC).
        * NPCs have names and coordinates for their location.
    * Quests may have rewards (XP and/or gold and/or items).

* Characters collect and equip items.
    * Items may be equipped into specific “equipment slots”, such as “head”,        “chest”, “legs”, or “main hand”.
    * Items have a current and maximum durability. The current durability may       never exceed the maximum. Current durability is consumed through item         usage (such as combat).
    * Items may have one or more requirements and/or restrictions to equip,         such as having a specific race, class, specialization, minimum or             maximum level.
    * Sample requirement: “Pendant of Avarice” may only be equipped by              characters of the Goblin race.
    * Sample restriction: “Holy Sword” may not be equipped by players with          the Necromancer class or Death Knight specialization.
      Items cannot be equipped if they have zero current durability.
* Items can be traded between characters or sold to NPCs.
    * All items have a fixed price that an NPC will pay for it. All NPCs pay        the same amount.
    * The game stores a complete record of trade history for all items: an          items’ entire ownership history should be traceable from its creation         to its disappearance.
    * Items can come from quests as rewards, from slain enemies as loot, or         purchased from NPCs.
* Gold is a currency in the game. It is a non-negative whole number.
    * Players may earn it from quest rewards, slain monster loot, or trade.
    * Players may spend it on item repairs or trade.
    * All transactions must be recorded.
* Players may send chat messages.
    * Chat messages may be direct from player to player or sent to multi-           player channels such as “guild chat” or “everyone currently in the city       of Urdia”.
    * A complete history of chat messages must be kept and easily searchable        for offensive or abusive content.

## The ERD:
> With the set of business needs as a guide our first task was to design and
> create an ERD to base our database off of.

![ERD](/docs/ERD/ERD.png)

> [!NOTE]
> We chose to color code the ERD for improved readability, with the color of
> lines being the same as the parent tables.
>
> The groups of the ERD
> | Color     | Group              |
> | --------- | -------------- | 
> | Light Pink | Guilds | 
> | Purple | Chats |  
> | Dark Green | NPC's/Mobs/Quests | 
> | Light Green | Regions/Zones/Factions |
> | Gold | Items/Loot_Tables/Rewards |  
> | Orange | Trades |
> | Brown | Restrictions | 
> | Light Purple | Modifiers | 
> | Turquoise | Combat | 
> | Blue |Accounts/Characters/Character_Attributes |
>

## Generation Script:
[The Generation Script](scripts/gen.sql)

> The generaction script starts by creating the database
> then creates all 51 tables.
> next we create all 42 procedures for randomly generating data
> The last section of the generation script is calling all the procedures
> as well as adding insert statements for data that isnt randomly generated
> (i.e. classes, races etc)

ADD HIGHLIGHTED SECTIONS

## Query Challenges:
> The final step of the project was to complete 10 queries.

#### List the top 5 characters with the most gold earned in the last 30 days.
```MySQL
-- A view containing all gold sources
DROP VIEW IF EXISTS gold_sources_view;
CREATE VIEW IF NOT EXISTS gold_sources_view AS
-- Gets gold from player trades
SELECT 
    pt.reciever_id AS character_id,
    ti.gold AS total_gold,
    ti.time AS event_time,
    'player_trade' AS source
FROM player_trades pt
JOIN trade_info ti 
    ON pt.trade_id = ti.player_trade_id
WHERE ti.gold IS NOT NULL

UNION ALL
-- Gets gold from npc trades
SELECT 
    nt.character_id,
    ti.gold,
    ti.time,
    'npc_trade'
FROM npc_trades nt
JOIN trade_info ti 
    ON nt.trade_id = ti.npc_trade_id
WHERE ti.gold IS NOT NULL

UNION ALL
-- Gets gold from quests
SELECT  
    qh.character_id,
    qr.gold,
    qh.time,
    'quest'
FROM quest_history qh
JOIN quest_rewards qr 
    ON qh.quest_id = qr.quest_id
WHERE qh.state = 'completed'
  AND qr.gold IS NOT NULL

UNION ALL
-- Gets gold from combats
SELECT  
    cm.character_id,
    -- Using min_gold instead of randomizing
    -- between min & max gold
    lt.min_gold,
    ci.time,
    'combat'
FROM combats cm
JOIN combat_info ci
    ON ci.combat_id = cm.combat_id
JOIN mobs m
    ON cm.mob_id = m.mob_id
JOIN loot_tables lt
    ON m.loot_table_id = lt.loot_table_id
WHERE ci.result = 'win';

-- Uses the view gold_sources_view to list
-- the top 5 gold earned in 30 days
SELECT 
    c.name,
    SUM(g.total_gold) AS gold_earned
FROM characters c
JOIN gold_sources_view g
    ON c.character_id = g.character_id
WHERE g.event_time >= NOW() - INTERVAL 30 DAY
GROUP BY c.character_id, c.name
ORDER BY gold_earned DESC
LIMIT 5;
```
* Show names of all the quests completed by the character “Thalor”.
```MySQL
SELECT q.name
FROM quests q
JOIN quest_history qh ON q.quest_id = qh.quest_id
WHERE qh.state = 'completed'
AND qh.character_id = (
    SELECT character_id
    FROM characters
    WHERE name = 'Thalor'
);
```
* Determine (true or false) whether “Thalor” can equip the item “Axe of the    First Moon”.
```MySQL
SELECT 
    MIN(
        CASE 
            WHEN r.type = 'requirement' THEN
                CASE 
                    WHEN (r.class_id IS NOT NULL AND r.class_id != c.class_id) THEN 0
                    WHEN (r.specialization_id IS NOT NULL AND r.specialization_id != c.specialization_id) THEN 0
                    WHEN (r.race_id IS NOT NULL AND r.race_id != c.race_id) THEN 0
                    WHEN (r.level_id IS NOT NULL AND c.level_id < r.level_id) THEN 0
                    WHEN r.quest_id IS NOT NULL AND r.quest_id NOT IN (
                        SELECT qh.quest_id 
                        FROM quest_history qh 
                        WHERE qh.state = 'completed' AND qh.character_id = c.character_id
                    ) THEN 0
                    ELSE 1
                END
            WHEN r.type = 'restriction' THEN
                CASE 
                    WHEN (r.class_id IS NOT NULL AND r.class_id = c.class_id) THEN 0
                    WHEN (r.specialization_id IS NOT NULL AND r.specialization_id = c.specialization_id) THEN 0
                    WHEN (r.race_id IS NOT NULL AND r.race_id = c.race_id) THEN 0
                    WHEN r.quest_id IS NOT NULL AND r.quest_id IN (
                        SELECT qh.quest_id 
                        FROM quest_history qh 
                        WHERE qh.state = 'completed' AND qh.character_id = c.character_id
                    ) THEN 0
                    ELSE 1
                END
            ELSE 1
        END
    ) AS can_equip
FROM item_info i
JOIN item_restrictions ir ON i.info_id = ir.item_id
JOIN restrictions r ON ir.restriction_id = r.restriction_id
CROSS JOIN characters c
WHERE i.info_id = 501 
AND c.name = 'Thalor'
GROUP BY c.character_id, i.info_id;
```
* Which guild has the highest number of active members?  Active members have   had at least one play session lasting 45 minutes or longer in the last 7     days.
```MySQL
SELECT g.guild_id, COUNT(*) AS active_players
FROM guilds g
JOIN guild_members gm ON g.guild_id = gm.guild_id
JOIN member_activity ma ON gm.member_id = ma.member_id
WHERE ma.day >= DATE_SUB(NOW(), INTERVAL 7 DAY)
AND TIMESTAMPDIFF(MINUTE,ma.time_played,NOW()) >= 45
GROUP BY g.guild_id
ORDER BY active_players DESC
LIMIT 1;
```
* List the top 5 guilds by total experience gained by members of the           “Officer” or “Guild Leader” rank. Don’t forget to account for their          current level.
```MySQL
SELECT gm.guild_id as guild,
    SUM(
    (
    SELECT SUM(xp_requirement) 
    FROM levels l2
    WHERE l2.level_id <= c.level_id
    )
    ) AS total_guild_xp
FROM characters c
JOIN guild_members gm
    ON gm.character_id = c.character_id
WHERE gm.role_id = 3
    OR gm.role_id = 4
    GROUP BY gm.guild_id
ORDER BY total_guild_xp DESC
LIMIT 5;
```
* List the top 5 guilds by total amount of play time in the last year.         Remember that characters can swap between guilds, and that their play time    only counts for their current guild when they play.
```MySQL
SELECT g.guild_id, SUM(ma.time_played) AS total_time
FROM guilds g
JOIN guild_members gm ON g.guild_id = gm.guild_id
JOIN member_activity ma ON gm.member_id = ma.member_id
WHERE ma.day >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
GROUP BY g.guild_id
ORDER BY total_time
LIMIT 5;
```
* List the top 5 items with the highest number of times traded.
```MySQL
SELECT ii.name, COUNT(i.item_id) AS times_traded
FROM item_info ii
JOIN items i ON i.info_id = ii.info_id
JOIN trade_info ti ON ti.item_id = i.item_id
GROUP BY ii.info_id
ORDER BY times_traded DESC
LIMIT 5;
```
* For the quest “Wrath of the Dwarven Lords”, count how many players have      completed it, count how many players have it in progress (accepted but not   completed), and count how many players qualify for it (having completed      all the prerequisites but haven’t accepted it yet).
```MySQL
SELECT (
    SELECT COUNT(DISTINCT c.character_id)
    FROM characters c
    JOIN quests q ON q.name = 'Wrath of the Dwarven Lords'
    JOIN quest_restrictions qr ON qr.quest_id = q.quest_id
    JOIN restrictions r ON r.restriction_id = qr.restriction_id
    WHERE IF(
        r.type = 'requirement', 
        r.level_id IS NULL OR c.level_id >= r.level_id, 
        r.level_id IS NULL OR c.level_id < r.level_id
        )
    AND IF(
        r.type = 'requirement', 
        r.class_id IS NULL OR c.class_id = r.class_id, 
        r.class_id IS NULL OR c.class_id != r.class_id
        )
    AND IF(
        r.type = 'requirement', 
        r.specialization_id IS NULL OR c.specialization_id = r.specialization_id, 
        r.specialization_id IS NULL OR c.specialization_id != r.specialization_id
        )
    AND IF(
        r.type = 'requirement', 
        r.race_id IS NULL OR c.race_id = r.race_id, 
        r.race_id IS NULL OR c.race_id != r.race_id
        )
    AND IF(
        r.type = 'requirement',
        r.quest_id IS NULL OR r.quest_id IN(
            SELECT qh.quest_id
            FROM quest_history qh
            WHERE qh.state = 'completed' AND qh.character_id = c.character_id
        ),
        r.quest_id IS NULL OR r.quest_id NOT IN(
            SELECT qh.quest_id
            FROM quest_history qh
            WHERE qh.state = 'completed' AND qh.character_id = c.character_id
        )
    )
    AND c.character_id NOT IN (
        SELECT character_id
        FROM quest_history qh
        WHERE quest_id = (
            SELECT quest_id
            FROM quests
            WHERE name = 'Wrath of the Dwarven Lords'
        )
        AND qh.state IN ('completed','accepted')
    )
) AS can_accept,
(
    SELECT COUNT(DISTINCT c.character_id)
    FROM quest_history qh
    JOIN quests q ON qh.quest_id = q.quest_id
    JOIN characters c ON qh.character_id = c.character_id
    WHERE q.name = 'Wrath of the Dwarven Lords'
    AND qh.state = 'completed'
) AS has_completed,
(
    SELECT COUNT(DISTINCT c.character_id)
    FROM quest_history qh
    JOIN quests q ON qh.quest_id = q.quest_id
    JOIN characters c ON qh.character_id = c.character_id
    WHERE q.name = 'Wrath of the Dwarven Lords'
    AND qh.state = 'accepted'
    AND c.character_id NOT IN (
        SELECT character_id
        FROM quest_history qh
        WHERE quest_id = (
            SELECT quest_id
            FROM quests
            WHERE name = 'Wrath of the Dwarven Lords'
        )
        AND qh.state = 'completed'
    )
) AS has_accepted;
```
* List the 5 most popular class & specialization combinations.
```MySQL
SELECT 
    cl.name,
    COALESCE(sp.name, 'None') AS specialization_name,
    COUNT(*) AS popularity
FROM characters c
JOIN classes cl 
    ON c.class_id = cl.class_id
LEFT JOIN specializations sp 
    ON c.specialization_id = sp.specialization_id
GROUP BY 
    cl.name,
    sp.name
ORDER BY popularity DESC
LIMIT 5;
```
* Pick an offensive or abusive word (I’m sure you can think of a few).         Identify users that sent messages using this word.
```MySQL
SELECT 
    c.name AS character_name
FROM message_history mh
JOIN characters c 
    ON c.character_id = mh.sender_id
WHERE mh.message LIKE '%ass%';
```
[Query Solutions](scripts/submit_queries.sql)




