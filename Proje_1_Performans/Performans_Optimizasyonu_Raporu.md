
**VERİTABANI PERFORMANS OPTİMİZASYONU VE İZLEME — TEKNİK UYGULAMA RAPORU**
**Proje 1: Veritabanı Performans Optimizasyonu ve İzleme**
**Platform: MSSQL Server**
**Veri Kaynağı: Olist Brazilian E-Commerce Public Dataset**

---

**Gün 1: Mimari Kurulum, Veri Tipi Optimizasyonu ve Test Ortamının Hazırlanması**

Projenin ilk aşamasında indirilen ham veri setinin yapısal durumu incelenmiştir. `Olist_Order_Items` tablosunda `price` ve `freight_value` sütunlarının `NVARCHAR` formatında tutulduğu tespit edilmiştir. Finansal verilerin metin tipinde saklanması, SQL Server'ın her aritmetik işlemde örtülü tip dönüşümü (Implicit Conversion) yapmasına yol açar. Bu durum CPU maliyetini artırır ve indeks kullanımını engeller. Performans testlerine geçmeden önce bu sorunun giderilmesi gerektiğinden veritabanı mimarisi baştan kurulmuştur.

`DB_Performans` adlı veritabanı oluşturulmuş; `Olist_Customers`, `Olist_Orders` ve `Olist_Order_Items` tabloları ilgili veri tipleriyle tanımlanmıştır. `price` ve `freight_value` sütunları doğrudan `DECIMAL(10,2)` olarak tanımlanarak örtülü dönüşüm riski baştan ortadan kaldırılmıştır. Veriler `BULK INSERT` yöntemiyle tablolara aktarılmıştır. Ardından `Olist_Orders` ile `Olist_Customers` ve `Olist_Order_Items` ile `Olist_Orders` arasına `FOREIGN KEY` kısıtlamaları eklenerek ilişkisel veri bütünlüğü sağlanmıştır.

Optimizasyon testlerinin anlamlı sonuçlar verebilmesi için veri hacminin artırılması gerekiyordu. Bu amaçla sipariş ve sipariş kalemleri arasındaki ilişkisel bütünlüğü koruyarak veriyi çoğaltan bir T-SQL döngüsü tasarlanmıştır. Her iterasyonda mevcut siparişlerin kopyaları, `order_id`'ye benzersiz bir sonek eklenerek ve tarih sütunları 15'er gün öteleyerek oluşturulmuştur. Döngü 5 kez çalıştırılmış ve veri seti yaklaşık 5 katına çıkarılarak test ortamı hazır hale getirilmiştir.
