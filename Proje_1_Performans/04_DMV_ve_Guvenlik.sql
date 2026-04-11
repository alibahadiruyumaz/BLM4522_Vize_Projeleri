USE DB_Performans;
GO

-- 1. TRAFİK YARATMA: Motoru indeksleri kullanmaya zorla
SELECT 
    c.customer_state,
    YEAR(o.order_purchase_timestamp) AS PurchaseYear,
    COUNT(i.order_item_id) AS TotalItems,
    SUM(i.price) AS TotalRevenue
FROM Olist_Customers c
INNER JOIN Olist_Orders o ON c.customer_id = o.customer_id
INNER JOIN Olist_Order_Items i ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= '2018-01-01' 
  AND o.order_purchase_timestamp < '2019-01-01'
  AND o.order_status = 'delivered'
GROUP BY 
    c.customer_state,
    YEAR(o.order_purchase_timestamp);
GO

-- 2. RADAR: İndeks kullanım istatistiklerini DMV üzerinden oku
SELECT 
    OBJECT_NAME(s.[object_id]) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks, 
    s.user_scans
FROM sys.dm_db_index_usage_stats AS s
INNER JOIN sys.indexes AS i ON i.[object_id] = s.[object_id] AND i.index_id = s.index_id
WHERE s.database_id = DB_ID('DB_Performans')
  AND OBJECT_NAME(s.[object_id]) IN ('Olist_Orders', 'Olist_Order_Items')
ORDER BY user_seeks DESC;
GO

-- 3. GÜVENLİK VE ROL YÖNETİMİ
CREATE LOGIN AnalistLogin WITH PASSWORD = 'Sifre123_Analist';
GO

CREATE USER AnalistUser FOR LOGIN AnalistLogin;
GO

GRANT SELECT ON Olist_Orders TO AnalistUser;
GRANT SELECT ON Olist_Order_Items TO AnalistUser;
GO