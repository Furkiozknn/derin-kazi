## Koşu + ilerleme durumu ve tüm ekonomi kuralları.
## Node değil: testler doğrudan kurup sınayabilir.
class_name Durum
extends RefCounted

var tohum := 0
var para := 0
var en_derin := 0

var matkap := 0   ## geliştirme seviyeleri 0..3
var depo := 0
var kasa := 0

var yakit := 0.0
var yuk := {}     ## karo türü -> adet
var bitti := false
var kazandi := false
var sure := 0.0

func _init(p_tohum := 0) -> void:
	tohum = p_tohum
	yakit = yakit_kapasitesi()

# --- geliştirmeden türeyen değerler ---
func yakit_kapasitesi() -> float:
	return Ayarlar.YAKIT_SEVIYE[depo]

func yuk_kapasitesi() -> int:
	return Ayarlar.YUK_SEVIYE[kasa]

func matkap_hizi() -> float:
	return Ayarlar.MATKAP_SEVIYE[matkap]

func seviye(alan: String) -> int:
	match alan:
		"matkap": return matkap
		"depo": return depo
		"kasa": return kasa
	return 0

func _seviye_ayarla(alan: String, deger: int) -> void:
	match alan:
		"matkap": matkap = deger
		"depo": depo = deger
		"kasa": kasa = deger

## Bir sonraki seviyenin fiyatı. -1 = zaten en üst seviye.
func fiyat(alan: String) -> int:
	var s := seviye(alan)
	if s >= Ayarlar.EN_YUKSEK_SEVIYE:
		return -1
	return Ayarlar.FIYAT[s + 1]

# --- yük ---
func yuk_toplam() -> int:
	var t := 0
	for adet in yuk.values():
		t += int(adet)
	return t

func yuk_dolu() -> bool:
	return yuk_toplam() >= yuk_kapasitesi()

## Madeni yüke ekler. Yük doluysa eklemez ve false döner.
func maden_ekle(tur: int) -> bool:
	if not Ayarlar.MADEN_DEGER.has(tur):
		return false
	if yuk_dolu():
		return false
	yuk[tur] = int(yuk.get(tur, 0)) + 1
	return true

func yuk_degeri() -> int:
	var t := 0
	for tur in yuk:
		t += int(Ayarlar.MADEN_DEGER[tur]) * int(yuk[tur])
	return t

## Yükü satar, parayı artırır, kazanılan tutarı döner.
func sat() -> int:
	var kazanc := yuk_degeri()
	para += kazanc
	yuk.clear()
	return kazanc

# --- geliştirme ---
## Parası yeterse seviyeyi artırır ve parayı düşer. Yetmezse hiçbir şey yapmaz.
func satin_al(alan: String) -> bool:
	var f := fiyat(alan)
	if f < 0 or para < f:
		return false
	para -= f
	_seviye_ayarla(alan, seviye(alan) + 1)
	return true

# --- yakıt ---
func yakit_dolum_fiyati() -> int:
	return int(ceil((yakit_kapasitesi() - yakit) * Ayarlar.YAKIT_BIRIM_FIYAT))

## Paranın yettiği kadar yakıt doldurur, harcanan parayı döner.
func yakit_doldur() -> int:
	var eksik := yakit_kapasitesi() - yakit
	if eksik <= 0.01:
		return 0
	var alinabilir := minf(eksik, float(para) / Ayarlar.YAKIT_BIRIM_FIYAT)
	var maliyet := int(floor(alinabilir * Ayarlar.YAKIT_BIRIM_FIYAT))
	yakit += alinabilir
	para -= maliyet
	return maliyet

func yakit_harca(miktar: float) -> void:
	yakit = maxf(0.0, yakit - miktar)
	if yakit <= 0.0:
		bitti = true

## Yakıt bitince: yükün yarısı kaybolur, acil yakıtla üsse dönülür.
## Acil yakıt bedava, yoksa parasız+yakıtsız oyuncu kilitlenirdi.
func kosu_basarisiz() -> void:
	for tur in yuk.keys():
		var kalan := int(yuk[tur]) / 2
		if kalan > 0:
			yuk[tur] = kalan
		else:
			yuk.erase(tur)
	yakit = maxf(yakit, yakit_kapasitesi() * Ayarlar.ACIL_YAKIT_ORAN)
	bitti = false

# --- kayıt ---
func sozluge() -> Dictionary:
	return {
		"tohum": tohum, "para": para, "en_derin": en_derin,
		"matkap": matkap, "depo": depo, "kasa": kasa,
	}

func sozlukten(d: Dictionary) -> void:
	tohum = int(d.get("tohum", tohum))
	para = int(d.get("para", 0))
	en_derin = int(d.get("en_derin", 0))
	matkap = clampi(int(d.get("matkap", 0)), 0, Ayarlar.EN_YUKSEK_SEVIYE)
	depo = clampi(int(d.get("depo", 0)), 0, Ayarlar.EN_YUKSEK_SEVIYE)
	kasa = clampi(int(d.get("kasa", 0)), 0, Ayarlar.EN_YUKSEK_SEVIYE)
	yakit = yakit_kapasitesi()
