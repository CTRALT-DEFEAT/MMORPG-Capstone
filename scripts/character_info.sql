INSERT INTO character_info (account_id, character_id, active, create_date, last_played, time_played)
SELECT
    FLOOR(1 + RAND()*250),
    character_id,
    1,
    NOW(),
    NOW(),
    FLOOR(RAND()*10000)
FROM characters;
