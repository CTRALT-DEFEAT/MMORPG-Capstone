INSERT INTO member_activity (member_id, log_on, log_off)
SELECT
    member_id,
    NOW() - INTERVAL FLOOR(RAND()*7) DAY,
    NOW()
FROM guild_members;
