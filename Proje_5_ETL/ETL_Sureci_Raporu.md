
**ETL SÜRECİ VE İŞ ZEKASI KATMANI — TEKNİK UYGULAMA RAPORU**
**Proje 5: Veri Temizleme ve ETL Süreçleri Tasarımı**
**Platform: MSSQL Server**
**Veri Kaynağı: Kaggle — NYC Airbnb Open Data**

---

**Gün 1: Veri Çıkarımı (Extract) ve Ham Veri Katmanının Hazırlanması**

Projenin ilk gününde ETL sürecinin Extract aşaması uygulanmıştır. Kaggle platformundan indirilen NYC Airbnb veri seti, herhangi bir ön işlem yapılmadan MSSQL Server ortamına aktarılarak `Raw_Airbnb_Data` tablosuna yüklenmiştir. Bu tablo, orijinal verinin bozulmadan saklandığı ham veri katmanı olarak işlev görmektedir.

Yükleme tamamlandıktan sonra veri setinin yapısal durumunu anlamak amacıyla ilk kirlilik analizi gerçekleştirilmiştir. `SELECT TOP 100` sorgusuyla `id`, `price` ve `service_fee` sütunları incelenmiş; finansal değerlerin sayısal değil metin (string) formatında tutulduğu ve içlerinde `$` ile `,` karakterleri barındırdığı tespit edilmiştir. Bu durum, söz konusu sütunlar üzerinde doğrudan aritmetik işlem yapılmasını engellemektedir.

Tespit edilen sorunu gidermek için iki aşamalı bir dönüşüm uygulanmıştır. Önce `ALTER TABLE` komutuyla `Raw_Airbnb_Data` tablosuna `Cleaned_Price` ve `Cleaned_Service_Fee` adında `DECIMAL(10,2)` tipinde iki yeni sütun eklenmiştir. Ardından `UPDATE` sorgusuyla, `REPLACE` fonksiyonu aracılığıyla `$` ve `,` karakterleri ayıklanmış; `TRY_CAST` ile temizlenen değerler yeni sütunlara yazılmıştır. Dönüşüm tamamlandıktan sonra artık işe yaramayan orijinal `price` ve `service_fee` sütunları `ALTER TABLE ... DROP COLUMN` komutuyla tablodan kaldırılmıştır.

Aynı gün içinde `last_review` sütununa da müdahale edilmiştir. Sütunun mevcut formatı tarih hesaplamalarına uygun olmadığından, `ALTER TABLE` ile `Cleaned_Last_Review` adında `DATE` tipinde yeni bir sütun oluşturulmuş ve `TRY_CAST` kullanılarak tarih dönüşümü gerçekleştirilmiştir. Dönüşüm sonrasında orijinal `last_review` sütunu da tablodan silinmiştir.

Son olarak fiyat bilgisi bulunmayan, yani `Cleaned_Price` veya `Cleaned_Service_Fee` değeri NULL olan kayıtlar veri setinden çıkarılmıştır. Bu kayıtlar toplam veri setinin %0,26'sını oluşturmakta olup 486 satıra karşılık gelmektedir.

---

**Gün 2: Veri Dönüştürme (Transform), Standardizasyon ve Tekrar Eden Kayıtların Temizlenmesi**

İkinci günde Transform aşaması kapsamında veri kalitesini artırmaya yönelik birden fazla operasyon uygulanmıştır.

İlk adım olarak `neighbourhood_group` sütunundaki kategori kirliliği giderilmiştir. Standardizasyon öncesinde sütundaki değerlerin dağılımını görmek amacıyla `GROUP BY` sorgusuyla bir frekans analizi yapılmıştır. Bu analiz sonucunda "brookln" ve "manhatan" gibi yazım hatalarının varlığı doğrulanmıştır. Her iki hata ayrı `UPDATE` sorguları ile doğru değerlere (Brooklyn, Manhattan) düzeltilmiştir. Ardından coğrafi bilgisi olmayan, yani `neighbourhood_group` değeri NULL olan 29 kayıt `DELETE` komutuyla tablodan çıkarılmıştır. Standardizasyonun doğru uygulandığını teyit etmek için aynı `GROUP BY` sorgusu tekrar çalıştırılarak sonuçlar karşılaştırılmıştır.

Günün en kritik operasyonu tekrar eden kayıtların temizlenmesi olmuştur. Önce `GROUP BY id HAVING COUNT(*) > 1` sorgusuyla `id` bazında tekrar eden kayıtlar tespit edilmiştir. Temizleme işlemi için doğrudan `DELETE` yerine daha kontrollü bir yaklaşım tercih edilmiştir: CTE (Common Table Expression) yapısı içinde `ROW_NUMBER()` pencere fonksiyonu kullanılarak her `id` için ilk kayıt korunmuş, `Satir_Numarasi > 1` koşuluyla yalnızca tekrar eden 541 kayıt silinmiştir. Bu yöntem, hangi kaydın silineceğini önceden kontrol etme imkânı sunması açısından teknik olarak daha güvenlidir.

---

**Gün 3: Veri Yükleme (Load), Kalite Raporu ve İş Zekası Katmanının İnşası**

Üçüncü günde temizlenmiş veri üretim ortamına aktarılmış, kalite raporu oluşturulmuş ve analiz katmanı inşa edilmiştir.

Öncelikle `PRIMARY KEY` kısıtlamasıyla tanımlanmış `Production_Airbnb_Data` tablosu oluşturulmuştur. Tablo şu sütunları içermektedir: `id (INT, PRIMARY KEY)`, `price (DECIMAL(10,2))`, `service_fee (DECIMAL(10,2))`, `last_review (DATE)` ve `neighbourhood_group (NVARCHAR(50))`. Ardından `INSERT INTO ... SELECT` komutuyla `Raw_Airbnb_Data` tablosundaki temizlenmiş veriler bu tabloya aktarılmıştır.

Yükleme sonrasında veri setinde 2024 ve sonrasına ait `last_review` değerleri taşıyan 5 kayıt tespit edilmiştir. Bu kayıtlar gerçek rezervasyon verisini değil muhtemelen test amaçlı girilmiş hatalı kayıtları temsil ettiğinden `DELETE` komutuyla üretim tablosundan çıkarılmıştır. Nihai üretim tablosu 101.539 satır temiz veri içermektedir.

Proje gereksinimlerindeki veri kalitesi raporlaması maddesini karşılamak amacıyla `vw_Veri_Kalitesi_Raporu` adlı bir view oluşturulmuştur. Bu view, ETL süreci boyunca gerçekleştirilen tüm müdahaleleri sayısal metriklerle bir arada sunmaktadır:

| Metrik | Değer |
|---|---|
| Silinen tekrar eden kayıt | 541 |
| Silinen NULL lokasyon kaydı | 29 |
| Silinen NULL fiyat kaydı | 486 |
| Silinen zaman serisi anomalisi | 5 |
| Üretime yüklenen temiz veri | 101.539 |

ETL sürecinin tamamlanmasının ardından üretim tablosu üzerinde analitik görünümler (view) oluşturulmuştur. Bu katmanın amacı, temizlenmiş veriden iş değeri üretmek ve raporlama sistemlerine hazır çıktılar sunmaktır.

**Bölge Bazlı Pazar Hacmi Analizi (`vw_Bolge_Istatistikleri`):** `Production_Airbnb_Data` tablosu `neighbourhood_group` bazında gruplandırılarak her bölge için toplam ilan sayısı, ortalama fiyat, minimum ve maksimum fiyat ile toplam pazar hacmi hesaplanmıştır. Bu view New York'un hangi bölgesinin Airbnb pazarında ne kadar ağırlık taşıdığını ortaya koymaktadır. Sorgu çıktısı incelendiğinde veri setindeki yapay fiyat sınırlaması (50–1200 dolar aralığı) da bu aşamada gözlemlenmiştir.

**Yıllık Etkileşim Trendi Analizi (`vw_Yillik_Trend_Analizi`):** `last_review` sütunundan `YEAR()` fonksiyonuyla yıl bilgisi çıkarılarak yıllık bazda toplam etkileşim sayısı ve ortalama fiyat hesaplanmıştır. Bu view Airbnb kullanım yoğunluğunun yıllara göre nasıl değiştiğini göstermektedir. 2019 yılındaki zirvenin ardından 2020'de yaşanan keskin düşüş, Covid-19 pandemisinin rezervasyon hacmi üzerindeki etkisini sayısal olarak ortaya koymaktadır.

**Pandemi Etkisi Analizi (`vw_Pandemi_Etkisi_Analizi`):** Pandeminin bölgeler üzerindeki etkisini ölçmek amacıyla 2019 ve 2020 yıllarına ait rezervasyon verileri karşılaştırılmıştır. `PIVOT` operatörü kullanılarak her bölge için 2019 ve 2020 rezervasyon sayıları yan yana getirilmiş, yüzdesel kayıp `(2019 - 2020) * 100.0 / 2019` formülüyle hesaplanmıştır. Bu analiz hangi bölgenin pandemi döneminde görece daha sert etkilendiğini bölge bazında göstermektedir.

---

**Sonuç**

Bu proje kapsamında Kaggle'dan elde edilen ham NYC Airbnb verisi, MSSQL Server üzerinde eksiksiz bir ETL döngüsünden geçirilmiştir. Extract aşamasında ham veri katmanı oluşturulmuş; Transform aşamasında tip dönüşümleri, kategori standardizasyonu ve tekrar eden kayıt temizliği uygulanmıştır. Load aşamasında temiz veri `PRIMARY KEY` kısıtlamalı üretim tablosuna aktarılmış ve kalite raporu view'i ile süreç sayısal olarak belgelenmiştir. Son olarak üretim verisi üzerinde bölgesel pazar analizi, yıllık trend analizi ve pandemi etkisi analizi içeren bir iş zekası katmanı inşa edilmiştir.

Proje tanıtım videosu: https://youtu.be/boSKdwsMXE0
