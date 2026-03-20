INSERT INTO guild_members (character_id, guild_id, role_id)
SELECT
    character_id,
    FLOOR(1 + RAND()*3),
    1
FROM characters;
