## Tüm pixel art'ı koddan üretir. GUI aracı yok; bu betik tek kaynak.
## Palet: Endesga 32 (EDG32) — oyunun tamamı bu 32 renge bağlı.
##
##   godot --headless --path . --script res://tools/sprite_uret.gd
##
## Çıktılar: assets/sprites/*.png
extends SceneTree

const K := 16   ## karo kenarı

# --- Endesga 32 -----------------------------------------------------------
const EDG := [
	"be4a2f", "d77643", "ead4aa", "e4a672", "b86f50", "733e39", "3e2731", "a22633",
	"e43b44", "f77622", "feae34", "fee761", "63c74d", "3e8948", "265c42", "193c3e",
	"124e89", "0099db", "2ce8f5", "ffffff", "c0cbdc", "8b9bb4", "5a6988", "3a4466",
	"262b44", "181425", "ff0044", "68386c", "b55088", "f6757a", "e8b796", "c28569",
]

var rng := RandomNumberGenerator.new()

static func c(i: int) -> Color:
	return Color(EDG[i])

func _initialize() -> void:
	var kok := ProjectSettings.globalize_path("res://assets/sprites/")
	DirAccess.make_dir_recursive_absolute(kok)
	_yaz(kok + "karolar.png", _karolar())
	_yaz(kok + "arac.png", _arac())
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

## Dolu elips (maden damarı, yumuşak lekeler için).
static func elips(im: Image, cx: int, cy: int, rx: float, ry: float, renk: Color) -> void:
	for j in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for i in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (float(i - cx) + 0.5) / maxf(rx, 0.5)
			var dy := (float(j - cy) + 0.5) / maxf(ry, 0.5)
			if dx * dx + dy * dy <= 1.0:
				nokta(im, i, j, renk)

# --- karo atlası ----------------------------------------------------------

## [koyu, ana, açık] üçlüsü ile gürültülü kaya dokusu.
## Sert kenar çizgisi YOK: 16 px'lik karo ekranda tekrarladığı için düz bir üst/alt
## şerit duvarı tuğlaya çeviriyordu. Onun yerine yumuşak dikey degrade + çakıl kümesi.
func _kaya_dokusu(im: Image, ox: int, koyu: Color, ana: Color, acik: Color) -> void:
	for y in K:
		# üstte biraz aydınlık, altta biraz koyu — ama karşıtlık düşük
		var t := float(y) / float(K - 1)
		var zemin := Color(acik).lerp(ana, clampf(t * 2.2, 0.0, 1.0)).lerp(koyu, clampf((t - 0.55) * 1.1, 0.0, 1.0))
		for x in K:
			var r := rng.randi() % 100
			var renk := zemin
			if r < 18:
				renk = Color(zemin).lerp(koyu, 0.75)
			elif r < 32:
				renk = Color(zemin).lerp(acik, 0.6)
			im.set_pixel(ox + x, y, renk)
	# birkaç çakıl: tekrar eden dokuyu kırar
	for i in 3:
		var cx := 2 + rng.randi() % (K - 4)
		var cy := 2 + rng.randi() % (K - 4)
		elips(im, ox + cx, cy, 1.8, 1.4, Color(ana).lerp(koyu, 0.6))
		nokta(im, ox + cx - 1, cy - 1, Color(ana).lerp(acik, 0.7))

## Maden damarı: koyu dış hat + parlak çekirdek. 16 px'te okunur olsun diye
## üç ayrı küme ve her kümede bir beyaz parıltı pikseli var.
func _damar(im: Image, ox: int, renk: Color, parlak: Color) -> void:
	var koyu := renk.darkened(0.45)
	var kumeler := [Vector3i(4, 4, 2), Vector3i(11, 7, 2), Vector3i(6, 11, 2)]
	for kume in kumeler:
		elips(im, ox + kume.x, kume.y, float(kume.z) + 0.6, float(kume.z) + 0.6, koyu)
	for kume in kumeler:
		elips(im, ox + kume.x, kume.y, float(kume.z) - 0.2, float(kume.z) - 0.2, renk)
		nokta(im, ox + kume.x - 1, kume.y - 1, parlak)

func _karolar() -> Image:
	rng.seed = 20260916
	var im := _bos(K * Ayarlar.KARO_SAYISI, K)

	# 5 katman taban kayası: yüzeyden çekirdeğe doğru koyulaşır.
	var tabanlar := [
		[c(6), c(5), c(4)],       # toprak  — koyu kahve (bakır üstünde okunsun)
		[c(22), c(21), c(20)],    # taş     — mavi gri
		[c(15), c(23), c(22)],    # sert taş— soğuk teal aralık
		[c(25), c(24), c(23)],    # bazalt  — gece mavisi
		[c(25), c(27), c(23)],    # obsidyen— mor siyah
	]
	for i in tabanlar.size():
		_kaya_dokusu(im, i * K, tabanlar[i][0], tabanlar[i][1], tabanlar[i][2])

	# 5 maden. Damar kayası HER katmanda aynı nötr koyu taş: bakır bazaltın içinde
	# de çıkabiliyor, kendi katmanının kayasıyla çizilirse oraya yanlış yapıştırılmış
	# gibi duruyordu. Rengi damar veriyor, zemin değil.
	var damar_kaya := [c(25), c(23), c(22)]
	var madenler := [
		[c(9), c(10)],     # bakır  — turuncu
		[c(20), c(19)],    # demir  — gümüş
		[c(10), c(11)],    # altın  — sarı
		[c(18), c(19)],    # elmas  — camgöbeği
		[c(12), c(11)],    # platin — yeşil
	]
	for i in madenler.size():
		var ox := (Ayarlar.BAKIR + i) * K
		_kaya_dokusu(im, ox, damar_kaya[0], damar_kaya[1], damar_kaya[2])
		_damar(im, ox, madenler[i][0], madenler[i][1])

	_kazilamaz_kaya(im, Ayarlar.KAYA * K)
	_cekirdek(im, Ayarlar.CEKIRDEK * K)
	_gaz(im, Ayarlar.GAZ * K)
	_gevsek(im, Ayarlar.GEVSEK * K)
	_lav(im, Ayarlar.LAV * K)
	_sandik(im, Ayarlar.SANDIK * K)
	_eser(im, Ayarlar.ESER * K)
	return im

func _kazilamaz_kaya(im: Image, ox: int) -> void:
	# Köşeli, parlak kenarlı: "buraya matkap işlemez" hissi.
	_kaya_dokusu(im, ox, c(26 - 1), c(25), c(24))
	for y in K:
		for x in K:
			if (x + y) % 7 == 0:
				im.set_pixel(ox + x, y, c(23))
	kutu(im, ox + 2, 2, 12, 1, c(22))
	kutu(im, ox + 2, 13, 12, 1, c(26 - 1))
	kutu(im, ox + 2, 3, 1, 10, c(22))
	kutu(im, ox + 13, 3, 1, 10, c(26 - 1))

func _cekirdek(im: Image, ox: int) -> void:
	_kaya_dokusu(im, ox, c(25), c(27), c(28))
	elips(im, ox + 8, 8, 6.2, 6.2, c(28))
	elips(im, ox + 8, 8, 4.6, 4.6, c(26))
	elips(im, ox + 8, 8, 3.0, 3.0, c(9))
	elips(im, ox + 8, 8, 1.6, 1.6, c(11))
	nokta(im, ox + 7, 7, c(19))
	for i in 4:
		nokta(im, ox + 8, i + 1, c(28))
		nokta(im, ox + 8, 14 - i, c(28))

func _gaz(im: Image, ox: int) -> void:
	# Uyarı karosu: kayanın içinde parlak yeşil kabarcıklar. Kazmadan görülmeli.
	_kaya_dokusu(im, ox, c(22), c(21), c(20))
	var kabarcik := [Vector3i(5, 6, 3), Vector3i(10, 9, 2), Vector3i(7, 12, 2)]
	for k in kabarcik:
		elips(im, ox + k.x, k.y, float(k.z), float(k.z), c(14))
		elips(im, ox + k.x, k.y, float(k.z) - 1.0, float(k.z) - 1.0, c(12))
		nokta(im, ox + k.x - 1, k.y - 1, c(11))
	nokta(im, ox + 2, 3, c(12))
	nokta(im, ox + 13, 4, c(12))

func _gevsek(im: Image, ox: int) -> void:
	# Çatlamış kaya: altı boşalınca düşer. Çatlaklar görünür uyarı.
	_kaya_dokusu(im, ox, c(6), c(5), c(4))
	var catlak := [[1, 4], [2, 5], [3, 5], [4, 6], [5, 7], [6, 7], [7, 8], [8, 8],
		[9, 9], [10, 9], [11, 10], [12, 10], [13, 11], [4, 2], [5, 3], [6, 3],
		[10, 2], [11, 3], [2, 11], [3, 12], [9, 13], [10, 13], [11, 12]]
	for p in catlak:
		nokta(im, ox + p[0], p[1], c(26 - 1))
		nokta(im, ox + p[0], p[1] + 1, c(6))
	kutu(im, ox, 0, K, 1, c(3))

func _lav(im: Image, ox: int) -> void:
	for y in K:
		for x in K:
			var r := rng.randi() % 100
			var renk := c(9)
			if r < 22:
				renk = c(10)
			elif r < 34:
				renk = c(0)
			im.set_pixel(ox + x, y, renk)
	# Üstte parlak, altta karanlık: derinlik hissi.
	for x in K:
		im.set_pixel(ox + x, 0, c(11))
		im.set_pixel(ox + x, 1, c(10))
		im.set_pixel(ox + x, K - 1, c(7))
	for i in 3:
		elips(im, ox + 3 + i * 5, 6 + (i % 2) * 4, 1.6, 1.2, c(11))

func _sandik(im: Image, ox: int) -> void:
	_kaya_dokusu(im, ox, c(23), c(22), c(21))   ## karo kayanın içinde durur
	kutu(im, ox + 1, 4, 14, 11, c(6))
	kutu(im, ox + 2, 5, 12, 9, c(5))
	kutu(im, ox + 2, 5, 12, 3, c(4))
	kutu(im, ox + 1, 3, 14, 2, c(6))
	kutu(im, ox + 2, 3, 12, 1, c(4))
	kutu(im, ox + 7, 7, 2, 4, c(11))     # kilit
	nokta(im, ox + 7, 8, c(10))
	kutu(im, ox + 2, 9, 12, 1, c(6))
	for x in range(2, 14):
		nokta(im, ox + x, 14, c(26 - 1))

func _eser(im: Image, ox: int) -> void:
	_kaya_dokusu(im, ox, c(25), c(24), c(23))   ## karo kayanın içinde durur
	kutu(im, ox + 3, 12, 10, 3, c(22))   # kaide
	kutu(im, ox + 4, 12, 8, 1, c(21))
	elips(im, ox + 8, 7, 4.2, 4.6, c(10))
	elips(im, ox + 8, 7, 2.8, 3.2, c(11))
	kutu(im, ox + 7, 3, 2, 3, c(10))
	kutu(im, ox + 5, 4, 6, 1, c(11))
	nokta(im, ox + 6, 5, c(19))
	nokta(im, ox + 10, 9, c(19))
	for i in 3:                           # parıltı
		nokta(im, ox + 2, 3 + i * 4, c(11))
		nokta(im, ox + 13, 5 + i * 3, c(11))

# --- araç -----------------------------------------------------------------

## 4 kare: 0 bekle · 1-2 kazma (matkap döner) · 3 pervane (uçuş)
func _arac() -> Image:
	var im := _bos(K * 4, K)
	for k in 4:
		var ox := k * K
		var yy := 0
		if k == 3:
			yy = -1                       # uçarken hafif yukarı kayar
		# gövde
		kutu(im, ox + 2, 4 + yy, 12, 7, c(6))
		kutu(im, ox + 3, 5 + yy, 10, 5, c(10))
		kutu(im, ox + 3, 5 + yy, 10, 1, c(11))
		# kabin
		kutu(im, ox + 4, 3 + yy, 6, 3, c(6))
		kutu(im, ox + 5, 4 + yy, 4, 2, c(17))
		nokta(im, ox + 5, 4 + yy, c(18))
		# paletler
		kutu(im, ox + 2, 11 + yy, 12, 3, c(24))
		kutu(im, ox + 3, 12 + yy, 10, 1, c(22))
		for i in 5:
			nokta(im, ox + 3 + i * 2 + (k % 2), 12 + yy, c(20))
		# matkap (aşağı bakar): koyu dış hat + parlak dişler, kazma karelerinde kayar
		kutu(im, ox + 5, 10 + yy, 6, 5, c(25))
		kutu(im, ox + 6, 10 + yy, 4, 4, c(21))
		kutu(im, ox + 6, 10 + yy, 1, 4, c(20))
		var d := c(19) if k == 1 or k == 2 else c(20)
		for i in 4:
			if (i + k) % 2 == 0:
				nokta(im, ox + 6 + i, 14 + yy, d)
			else:
				nokta(im, ox + 6 + i, 13 + yy, d)
		# egzoz / pervane alevi
		if k == 3:
			kutu(im, ox + 4, 14, 2, 2, c(9))
			kutu(im, ox + 10, 14, 2, 2, c(9))
			nokta(im, ox + 5, 15, c(11))
			nokta(im, ox + 10, 15, c(11))
	return im

# --- yüzey kasabası -------------------------------------------------------

## Üs binası: satış terazisi + geliştirme dükkânı, 120x56, zemini y=56'da.
func _us() -> Image:
	var g := 120
	var y := 56
	var im := _bos(g, y)
	# zemin platformu
	kutu(im, 0, y - 6, g, 6, c(5))
	kutu(im, 0, y - 6, g, 1, c(3))
	# sol bina: satış (teraziye benzer çatı)
	kutu(im, 6, 20, 34, 30, c(23))
	kutu(im, 7, 21, 32, 28, c(22))
	kutu(im, 4, 16, 38, 5, c(0))
	kutu(im, 4, 16, 38, 1, c(1))
	kutu(im, 12, 28, 8, 8, c(17))
	kutu(im, 26, 28, 8, 8, c(17))
	kutu(im, 18, 38, 10, 12, c(6))
	kutu(im, 19, 39, 8, 11, c(5))
	nokta(im, 25, 44, c(11))
	# baca
	kutu(im, 32, 8, 6, 9, c(6))
	kutu(im, 31, 6, 8, 3, c(5))
	# sağ bina: geliştirme dükkânı (dişli tabelası)
	kutu(im, 56, 14, 40, 36, c(23))
	kutu(im, 57, 15, 38, 34, c(22))
	kutu(im, 54, 10, 44, 5, c(13))
	kutu(im, 54, 10, 44, 1, c(12))
	kutu(im, 62, 22, 10, 9, c(17))
	kutu(im, 80, 22, 10, 9, c(17))
	kutu(im, 70, 36, 12, 14, c(6))
	kutu(im, 71, 37, 10, 13, c(5))
	nokta(im, 79, 43, c(11))
	# dişli tabelası
	elips(im, 100, 22, 7.0, 7.0, c(21))
	elips(im, 100, 22, 4.5, 4.5, c(10))
	elips(im, 100, 22, 2.0, 2.0, c(23))
	for i in 6:
		var a := TAU * float(i) / 6.0
		kutu(im, 100 + int(cos(a) * 8.0) - 1, 22 + int(sin(a) * 8.0) - 1, 3, 3, c(21))
	# asansör kulesi (araç buradan iner)
	kutu(im, 44, 4, 10, 46, c(24))
	kutu(im, 45, 5, 8, 44, c(23))
	for i in 8:
		kutu(im, 45, 8 + i * 5, 8, 1, c(21))
	kutu(im, 42, 0, 14, 5, c(8))
	kutu(im, 42, 0, 14, 1, c(9))
	return im

func _gok() -> Image:
	# Alacakaranlık gök: 4 bantlı degrade, 1 px genişliğinde uzatılır.
	var y := 180
	var im := _bos(8, y)
	var bantlar := [c(23), c(22), c(28), c(4)]
	for j in y:
		var t := float(j) / float(y - 1)
		var i := clampi(int(t * float(bantlar.size())), 0, bantlar.size() - 1)
		var sonraki: Color = bantlar[mini(i + 1, bantlar.size() - 1)]
		var f := t * float(bantlar.size()) - float(i)
		kutu(im, 0, j, 8, 1, Color(bantlar[i]).lerp(sonraki, f))
	# Yıldız yok: 8 px'lik şerit ekrana yayıldığı için tek piksel uzun bir
	# yatay çizgiye dönüşüyordu.
	return im

func _tepeler() -> Image:
	# Uzak tepe silueti, yatayda tekrar eder (320x64).
	var g := 320
	var y := 64
	var im := _bos(g, y)
	rng.seed = 31
	var yuks := PackedInt32Array()
	var h := 34
	for x in g:
		if x % 16 == 0:
			h = clampi(h + rng.randi_range(-5, 5), 20, 46)
		yuks.append(h)
	# başı ve sonu eşitle (tekrar dikişsiz olsun)
	for x in range(g - 24, g):
		var f := float(x - (g - 24)) / 24.0
		yuks[x] = int(lerpf(float(yuks[x]), float(yuks[0]), f))
	for x in g:
		kutu(im, x, yuks[x], 1, y - yuks[x], c(23))
		nokta(im, x, yuks[x], c(22))
	return im

func _kasaba() -> Image:
	# Yakın plan kasaba silueti (320x48), yatayda tekrar eder.
	var g := 320
	var y := 48
	var im := _bos(g, y)
	rng.seed = 91
	var x := 0
	while x < g:
		var bg := rng.randi_range(14, 26)
		var by := rng.randi_range(16, 34)
		kutu(im, x, y - by, bg, by, c(24))
		kutu(im, x, y - by, bg, 1, c(23))
		for p in range(2, bg - 3, 5):
			for q in range(3, by - 4, 6):
				nokta(im, x + p, y - by + q, c(10) if rng.randi() % 3 == 0 else c(23))
		x += bg + rng.randi_range(1, 4)
	kutu(im, 0, y - 4, g, 4, c(24))
	return im

func _fon_kaya() -> Image:
	# Yeraltı parallaks dokusu (64x64, tekrar eder). Oyunda katman rengiyle boyanır.
	var g := 64
	var im := _bos(g, g)
	rng.seed = 404
	for y in g:
		for x in g:
			var r := rng.randi() % 100
			var t := 0.55 if r < 20 else (0.85 if r < 60 else 1.0)
			im.set_pixel(x, y, Color(t, t, t, 1.0))
	# yatay tabakalar: derinlik hissi
	for j in range(0, g, 8):
		for x in g:
			im.set_pixel(x, j, Color(0.4, 0.4, 0.4, 1.0))
			im.set_pixel(x, (j + 1) % g, Color(0.7, 0.7, 0.7, 1.0))
	return im

# --- arayüz ---------------------------------------------------------------

## 9 simge x 16 px: yakıt, yük, para, can, derinlik, radar, dinamit, istasyon, eser
func _simgeler() -> Image:
	var im := _bos(K * 9, K)
	# 0 yakıt bidonu
	kutu(im, 3, 4, 10, 10, c(9))
	kutu(im, 4, 5, 8, 8, c(10))
	kutu(im, 6, 2, 4, 2, c(6))
	kutu(im, 5, 7, 6, 4, c(6))
	# 1 yük sandığı
	kutu(im, K + 2, 5, 12, 9, c(5))
	kutu(im, K + 3, 6, 10, 7, c(4))
	kutu(im, K + 2, 8, 12, 2, c(6))
	# 2 para
	elips(im, K * 2 + 8, 8, 6.0, 6.0, c(10))
	elips(im, K * 2 + 8, 8, 4.4, 4.4, c(11))
	kutu(im, K * 2 + 7, 4, 2, 9, c(10))
	# 3 can
	elips(im, K * 3 + 5, 6, 3.0, 3.0, c(8))
	elips(im, K * 3 + 11, 6, 3.0, 3.0, c(8))
	for i in 7:
		kutu(im, K * 3 + 2 + i, 7 + i, 12 - i * 2, 1, c(8))
	nokta(im, K * 3 + 5, 5, c(29))
	# 4 derinlik (aşağı ok)
	kutu(im, K * 4 + 7, 2, 2, 8, c(18))
	for i in 5:
		kutu(im, K * 4 + 3 + i, 10 + i, 10 - i * 2, 1, c(18))
	# 5 radar
	elips(im, K * 5 + 8, 9, 7.0, 7.0, c(14))
	elips(im, K * 5 + 8, 9, 5.0, 5.0, c(12))
	elips(im, K * 5 + 8, 9, 2.5, 2.5, c(14))
	kutu(im, K * 5 + 8, 3, 1, 6, c(12))
	# 6 dinamit
	kutu(im, K * 6 + 4, 6, 8, 8, c(8))
	kutu(im, K * 6 + 4, 8, 8, 2, c(3))
	kutu(im, K * 6 + 7, 2, 2, 4, c(21))
	nokta(im, K * 6 + 8, 1, c(11))
	# 7 istasyon
	kutu(im, K * 7 + 3, 5, 10, 9, c(21))
	kutu(im, K * 7 + 4, 6, 8, 7, c(23))
	kutu(im, K * 7 + 6, 2, 4, 3, c(12))
	kutu(im, K * 7 + 6, 8, 4, 4, c(12))
	# 8 eser
	elips(im, K * 8 + 8, 7, 4.0, 4.5, c(10))
	elips(im, K * 8 + 8, 7, 2.4, 2.8, c(11))
	kutu(im, K * 8 + 4, 12, 8, 2, c(21))
	return im

func _istasyon() -> Image:
	var im := _bos(16, 24)
	kutu(im, 2, 8, 12, 15, c(23))
	kutu(im, 3, 9, 10, 13, c(22))
	kutu(im, 1, 5, 14, 4, c(21))
	kutu(im, 1, 5, 14, 1, c(20))
	kutu(im, 5, 12, 6, 6, c(18))
	kutu(im, 6, 13, 4, 4, c(12))
	kutu(im, 7, 0, 2, 6, c(21))
	nokta(im, 8, 0, c(19))
	kutu(im, 2, 22, 12, 2, c(24))
	return im

func _benek() -> Image:
	var im := _bos(4, 4)
	im.fill(Color(1, 1, 1, 1))
	return im

func _logo() -> Image:
	# Kapak görselinde ve menüde kullanılan matkap amblemi (48x48).
	var im := _bos(48, 48)
	elips(im, 24, 24, 22.0, 22.0, c(25))
	elips(im, 24, 24, 19.0, 19.0, c(24))
	for i in 5:
		kutu(im, 6, 10 + i * 7, 36, 3, c(23))
	kutu(im, 20, 4, 8, 22, c(21))
	kutu(im, 21, 5, 6, 20, c(20))
	for i in 11:
		kutu(im, 18 - (i % 2), 26 + i, 12 + (i % 2) * 2, 1, c(20) if i % 2 == 0 else c(21))
	kutu(im, 22, 40, 4, 4, c(19))
	elips(im, 24, 44, 5.0, 3.0, c(10))
	return im
