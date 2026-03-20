-- CLASSES
INSERT INTO classes (name, description) VALUES
('Warrior','Melee fighter'),
('Mage','Spell caster'),
('Rogue','Stealth attacker'),
('Cleric','Support/healer');

-- RACES
INSERT INTO races (name, description) VALUES
('Human','Balanced'),
('Elf','Agile'),
('Orc','Strong'),
('Dwarf','Tanky');

-- STATS
INSERT INTO stats (name) VALUES
('Strength'),('Dexterity'),('Intelligence'),('Vitality');

-- LEVELS
INSERT INTO levels (xp_requirement) VALUES
(0),(100),(300),(600),(1000),(1500),(2100),(2800),(3600),(4500);

-- ITEM RARITY
INSERT INTO item_rarities (name,color) VALUES
('Common','gray'),
('Rare','blue'),
('Epic','purple'),
('Legendary','orange');
