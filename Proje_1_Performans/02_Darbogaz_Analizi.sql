USE DB_Performans;
GO

-- Önbelleği (RAM) tamamen boşaltıyoruz. 
-- Bunu yapmazsak SQL Server veriyi RAM'den okur ve performans sorununu göremeyiz.
CHECKPOINT;
GO
DBCC DROPCLEANBUFFERS; 
DBCC FREEPROCCACHE;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT 
    c.customer_state,
    YEAR(o.order_purchase_timestamp) AS PurchaseYear,
    COUNT(i.order_item_id) AS TotalItems,
    SUM(i.price) AS TotalRevenue
FROM Olist_Customers c
INNER JOIN Olist_Orders o ON c.customer_id = o.customer_id
INNER JOIN Olist_Order_Items i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY 
    c.customer_state,
    YEAR(o.order_purchase_timestamp)
ORDER BY 
    TotalRevenue DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO