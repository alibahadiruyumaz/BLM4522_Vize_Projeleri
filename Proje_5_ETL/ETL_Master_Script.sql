-- ==========================================
-- ETL PROJESİ MASTER SCRIPT
-- PROJE: Airbnb Veri Temizleme ve Dönüşümü
-- ==========================================

-- ADIM 1: İlk Kirlilik Analizi (Gözlem)
/*
SELECT TOP 100 id, price, service_fee FROM Raw_Airbnb_Data;
*/

-- ADIM 2: Yeni Tip Güvenli (Type-Safe) Kolonların İnşası
/*
ALTER TABLE Raw_Airbnb_Data
ADD Cleaned_Price DECIMAL(10,2),
    Cleaned_Service_Fee DECIMAL(10,2);
*/

-- ADIM 3: Veri Dönüşümü (String'den Decimal'e) ve Temizlik
/*
UPDATE Raw_Airbnb_Data
SET 
    Cleaned_Price = TRY_CAST(REPLACE(REPLACE(price, '$', ''), ',', '') AS DECIMAL(10,2)),
    Cleaned_Service_Fee = TRY_CAST(REPLACE(REPLACE(service_fee, '$', ''), ',', '') AS DECIMAL(10,2));
*/

-- ADIM 4: Veri Tekrarını Önleme (Eski Kirli Kolonların Silinmesi)
/*
ALTER TABLE Raw_Airbnb_Data
DROP COLUMN price, service_fee;
*/

-- ADIM 5: İstatistiksel Sapanların (NULL) Tespiti ve Yok Edilmesi
/*
DELETE FROM Raw_Airbnb_Data
WHERE Cleaned_Price IS NULL OR Cleaned_Service_Fee IS NULL;
*/

-- ADIM 6: Tarih Kolonu (last_review) Kirlilik Analizi
/*
SELECT TOP 50 last_review 
FROM Raw_Airbnb_Data 
WHERE last_review IS NOT NULL;
*/

-- ADIM 7: Fiziksel Tarih Kolonunun İnşası
/*
ALTER TABLE Raw_Airbnb_Data
ADD Cleaned_Last_Review DATE;
*/

-- ADIM 8: Tarih Verisi Dönüşümü (TRY_CAST ile)
/*
UPDATE Raw_Airbnb_Data
SET Cleaned_Last_Review = TRY_CAST(last_review AS DATE);
*/


-- ADIM 9: Eski Kirli Tarih Kolonunun İmhası
/*
ALTER TABLE Raw_Airbnb_Data
DROP COLUMN last_review;
*/

-- ADIM 10: Kategori (Text) Standardizasyonu Ön Analizi
/*
SELECT 
    neighbourhood_group, 
    COUNT(*) AS Kayit_Sayisi
FROM Raw_Airbnb_Data
GROUP BY neighbourhood_group
ORDER BY neighbourhood_group ASC;
*/

-- ADIM 11: Kategori Standardizasyonu (Yazım Hatalarının Düzeltilmesi)
/*
UPDATE Raw_Airbnb_Data
SET neighbourhood_group = 'Brooklyn'
WHERE neighbourhood_group = 'brookln';

UPDATE Raw_Airbnb_Data
SET neighbourhood_group = 'Manhattan'
WHERE neighbourhood_group = 'manhatan';
*/

-- ADIM 12: Coğrafi Kirliliğin (NULL) İmhası
/*
DELETE FROM Raw_Airbnb_Data
WHERE neighbourhood_group IS NULL;
*/

-- ADIM 13: Standardizasyon Kontrolü
/*
SELECT 
    neighbourhood_group, 
    COUNT(*) AS Kayit_Sayisi
FROM Raw_Airbnb_Data
GROUP BY neighbourhood_group
ORDER BY neighbourhood_group ASC;
*/

-- ADIM 14: Mükerrer Kayıt (Duplicate) Analizi
/*
SELECT 
    id, 
    COUNT(*) as Tekrar_Sayisi
FROM Raw_Airbnb_Data
GROUP BY id
HAVING COUNT(*) > 1;
*/

-- ADIM 15: Mükerrer Kayıtların (Duplicates) CTE ile Temizlenmesi
/*
WITH Duplicate_CTE AS (
    SELECT 
        id,
        ROW_NUMBER() OVER(
            PARTITION BY id 
            ORDER BY id
        ) as Satir_Numarasi
    FROM Raw_Airbnb_Data
)
DELETE FROM Duplicate_CTE
WHERE Satir_Numarasi > 1;
*/

-- ADIM 16: Final Production (Üretim) Tablosunun İnşası
/*
CREATE TABLE Production_Airbnb_Data (
    id INT PRIMARY KEY,
    price DECIMAL(10,2),
    service_fee DECIMAL(10,2),
    last_review DATE,
    neighbourhood_group NVARCHAR(50)
);
*/

-- ADIM 17: Verinin Üretim Ortamına Yüklenmesi (LOAD)
/*
INSERT INTO Production_Airbnb_Data (id, price, service_fee, last_review, neighbourhood_group)
SELECT 
    id, 
    Cleaned_Price, 
    Cleaned_Service_Fee, 
    Cleaned_Last_Review, 
    neighbourhood_group
FROM Raw_Airbnb_Data;
*/

-- ADIM 20: Üretim Tablosunda Son Kontrol ve Zaman Serisi Temizliği
-- Not: Veri setindeki 2024 ve sonrası "hatalı/test" kayıtları temizlenerek raporlama öncesi veri mühürlenir.
/*
DELETE FROM Production_Airbnb_Data
WHERE YEAR(last_review) >= 2024;
*/

-- ETL SÜRECİ BURADA BİTER.