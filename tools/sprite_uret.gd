## Tüm görselleri koddan üretir: DÜZ renk, gölgesiz, dış çizgisiz, geometrik.
## GUI aracı yok; bu betik tek kaynak. v0.8'e kadar burada Endesga 32 pixel art vardı;
## tanıtım videosundaki dünyaya (koyu kahve zemin, toprak bantları, kağıt matkap,
## kırmızı uç, amber maden kareleri) geçildi. Boyutlar/düzen AYNI kaldı (atlas sütunları,
## 9 karelik araç, yüzey varyantları): motor tarafı ve testler bunlara bağlı.
##
##   godot --headless --path . --script res://tools/sprite_uret.gd
##
## Çıktılar: assets/sprites/*.png
extends SceneTree

const K := 16   ## karo kenarı

# --- palet (docs/TASARIM.md; scripts/tema.gd ile aynı değerler) -------------
const INK := Color("1c130d")
const ZEMIN := Color("2d2019")
const KAGIT := Color("f3e8d7")
const AMBER := Color("f3a33d")
const TEHLIKE := Color("e94f36")
const UC := Color("e2552c")
const KIRMIZI := Color("571d13")
const CAM := Color("7dd4e7")
const YESIL := Color("6fc38a")

## Taban kayaları (yüzeyden çekirdeğe): video örneklerinden — toprak #896843, koyulaşan
## kahveler, en dipte çekirdek kabuğunun kırmızısı #571d13.
const TABAN := [
	Color("896843"),   # toprak
	Color("6d4f33"),   # taş
	Color("55402c"),   # sert taş
	Color("3b2b20"),   # bazalt
	Color("571d13"),   # çekirdek kabuğu (obsidyen)
]
## Maden kareleri: damarın rengi (zemin katmanın taban kayası).
const MADEN := [
	Color("d9773a"),   # bakır
	Color("b7b1a6"),   # demir
	Color("f3a33d"),   # altın
	Color("7dd4e7"),   # elmas
	Color("f3e8d7"),   # platin
]

func _initialize() -> void:
	var kok := ProjectSettings.globalize_path("res://assets/sprites/")
	DirAccess.make_dir_recursive_absolute(kok)
	_yaz(kok + "karolar.png", _karolar())
	_yaz(kok + "yuzey.png", _yuzey())
	_yaz(kok + "arac.png", _arac())
	_yaz(kok + "isaret.png", _isaret())
	_yaz(kok + "us.png", _us())
	_yaz(kok + "gok.png", _gok())
	_yaz(kok + "tepeler.png", _tepeler())
	_yaz(kok + "kasaba.png", _kasaba())
	_yaz(kok + "fon_kaya.png", _fon_kaya())
	_yaz(kok + "simgeler.png", _simgeler())
	_yaz(kok + "istasyon.png", _istasyon())
	_yaz(kok + "benek.png", _benek())
	_yaz(kok + "logo.png", _logo())
	quit(0)

func _yaz(yol: String, g: Image) -> void:
	var h := g.save_png(yol)
	print("%s  %dx%d  %s" % [yol.get_file(), g.get_width(), g.get_height(), "OK" if h == OK else "HATA"])

static func _bos(g: int, y: int) -> Image:
	var im := Image.create(g, y, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im

# --- çizim yardımcıları ---------------------------------------------------

static func kutu(im: Image, x: int, y: int, g: int, yy: int, renk: Color) -> void:
	for j in range(maxi(y, 0), mini(y + yy, im.get_height())):
		for i in range(maxi(x, 0), mini(x + g, im.get_width())):
			im.set_pixel(i, j, renk)

static func nokta(im: Image, x: int, y: int, renk: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, renk)

## Dolu daire (keskin kenarlı, yumuşatmasız — düz renk dili).
static func daire(im: Image, cx: int, cy: int, r: float, renk: Color) -> void:
	for j in range(int(cy - r) - 1, int(cy + r) + 2):
		for i in range(int(cx - r) - 1, int(cx + r) + 2):
			var dx := float(i - cx) + 0.5
			var dy := float(j - cy) + 0.5
			if dx * dx + dy * dy <= r * r:
				nokta(im, i, j, renk)

## Köşesi 1 px kırpılmış dikdörtgen: videodaki yuvarlatılmış kare hissi.
static func yuvarlak_kutu(im: Image, x: int, y: int, g: int, yy: int, renk: Color) -> void:
	kutu(im, x + 1, y, g - 2, yy, renk)
	kutu(im, x, y + 1, g, yy - 2, renk)

# --- karo atlası ----------------------------------------------------------

## Taban kayası: tek düz renk + varyanta göre 0-2 küçük koyu benek (videodaki toprak
## benekleri). Beneklerin konumu varyant ve türden belirlenimci — yan yana karolar
## 16 px'lik desen oluşturmasın diye her satırda farklı.
func _kaya(im: Image, ox: int, oy: int, renk: Color, v: int, tur: int) -> void:
	kutu(im, ox, oy, K, K, renk)
	var koyu := renk.darkened(0.22)
	var adet := (v + tur) % 3
	for i in adet:
		var x := 2 + ((v * 5 + tur * 3 + i * 7) % 11)
		var y := 2 + ((v * 3 + tur * 5 + i * 5) % 11)
		kutu(im, ox + x, oy + y, 2, 2, koyu)

func _karolar() -> Image:
	var im := _bos(K * Ayarlar.KARO_SAYISI, K * Ayarlar.VARYANT_SAYISI)
	for v in Ayarlar.VARYANT_SAYISI:
		var oy := v * K
		# 5 taban kayası: her satırda benek düzeni farklı
		for t in 5:
			_kaya(im, t * K, oy, TABAN[t], v, t)
		# 5 maden: zemin = v. katmanın kayası, damar iki düz kare
		for i in 5:
			var ox := (Ayarlar.BAKIR + i) * K
			_kaya(im, ox, oy, TABAN[v], v, 5 + i)
			kutu(im, ox + 3, oy + 3, 6, 6, MADEN[i])
			kutu(im, ox + 10, oy + 9, 4, 4, MADEN[i])
		# özel karolar: tehlikeler ve hedefler satırdan bağımsız (0. satırın kopyası)
		_kazilamaz(im, Ayarlar.KAYA * K, oy)
		_cekirdek(im, Ayarlar.CEKIRDEK * K, oy)
		_gaz(im, Ayarlar.GAZ * K, oy)
		_gevsek(im, Ayarlar.GEVSEK * K, oy)
		_lav(im, Ayarlar.LAV * K, oy)
		_sandik(im, Ayarlar.SANDIK * K, oy)
		_eser(im, Ayarlar.ESER * K, oy)
	return im

func _kazilamaz(im: Image, ox: int, oy: int) -> void:
	# "Matkap işlemez": koyu, içine gömülü bir kare. Tünel zeminiyle karışmasın diye
	# tünelden (#1c130d) açık bir zemin.
	kutu(im, ox, oy, K, K, Color("2b2018"))
	kutu(im, ox + 3, oy + 3, 10, 10, Color("15100b"))
	kutu(im, ox + 6, oy + 6, 4, 4, Color("3a2c22"))

func _cekirdek(im: Image, ox: int, oy: int) -> void:
	kutu(im, ox, oy, K, K, KIRMIZI)
	daire(im, ox + 8, oy + 8, 6.0, UC)
	kutu(im, ox + 6, oy + 6, 4, 4, KAGIT)

func _gaz(im: Image, ox: int, oy: int) -> void:
	# Uyarı karosu: tas zemininde yeşil kareler. Kazmadan görülmeli.
	kutu(im, ox, oy, K, K, TABAN[1])
	kutu(im, ox + 3, oy + 4, 5, 5, YESIL)
	kutu(im, ox + 9, oy + 8, 4, 4, YESIL)
	kutu(im, ox + 9, oy + 2, 3, 3, YESIL)

func _gevsek(im: Image, ox: int, oy: int) -> void:
	# Çatlamış kaya: toprak zemininde iki koyu yarık — altı boşalınca düşer.
	kutu(im, ox, oy, K, K, Color("7c5c3b"))
	kutu(im, ox + 2, oy + 4, 8, 2, INK)
	kutu(im, ox + 6, oy + 10, 8, 2, INK)
	kutu(im, ox + 4, oy + 6, 2, 2, INK)
	kutu(im, ox + 10, oy + 8, 2, 2, INK)

func _lav(im: Image, ox: int, oy: int) -> void:
	kutu(im, ox, oy, K, K, TEHLIKE)
	kutu(im, ox, oy, K, 2, AMBER)
	kutu(im, ox + 3, oy + 6, 4, 4, AMBER)
	kutu(im, ox + 10, oy + 10, 3, 3, AMBER)

func _sandik(im: Image, ox: int, oy: int) -> void:
	kutu(im, ox, oy, K, K, TABAN[3])
	yuvarlak_kutu(im, ox + 2, oy + 4, 12, 9, AMBER)
	kutu(im, ox + 2, oy + 7, 12, 1, KIRMIZI)
	kutu(im, ox + 7, oy + 6, 2, 4, INK)

func _eser(im: Image, ox: int, oy: int) -> void:
	kutu(im, ox, oy, K, K, TABAN[3])
	kutu(im, ox + 4, oy + 4, 8, 8, KAGIT)
	kutu(im, ox + 6, oy + 6, 4, 4, AMBER)
	kutu(im, ox + 3, oy + 13, 10, 2, AMBER)

# --- yüzey karosu ---------------------------------------------------------

## 0. satırın toprağı için ayrı "üst" karo seti: YUZEY_VARYANT sütun, tek satır.
## Üstte iki piksellik açık toprak bandı (satır 2-3), geri kalanı toprak. İlk iki
## piksel satırı basamaklı: her varyantta çıkıntılar farklı yerde, gökle birleşim
## ekran boyunca düz tek çizgi olmasın. Karo türü hâlâ TOPRAK.
func _yuzey() -> Image:
	var im := _bos(K * Ayarlar.YUZEY_VARYANT, K)
	const BANT := Color("b58a55")
	for v in Ayarlar.YUZEY_VARYANT:
		var ox := v * K
		kutu(im, ox, 2, K, K - 2, TABAN[0])
		kutu(im, ox, 2, K, 2, BANT)
		# Satır 0-1: 2 px'lik basamaklar (her varyant farklı: konum ve sayı v'den)
		var baslangic := (v * 5 + 1) % 6
		var say := 2 + v % 2
		for i in say:
			var x := ox + (baslangic + i * 5) % (K - 3)
			kutu(im, x, 1, 3, 1, BANT)
			if (v + i) % 2 == 0:
				kutu(im, x + 1, 0, 2, 1, BANT)
		# Bir çukur: bandın kendisi de bir yerde iki piksel çöker.
		kutu(im, ox + 8 + v, 2, 2, 1, Color(0, 0, 0, 0))
		kutu(im, ox + 8 + v, 3, 2, 1, TABAN[0])
		# Kökler: toprak beneği
		kutu(im, ox + 3 + v, 9, 2, 2, TABAN[0].darkened(0.22))
	return im

# --- araç -----------------------------------------------------------------

## 9 kare (scripts/arac.gd KARE_* sabitleri ve oyun.tscn hframes ile aynı düzen):
##   0     bekle
##   1-2   kazma: uç sağa-sola titrer, renk değişir
##   3-5   palet dönüşü: 3 px periyotlu amber dişler her karede 1 px kayar, 3. kare
##         0. kareye döner (dikişsiz)
##   6-8   uçuş: pervane alevi boy ve renk değiştirir, gövde 1 px yukarıda
## Videodaki matkap: kağıt rengi yuvarlak kare gövde + altında kırmızı-turuncu üçgen uç.
func _arac() -> Image:
	var im := _bos(K * 9, K)
	for k in 9:
		var ox := k * K
		var ucus := k >= 6
		var yy := -1 if ucus else 0
		# gövde: kağıt + koyu göz
		yuvarlak_kutu(im, ox + 3, 2 + yy, 10, 7, KAGIT)
		kutu(im, ox + 9, 4 + yy, 2, 2, INK)
		# palet: koyu şerit + amber dişler (3 px periyot)
		var kayma := (k - 3) if k >= 3 and k <= 5 else 0
		kutu(im, ox + 2, 9 + yy, 12, 2, INK)
		for i in 4:
			nokta(im, ox + 2 + (i * 3 + kayma) % 12, 9 + yy, AMBER)
		# uç: aşağı bakan üçgen
		var kaziyor := k == 1 or k == 2
		var kx := ox + ((k - 1) * 2 - 1 if kaziyor else 0)   # kazarken ±1 px titrer
		var uc := AMBER if (kaziyor and k == 2) else UC
		kutu(im, kx + 5, 11 + yy, 6, 1, uc)
		kutu(im, kx + 6, 12 + yy, 4, 1, uc)
		kutu(im, kx + 7, 13 + yy, 2, 1, uc)
		# pervane alevi: gövdenin iki yanında
		if ucus:
			_alev(im, ox + 1, k - 6)
			_alev(im, ox + 13, k - 6)
	return im

## Egzoz alevi (2 px geniş). 0: kısa · 1: uzun, amber çekirdek · 2: alçak, kıvılcımlı
func _alev(im: Image, x: int, kare: int) -> void:
	match kare:
		0:
			kutu(im, x, 10, 2, 2, UC)
		1:
			kutu(im, x, 10, 2, 4, UC)
			kutu(im, x, 10, 2, 2, AMBER)
		2:
			kutu(im, x, 11, 2, 3, TEHLIKE)
			nokta(im, x + 1, 14, AMBER)

## Işınlama işareti: kağıt direk + amber flama. İstasyondan ayrı okunmalı (istasyon camgöbeği).
func _isaret() -> Image:
	var im := _bos(K, K)
	kutu(im, 7, 2, 2, 13, KAGIT)
	kutu(im, 9, 3, 5, 4, AMBER)
	kutu(im, 5, 14, 6, 2, KAGIT)
	return im

# --- yüzey ----------------------------------------------------------------

## Üs binası: satış + geliştirme dükkânı + asansör kulesi, 120x56, zemini y=56'da.
func _us() -> Image:
	var g := 120
	var y := 56
	var im := _bos(g, y)
	kutu(im, 0, y - 6, g, 6, TABAN[0])
	kutu(im, 0, y - 6, g, 2, Color("b58a55"))
	# sol bina: kağıt, amber çatı, koyu pencere ve kapı
	kutu(im, 6, 20, 34, 30, KAGIT)
	kutu(im, 4, 16, 38, 5, AMBER)
	kutu(im, 12, 28, 8, 8, INK)
	kutu(im, 26, 28, 8, 8, INK)
	kutu(im, 18, 38, 10, 12, ZEMIN)
	kutu(im, 32, 6, 6, 10, ZEMIN)
	# sağ bina: amber, kağıt çatı
	kutu(im, 56, 14, 40, 36, AMBER)
	kutu(im, 54, 10, 44, 5, KAGIT)
	kutu(im, 62, 22, 10, 9, INK)
	kutu(im, 80, 22, 10, 9, INK)
	kutu(im, 70, 36, 12, 14, ZEMIN)
	daire(im, 100, 22, 7.0, KAGIT)
	daire(im, 100, 22, 3.0, AMBER)
	# asansör kulesi
	kutu(im, 44, 4, 10, 46, ZEMIN)
	kutu(im, 46, 8, 6, 2, KAGIT)
	kutu(im, 46, 16, 6, 2, KAGIT)
	kutu(im, 46, 24, 6, 2, KAGIT)
	kutu(im, 42, 0, 14, 5, TEHLIKE)
	return im

func _gok() -> Image:
	# Düz gök: video zemini. 8 px'lik şerit ekrana yayılır.
	var im := _bos(8, 180)
	im.fill(ZEMIN)
	return im

func _tepeler() -> Image:
	# Uzak tepe: basamaklı geometrik siluet (320x64), yatayda tekrar eder. Düz renk.
	var g := 320
	var y := 64
	var im := _bos(g, y)
	var yuks := [34, 28, 40, 30, 24, 36, 42, 32, 26, 38, 30, 34, 28, 40, 34, 34]   # 16 sütun x 20 px, başı = sonu
	for s in yuks.size():
		kutu(im, s * 20, int(yuks[s]), 20, y - int(yuks[s]), Color("362820"))
	return im

func _kasaba() -> Image:
	# Yakın plan kasaba: düz koyu bloklar, birkaç amber pencere (320x48), yatayda tekrar eder.
	var g := 320
	var y := 48
	var im := _bos(g, y)
	var x := 0
	var i := 0
	var genis := [18, 24, 16, 22, 20, 26, 14, 24, 18, 22, 20, 24]
	var yuk := [22, 30, 18, 34, 26, 20, 32, 24, 28, 18, 30, 22]
	while x < g and i < genis.size():
		var bg: int = genis[i]
		var by: int = yuk[i]
		kutu(im, x, y - by, bg, by, INK)
		if i % 3 == 0:
			kutu(im, x + 4, y - by + 5, 3, 3, AMBER)
		if i % 4 == 1:
			kutu(im, x + bg - 7, y - by + 9, 3, 3, AMBER)
		x += bg + 4
		i += 1
	kutu(im, 0, y - 4, g, 4, INK)
	return im

func _fon_kaya() -> Image:
	# Yeraltı arka planı: düz beyaz, oyunda katman rengiyle boyanır (oyun.gd → _arkaplan_yenile).
	var im := _bos(64, 64)
	im.fill(Color(1, 1, 1, 1))
	return im

# --- arayüz ---------------------------------------------------------------

## 9 simge x 16 px (yedek): yakıt, yük, para, can, derinlik, radar, dinamit, istasyon, eser.
## Düz geometri; oyunda kullanılan asıl simgeler yazı tipinden gelir.
func _simgeler() -> Image:
	var im := _bos(K * 9, K)
	kutu(im, 3, 4, 10, 10, AMBER)
	kutu(im, K + 2, 5, 12, 9, TABAN[0])
	daire(im, K * 2 + 8, 8, 6.0, AMBER)
	kutu(im, K * 3 + 3, 4, 10, 9, TEHLIKE)
	kutu(im, K * 4 + 7, 2, 2, 8, CAM)
	daire(im, K * 5 + 8, 9, 6.0, YESIL)
	kutu(im, K * 6 + 4, 6, 8, 8, TEHLIKE)
	kutu(im, K * 7 + 3, 5, 10, 9, KAGIT)
	kutu(im, K * 8 + 4, 4, 8, 8, AMBER)
	return im

func _istasyon() -> Image:
	var im := _bos(16, 24)
	kutu(im, 2, 8, 12, 15, KAGIT)
	kutu(im, 1, 5, 14, 4, AMBER)
	kutu(im, 5, 12, 6, 6, CAM)
	kutu(im, 7, 0, 2, 6, KAGIT)
	kutu(im, 2, 22, 12, 2, ZEMIN)
	return im

func _benek() -> Image:
	var im := _bos(4, 4)
	im.fill(Color(1, 1, 1, 1))
	return im

func _logo() -> Image:
	# Kapak görselinde ve menüde: kağıt gövde + kırmızı uç (48x48), amber zemin karesi.
	var im := _bos(48, 48)
	yuvarlak_kutu(im, 0, 0, 48, 48, ZEMIN)
	yuvarlak_kutu(im, 12, 8, 24, 18, KAGIT)
	kutu(im, 28, 13, 5, 5, INK)
	for i in 8:
		kutu(im, 14 + i, 27 + i, 20 - i * 2, 1, UC)
	kutu(im, 22, 40, 4, 3, AMBER)
	return im
