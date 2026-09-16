## Tohumdan dünya üreten saf sınıf. Node değil: testler doğrudan kullanabilir.
## Aynı tohum + aynı (x, y) => hep aynı karo. Hiç durum tutmaz, chunk üretimi buna dayanır.
class_name DunyaUretici
extends RefCounted

var tohum: int
var cekirdek_x: int
var _magara: FastNoiseLite
var _kaya: FastNoiseLite

func _init(p_tohum: int) -> void:
	tohum = p_tohum
	_magara = FastNoiseLite.new()
	_magara.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_magara.seed = p_tohum
	_magara.frequency = 0.075
	_kaya = FastNoiseLite.new()
	_kaya.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_kaya.seed = p_tohum + 7919
	_kaya.frequency = 0.13
	# Çekirdek kenarlardan uzakta, tohuma göre sabit bir sütunda.
	cekirdek_x = 6 + absi(hash(p_tohum)) % (Ayarlar.GENISLIK - 12)

## Deterministik 0..1 arası sayı. RNG nesnesi kurmadan, sadece hash ile.
func _gurultu_sayi(x: int, y: int, tuz: int) -> float:
	return float(absi(hash(Vector4i(x, y, tohum, tuz))) % 1000000) / 1000000.0

func karo(x: int, y: int) -> int:
	if y < 0:
		return Ayarlar.BOS
	if x < 0 or x >= Ayarlar.GENISLIK or y >= Ayarlar.DERINLIK:
		return Ayarlar.KAYA
	if x == 0 or x == Ayarlar.GENISLIK - 1:
		return Ayarlar.KAYA
	if y == Ayarlar.CEKIRDEK_DERINLIK and x == cekirdek_x:
		return Ayarlar.CEKIRDEK
	if y >= Ayarlar.DERINLIK - 1:
		return Ayarlar.KAYA   ## taban: dünyanın altından düşülmesin

	var cekirdege_yakin := absi(y - Ayarlar.CEKIRDEK_DERINLIK) <= 2 and absi(x - cekirdek_x) <= 2
	if y >= Ayarlar.KAPALI_UST:
		if _magara.get_noise_2d(float(x), float(y)) > Ayarlar.MAGARA_ESIK:
			return Ayarlar.BOS
		# Kazılamaz kaya kümeleri. Çekirdeğin çevresine konmaz, yolu tıkamasın.
		if y >= 30 and not cekirdege_yakin:
			if _kaya.get_noise_2d(float(x), float(y)) > Ayarlar.KAYA_ESIK:
				return Ayarlar.KAYA

	var maden := _maden(x, y)
	if maden != Ayarlar.BOS:
		return maden
	if y >= 170:
		return Ayarlar.SERT
	if y >= 70:
		return Ayarlar.TAS
	return Ayarlar.TOPRAK

## Derinliğe göre maden. Her tür kendi penceresinde çıkar, ortasında en bol.
func _maden(x: int, y: int) -> int:
	var r := _gurultu_sayi(x, y, 101)
	var toplam := 0.0
	for satir in Ayarlar.MADEN_TABLO:
		var tur: int = satir[0]
		var en_sig: int = satir[1]
		var tepe: int = satir[2]
		var en_derin: int = satir[3]
		var sans: float = satir[4]
		if y < en_sig or y > en_derin:
			continue
		var yayilma := float(maxi(tepe - en_sig, en_derin - tepe))
		var uzaklik := absf(float(y - tepe)) / maxf(yayilma, 1.0)
		var agirlik := clampf(1.0 - uzaklik, 0.12, 1.0)
		toplam += sans * agirlik
		if r < toplam:
			return tur
	return Ayarlar.BOS
