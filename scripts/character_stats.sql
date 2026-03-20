INSERT INTO character_stats (character_id, stat_id, amount)
SELECT
    c.character_id,
    s.stat_id,
    FLOOR(5 + RAND()*20)
FROM characters c
CROSS JOIN stats s;
