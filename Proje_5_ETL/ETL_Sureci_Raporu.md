ETL Süreci Log Kayıtları

## Gün 1: Veri Çıkarımı (Extraction) ve Temel Tip Dönüşümleri 
* **Kaynak Bağlantısı (Extract):** Kaggle üzerinden "New York City Airbnb Open Data" seti temin edilerek MSSQL Server ortamına ham tablo (`Raw_Airbnb_Data`) olarak aktarıldı.
* **Kirlilik Tespiti:** `price` ve `service_fee` kolonlarının metin (string) formatında olduğu, dolar işareti ($) ve virgül (,) içerdiği; `last_review` kolonunun ise geçersiz metin tipinde tutulduğu tespit edildi.
* **Teknik Müdahale:** * SQL `REPLACE` ve `TRY_CAST` fonksiyonları kullanılarak fiyat/ücret kolonlarındaki kirlilik temizlendi ve veriler matematiksel işleme uygun `DECIMAL(10,2)` tipinde yeni kolonlara yazıldı.
    * İstatistiksel sapmayı önlemek adına fiyatı veya servis ücreti bulunmayan (NULL) %0.26'lık anlamsız veri kümesi (486 satır) `DELETE` komutu ile silindi.
    * `last_review` kolonu tip güvenli `DATE` formatına dönüştürüldü. Veri tekrarını (redundancy) ve disk israfını önlemek amacıyla eski kirli metin kolonları `DROP COLUMN` ile veritabanından kalıcı olarak imha edildi.

## Gün 2: Kategori Standardizasyonu ve Coğrafi Veri Temizliği 
* **Kirlilik Tespiti:** `neighbourhood_group` (Bölge) kolonunda yazım hataları ("brookln", "manhatan") ve 29 adet anlamsız `NULL` değer tespit edildi.
* **Teknik Müdahale:** * SQL `UPDATE` komutları ile mutasyona uğramış kayıtlar tek bir standarda (Brooklyn, Manhattan) zorlandı.
    * İlerideki coğrafi ve istatistiksel analizleri bozacak olan lokasyonu belirsiz (NULL) 29 asalak kayıt `DELETE` komutu ile fiziksel olarak imha edildi.