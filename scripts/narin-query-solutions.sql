-- Active: 1771873789211@@127.0.0.1@3306@capstone_mmorpg
USE capstone_mmorpg;
-- Top 5 characters with most gold earned in the last 30 days.

SELECT character_id, SUM(gold) AS total_gold
FROM (
    SELECT qh.character_id, qr.gold AS gold
    FROM quest_history qh 
    JOIN quest_rewards qr ON qh.reward_id = qr.reward_id
    WHERE qh.state = 'completed'
    AND qh.time >= DATE_SUB(NOW(), INTERVAL 30 DAY)

    UNION ALL

    SELECT pt.reciever_id AS character_id, t.gold AS gold
    FROM player_trades pt
    JOIN trade_info t ON pt.trade_id = t.player_trade_id
    WHERE t.time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    AND t.gold > 0

    UNION ALL

    SELECT nt.character_id, t.gold AS gold
    FROM npc_trades nt
    JOIN trade_info t ON nt.trade_id = t.npc_trade_id
    WHERE t.time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    AND t.gold > 0
) AS gold_sources
GROUP BY character_id
ORDER BY total_gold DESC
LIMIT 5;

-- Show names of all the quests completed by the character "Thalor"
SELECT q.name
FROM quests q
JOIN quest_history qh ON q.quest_id = qh.quest_id
WHERE qh.state = 'completed'
AND qh.character_id = (
    SELECT character_id
    FROM characters
    WHERE name = 'Thalor'
);

-- Determine(true or false) whether "Thalor" can equip the item  "Axe of the first moon"
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
