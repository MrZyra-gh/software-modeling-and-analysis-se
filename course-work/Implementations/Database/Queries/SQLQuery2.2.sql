USE TakeAwayDB;
GO

-- Procedure to place a new food order with items
CREATE PROCEDURE sp_PlaceOrder
    @user_id INTEGER,
    @arrival_address VARCHAR(40),
    @comment_to_restaurant TEXT = NULL,
    @payment_type VARCHAR(20),
    @item_ids VARCHAR(MAX), -- Comma-separated list of item IDs (e.g., '1,3,5')
    @delivery_type VARCHAR(20) = 'delivery',
    @courier_id INTEGER = NULL,
    @order_id INTEGER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate user exists
        IF NOT EXISTS (SELECT 1 FROM TAUser WHERE user_id = @user_id)
        BEGIN
            RAISERROR('User does not exist', 16, 1);
            RETURN;
        END
        
        -- Validate delivery type
        IF @delivery_type NOT IN ('delivery', 'pick up')
        BEGIN
            RAISERROR('Invalid delivery type. Must be ''delivery'' or ''pick up''', 16, 1);
            RETURN;
        END
        
        -- Create payment record
        DECLARE @payment_id INTEGER;
        INSERT INTO Payment (type, status)
        VALUES (@payment_type, 'pending');
        
        SET @payment_id = SCOPE_IDENTITY();
        
        -- Create food order (trigger will set date and time_made)
        INSERT INTO FoodOrder (payment_id, user_id, arrival_address, comment_to_restaurant)
        VALUES (@payment_id, @user_id, @arrival_address, @comment_to_restaurant);
        
        SET @order_id = SCOPE_IDENTITY();
        
        -- Add items to order
        DECLARE @item_id INTEGER;
        DECLARE @pos INTEGER;
        DECLARE @remaining_items VARCHAR(MAX) = @item_ids;
        
        WHILE LEN(@remaining_items) > 0
        BEGIN
            SET @pos = CHARINDEX(',', @remaining_items);
            
            IF @pos > 0
            BEGIN
                SET @item_id = CAST(LEFT(@remaining_items, @pos - 1) AS INTEGER);
                SET @remaining_items = SUBSTRING(@remaining_items, @pos + 1, LEN(@remaining_items));
            END
            ELSE
            BEGIN
                SET @item_id = CAST(@remaining_items AS INTEGER);
                SET @remaining_items = '';
            END
            
            -- Validate item exists
            IF EXISTS (SELECT 1 FROM Item WHERE item_id = @item_id)
            BEGIN
                INSERT INTO Item_Order (item_id, order_id)
                VALUES (@item_id, @order_id);
            END
        END
        
        -- Create delivery record
        INSERT INTO Delivery (courrier_id, type, status, order_id, expected_time)
        VALUES (
            @courier_id, 
            @delivery_type, 
            'being made', 
            @order_id,
            DATEADD(MINUTE, 45, CAST(GETDATE() AS TIME)) -- Expected in 45 minutes
        );
        
        COMMIT TRANSACTION;
        
        -- Return order details
        SELECT 
            @order_id AS order_id,
            @payment_id AS payment_id,
            'Order placed successfully' AS message;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Example usage:
/*
DECLARE @new_order_id INTEGER;

EXEC sp_PlaceOrder
    @user_id = 1,
    @arrival_address = '123 Main Street, Apt 4B',
    @comment_to_restaurant = 'Please add extra sauce',
    @payment_type = 'Credit Card',
    @item_ids = '1,2,5,7',
    @delivery_type = 'delivery',
    @courier_id = 3,
    @order_id = @new_order_id OUTPUT;

SELECT @new_order_id AS NewOrderID;
*/



-- Scalar function to calculate total cost of an order
CREATE FUNCTION dbo.fn_GetOrderTotal
(
    @order_id INTEGER
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2);
    
    SELECT @total = SUM(i.price)
    FROM Item_Order io
    INNER JOIN Item i ON io.item_id = i.item_id
    WHERE io.order_id = @order_id;
    
    -- Return 0 if no items found
    RETURN ISNULL(@total, 0);
END;
GO

-- Example usage:
/*
-- Get total for order #5
SELECT dbo.fn_GetOrderTotal(5) AS OrderTotal;

-- Use in a query to show all orders with their totals
SELECT 
    fo.order_id,
    fo.date,
    u.user_name,
    dbo.fn_GetOrderTotal(fo.order_id) AS total_cost,
    p.status AS payment_status
FROM FoodOrder fo
INNER JOIN TAUser u ON fo.user_id = u.user_id
INNER JOIN Payment p ON fo.payment_id = p.payment_id
ORDER BY fo.date DESC;
*/

GO

-- Table-valued function to get restaurant's average rating
CREATE FUNCTION dbo.fn_GetRestaurantRating
(
    @restaurant_id INTEGER
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        @restaurant_id AS restaurant_id,
        COUNT(*) AS total_reviews,
        AVG(CAST(score AS DECIMAL(10,2))) AS average_score,
        MAX(score) AS highest_score,
        MIN(score) AS lowest_score
    FROM Review
    WHERE restaurant_id = @restaurant_id
);
GO

-- Example usage:
/*
-- Get rating details for restaurant #1
SELECT * FROM dbo.fn_GetRestaurantRating(1);

-- Use in a query with restaurant info
SELECT 
    r.restaurant_id,
    r.address,
    r.phone,
    rr.total_reviews,
    rr.average_score,
    rr.highest_score,
    rr.lowest_score
FROM Restaurant r
CROSS APPLY dbo.fn_GetRestaurantRating(r.restaurant_id) rr
WHERE rr.total_reviews > 0;
*/