# Denetim — arayüz yenilemesi öncesi durum (29 Eylül 2026)

Kapsam: `main` dalının `05ed385` hâli (v0.7.2). Oyun bu makinede (Windows 11,
Intel UHD, Godot 4.7.2) gerçekten açılıp oynandı; yalnızca kod okunmadı.
"Önce" kareleri `docs/tasarim/once-*.png` (bu belgede geçen görseller).

## Nasıl denetlendi

| Yol | Ne yapıldı |
|---|---|
| Masaüstü (Godot) | `tools/ekran_al.gd` ile yüzey, kazı, mağaza, derin katman + deprem, menü, oyun sonu ve telefon oranlı kareler alındı; `tools/fps.gd` ile kare süresi ölçüldü. |
| Web, canlı | `https://furkiozknn.github.io/derin-kazi/` Claude Browser'da açıldı: menü geldi, "Başla" oyuna girdi, HUD göründü, konsol okundu. |
| Web, yerel | `main`'den `--export-release "Web (HTML5)"` (pck 970.752 bayt), yeni yapı için ayrıca; `python -m http.server` + tarayıcı. |
| Girdi | Tarayıcıya klavye olayı yollandı (`S` basılı → matkap deliği, `Esc` → duraklat). Yalnızca sentetik olay: gerçek klavye, gamepad ve telefon parmağı denenmedi. |
| Kod okuma | `menu.gd`, `oyun.gd`, `arac.gd`, `ipucu.gd`, `ayar_panel.gd` (metin envanteri, girdi yolu, panel akışları). |

## Bulgular

### İlk 30 saniye anlaşılıyor mu?

Kısmen.

- Menüde **yedi eşit düğme** üst üste (`Başla`, `Yeni dünya (ilerleme
  sıfırlanır)`, `Tohum kodu — göster / gir`, `Günlük dünya (2026-09-29)`,
  `Derin Mod ...`, `Ayarlar`, `Çıkış`). Asıl eylem (oyna) ayırt edilmiyor;
  ilerlemeyi silen `Yeni dünya` iki düğme altında, **onaysız** tek tıkla çalışıyor.
- Menünün altında **beş satır** açık mavi yazı: kayıt bilgisi, günlük dünya,
  üç satır tuş ve gamepad listesi (8 tuş + 7 gamepad düğmesi). Yeni oyuncuya
  gereken tek satırdı: yürü, kaz, yüksel.
- Görünüm tanıtım videosuyla **hiç örtüşmüyor**. Video: koyu kahve zemin, düz
  toprak bantları, kağıt rengi matkap + kırmızı uç, amber maden kareleri, mono
  etiketler. Oyun: gün batımı degradeli gökyüzü, mor tepe ve kasaba silueti,
  gürültülü Endesga-32 pixel-art kaya, çimenli yüzey.
- HUD tek satırda **beş farklı renk** (mavi derinlik, turuncu yakıt, yeşil
  yük, kırmızı can, sarı para) ve kalın kontur; ikinci satırda `[====....]`
  metin çubuğu. Renk bilgi taşımıyor (yakıt azalınca da turuncu).

![önce: menü](tasarim/once-menu.png)
![önce: yüzey](tasarim/once-yuzey.png)

### Dil

- Arayüz **yalnız Türkçe**; İngilizce tablo, dil ayarı ve dil algılama yok.
  Tanıtım videoları X ve YouTube'da İngilizce yayınlanıyor: oradan gelen oyuncu
  Türkçe metinle karşılaşıyor. Metinler dağınık: `oyun.gd` (≈100 satır),
  `ipucu.gd`, `menu.gd`, `ayarlar.gd` tabloları (madenler, katmanlar, eser
  hikâyeleri).
- Kayıt tarafı hazır: `[ayar]` bölümü var, yeni bir anahtar eski kaydı bozmaz.

### Kontroller ve tepki

- Kazma yolu `Arac._physics_process` içinde girdiyi 60 Hz'de okuyor: tuş →
  ilk kazma sinyali **≈16 ms**, yürüyüş / pervane **≈32 ms** (sentetik olay,
  pencereli, ölçüm `docs/TASARIM.md` §4). Tepki gecikmesi sorun değil.
- **Dinamit yalnız zemindeyken atılıyor.** Karo kırılınca araç her seferinde
  ~0,47 sn'ye kadar boşlukta; oyuncu `F`'ye iniş anından **0,04 sn bile önce**
  basarsa "Dinamit için zemine bas" uyarısı alıyordu (sınama: 8 denemede 1/8
  iniş anında, erken basışlarda 0/8).
- **Araç deliğin kenarına asılıyor.** 12 px'lik gövde 16 px'lik deliğe tam
  ortalanmadan basılırsa bir kenarı komşu karonun köşesinde 0,1-1 px asılı
  kalıyor ve "aşağı" tuşu basılıyken düşmüyor. Sınama (delik ortasından −5…+5 px
  kayma, 11 başlangıç): **3/11 düştü**; ±2 px ve ötesinde hep asıldı.
- Kazı sürekliliği: matkap en üst seviyedeyken (Sv5) aşağı basılı tutulurken 12 sn'de 26 m; zamanın
  **%59'u boşlukta** (her karodan sonra ~0,28 sn serbest düşüş). Fizik ve denge
  bu oyunun çekirdeği: **değiştirilmedi**, TASARIM'da aday olarak not edildi.

### Zorluk ve ilk oyun

- Deprem (uyarılı, yüzeye çıkma ikramiyesi), sis, yakıt bahsi: adil ve okunur;
  `test_insan` ölçümü (tur 106 sn, çekirdeğe ~25 dk, 7/7 tohum) bu turda da aynı
  kaldı. Ölçülen bot davranışı insan hissini kanıtlamaz.
- İlk oyunda öğretme var (alt ipucu: "S / ↓ ile aşağı kaz", "Madeni sat: …") ve
  çalışıyor; fakat menüdeki tuş dökümüyle çakışıyordu (iki yerde iki anlatım).

### Oyun sonu ve ölüm

- "Ölüm" yok: can bitince araç yüzeye çekilir, yalnız küçük bir uyarı paneli
  çıkıyor; ekranda hiçbir geçiş yok, konum bir karede değişiyor.
- Çekirdek çıkarılınca uzun bir metin duvarı: süre, en derin, para, eser,
  tohum, iki istatistik satırı ve iki paragraf. **Tekrar yok**, yalnız
  "Menüye dön".

![önce: mağaza](tasarim/once-magaza.png)
![önce: oyun sonu](tasarim/once-bitis.png)

### Mobil ve dokunmatik

- Dokunmatik düzen v0.4-0.7'de düzeltilmiş (alanlar birbirine binmiyor, testi
  var). Menüde dokunmatik için ayrı yardım metni var. Dikey telefonda oyun 16:9
  şerit kalıyor (bilinen sınır). **Gerçek telefonda denenmedi.**

### Konsol

- Canlı sayfada yalnız `GL_INVALID_FRAMEBUFFER_OPERATION ... Attachment has
  zero size` (3 uyarı, açılışta; hata değil, kaynağı doğrulanmadı). Hata yok.

### Bot ve testler

- 304 birim + 156 oynanış + 7 denge + 10 insan sınaması yeşil; fay kapısı 12/12
  (kusursuz bot) ve 12/12 (sisli insan botu). Bu turun ölçümlerinde de değişmedi.

## Özet: önce

| Konu | Durum |
|---|---|
| Menü | 7 eşit düğme, 5 satır soluk yazı, onaysız "Yeni dünya" |
| Görünüm | videoyla ilgisiz (gün batımı + pixel art) |
| HUD | 5 renk + kontur, renk bilgi taşımıyor |
| Dil | yalnız Türkçe |
| Oyun sonu | metin duvarı, tekrar yok |
| Dinamit | inişten önce basış kaybolur |
| Delik kenarı | 11 başlangıçtan 8'inde asılıyor |
| Web paketi | pck 970.752, wasm 39.514.754, js 279.815 bayt |
| Kare süresi (60 m, vsync kapalı) | 2,56 ms (medyan), ≈391 FPS |
