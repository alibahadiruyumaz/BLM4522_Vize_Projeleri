ETL Süreci Log Kayıtları

Gün 1:

    Veritabanı altyapı hazırlıkları başladı, Kaggle üzerinden veri setleri taranıyor.

    New York City Airbnb Data Cleaning veri seti indirildi ve MSSQL aktarımına hazırlanıyor.

    Fiyat ve servis ücreti verileri SQL fonksiyonları ile fiziksel olarak temizlenip DECIMAL tiplere dönüştürüldü. Veri tekrarını önlemek için eski kirli kolonların silinmesi (Drop) ve NULL değerlerin analizi aşamasına geçiliyor.

    Metin formatındaki last_review kolonu TRY_CAST fonksiyonu ile tip güvenli DATE formatına (Cleaned_Last_Review) fiziksel olarak dönüştürüldü ve veri tekrarını önlemek için eski kolon silindi.