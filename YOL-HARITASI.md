# Yol haritası — Derin Kazı

## Bu turda yapıldı (2026-09-16, prototip)

- [x] Tohumla üretilen dünya: 60 karo genişlik, 320 karo derinlik, FastNoiseLite mağara +
      kazılamaz kaya kümeleri, katmanlar toprak → taş → sert taş
- [x] Parça parça (32 satırlık chunk) üretim — tüm harita bir kerede kurulmuyor
- [x] Derinliğe göre maden dağılımı: bakır / demir / altın / elmas
- [x] Matkaplı araç: sağ/sol/aşağı kazar, yukarı kazamaz, pervaneyle yükselir
- [x] Karo sertliğine göre kazma süresi, matkap geliştirmesiyle hızlanıyor
- [x] Yakıt (boşta/hareket/kazma/pervane ayrı tüketim), yük kapasitesi
- [x] Yakıt bitince koşu biter, yükün yarısı kaybolur, acil yakıtla üsse çekilir
- [x] HUD: derinlik (m), yakıt, yük, para + duruma göre ipucu satırı
- [x] Üs menüsü: sat, yakıt doldur, 3 geliştirme × 3 seviye (artan fiyat)
- [x] 250 m'de çekirdek → bitiş ekranı (derinlik, süre, para, tohum)
- [x] Ana menü (Başla / Yeni dünya / Çıkış), duraklatma, kayıt `user://kayit.cfg`
- [x] Klavye + gamepad girdisi
- [x] Headless testler: 45 birim sınaması + 12 oynanış sınaması
- [x] Windows ve Web dışa aktarımı

## Sonraki aşama — oynanış

- [ ] **Denge turu**: gerçek bir oyuncuyla 250 m'ye ulaşma süresini ölç. Şu an yakıt/fiyat
      eğrisi masa başında ayarlandı, oynanarak doğrulanmadı.
- [ ] Yerçekimi tehlikesi: boş tünelin üstündeki karo düşsün (kum/gevşek taş türü)
- [ ] Yüzeye dönmeyi zorlaştıran şeyler: gaz cebi, su, dar boğaz
- [ ] Sandık / nadir damar: derinde tek seferlik büyük ödül
- [ ] Geliştirmelere 4.–5. seviye + yeni dal (ısı kalkanı, tarayıcı/maden radarı)
- [ ] Tarayıcı: `Q` ile çevredeki madenleri kısa süre göster (yakıt harcar)
- [ ] Kazılmış karoların kaydı (şu an her koşu temiz dünyayla başlıyor)

## Sonraki aşama — sunum

- [ ] Gerçek pixel art (Pixelorama): karo atlası, araç, üs, arka plan katmanları
- [ ] Parçacık: kazma tozu, matkap kıvılcımı, maden toplama parıltısı
- [ ] Ses (rFXGen): matkap döngüsü, maden toplama, yakıt uyarısı, çekirdek
- [ ] Ekran sarsıntısı + kamera ileri bakış (kazma yönüne doğru kayma)
- [ ] Derinliğe göre değişen arka plan rengi / ışık düşüşü
- [ ] Menü ve panellerde ortak tema (`.tres`), şu an düğümlerde tek tek renk geçersizi var

## Sonraki aşama — dağıtım

- [ ] Web çıktısını COOP/COEP başlıklı bir sunucuda gerçekten oynayarak doğrula
- [ ] itch.io sayfası (SharedArrayBuffer kutusu işaretli) — **Furki'nin onayı gerekiyor**
- [ ] Mobil dokunmatik kontroller (sol/sağ/kaz/pervane düğmeleri)
- [ ] GitHub deposu ve push — **Furki'nin onayı gerekiyor**

## Bilinen sınırlar

- Araç üste dönmek zorunda değil; çekirdeğe ulaşmak oyunu doğrudan bitiriyor.
- Kazılmış tüneller kaydedilmediği için menüden çıkıp dönünce dünya tazeleniyor
  (para ve geliştirmeler korunuyor).
- Kamera 2× yakınlaştırılmış; derin tünelde çevre görüşü dar. Denge turunda gözden geçir.
