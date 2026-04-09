# PERFORMANS OPTİMİZASYONU VE İZLEME — TEKNİK UYGULAMA RAPORU

**Proje 1:** Veritabanı Performans Optimizasyonu ve İzleme
**Platform:** MSSQL Server
**Veri Kaynağı:** Olist Brazilian E-Commerce Public Dataset

## Gün 1: Mimari Revizyon, Veri Tipi Optimizasyonu ve İlişkisel Ölçekleme

Projenin ilk aşamasında, indirilen ham veri setinin performans testlerine uygunluğu analiz edilmiştir. Yapılan incelemelerde `Olist_Order_Items` tablosunda yer alan `price` ve `freight_value` finansal metriklerinin metin (`NVARCHAR`) formatında tutulduğu tespit edilmiştir. Finansal verilerin metin tipinde tutulması, SQL Server'ın her aritmetik operasyonda "Örtülü Dönüşüm" (Implicit Conversion) yapmasına neden olarak CPU maliyetlerini artıracak ve indeks kullanımını engelleyecektir. 

Bu darboğazı test aşamasına geçmeden yok etmek amacıyla veritabanı mimarisi yeniden inşa edilmiştir. İlgili sütunlar `DECIMAL(10,2)` veri tipiyle güncellenmiş ve ham veriler `BULK INSERT` yöntemiyle içeri aktarılmıştır. `Olist_Orders` ile `Olist_Customers` ve `Olist_Order_Items` ile `Olist_Orders` tabloları arasına Foreign Key kısıtlamaları eklenerek ilişkisel veri bütünlüğü güvence altına alınmıştır.

Optimizasyon testleri için veri hacmini artırmak (Scaling) amacıyla, sipariş ve ürün detayları arasındaki bütünlüğü koruyan iteratif bir T-SQL döngüsü tasarlanmıştır. Bu işlem sonucunda veri seti 5 katına çıkarılmış ve test ortamı hazır hale getirilmiştir.

**Uygulanan Mimari Kurulum ve Ölçekleme Betiği:**

```sql
USE master;
GO

DROP DATABASE IF EXISTS DB_Performans;
GO
CREATE DATABASE DB_Performans;
GO
USE DB_Performans;
GO

CREATE TABLE Olist_Customers (
    customer_id NVARCHAR(50) PRIMARY KEY,
    customer_unique_id NVARCHAR(50),
    customer_zip_code_prefix NVARCHAR(20),
    customer_city NVARCHAR(100),
    customer_state NVARCHAR(10)
);

CREATE TABLE Olist_Orders (
    order_id NVARCHAR(100) PRIMARY KEY,
    customer_id NVARCHAR(50),
    order_status NVARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE Olist_Order_Items (
    order_id NVARCHAR(100),
    order_item_id INT,
    product_id NVARCHAR(50),
    seller_id NVARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2), 
    freight_value DECIMAL(10,2) 
);
GO

BULK INSERT Olist_Customers FROM 'C:\Olist\olist_customers_dataset.csv' WITH (CODEPAGE = '65001', FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', FIRSTROW = 2, TABLOCK);
BULK INSERT Olist_Orders FROM 'C:\Olist\olist_orders_dataset.csv' WITH (CODEPAGE = '65001', FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', FIRSTROW = 2, TABLOCK);
BULK INSERT Olist_Order_Items FROM 'C:\Olist\olist_order_items_dataset.csv' WITH (CODEPAGE = '65001', FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', FIRSTROW = 2, TABLOCK);
GO

ALTER TABLE Olist_Orders ADD CONSTRAINT FK_Orders_Customers FOREIGN KEY (customer_id) REFERENCES Olist_Customers(customer_id);
ALTER TABLE Olist_Order_Items ADD CONSTRAINT FK_Items_Orders FOREIGN KEY (order_id) REFERENCES Olist_Orders(order_id);
GO

DECLARE @i INT = 1;
WHILE @i <= 5 
BEGIN
    INSERT INTO Olist_Orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
    SELECT order_id + '-' + CAST(@i AS NVARCHAR(10)), customer_id, order_status, DATEADD(day, @i * 15, order_purchase_timestamp), DATEADD(day, @i * 15, order_approved_at), DATEADD(day, @i * 15, order_delivered_carrier_date), DATEADD(day, @i * 15, order_delivered_customer_date), DATEADD(day, @i * 15, order_estimated_delivery_date)
    FROM Olist_Orders WHERE order_id NOT LIKE '%-%';

    INSERT INTO Olist_Order_Items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
    SELECT order_id + '-' + CAST(@i AS NVARCHAR(10)), order_item_id, product_id, seller_id, DATEADD(day, @i * 15, shipping_limit_date), price, freight_value
    FROM Olist_Order_Items WHERE order_id NOT LIKE '%-%';

    SET @i = @i + 1;
END;
GO