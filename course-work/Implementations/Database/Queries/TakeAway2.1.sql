Use TakeAwayDB;

SELECT * FROM sys.tables WHERE name = 'FoodOrder';

CREATE TRIGGER trg_SetOrderDate
ON dbo.FoodOrder
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE fo
    SET 
        fo.date = ISNULL(fo.date, CAST(GETDATE() AS DATE)),
        fo.time_made = ISNULL(fo.time_made, CAST(GETDATE() AS TIME))
    FROM dbo.FoodOrder fo
    INNER JOIN inserted i ON fo.order_id = i.order_id;
END;
GO

SELECT name, parent_class_desc, create_date
FROM sys.triggers
WHERE name = 'trg_SetOrderDate';


CREATE TRIGGER trg_SetMenuDateAdded
ON dbo.Menu
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE m
    SET m.date_added = ISNULL(m.date_added, CAST(GETDATE() AS DATE))
    FROM dbo.Menu m
    INNER JOIN inserted i ON m.menu_id = i.menu_id;
END;
GO

