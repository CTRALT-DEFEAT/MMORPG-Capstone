INSERT INTO quest_transaction (quest_id, character_id, state, time)
SELECT
    FLOOR(1 + RAND()*10),
    character_id,
    'completed',
    NOW()
FROM characters
LIMIT 300;
