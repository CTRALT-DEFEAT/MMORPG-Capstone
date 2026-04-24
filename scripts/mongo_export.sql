-- Active: 1767971538787@@127.0.0.1@3306@capstone_mmorpg


-- Trade Tables   WORKS

SELECT JSON_OBJECT(
    'trade_info', ti.info_id,
    'player_trades', JSON_OBJECT(
    'player_trades', pt.trade_id,
    'sender_id', pt.sender_id,
    'reciever_id', pt.reciever_id
    ),

    'npc_trade_id', JSON_OBJECT(
    'trade_id', nt.trade_id,
    'npc_id', nt.npc_id
    ),
    'item_id', ti.item_id,
    'gold', ti.gold,
    'time', ti.time
)
AS trade_data
FROM trade_info ti
JOIN player_trades pt
    ON pt.trade_id = ti.info_id
JOIN npc_trades nt
    ON nt.trade_id = ti.info_id
INTO OUTFILE 'C:\\data\\_exports\\trades.jsonl'
LINES TERMINATED BY '\n';


-- Guild Tables

SELECT JSON_OBJECT(
    'guilds_id', g.guild_id,
    'chat_id', g.chat_id,
    'creation_date', g.creation_date,
    'motd', g.motd,
    'member_limit', g.member_limit,
    'guild_members', JSON_OBJECT(
        'member_id', gm.member_id,
        'role_id', gm.role_id,
        'guild_id', gm.guild_id,
        'character_id', gm.character_id
    ),
    'member_activity', JSON_OBJECT(
        'activity_id', ma.activity_id,
        'member_id', ma.member_id,
        'day', ma.day,
        'time_played', ma.time_played
    ),
    'member_history', JSON_OBJECT(
        'member_history', mh.member_history_id,
        'role_id', mh.role_id,
        'member_id', mh.member_id,
        'time', mh.time
    ),
    'roles', JSON_OBJECT(
        'role_id', r.role_id,
        'name', r.name,
        'can_invite', r.can_invite,
        'can_kick', r.can_kick,
        'can_edit_roles', r.can_edit_roles,
        'can_edit_motd', r.can_edit_motd
    ),
    'guild_roles', JSON_OBJECT(
        'role_id', gr.role_id,
        'guild_id', gr.guild_id
    )
)
AS guild_info
FROM guilds g
JOIN guild_members gm
    ON gm.guild_id = g.guild_id
JOIN guild_roles gr
    ON gm.role_id = gr.role_id
JOIN roles r
    ON gr.role_id = r.role_id
JOIN member_history mh
    ON mh.member_id = gm.member_id
JOIN member_activity ma
    ON gm.member_id = ma.member_id
INTO OUTFILE 'C:\\data\\_exports\\guilds.jsonl'
LINES TERMINATED BY '\n';

-- chats

SELECT JSON_OBJECT(
    'chat_id', c.chat_id,
    'name', c.name,
    'is_private', CASE WHEN c.is_private = 1 THEN 'True' ELSE 'False' END,
    'chat_filters', JSON_OBJECT(
        'filter_id', cf.filter_id,
        'chat_id', cf.chat_id
    ),
    'filters', JSON_OBJECT(
        'filter_id', f.filter_id,
        'word', f.word,
        'filtered_word', f.filtered_word
    ),
    'chat_members', JSON_OBJECT(
        'chat_id', cm.chat_id,
        'character_id', cm.character_id
    ),
    'message_history', JSON_OBJECT(
        'message_id', mh.message_id,
        'chat_id', mh.chat_id,
        'sender_id', mh.sender_id,
        'message', REPLACE(mh.message, '"', '\\"'),
        'time', mh.time
    )
)
AS chat_data
FROM chats c
JOIN chat_filters cf
    ON c.chat_id = cf.chat_id
JOIN filters f
    ON f.filter_id = cf.filter_id
JOIN chat_members cm
    ON cm.chat_id = c.chat_id
JOIN message_history mh
    ON mh.chat_id = c.chat_id
INTO OUTFILE 'C:\\data\\_exports\\chats.jsonl'
LINES TERMINATED BY '\n';


-- characters   WORKS

SELECT JSON_OBJECT(
    'character_info_id', ci.character_id,
    'character_id', JSON_OBJECT(
        'character_id', c.character_id,
        'class_id', JSON_OBJECT(
            'class_id', cl.class_id,
            'name', cl.name,
            'description', cl.description
        ),
        'specialization_id', JSON_OBJECT(
            'specialization_id', s.specialization_id,
            'name', s.name
        ),
        'race_id', JSON_OBJECT(
            'race_id', r.race_id,
            'name', r.name,
            'description', r.description
        ),
        'level_id', JSON_OBJECT(
            'level_id', l.level_id,
            'xp_requirement', l.xp_requirement
        ),
        'inventory_id', JSON_OBJECT(
            'inventory_id', i.inventory_id,
            'max_size', i.max_size
        ),
        'name', c.name,
        'gold_balance', c.gold_balance,
        'experience', c.experience
    ),
    'account_id', JSON_OBJECT(
        'account_id', a.account_id,
        'account_history', JSON_OBJECT(
            'history_id', ah.history_id,
            'account_id', ah.account_id,
            'log_on', ah.log_on,
            'log_off', ah.log_off
        ),
        'name', a.username,
        'creation_date', a.creation_date,
        'max_characters', a.max_characters,
        'current_characters', a.current_characters
    ),
    'active', CASE WHEN ci.active = 1 THEN 'True' ELSE 'False' END,
    'creation_date', ci.creation_date,
    'last_played', ci.last_played,
    'time_played', ci.time_played
    
) AS account_character_attributes
FROM character_info ci
JOIN accounts a
    ON a.account_id = ci.account_id
JOIN account_history ah
    ON ah.account_id = a.account_id
JOIN characters c
    ON c.character_id = ci.character_id
JOIN classes cl 
    ON cl.class_id = c.class_id
JOIN specializations s 
    ON s.specialization_id = c.specialization_id
JOIN races r 
    ON r.race_id = c.race_id
JOIN levels l 
    ON l.level_id = c.level_id
JOIN inventories i 
    ON i.inventory_id = c.inventory_id
INTO OUTFILE 'C:\\data\\_exports\\characters.jsonl'
LINES TERMINATED BY '\n';

-- combat

SELECT JSON_OBJECT(
    'combat_id', c.combat_id,
    'character_id', c.character_id,
    'mob_id', c.mob_id,
    'combat_info', JSON_OBJECT(
        'info_id', ci.info_id,
        'combat_id', ci.combat_id,
        'time', ci.time,
        'result', ci.result
    ),
    'combat_equiptment', JSON_OBJECT(
        'equipped_id', ce.equipped_id,
        'combat_id', ce.combat_id,
        'durability_lost', ce.durability_lost
    )
) AS combat_info
FROM combats c
JOIN combat_info ci
    ON ci.combat_id = c.combat_id
JOIN combat_equipment ce 
    ON ce.combat_id = c.combat_id
INTO OUTFILE 'C:\\data\\_exports\\combat.jsonl'
LINES TERMINATED BY '\n';



-- npcs

SELECT JSON_OBJECT(
    'npc_id', n.npc_id,
    'zone_id', n.zone_id,
    'role_id', n.role_id,
    'race_id', n.race_id,
    'name', n.name,
    'description', n.description,
    'killable', n.killable,
    'npc_roles', JSON_OBJECT(
        'role_id', nr.role_id,
        'name', nr.name
    ),
    'npc_dialog', JSON_OBJECT(
        'dialog_id', nd.dialog_id,
        'npc_id', nd.npc_id
    ),
    'dialogs', JSON_OBJECT(
        'dialog_id', d.dialog_id,
        'dialog', d.dialog
    )
)
AS npcs
FROM npcs n
JOIN npc_roles nr
    ON nr.role_id = n.role_id
JOIN npc_dialog nd
    ON nd.npc_id = n.npc_id
JOIN dialogs d
    ON nd.dialog_id =  d.dialog_id
INTO OUTFILE 'C:\\data\\_exports\\npcs.jsonl'
LINES TERMINATED BY '\n';


-- zones   WORKS

SELECT JSON_OBJECT(
    'zone_id', z.zone_id,
    'region_id', z.region_id,
    'name', z.name,
    'factions', JSON_OBJECT(
        'faction_id', f.faction_id,
        'region_id', f.region_id,
        'name', f.name
    ),
    'regions', JSON_OBJECT(
        'region_id', r.region_id,
        'chat_id', r.chat_id,
        'name', r.name
    ),
    'zone_mobs', JSON_OBJECT(
        'zone_id', zm.zone_id,
        'mob_id', zm.mob_id,
        'amount', zm.amount
    )
)
AS zones
FROM zones z
JOIN factions f
    ON f.region_id = z.region_id
JOIN regions r
    ON r.region_id = z.region_id
JOIN zone_mobs zm
    ON zm.zone_id =  z.zone_id
INTO OUTFILE 'C:\\data\\_exports\\zones.jsonl'
LINES TERMINATED BY '\n';


-- quests   CANNOT PARSE

SELECT JSON_OBJECT(
    'quest_id', q.quest_id,
    'npc_id', q.npc_id,
    'name', q.name,
    'description', q.description,
    'repeatable', CASE WHEN q.repeatable = 1 THEN 'True' ELSE 'False' END,
    'location', q.location,
    'quest_history', JSON_OBJECT(
        'history_id', qh.history_id,
        'character_id', qh.character_id,
        'quest_id', qh.quest_id,
        'reward_id', qh.reward_id,
        'state', qh.state,
        'time', qh.time
    )
)
AS quests
FROM quests q
JOIN quest_history qh
    ON qh.quest_id = q.quest_id
INTO OUTFILE 'C:\\data\\_exports\\quests.jsonl'
LINES TERMINATED BY '\n';





-- items

SELECT JSON_OBJECT(
    'info_id', ii.info_id,
    'item_rarity_id', JSON_OBJECT(
        'rarity_id', r.rarity_id,
        'name', r.name,
        'color', r.color
    ),
    'items', JSON_OBJECT(
        'item_id', i.item_id,
        'inventory_id', i.inventory_id,
        'info_id', i.info_id
    ),
    'quest_rewards', JSON_OBJECT(
        'reward_id', qr.reward_id,
        'item_id', qr.item_id,
        'quest_id', qr.quest_id,
        'gold', qr.gold,
        'experience', qr.experience
    ),
    'loot_table_items', JSON_OBJECT(
        'item_id', lti.item_id,
        'loot_table_id', JSON_OBJECT(
            'loot_table_id', lt.loot_table_id,
            'min_gold', lt.min_gold,
            'max_gold', lt.max_gold,
            'min_exp', lt.min_exp,
            'max_exp', lt.max_exp
        ),
        'drop_rate', lti.drop_rate
    ),
    'name', ii.name,
    'durability_max', ii.durability_max,
    'sell_price', ii.sell_price,
    'repair_cost', ii.repair_cost,
    'two_handed', ii.two_handed
) AS items
FROM item_info ii
JOIN item_rarities r
    ON r.rarity_id = ii.rarity_id
JOIN items i
    ON i.info_id = ii.info_id
JOIN quest_rewards qr
    ON qr.item_id = i.item_id
JOIN loot_table_items lti
    ON lti.item_id = ii.info_id
JOIN loot_tables lt
    ON lt.loot_table_id = lti.loot_table_id
INTO OUTFILE 'C:\\data\\_exports\\items.jsonl';


-- restrictions   WORKS

SELECT JSON_OBJECT (
    'restriction_id', r.restriction_id,
    'specialization_restrictions', JSON_OBJECT(
        'specialization_id', sr.specialization_id,
        'resctiction_id', sr.restriction_id
    ),
    'item_restrictions', JSON_OBJECT(
        'restriction_id', ir.restriction_id,
        'item_id', ir.item_id
    ),
    'quest_restrictions', JSON_OBJECT(
        'restriction_id', qr.restriction_id,
        'quest_id', qr.quest_id
    ),
    'class_id', r.class_id,
    'specialization_id', r.specialization_id,
    'race_id', r.race_id,
    'level_id', r.level_id,
    'quest_id', r.quest_id,
    'type', r.type
) as restriction_data
FROM restrictions r
JOIN specialization_restrictions sr
    ON sr.restriction_id = r.restriction_id
JOIN item_restrictions ir
    ON ir.restriction_id = r.restriction_id
JOIN quest_restrictions qr
    ON qr.restriction_id = r.restriction_id
INTO OUTFILE 'C:\\data\\_exports\\restrictions.jsonl'
LINES TERMINATED BY '\n';

-- modifiers

SELECT JSON_OBJECT(
    'modifier_id', m.modifier_id,
    'class_modifiers', JSON_OBJECT(
        'class_id', cm.class_id,
        'modifier_id', cm.modifier_id
    ),
    'specialization_modifiers', JSON_OBJECT(
        'specialization_id', sm.specialization_id,
        'modifier_id', sm.modifier_id
    ),
    'race_modifiers', JSON_OBJECT(
        'race_id', rm.race_id,
        'modifier_id', rm.modifier_id
    ),
    'item_modifiers', JSON_OBJECT (
        'item_id', im.item_id,
        'modifier_id', im.modifier_id
    ),
    'stat_id', m.stat_id,
    'amount', m.amount,
    'type', m.type
) AS modifier_data
FROM modifiers m
JOIN class_modifiers cm
    ON cm.modifier_id = m.modifier_id
JOIN specialization_modifiers sm
    ON sm.modifier_id = m.modifier_id
JOIN race_modifiers rm
    ON rm.modifier_id = m.modifier_id
JOIN item_modifiers im
    ON im.modifier_id = m.modifier_id
INTO OUTFILE 'C:\\data\\_exports\\modifiers.jsonl'
LINES TERMINATED BY '\n';



-- test chats

SELECT JSON_OBJECT(
    'chat_id', c.chat_id,
    'name', c.name,
    'is_private', IF(c.is_private = 1, TRUE, FALSE),

    -- ✅ filters array
    'filters', (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'filter_id', f.filter_id,
                'word', f.word,
                'filtered_word', f.filtered_word
            )
        )
        FROM chat_filters cf
        JOIN filters f ON f.filter_id = cf.filter_id
        WHERE cf.chat_id = c.chat_id
    ),

    -- ✅ members array
    'members', (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'character_id', cm.character_id
            )
        )
        FROM chat_members cm
        WHERE cm.chat_id = c.chat_id
    ),

    -- ✅ messages array
    'messages', (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'message_id', mh.message_id,
                'sender_id', mh.sender_id,
                'message', REPLACE(REPLACE(REPLACE(mh.message, '"', '\\"'), '\n', ' '), '\r', ''),
                'time', mh.time
            )
        )
        FROM message_history mh
        WHERE mh.chat_id = c.chat_id
    )

)
AS chat_data

FROM chats c

INTO OUTFILE 'C:\\data\\_exports\\chats.jsonl'
LINES TERMINATED BY '\n';


