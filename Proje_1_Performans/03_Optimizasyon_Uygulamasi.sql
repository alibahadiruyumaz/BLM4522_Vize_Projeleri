USE DB_Performans;
GO

-- 1. ADIM: İNDEKS MİMARİSİNİN KURULUMU
-- Siparişler tablosunda tarih ve durum filtrelemesini hızlandıracak, Müşteri ID'sini de okuma maliyetinden düşürecek Covering Index.
CREATE NONCLUSTERED INDEX IX_Orders_Date_Status 
ON Olist_Orders(order_purchase_timestamp, order_status) 
INCLUDE (customer_id);
GO

-- Sipariş kalemleri tablosunda JOIN işlemini hızlandıracak ve fiyat bilgisini doğrudan indeksten okutacak yapı.
CREATE NONCLUSTERED INDEX IX_OrderItems_OrderID 
ON Olist_Order_Items(order_id) 
INCLUDE (price);
GO

-- 2. ADIM: OPTİMİZE EDİLMİŞ SORGUNUN TEST EDİLMESİ
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
-- SARGable Filtreleme: Fonksiyon kullanımı kaldırıldı, doğrudan tarih aralığı verildi.
WHERE o.order_purchase_timestamp >= '2018-01-01' 
  AND o.order_purchase_timestamp < '2019-01-01'
  AND o.order_status = 'delivered'
GROUP BY 
    c.customer_state,
    YEAR(o.order_purchase_timestamp)
ORDER BY 
    TotalRevenue DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO