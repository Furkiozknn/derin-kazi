## Tohumdan dünya üreten saf sınıf. Node değil: testler ve chunk üretimi doğrudan kullanır.
## Aynı tohum + aynı (x, y) => hep aynı karo. Hiç durum tutmaz.
## Odalar chunk düzeyinde karar verilir: hash(tohum, cx, cy).
class_name DunyaUretici
extends RefCounted

const ODA_G := 7
const ODA_Y := 5
const FAY_YARICAP := 1   ## fay koridoru = 2 * FAY_YARICAP + 1 karo genişlik

## Yalnız ölçüm için: kapatılınca dünya v0.2 gibi üretilir (garanti yok).
## Testte "garanti gerçekten bir şey yapıyor mu" sorusunu cevaplamak için var.
static var fay_acik := true

var tohum: int
var cekirdek_x: int
var _magara: FastNoiseLite
var _kaya: FastNoiseLite
var _lav: FastNoiseLite
var _fay: FastNoiseLite
var _fay_sutun := PackedInt32Array()   ## y -> koridorun orta sütunu
var _maden_tablo: Array = []   ## [tür, en_sığ, tepe, yoğunluk]

func _init(p_tohum: int) -> void:
	tohum = p_tohum
	_magara = _gurultu(p_tohum, 0.075)
	_kaya = _gurultu(p_tohum + 7919, 0.13)
	_lav = _gurultu(p_tohum + 104729, 0.11)
	# Fay hattının kıvrımı (koridorun kopmaması _fay_kur() içinde garanti ediliyor).
	_fay = _gurultu(p_tohum + 15485863, 0.020)
	for i in Ayarlar.KATMANLAR.size():
		var k: Dictionary = Ayarlar.KATMANLAR[i]
		var son: int = int(Ayarlar.KATMANLAR[i + 1]["y0"]) if i + 1 < Ayarlar.KATMANLAR.size() else Ayarlar.CEKIRDEK_DERINLIK
		_maden_tablo.append([int(k["maden"]), int(k["y0"]), (int(k["y0"]) + son) / 2, float(k["yogunluk"])])
	# Çekirdek kenarlardan uzakta, tohuma göre sabit bir sütunda.
	cekirdek_x = 6 + absi(hash(p_tohum)) % (Ayarlar.GENISLIK - 12)
	_fay_kur()

static func _gurultu(t: int, f: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.seed = t
	n.frequency = f
	return n

## Deterministik 0..1 arası sayı. RNG nesnesi kurmadan, sadece hash ile.
func _sayi(x: int, y: int, tuz: int) -> float:
	return float(absi(hash(Vector4i(x, y, tohum, tuz))) % 1000000) / 1000000.0

# --- garantili fay hattı --------------------------------------------------

## Üsten çekirdeğe inen, kıvrımlı bir koridorun o derinlikteki orta sütunu.
## Koridorun İÇİ sıradan kaya ve madenle dolu — oyuncu onu göremez — ama içinde
## ASLA kazılamaz kaya ya da lav olmaz. Dome Keeper şikâyeti ("kötü dünya üretimi
## oyunu bitirilemez yapıyor") bu yüzden burada oluşamaz: her tohumda yüzeyden
## çekirdeğe kazılabilir bir yol var (tests/test_calistir.gd BFS ile doğruluyor).
func fay_x(y: int) -> int:
	return _fay_sutun[clampi(y, 0, Ayarlar.DERINLIK)]

## Koridoru bir kez kurar. İki güvence kodda, ayarda değil:
##   - satır başına en fazla 1 karo kayar (koridor kopmaz)
##   - iki uçta sapma 0: üsten (US_KARO_X) başlar, çekirdek sütununda biter
func _fay_kur() -> void:
	_fay_sutun.resize(Ayarlar.DERINLIK + 1)
	var onceki := Ayarlar.US_KARO_X
	for y in range(0, Ayarlar.DERINLIK + 1):
		var t := clampf(float(y) / float(Ayarlar.CEKIRDEK_DERINLIK), 0.0, 1.0)
		var taban := lerpf(float(Ayarlar.US_KARO_X), float(cekirdek_x), t)
		var sapma := _fay.get_noise_1d(float(y)) * 9.0 * sin(PI * t)
		var hedef := int(round(taban + sapma))
		onceki = clampi(clampi(hedef, onceki - 1, onceki + 1), 2, Ayarlar.GENISLIK - 3)
		_fay_sutun[y] = onceki

## Hücre fay koridorunda mı? (3 karo genişlik)
func fayda_mi(x: int, y: int) -> bool:
	return fay_acik and absi(x - fay_x(y)) <= FAY_YARICAP

# --- odalar ---------------------------------------------------------------

## Chunk'ta hazır oda varsa {"x0","y0","tur"} döner, yoksa boş sözlük.
## tur: SANDIK ya da ESER. Görev: "chunk başına olasılıkla hazır oda şablonu".
func oda(cx: int, cy: int) -> Dictionary:
	if cy < 2 or cx < 0 or cx >= _chunk_genislik():
		return {}
	var r := _sayi(cx, cy, 555)
	if r >= Ayarlar.ODA_SANS:
		return {}
	var ox := 2 + int(_sayi(cx, cy, 556) * float(Ayarlar.PARCA - ODA_G - 3))
	var oy := 2 + int(_sayi(cx, cy, 557) * float(Ayarlar.PARCA - ODA_Y - 3))
	var tur := Ayarlar.ESER if _sayi(cx, cy, 558) < 0.30 else Ayarlar.SANDIK
	return {"x0": cx * Ayarlar.PARCA + ox, "y0": cy * Ayarlar.PARCA + oy, "tur": tur}

func _chunk_genislik() -> int:
	return ceili(float(Ayarlar.GENISLIK) / float(Ayarlar.PARCA))

func _oda_karosu(x: int, y: int) -> int:
	var o := oda(x / Ayarlar.PARCA, y / Ayarlar.PARCA)
	if o.is_empty():
		return -2   ## "oda yok" (BOS ile karışmasın)
	var lx: int = x - int(o["x0"])
	var ly: int = y - int(o["y0"])
	if lx < 0 or ly < 0 or lx >= ODA_G or ly >= ODA_Y:
		return -2
	if lx == ODA_G / 2 and ly == ODA_Y - 1:
		return int(o["tur"])
	return Ayarlar.BOS

# --- karo -----------------------------------------------------------------

func karo(x: int, y: int) -> int:
	if y < 0:
		return Ayarlar.BOS
	if x < 0 or x >= Ayarlar.GENISLIK or y >= Ayarlar.DERINLIK:
		return Ayarlar.KAYA
	if x == 0 or x == Ayarlar.GENISLIK - 1:
		return Ayarlar.KAYA
	if y >= Ayarlar.DERINLIK - 1:
		return Ayarlar.KAYA   ## taban: dünyanın altından düşülmesin
	if y == Ayarlar.CEKIRDEK_DERINLIK and x == cekirdek_x:
		return Ayarlar.CEKIRDEK

	# Üsün altındaki garantili bakır damarı: ilk 10 m'de "+$" öğretilir.
	var basi := _baslangic_damari(x, y)
	if basi != -2:
		return basi

	if y < Ayarlar.KAPALI_UST:
		return Ayarlar.TOPRAK

	var k := Ayarlar.katman(y)
	var kat: Dictionary = Ayarlar.KATMANLAR[k]
	var cekirdege_yakin := absi(y - Ayarlar.CEKIRDEK_DERINLIK) <= 3 and absi(x - cekirdek_x) <= 3

	var od := _oda_karosu(x, y)
	if od != -2:
		return od

	# Mağara. Derin katmanlarda mağara tabanına lav dolar (kazılmaz ama yolu kapatmaz:
	# lav hep boşluğun yerine gelir, kayanın değil).
	var fayda := fayda_mi(x, y)
	if _magara.get_noise_2d(float(x), float(y)) > Ayarlar.MAGARA_ESIK:
		if not fayda and int(kat["tehlike"]) == Ayarlar.LAV \
				and _lav.get_noise_2d(float(x), float(y) * 1.6) > 0.30:
			return Ayarlar.LAV
		return Ayarlar.BOS

	if y >= 30 and not cekirdege_yakin and not fayda:
		if _kaya.get_noise_2d(float(x), float(y)) > Ayarlar.KAYA_ESIK:
			return Ayarlar.KAYA

	var maden := _maden(x, y)
	if maden != Ayarlar.BOS:
		return maden

	# Katmanın tehlikesi (lav dışında; lav yukarıda mağaraya kondu).
	var teh := int(kat["tehlike"])
	if teh != Ayarlar.LAV and not cekirdege_yakin:
		if _sayi(x, y, 202) < float(kat["tehlike_sans"]):
			return teh

	return int(kat["taban"])

## Üsün altında elle yerleştirilmiş bakır damarı (rakip analizi: 0:30'da ilk "+$").
func _baslangic_damari(x: int, y: int) -> int:
	if y < Ayarlar.BASLANGIC_DAMAR or y > Ayarlar.BASLANGIC_DAMAR + 3:
		return -2
	var d := absi(x - Ayarlar.US_KARO_X)
	if d > 2:
		return -2
	if d + (y - Ayarlar.BASLANGIC_DAMAR) <= 3:
		return Ayarlar.BAKIR
	return -2

## Derinliğe göre maden. Her katmanın madeni kendi ortasında en bol, derinde seyrelir.
func _maden(x: int, y: int) -> int:
	var r := _sayi(x, y, 101)
	var toplam := 0.0
	for satir in _maden_tablo:
		var tur: int = satir[0]
		var en_sig: int = satir[1]
		var tepe: int = satir[2]
		var sans: float = satir[3]
		if y < en_sig:
			continue
		var agirlik := clampf(1.0 - absf(float(y - tepe)) / 90.0, 0.10, 1.0)
		toplam += sans * agirlik
		if r < toplam:
			return tur
	return Ayarlar.BOS
