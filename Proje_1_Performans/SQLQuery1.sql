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
    order_id NVARCHAR(50) PRIMARY KEY,
    customer_id NVARCHAR(50),
    order_status NVARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE Olist_Order_Items (
    order_id NVARCHAR(50),
    order_item_id INT,
    product_id NVARCHAR(50),
    seller_id NVARCHAR(50),
    shipping_limit_date DATETIME,
    price NVARCHAR(50),
    freight_value NVARCHAR(50)
);
GO

BULK INSERT Olist_Customers
FROM 'C:\Olist\olist_customers_dataset.csv'
WITH (
    CODEPAGE = '65001',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK
);

BULK INSERT Olist_Orders
FROM 'C:\Olist\olist_orders_dataset.csv'
WITH (
    CODEPAGE = '65001',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK
);

BULK INSERT Olist_Order_Items
FROM 'C:\Olist\olist_order_items_dataset.csv'
WITH (
    CODEPAGE = '65001',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK
);
GO

ALTER TABLE Olist_Orders ADD CONSTRAINT FK_Orders_Customers FOREIGN KEY (customer_id) REFERENCES Olist_Customers(customer_id);
ALTER TABLE Olist_Order_Items ADD CONSTRAINT FK_Items_Orders FOREIGN KEY (order_id) REFERENCES Olist_Orders(order_id);
GO

INSERT INTO Olist_Orders (order_id, customer_id, order_status, order_purchase_timestamp)
SELECT 
    NEWID(),
    o1.customer_id,
    o1.order_status,
    DATEADD(day, ABS(CHECKSUM(NEWID()) % 365), o1.order_purchase_timestamp)
FROM Olist_Orders o1
CROSS JOIN (SELECT TOP 50 * FROM Olist_Orders) AS o2;
GO