
**VERİTABANI PERFORMANS OPTİMİZASYONU VE İZLEME — TEKNİK UYGULAMA RAPORU**
**Proje 1: Veritabanı Performans Optimizasyonu ve İzleme**
**Platform: MSSQL Server**
**Veri Kaynağı: Olist Brazilian E-Commerce Public Dataset**

---

**Gün 1: Mimari Kurulum, Veri Tipi Optimizasyonu ve Test Ortamının Hazırlanması**

Projenin ilk aşamasında indirilen ham veri setinin yapısal durumu incelenmiştir. `Olist_Order_Items` tablosunda `price` ve `freight_value` sütunlarının `NVARCHAR` formatında tutulduğu tespit edilmiştir. Finansal verilerin metin tipinde saklanması, SQL Server'ın her aritmetik işlemde örtülü tip dönüşümü (Implicit Conversion) yapmasına yol açar. Bu durum CPU maliyetini artırır ve indeks kullanımını engeller. Performans testlerine geçmeden önce bu sorunun giderilmesi gerektiğinden veritabanı mimarisi baştan kurulmuştur.

`DB_Performans` adlı veritabanı oluşturulmuş; `Olist_Customers`, `Olist_Orders` ve `Olist_Order_Items` tabloları ilgili veri tipleriyle tanımlanmıştır. `price` ve `freight_value` sütunları doğrudan `DECIMAL(10,2)` olarak tanımlanarak örtülü dönüşüm riski baştan ortadan kaldırılmıştır. Veriler `BULK INSERT` yöntemiyle tablolara aktarılmıştır. Ardından `Olist_Orders` ile `Olist_Customers` ve `Olist_Order_Items` ile `Olist_Orders` arasına `FOREIGN KEY` kısıtlamaları eklenerek ilişkisel veri bütünlüğü sağlanmıştır.

Optimizasyon testlerinin anlamlı sonuçlar verebilmesi için veri hacminin artırılması gerekiyordu. Bu amaçla sipariş ve sipariş kalemleri arasındaki ilişkisel bütünlüğü koruyarak veriyi çoğaltan bir T-SQL döngüsü tasarlanmıştır. Her iterasyonda mevcut siparişlerin kopyaları, `order_id`'ye benzersiz bir sonek eklenerek ve tarih sütunları 15'er gün öteleyerek oluşturulmuştur. Döngü 5 kez çalıştırılmış ve veri seti yaklaşık 5 katına çıkarılarak test ortamı hazır hale getirilmiştir.

**Gün 2: Darboğaz Analizi ve Performans Temel Çizgisinin Belirlenmesi**

Performans iyileştirme stratejilerini uygulayabilmek için öncelikle sistemin mevcut yük altındaki zayıf noktalarını ölçülebilir verilerle ortaya koymak gerekiyordu. Bu amaçla SQL Server'ın RAM önbelleğini temizleyen ve motoru fiziksel diskten okuma yapmaya zorlayan bir stres testi kurgulanmıştır. `DBCC DROPCLEANBUFFERS` ve `DBCC FREEPROCCACHE` komutlarıyla önbellek sıfırlanmış, ardından `SET STATISTICS IO` ve `SET STATISTICS TIME` parametreleri aktif edilerek sorgunun gerçek I/O ve CPU maliyeti ölçülmüştür.

Test sorgusunda iki ayrı performans tuzağı kasıtlı olarak bir araya getirilmiştir. Birincisi `YEAR(order_purchase_timestamp)` fonksiyonunun WHERE koşulunda kullanılmasıdır; bu ifade SARGable olmadığından SQL Server mevcut indeksleri kullanamaz ve tüm tabloyu baştan sona taramak zorunda kalır. İkincisi ise üç büyük tablo arasında kurulan `JOIN` zinciridir. Bu kombinasyon, sistemin indekssiz ortamdaki en kötü senaryosunu temsil etmektedir. Sorgu `02_Darbogaz_Analizi.sql` dosyasında yer almaktadır.

Elde edilen çıktılar sistemin mevcut durumunu açıkça ortaya koymuştur. `Olist_Orders` tablosunda 23.582, `Olist_Order_Items` tablosunda 21.098, `Olist_Customers` tablosunda ise 2.560 logical read gerçekleşmiş; toplamda yaklaşık 47.240 sayfa, yani yaklaşık 377 MB veri okunmuştur. Her üç tabloda da `Scan count` değerinin 13 olması, motorun indeks bulamadığı için tabloları 13 kez baştan sona taradığını göstermektedir. CPU süresi 1.938 ms iken sorgunun toplam tamamlanma süresi 502 ms olarak ölçülmüştür. CPU süresinin elapsed time'ın yaklaşık 4 katı olması, SQL Server'ın işlemi tek çekirdekle tamamlayamayıp paralel işleme (Parallelism) yöneldiğine işaret etmektedir.

Bu ölçümler, Gün 3'te uygulanacak indeksleme stratejisi için referans noktası olarak belgelenmiştir. İndeks eklendikten sonra aynı sorgu tekrar çalıştırılarak iyileşme oranı bu değerler üzerinden karşılaştırılacaktır.

**Gün 3: İndeks Mimarisi ve Sorgu Optimizasyonu**

Gün 2'de ölçülen yüksek I/O ve CPU maliyetlerini gidermek amacıyla iki ayrı müdahale uygulanmıştır: indeks mimarisinin kurulması ve performansı düşüren sorgu deseninin yeniden yazılması.

İndeks tarafında, SQL Server'ın tabloları baştan sona taramasını önlemek amacıyla iki Non-Clustered (Kümelenmemiş) indeks oluşturulmuştur. `Olist_Orders` tablosu için `IX_Orders_Date_Status` indeksi `order_purchase_timestamp` ve `order_status` sütunları üzerine tanımlanmış, `customer_id` sütunu `INCLUDE` ile kapsama alınmıştır. `Olist_Order_Items` tablosu için ise `IX_OrderItems_OrderID` indeksi `order_id` üzerine kurulmuş, `price` sütunu kapsama eklenmiştir. Bu yapı sayesinde SQL Server, JOIN ve filtreleme işlemlerinde ilgili veriyi tam tablo taraması yapmadan doğrudan bulabilmektedir.

Sorgu tarafında ise Gün 2'deki testte kasıtlı olarak kullanılan SARGable olmayan `YEAR(order_purchase_timestamp)` ifadesi refaktör edilmiştir. Bu fonksiyon sütunu dönüştürdüğünden SQL Server mevcut indeksleri kullanamamaktaydı. İfade, `>= '2018-01-01' AND < '2019-01-01'` şeklinde matematiksel aralık formatına dönüştürülmüş ve bu sayede motorun indeks üzerinden doğrudan arama (Index Seek) yapması sağlanmıştır. Uygulanan betik `03_Optimizasyon_Uygulamasi.sql` dosyasında yer almaktadır.

Optimizasyon sonrası aynı stres testi, önbellek sıfırlanarak tekrar çalıştırılmış ve Gün 2 ile karşılaştırmalı ölçüm yapılmıştır. `Olist_Orders` tablosunun logical read değeri 23.582 sayfadan 8.951 sayfaya gerilemiş, disk I/O maliyetinde %62 tasarruf sağlanmıştır. CPU süresi 1.938 ms'den 1.235 ms'ye, sorgunun toplam tamamlanma süresi ise 502 ms'den 223 ms'ye düşmüş; genel hız artışı %55 olarak ölçülmüştür.

`Olist_Order_Items` tablosunun logical read değeri ise değişmemiştir. Bu tablodaki `SUM` ve `COUNT` toplulaştırmaları bir yıllık teslimat verisi üzerinde çalıştığından, Query Optimizer bu veri hacmi için Index Seek yerine Scan yapmayı daha düşük maliyetli bulmuştur. Bu durum ilişkisel mimarilerdeki bilinen bir eşik noktasıdır (Tipping Point) ve Columnstore indeks mimarisine geçilmeden tam olarak çözülememektedir. Bununla birlikte elde edilen %55'lik performans artışı, mevcut ilişkisel yapı için belirlenen optimizasyon hedefini karşılamaktadır.

