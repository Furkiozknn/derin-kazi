# Derin Kazı — proje kuralları

Bu dosya her oturumda okunur. Kısa ve güncel tut.

## Ne bu

Yandan kesit kazı + gelişim oyunu (Godot 4.7.2). 250 m derinlikteki çekirdeğe in.
Arayüz, kod ve belgeler **Türkçe**. Değişken/fonksiyon adları da Türkçe.

## Motor ve ayarlar — değiştirme

- **GL Compatibility** renderer (tümleşik Intel UHD hedefi). `forward_plus` açma.
- Pixel art: `default_texture_filter=0` (nearest), `snap_2d_transforms_to_pixel`,
  `snap_2d_vertices_to_pixel`. Kamera yakınlaştırması **2x**, temel görüntü 640x360.
- Tüm `.gd` / `.tscn` / `.cfg` / `.md` dosyaları **BOM'suz UTF-8**.
- Ses veri yolları: `Master > Muzik`, `Master > Efekt` (`default_bus_layout.tres`).
- `Ses` autoload'u (`scripts/ses.gd`) efekt ve müziği yönetir; doğrudan
  `AudioStreamPlayer` eklemek yerine `Ses.cal("olay")` kullan.

## Klasörler

```
scripts/ayarlar.gd        TÜM denge sabitleri — sayı değiştireceksen burası
scripts/dunya_uretici.gd  tohumdan karo üreten saf sınıf (Node değil)
scripts/dunya.gd          TileMapLayer, 16x16 chunk yönetimi, kazı farkı
scripts/durum.gd          koşu + ilerleme durumu, tüm ekonomi kuralları (saf sınıf)
scripts/arac.gd           hareket, kazma, hasar, aletler
scripts/oyun.gd           HUD, üs, müze, ışınlanma, tehlikeler, oyun hissi
scripts/ses.gd            autoload: efekt/müzik/ayar
scripts/ayar_panel.gd     ayarlar ekranının içeriği (menü + duraklatma ortak)
scenes/                   menu · oyun · kapak
tools/                    varlık üretimi ve ekran görüntüsü betikleri
tests/                    headless testler (çıkış kodu 0 = geçti)
yayin/                    itch sayfası, ekran görüntüleri, kapak, butler komutları
_eski/                    kullanımdan kalkmış dosyalar (silme yok, buraya taşı)
```

## Denge

Bütün sayılar `scripts/ayarlar.gd` içinde. Değiştirdikten sonra **mutlaka**
`tests/test_denge.gd` çalıştır: gerçek üretici ve ekonomiyle bir bot simüle edip
tur süresini, tur başına geliştirmeyi, 10. dakikayı ve katman başına geliri ölçer.

Bilinmesi gereken iki bağ:
- **Maden ağırlığı** (`MADEN_AGIRLIK`) katman başına geliri ~x1,5'te tutan ayardır.
  Yalnız `MADEN_DEGER`'i büyütürsen gelir katman başına x2'nin üstüne çıkar.
- **`BEDAVA_YAKIT_ORAN`** kilitlenme önlemi: parasız + yakıtsız oyuncu kalmasın.
  Kaldırırsan simülasyon 88 m'de takılıp 0 gelirle döner.

## Komutlar

```powershell
godot --headless --path . --import                                # içe aktar
godot --path .                                                    # oyna
godot --headless --path . --script res://tests/test_calistir.gd   # birim testleri
godot --headless --path . --script res://tests/test_oynanis.gd    # oynanış testi
godot --headless --path . --script res://tests/test_denge.gd      # denge simülasyonu
godot --headless --path . --script res://tools/sprite_uret.gd     # tüm pixel art
godot --headless --path . --script res://tools/onizleme.gd        # sprite önizleme sayfası
godot --path . --script res://tools/ekran_al.gd                   # yayın görselleri (render gerekir)
godot --headless --path . --export-release "Windows Masaustu"
godot --headless --path . --export-release "Web (HTML5)"
```

Müzik (ön ayarlar: hizli/neseli/sakin/gizemli/gergin):
```powershell
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik.wav --ruh gizemli --tohum 3
```

Godot yolu: `C:\Users\furki\AppData\Local\Microsoft\WinGet\Links\godot.exe`

## Godot kilidi

Aynı anda birden çok oyun oturumu çalışıyor, RAM dar. Godot çalıştırmadan önce
`D:\Repolar\.godot-kilit` dosyasını al (varsa ve 15 dk'dan yeniyse 30 sn bekle;
yoksa oluştur, içine `derin-kazi` yaz), iş bitince sil. Açık süreç bırakma.

## Yayın

**Push yok, GitHub deposu yok, itch.io yüklemesi yok.** Yayın paketi yalnız
hazırlanır (`yayin/`), yükleme kararı Furki'nin. `yayin/butler-komutlari.md`
içindeki komutlar bilerek çalıştırılmamış durumda.

## Varlık üretimi

GUI aracı kullanılamıyor. Tüm pixel art `tools/sprite_uret.gd` içinde Godot
`Image` API'siyle üretiliyor; palet **Endesga 32** ve o dosya tek kaynak.
Elle PNG düzenleme yok — görseli değiştireceksen betiği değiştir ve yeniden üret,
sonra `tools/onizleme.gd` ile çıktıyı gözle denetle.

Ses efektleri rFXGen ön ayarlarından (`D:\Araclar\rFXGen\...\rfxgen.exe`).
`--generate` aynı ön ayar için **hep aynı** dalgayı veriyor (denendi), bu yüzden
çeşitlilik `scripts/ses.gd` içindeki perde eşlemesinden geliyor.
