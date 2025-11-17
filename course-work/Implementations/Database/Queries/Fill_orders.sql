DECLARE @i INT = 1;
DECLARE @order_id INT;
DECLARE @item_ids VARCHAR(MAX);
DECLARE @item_count INT;
DECLARE @rnd_item INT;

DECLARE @user_id INT;
DECLARE @courier_id INT;
DECLARE @arrival_address VARCHAR(40);
DECLARE @payment_type VARCHAR(20);
DECLARE @delivery_type VARCHAR(20);

WHILE @i <= 50 -- create 50 dummy orders
BEGIN
    -- Pick random valid IDs first
    SELECT TOP 1 @user_id = user_id FROM TAUser ORDER BY NEWID();
    SELECT TOP 1 @courier_id = courier_id FROM Courier ORDER BY NEWID();

    -- Randomize other values
    SET @arrival_address = CONCAT('Street ', FLOOR(RAND() * 500), ' Apt ', FLOOR(RAND() * 50));
    SET @payment_type = CASE WHEN RAND() > 0.5 THEN 'card' ELSE 'cash' END;
    SET @delivery_type = CASE WHEN RAND() > 0.3 THEN 'delivery' ELSE 'pick up' END;

    -- Build random item list (1–5 items)
    SET @item_ids = '';
    SET @item_count = FLOOR(RAND() * 5) + 1;

    DECLARE @j INT = 1;
    WHILE @j <= @item_count
    BEGIN
        SELECT TOP 1 @rnd_item = item_id FROM Item ORDER BY NEWID();
        SET @item_ids = CONCAT(@item_ids, CASE WHEN LEN(@item_ids) > 0 THEN ',' ELSE '' END, @rnd_item);
        SET @j += 1;
    END

    -- Call your procedure with the variables
    EXEC [dbo].[sp_PlaceOrder]
        @user_id = @user_id,
        @arrival_address = @arrival_address,
        @comment_to_restaurant = NULL, -- skip comments
        @payment_type = @payment_type,
        @item_ids = @item_ids,
        @delivery_type = @delivery_type,
        @courier_id = @courier_id,
        @order_id = @order_id OUTPUT;

    PRINT CONCAT('Created order #', @order_id, ' | Items: ', @item_ids, ' | User: ', @user_id);

    SET @i += 1;
END

UPDATE d
SET d.courrier_id = CASE 
                        WHEN d.type = 'pick up' THEN NULL
                        ELSE (
                            SELECT TOP 1 c.courier_id 
                            FROM Courier c 
                            ORDER BY NEWID()
                        )
                    END
FROM Delivery d;


SELECT * FROM Delivery;
