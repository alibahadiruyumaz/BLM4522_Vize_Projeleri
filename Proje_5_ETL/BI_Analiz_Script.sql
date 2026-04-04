-- ==========================================
-- IS ZEKASI (BI) VE ANALIZ KATMANI
-- Raporlama ve Gorsellestirme Icin Sanal Tablolar
-- ==========================================

-- ANALIZ 1: Bolge Bazli Pazar Hacmi ve Fiyat Dagilimi
-- Amac: New York bolgelerindeki Airbnb pazar hacmini (Toplam Gelir) ve fiyat anormalliklerini (Min/Max sinirlari) olcmek.
-- Not: Kaggle veri setindeki yapay fiyat tiraslamasinin (50-1200) tespit edildigi sorgudur.

/*
CREATE OR ALTER VIEW vw_Bolge_Istatistikleri AS
SELECT 
    neighbourhood_group AS Bolge,
    COUNT(*) AS Toplam_Ev_Sayisi,
    CAST(AVG(price) AS DECIMAL(10,2)) AS Ortalama_Fiyat,
    MIN(price) AS En_Ucuz_Ev,
    MAX(price) AS En_Pahali_Ev,
    CAST(SUM(price) AS DECIMAL(15,2)) AS Toplam_Pazar_Hacmi
FROM Production_Airbnb_Data
GROUP BY neighbourhood_group;

-- Analiz 1'i Okuma ve Test Etme Komutu (Ortalama Fiyata Gore Sirali)
SELECT * FROM vw_Bolge_Istatistikleri
ORDER BY Ortalama_Fiyat DESC;
*/
-- ==========================================

-- ANALIZ 2: Yillik Etkilesim ve Rezervasyon Trendi
-- Amac: Airbnb kullanim oranlarinin yillara gore dagilimini cizmek. 
-- Not: 2019'daki zirveden sonra 2020'de yasanan %95'lik Covid-19 cokusunun kanitlandigi sorgudur.

/*
CREATE OR ALTER VIEW vw_Yillik_Trend_Analizi AS
SELECT 
    YEAR(last_review) AS Inceleme_Yili,
    COUNT(*) AS Toplam_Etkilesim,
    CAST(AVG(price) AS DECIMAL(10,2)) AS Yillik_Ortalama_Fiyat
FROM Production_Airbnb_Data
WHERE last_review IS NOT NULL
GROUP BY YEAR(last_review);

-- Analiz 2'yi Okuma ve Test Etme Komutu (Guncel Yildan Gecmise Dogru Sirali)
SELECT * FROM vw_Yillik_Trend_Analizi 
ORDER BY Inceleme_Yili DESC;

*/

-- ANALIZ 3: Bolge Bazli Pandemi Cokus Analizi (2019 vs 2020)
-- Amac: Pandeminin hangi bolgeyi daha sert vurdugunu yuzdesel olarak gormek.

/*
CREATE OR ALTER VIEW vw_Pandemi_Etkisi_Analizi AS
SELECT 
    bolge,
    [2019] AS Rezervasyon_2019,
    [2020] AS Rezervasyon_2020,
    CAST((([2019] - [2020]) * 100.0 / [2019]) AS DECIMAL(10,2)) AS Kayip_Yuzdesi
FROM (
    SELECT neighbourhood_group AS bolge, YEAR(last_review) AS yil, id
    FROM Production_Airbnb_Data
    WHERE YEAR(last_review) IN (2019, 2020)
) AS KaynakTablo
PIVOT (
    COUNT(id) FOR yil IN ([2019], [2020])
) AS PivotTablo;

-- Analiz 3'ü Oku
SELECT * FROM vw_Pandemi_Etkisi_Analizi ORDER BY Kayip_Yuzdesi DESC;

*/