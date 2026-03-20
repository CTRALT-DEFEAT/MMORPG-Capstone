DELIMITER $$

CREATE PROCEDURE generate_inventories()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 500 DO
        INSERT INTO inventories (max_size)
        VALUES (20 + FLOOR(RAND()*20));
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_inventories();
