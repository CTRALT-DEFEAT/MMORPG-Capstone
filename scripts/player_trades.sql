INSERT INTO player_trade (character1_id, character2_id, time)
SELECT
    FLOOR(1 + RAND()*500),
    FLOOR(1 + RAND()*500),
    NOW()
FROM characters
LIMIT 200;
