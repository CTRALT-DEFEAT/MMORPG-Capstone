
-- Crete view for challenge 1

DROP VIEW IF EXISTS gold_sources_view;

CREATE VIEW IF NOT EXISTS gold_sources_view AS
-- Player trades
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
-- NPC trades
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
-- Quest rewards
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
-- Combat gold
SELECT  
    cm.character_id,
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


-- List the top 5 characters with the most gold earned in the last 30 days.

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



-- 2. Show names of all the quests completed by the character "Thalor"
SELECT q.name
FROM quests q
JOIN quest_history qh ON q.quest_id = qh.quest_id
WHERE qh.state = 'completed'
AND qh.character_id = (
    SELECT character_id
    FROM characters
    WHERE name = 'Thalor'
);



-- 3. Determine(true or false) whether "Thalor" can equip the item  "Axe of the first moon"
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



-- 4. Which guild has the highest number of active members? Active members have had
-- at lease one play session lasting 45 minutes or longer in the last 7 day
SELECT g.guild_id, COUNT(*) AS active_players
FROM guilds g
JOIN guild_members gm ON g.guild_id = gm.guild_id
JOIN member_activity ma ON gm.member_id = ma.member_id
WHERE ma.day >= DATE_SUB(NOW(), INTERVAL 7 DAY)
AND TIMESTAMPDIFF(MINUTE,ma.time_played,NOW()) >= 45
GROUP BY g.guild_id
ORDER BY active_players DESC
LIMIT 1;


-- 5.
-- List the top 5 guilds by total experience gained by members of the “Officer” or “Guild Leader” rank. Don’t forget to account for their current level.


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


-- 6. List the top 5 guilds by total amount of play time in the last year. 
-- Remember that characters can swap between guilds, and that their play 
-- time only counts for their current guild when they play.
SELECT g.guild_id, SUM(ma.time_played) AS total_time
FROM guilds g
JOIN guild_members gm ON g.guild_id = gm.guild_id
JOIN member_activity ma ON gm.member_id = ma.member_id
WHERE ma.day >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
GROUP BY g.guild_id
ORDER BY total_time
LIMIT 5;




-- 7. List the top 5 items with the highest number of times traded.
SELECT ii.name, COUNT(i.item_id) AS times_traded
FROM item_info ii
JOIN items i ON i.info_id = ii.info_id
JOIN trade_info ti ON ti.item_id = i.item_id
GROUP BY ii.info_id
ORDER BY times_traded DESC
LIMIT 5;




-- 8. For the quest “Wrath of the Dwarven Lords”, count how many players have 
-- completed it, count how many players have it in progress (accepted but not completed), 
-- and count how many players qualify for it (having completed all the prerequisites 
-- but haven’t accepted it yet).
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



-- 9.
-- List the 5 most popular class & specialization combinations.

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


SELECT 
    c.name AS character_name
FROM message_history mh
JOIN characters c 
    ON c.character_id = mh.sender_id
WHERE mh.message LIKE '%ass%';





























