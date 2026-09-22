# Sürüm geçmişi — Derin Kazı

README'nin ilk ekranı bir sürüm dökümüyle doluydu. Liste silinmedi, buraya taşındı.

Güncel sürümün notları GitHub'da da duruyor:
<https://github.com/Furkiozknn/derin-kazi/releases>

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
