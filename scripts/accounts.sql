DELIMITER $$

CREATE PROCEDURE generate_accounts()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 250 DO
        INSERT INTO accounts (account_name, creation_date, character_limit, character_count)
        VALUES (CONCAT('Account_', i), NOW(), 3, 0);
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_accounts();
