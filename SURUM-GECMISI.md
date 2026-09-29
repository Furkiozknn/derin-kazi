# Sürüm geçmişi — Derin Kazı

README'nin ilk ekranı bir sürüm dökümüyle doluydu. Liste silinmedi, buraya taşındı.

Güncel sürümün notları GitHub'da da duruyor:
<https://github.com/Furkiozknn/derin-kazi/releases>

## v0.9 — günlük video imkânları (29 Eylül 2026)

Günlük videolarda kullanılan **renk akışı** ve **geçiş aileleri** oyuna alındı; oyunun kendi
dünyası (koyu kahve zemin, amber, elmas camgöbeği, uç turuncusu, gaz yeşili, kâğıt) korundu.
Çekirdek mekanik, denge ve bot ölçümleri **değişmedi**.

- **Sekiz geçiş ailesi** tek shader'da (`assets/gecis.gdshader`, GL Compatibility): iris, glitch,
  bloklar, itme, perde, flaş, kararma, zoom. Menü açılışı (iris), menü → oyun (zoom), oyun → menü
  (perde), ışınlanma (bloklar), duraklatma (perde), oyun sonu (iris), çekirdeğe dokunuş (flaş),
  deprem (glitch), dil değişimi (glitch), yüzeye çekilme (tehlike renginde flaş).
- **Renk akışı:** iki derinlik paleti (toprak + kaya, bazalt + çekirdek); yazı rengi vurgunun
  üstünde kodla seçilir (en düşük 4,85:1, eşik 4,5:1). Derinlik sayacı her yeni 25 m'de akış
  rengine döner; en derin aşılınca **YENİ REKOR** damgası renk akışında döner.
- **Sade geçişler** (ayarlarda, tarayıcıda `prefers-reduced-motion` de): efekt yok, bekleme yok,
  sayaç vurgusu yok. Yeni `[ayar] sade_gecis` anahtarı; eski kayıt ve ayarlar açılır.
- **Ham klip** yeniden üretildi: 19 sn, sekiz ailenin hepsi görünür.
- **Testler:** 333 → 358 birim, 191 → 238 oynanış (palet kontrastı, havuzlar, her ailenin örtme/açma,
  sırayla tekrarsız seçim, sade kip, oyun içi tüm kullanım yerleri). `ci.yml` tabanları 358 ve 238.
- **Kare süresi** (`tools/fps.gd`, Intel UHD, 60 m): geçişsiz 3,15 → 2,68 ms (medyan, makine gürültülü);
  geçiş sürerken ort. 3,42 ms, %99 4,84-5,05 ms (~293 FPS). Ayrıntı: `docs/TASARIM.md` §7.

## v0.8 — arayüz yenilemesi (29 Eylül 2026)

Oyun, tanıtım videosuyla aynı dünyada: düz renk (gölgesiz, konturlu değil) toprak bantları,
kağıt rengi matkap + kırmızı uç, amber maden kareleri; Instrument Sans + JetBrains Mono
(OFL, lisansları `assets/fonts/`). Tüm görseller `tools/sprite_uret.gd` ile düz geometriye
yeniden üretildi (boyutlar ve atlas düzeni aynı). Çekirdek mekanik, denge ve bot ölçümleri
**değişmedi** (tur 106 sn, çekirdeğe 25 dk, 7/7 ve 12/12).

- **Menü:** tek büyük **Oyna**, tek satır kontrol yardımı, küçük ikincil düğmeler; sol şeritte
  ağır ağır inen matkap. "Yeni dünya" iki adımlı.
- **Yeni ekranlar:** duraklatma (Devam · Ayarlar · Menü + tam tuş listesi), oyun sonu (süre,
  en derin, istatistik, tek dokunuşla **Tekrar — Derin Mod xN**), ayarlar (ses, sarsıntı,
  tam ekran, **dil**). HUD yalnız gerekli bilgi; renk yalnız uyarıda. Menü ⇄ oyun renk bandı
  geçişi, yüzeye çekilirken tehlike flaşı.
- **Türkçe / İngilizce:** varsayılan tarayıcı / sistem dili (`tr` değilse İngilizce); ayarlardan
  değişir. Kayıt: `[ayar]` bölümüne yeni `dil` anahtarı; eski kayıt ve en iyi değerler bozulmaz.
- **Oynanış hissi (ölçüldü, `tools/his_olc.gd`):** dinamit kojotu + tamponu 0,12 sn (inişten önce
  basışta 1/8 → 8/8); kazı hizalama — deliğin kenarına asılan araç düşüyor (3/11 → 11/11).
- **Testler:** 304 → 333 birim, 156 → 191 oynanış (menü / duraklat / oyun sonu / dil / tema /
  girdi toleransı / çeviri kapsamı). `ci.yml` tabanları 333 ve 191.
- **Boyut:** web `index.pck` 970.752 → 1.220.160 bayt (yazı tipleri); toplam +%0,61. Kare süresi
  60 m derinlikte 2,56 → 2,83 ms (medyan). Ayrıntı: `docs/TASARIM.md` §5.
- **Denetim ve tasarım belgeleri:** `docs/DENETIM.md`, `docs/TASARIM.md`.

## v0.7.2 — paket küçültme ve depo turu (22 Eylül 2026)

Oynanış v0.7 ile aynı. Dışa aktarma ön ayarlarından `tests/*`, `tools/*`,
`docs/*` ve `yayin/*` çıkarıldı: web paketi **1.782.396 → 968.680 bayt**. Yeni
paketin dosya tablosu okunarak doğrulandı — `res://yayin`, `res://docs`,
`res://tests`, `res://tools` altında 0 dosya, 106 oyun dosyası yerinde. Ayrıca
MIT lisansı, her push'ta **304 birim + 156 oynanış** testi, 19 belge düzeltmesi
ve `*.gif` dosyalarının Git LFS'e alınması.

## Önceki sürümler

Aşağıdaki döküm README'den olduğu gibi taşındı.

> Durum: **v0.7.1 — v0.7'nin oynanışı + MIT lisansı ve her push'ta CI.**
> v0.7 sunum turu ve ışınlama işaretiydi; v0.6'nın üstüne: yüzey
> karosunun çimenli, kırık kenarlı "üst" görünümü; araç animasyonuna palet dönüşü
> (yolla döner) ve üç kareli pervane alevi; kazarken çalıp durunca sönen **matkap
> döngü sesi** ve depreme özel sarsıntı + çatırtı gürültüsü (ikisi de kodla
> sentezlendi, deterministik); bitiş ekranında **istatistik dökümü** (bu dünya +
> bütün dünyaların `[oyuncu]` toplamı); **ışınlama işareti** — yeraltında `R` ile
> tek kullanımlık dönüş noktası koy, üsten ışınlan. Bot hiçbirini bilmiyor: ölçümler
> v0.6 ile birebir aynı. Windows + Web çıktısı alınıyor; yayın paketi `yayin/`
> altında hazır (**yüklenmedi**).
