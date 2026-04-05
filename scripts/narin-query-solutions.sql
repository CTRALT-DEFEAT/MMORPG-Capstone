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

SELECT *
FROM restrictions r
JOIN item_restrictions ir ON ir.restriction_id = r.restriction_id
AND ir.item_id = 501;