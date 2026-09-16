# Derin Kazı

Yandan kesit görünümlü kazı + gelişim oyunu: matkaplı araçla yeraltına in, maden topla,
yakıt bitmeden yüzeye dön, sat, aracını geliştir, 250 m'deki çekirdeğe ulaş.

![Oynanış](docs/ekran.png)

> Durum: **oynanabilir çekirdek prototip**. Grafikler yer tutucu (kodla üretilmiş 16×16 karolar),
> ses yok. Baştan sona oynanıp bitirilebiliyor.

## Kontroller

| Tuş | Gamepad | İş |
|---|---|---|
| `A` / `D` veya `←` / `→` | Sol çubuk, D-pad | Yürü; zemindeyken yana kaz |
| `S` veya `↓` | Aşağı | Aşağı kaz |
| `W` / `Boşluk` | A | Pervane — boş tünelde yüksel |
| `E` | X | Üs menüsü (yüzeydeyken: sat, geliştir, yakıt) |
| `Esc` | Start | Duraklat |

**Yukarı kazma yok.** Yükselmek için pervaneyle açtığın tünelden çıkarsın — geri dönüş yolunu
düşünerek kazmak oyunun ana gerilimi.

## Oyun döngüsü

1. Üsten aşağı kaz. Toprak hızlı, taş yavaş, sert taş en yavaş kırılır. Koyu **kaya** kazılamaz.
2. Madenler derinliğe göre: bakır (sığ, 12) → demir (30) → altın (85) → elmas (derin, 240).
3. **Yakıt** boşta bile azalır; hareket, kazma ve özellikle pervane hızlı tüketir.
   Biterse koşu biter ve **yükün yarısı kaybolur**.
4. **Yük** dolunca yeni maden alınmaz — dönme vakti.
5. Üste dön, `E`: sat, yakıt doldur, geliştir (matkap hızı / yakıt deposu / yük kapasitesi,
   her biri 3 seviye: 150 → 450 → 1200 para).
6. 250 m'deki **çekirdeğe** dokun → bitiş ekranı.

## Verilen kararlar

- **Yakıt dolumu ücretli** (birim başına 0.25 para). Bedava olsaydı yakıt bir kaynak değil
  sadece bir tur sayacı olurdu; ücretli olunca "daha derine mi ineyim, yakıta mı yatırayım"
  kararı doğuyor. Kilitlenmeyi önlemek için tek istisna: **yakıt bitip koşu başarısız
  olduğunda deponun %25'i bedava dolar** — parasız + yakıtsız kalıp oyunu sürdürememek yok.
- **Dünya parça parça üretiliyor** (32 satırlık chunk, aracın 26 karo üstü/altı hazır).
  RAM dar; tüm 60×320 harita bir kerede kurulmuyor. Ölçüm: tipik bir koşuda 19.200 karonun
  ~5.300'ü bellekte, toplam ~30 MB statik bellek.
- **Kazılmış karolar kaydedilmiyor** (görev gereği). Yeni koşu = aynı tohumla temiz dünya;
  kaydedilen şey para, geliştirme seviyeleri, en derin nokta ve tohum.
- **Dünya üretimi saf bir sınıfta** (`DunyaUretici`): Node değil, durum tutmaz, aynı tohum +
  aynı (x, y) hep aynı karoyu verir. Chunk üretimi ve testler buna dayanıyor.

## Çalıştırma

```powershell
godot --path . --import                       # içe aktar
godot --path .                                # oyna
godot --headless --path . --script res://tests/test_calistir.gd   # birim testleri
godot --headless --path . --script res://tests/test_oynanis.gd    # oynanış testi
godot --path . --script res://arac/ekran_al.gd                    # ekran görüntüsü
powershell -ExecutionPolicy Bypass -File arac\karolar_uret.ps1     # karo atlasını yeniden üret
```

Dışa aktarma (klasörler önceden var olmalı):

```powershell
godot --headless --path . --export-release "Windows Masaustu"   # build/windows/derin-kazi.exe
godot --headless --path . --export-release "Web (HTML5)"        # build/web/index.html
```

Web çıktısı `thread_support` ile derlendi: tarayıcıda çalışması için sunucunun
`Cross-Origin-Opener-Policy: same-origin` ve `Cross-Origin-Embedder-Policy: require-corp`
başlıklarını vermesi gerekir (itch.io'da "SharedArrayBuffer" kutusu).

## Düzen

```
scripts/ayarlar.gd        tüm sabitler — denge buradan ayarlanır
scripts/dunya_uretici.gd  tohumdan karo üreten saf sınıf
scripts/dunya.gd          TileMapLayer, chunk yönetimi, kodda kurulan TileSet
scripts/arac.gd           hareket, kazma, yakıt tüketimi
scripts/durum.gd          koşu durumu + tüm ekonomi kuralları (saf, test edilebilir)
scripts/kayit.gd          user://kayit.cfg
scenes/menu.tscn          ana menü      scenes/oyun.tscn  oyun + HUD + üs menüsü
tests/                    headless testler (çıkış kodu 0 = geçti)
```

Kayıt dosyası: `user://kayit.cfg`
(`%APPDATA%\Godot\app_userdata\Derin Kazı\kayit.cfg`).
