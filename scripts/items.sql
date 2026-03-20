INSERT INTO items (
    inventory_id, name, durability_max,
    durability_current, sell_price, repair_cost,
    two_handed, rarity_id
)
SELECT
    FLOOR(1 + RAND()*500),
    CONCAT('Item_', FLOOR(RAND()*1000)),
    100,
    FLOOR(50 + RAND()*50),
    FLOOR(RAND()*100),
    FLOOR(RAND()*50),
    FLOOR(RAND()*2),
    FLOOR(1 + RAND()*4);
