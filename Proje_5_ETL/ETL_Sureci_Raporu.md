ETL Süreci Log Kayıtları

## Gün 1: Veri Çıkarımı (Extraction) ve Temel Tip Dönüşümleri
* **Kaynak Bağlantısı (Extract):** Kaggle üzerinden "New York City Airbnb Open Data" seti temin edilerek MSSQL Server ortamına ham tablo (Raw_Airbnb_Data) olarak aktarıldı.
* **Kirlilik Tespiti:** `price` ve `service_fee` kolonlarının metin formatında olduğu ($ ve , içerdiği); `last_review` kolonunun ise geçersiz veri tipinde tutulduğu belirlendi.
* **Teknik Müdahale:** * Fiyat ve ücret kolonlarındaki metinsel kirlilik `REPLACE` ve `TRY_CAST` fonksiyonları ile temizlenerek `DECIMAL(10,2)` veri tipinde yeni kolonlara aktarıldı.
  * İstatistiksel sapmayı önlemek adına fiyatı veya servis ücreti bulunmayan (NULL) %0.26'lık veri kümesi (486 satır) `DELETE` komutu ile veri setinden çıkarıldı.
  * `last_review` kolonu tip güvenli `DATE` formatına dönüştürüldü. Veri tekrarını ve disk israfını önlemek amacıyla işlevi biten eski kolonlar `DROP COLUMN` ile veritabanından kaldırıldı.

## Gün 2: Kategori Standardizasyonu ve Coğrafi Veri Temizliği
* **Kirlilik Tespiti:** `neighbourhood_group` (Bölge) kolonunda yazım hataları ("brookln", "manhatan") ve 29 adet `NULL` değer tespit edildi.
* **Teknik Müdahale:** * `UPDATE` komutları ile hatalı bölge kayıtları standartlaştırılarak (Brooklyn, Manhattan) düzeltildi.
  * İlerideki coğrafi ve istatistiksel analizlerin doğruluğunu tehlikeye atan, lokasyonu belirsiz (NULL) 29 kayıt `DELETE` komutu ile temizlendi.