# VERİTABANI PERFORMANS OPTİMİZASYONU VE İZLEME — TEKNİK UYGULAMA RAPORU

**Proje 1: Veritabanı Performans Optimizasyonu ve İzleme**  
**Platform:** MSSQL Server  
**Veri Kaynağı:** Olist Brazilian E-Commerce Public Dataset  

---

> ⚠️ **KURULUM ÖNKOŞULU:** `01_Mimari_Kurulum.sql` betiğinin çalışabilmesi için ham veri setine ait CSV dosyalarının yerel diskte `C:\Olist\` dizinine yerleştirilmiş olması gerekmektedir.

---

## Gün 1: Mimari Kurulum, Veri Tipi Optimizasyonu ve Test Ortamının Hazırlanması

Projenin ilk aşamasında indirilen ham veri setinin yapısal durumu incelenmiştir. `Olist_Order_Items` tablosunda `price` ve `freight_value` sütunlarının `NVARCHAR` formatında tutulduğu tespit edilmiştir. Finansal verilerin metin tipinde saklanması, SQL Server'ın her aritmetik işlemde örtülü tip dönüşümü (Implicit Conversion) yapmasına yol açar. Bu durum CPU maliyetini artırır ve indeks kullanımını engeller. Performans testlerine geçmeden önce bu sorunun giderilmesi gerektiğinden veritabanı mimarisi baştan kurulmuştur.

`DB_Performans` adlı veritabanı oluşturulmuş; ilgili tablolar tanımlanırken finansal sütunlar doğrudan `DECIMAL(10,2)` olarak ayarlanarak örtülü dönüşüm riski ortadan kaldırılmıştır. Veriler `BULK INSERT` yöntemiyle içeri aktarılmış ve tablolar arasına `FOREIGN KEY` kısıtlamaları eklenerek ilişkisel bütünlük sağlanmıştır.

Testlerin anlamlı sonuçlar verebilmesi için veri hacmini artırmak amacıyla bir T-SQL döngüsü tasarlanmıştır. Sipariş kayıtları 15'er günlük tarih ötelemesiyle kopyalanarak veri seti yaklaşık 5 katına çıkarılmış ve stres testine hazır hale getirilmiştir. İlgili betik `01_Mimari_Kurulum.sql` dosyasında yer almaktadır.

---

## Gün 2: Darboğaz Analizi ve Performans Temel Çizgisinin Belirlenmesi

Performans iyileştirme stratejilerini uygulayabilmek için öncelikle sistemin mevcut yük altındaki zayıf noktalarını ölçülebilir verilerle ortaya koymak gerekiyordu. Bu amaçla SQL Server'ın RAM önbelleğini temizleyen ve motoru fiziksel diskten okuma yapmaya zorlayan bir stres testi kurgulanmıştır. `DBCC DROPCLEANBUFFERS` ve `DBCC FREEPROCCACHE` komutlarıyla önbellek sıfırlanmış, ardından `SET STATISTICS IO` ve `SET STATISTICS TIME` parametreleri aktif edilerek sorgunun gerçek I/O ve CPU maliyeti ölçülmüştür.

Test sorgusunda performansı düşüren iki unsur kasıtlı olarak bir araya getirilmiştir:

- **SARGable olmayan `YEAR(order_purchase_timestamp)` filtresi:** Bu ifade sütunu dönüştürdüğünden SQL Server mevcut indeksleri kullanamaz ve tabloyu baştan sona taramak zorunda kalır.
- **Üç büyük tabloyu kapsayan JOIN zinciri:** Bu kombinasyon, sistemin indekssiz ortamdaki en kötü senaryosunu temsil etmektedir.

İlgili betik `02_Darbogaz_Analizi.sql` dosyasında yer almaktadır.

### Elde Edilen Donanım Çıktıları

| Metrik | Değer |
|---|---|
| Olist_Orders Logical Read | 23.582 sayfa |
| Olist_Order_Items Logical Read | 21.098 sayfa |
| Olist_Customers Logical Read | 2.560 sayfa |
| Toplam I/O | 47.240 sayfa (~377 MB) |
| CPU Time | 1.938 ms |
| Elapsed Time | 502 ms |
| Scan Count (her tabloda) | 13 |

Her üç tabloda da `Scan count` değerinin 13 olması, motorun indeks bulamadığı için tabloları 13 kez baştan sona taradığını göstermektedir. CPU süresinin elapsed time'ın yaklaşık 4 katı olması ise SQL Server'ın işlemi tek çekirdekle tamamlayamayıp paralel işleme (Parallelism) yöneldiğine işaret etmektedir. Bu ölçümler Gün 3'te uygulanacak indeksleme stratejisi için referans değerler olarak belgelenmiştir.

---

## Gün 3: İndeks Mimarisi ve Sorgu Optimizasyonu

Gün 2'de ölçülen yüksek I/O ve CPU maliyetlerini gidermek amacıyla iki ayrı müdahale uygulanmıştır: indeks mimarisinin kurulması ve performansı düşüren sorgu deseninin yeniden yazılması.

### İndeks Mimarisi

SQL Server'ın tabloları baştan sona taramasını önlemek için iki Non-Clustered (Kümelenmemiş) indeks oluşturulmuştur:

- **`IX_Orders_Date_Status`:** `Olist_Orders` tablosunda `order_purchase_timestamp` ve `order_status` sütunları üzerine tanımlanmış; `customer_id` sütunu `INCLUDE` ile kapsama alınmıştır.
- **`IX_OrderItems_OrderID`:** `Olist_Order_Items` tablosunda `order_id` üzerine kurulmuş; `price` sütunu kapsama eklenmiştir.

Bu yapı sayesinde SQL Server, JOIN ve filtreleme işlemlerinde ilgili veriyi tam tablo taraması yapmadan doğrudan bulabilmektedir.

### Sorgu Optimizasyonu (SARGable Refaktör)

Gün 2'deki test sorgusunda kullanılan `YEAR(order_purchase_timestamp)` ifadesi, sütunu fonksiyonla dönüştürdüğünden SQL Server mevcut indeksleri kullanamamaktaydı. Bu ifade `>= '2018-01-01' AND < '2019-01-01'` şeklinde matematiksel aralık formatına dönüştürülmüş ve motorun Index Seek yapması sağlanmıştır. İlgili betik `03_Optimizasyon_Uygulamasi.sql` dosyasında yer almaktadır.

### Optimizasyon Sonrası Karşılaştırmalı Metrikler

| Metrik | Önce | Sonra | İyileşme |
|---|---|---|---|
| Olist_Orders Logical Read | 23.582 sayfa | 8.951 sayfa | %62 azalma |
| CPU Time | 1.938 ms | 1.235 ms | %36 azalma |
| Elapsed Time | 502 ms | 223 ms | %55 azalma |

**Limitasyon (Tipping Point):** `Olist_Order_Items` tablosunun logical read değeri değişmemiştir. Bu tablodaki `SUM` ve `COUNT` toplulaştırmaları bir yıllık teslimat verisi üzerinde çalıştığından, Query Optimizer bu veri hacmi için Index Seek yerine Scan yapmayı daha düşük maliyetli bulmuştur. Bu durum ilişkisel mimarilerdeki bilinen bir eşik noktasıdır ve Columnstore indeks mimarisine geçilmeden tam olarak çözülememektedir. Bununla birlikte elde edilen %55'lik performans artışı, mevcut yapı için belirlenen optimizasyon hedefini karşılamaktadır.

---

## Gün 4: DMV Analizi ve Güvenlik Yönetimi

### DMV ile İndeks Telemetrisi

Kurulan indeks mimarisinin gerçek sistem trafiği altındaki davranışını doğrulamak amacıyla `sys.dm_db_index_usage_stats` görünümü sorgulanmıştır. Sistem yeniden başlatıldıktan sonra SARGable sorgu çalıştırılmış ve hemen ardından DMV çıktısı alınmıştır. `IX_Orders_Date_Status` indeksinin `user_seeks` değerinin 1 olarak kaydedildiği görülmüştür. Bu metrik, SQL Server Query Optimizer'ın artık tam tablo taraması (Table Scan) yerine oluşturulan kapsayan indeksi aktif olarak kullandığını doğrulamaktadır. Gün 2'de ölçülen I/O maliyetindeki düşüşün kalıcı olduğu bu şekilde kanıtlanmıştır.

### Rol Tabanlı Erişim Kontrolü (RBAC)

Veritabanının yetkisiz müdahalelere karşı korunması amacıyla En Az Yetki Prensibi (Principle of Least Privilege) uygulanmıştır. Sunucu düzeyinde `AnalistLogin` girişi ve buna bağlı `AnalistUser` veritabanı kullanıcısı oluşturulmuştur. Bu kullanıcıya `Olist_Customers`, `Olist_Orders` ve `Olist_Order_Items` tablolarında yalnızca `SELECT` yetkisi tanımlanmıştır. Veri silme (`DELETE`), güncelleme (`UPDATE`) ve şema değiştirme (`DROP`/`ALTER`) yetkileri tanımlanmamış olup varsayılan olarak kısıtlıdır. İlgili betik `04_DMV_ve_Guvenlik.sql` dosyasında yer almaktadır.

---

## Sonuç

Bu proje kapsamında Olist Brazilian E-Commerce veri seti üzerinde dört aşamalı bir performans optimizasyon döngüsü uygulanmıştır. Gün 1'de ilişkisel mimari kurulmuş, veri tipleri düzeltilmiş ve test ortamı hazırlanmıştır. Gün 2'de stres testi ile sistemin indekssiz durumdaki I/O ve CPU maliyeti ölçülmüş, referans değerler belgelenmiştir. Gün 3'te Non-Clustered indeksler ve SARGable sorgu tasarımı ile disk I/O maliyeti %62, sorgu tamamlanma süresi %55 oranında düşürülmüştür. Gün 4'te DMV telemetrisiyle iyileştirmenin kalıcılığı doğrulanmış ve rol tabanlı erişim kontrolüyle veritabanı güvenliği sağlanmıştır.

**Proje tanıtım videosu:** https://youtu.be/PeI-qhtNyhU
