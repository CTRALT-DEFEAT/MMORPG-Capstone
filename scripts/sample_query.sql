SELECT g.guild_id, COUNT(*) AS activity_count
FROM member_activity ma
JOIN guild_members gm ON ma.member_id = gm.member_id
JOIN guilds g ON gm.guild_id = g.guild_id
WHERE ma.log_on >= NOW() - INTERVAL 7 DAY
GROUP BY g.guild_id
ORDER BY activity_count DESC
LIMIT 5;
