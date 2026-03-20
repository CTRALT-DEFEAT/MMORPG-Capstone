DELIMITER $$

CREATE PROCEDURE generate_characters()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 500 DO
        INSERT INTO characters (
            class_id, race_id, level_id, inventory_id,
            name, gold_balance, experience
        )
        VALUES (
            FLOOR(1 + RAND()*4),
            FLOOR(1 + RAND()*4),
            FLOOR(1 + RAND()*10),
            i,
            CONCAT('Char_', i),
            FLOOR(RAND()*1000),
            FLOOR(RAND()*5000)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_characters();
