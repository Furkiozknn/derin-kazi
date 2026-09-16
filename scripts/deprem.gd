## Canlı yeraltı: her ARALIK seferde bir deprem.
##
## Saf sınıf — Node değil, sahne gerektirmez, hiçbir şeyi kendisi değiştirmez.
## `hesapla()` ne olacağını döner; uygulamak `Dunya.degistir()` işi. Böylece
## testler tek başına sınayabiliyor (tests/test_calistir.gd → _deprem_testleri).
##
## Üç güvenlik kuralı (oyuncu asla sıkışmasın):
##   1. Aracın, üssün ve istasyonların KORUMA yarıçapındaki hücrelere dokunulmaz.
##   2. Kapanan hücre HER ZAMAN o katmanın kazılabilir taban kayasıyla dolar —
##      asla KAYA ya da LAV ile. Yani kapanan tünel her zaman yeniden kazılabilir.
##   3. Yeni gaz cebi korunan alanın dışına konur (oyuncunun burnunun dibinde patlamaz).
class_name Deprem
extends RefCounted

const ARALIK := 5              ## kaç seferde bir deprem
const KAPANMA_ORAN := 0.22     ## açık tünelin kaçta kaçı kapanır
const KORUMA := 4              ## korunan yarıçap (karo)
const YENI_GAZ := 12           ## deprem başına yeni gaz cebi
const YENI_DAMAR := 18         ## deprem başına yeni maden hücresi
const UYARI_SURE := 3.5        ## önceden uyarı: sarsıntı + metin (saniye)
const EN_SIG := 10             ## bu derinliğin üstünde hiçbir şey değişmez (üs korunur)

## Korunacak hücrelerin listesi: üs sütunu, istasyonlar, aracın bulunduğu yer.
static func korunan_hucreler(istasyonlar: Array, arac: Vector2i) -> Array:
	var liste: Array = [arac]
	for h in istasyonlar:
		liste.append(Vector2i(h))
	for y in range(0, EN_SIG + 1):
		liste.append(Vector2i(Ayarlar.US_KARO_X, y))
	return liste

static func _koruma_kumesi(korunan: Array) -> Dictionary:
	var k := {}
	for m in korunan:
		var h := Vector2i(m)
		for dy in range(-KORUMA, KORUMA + 1):
			for dx in range(-KORUMA, KORUMA + 1):
				k[h + Vector2i(dx, dy)] = true
	return k

## Bir depremin sonucunu hesaplar.
##   kazilan : Vector2i -> true  (şu an açık tüneller)
##   karo    : Callable(Vector2i) -> int  (hücrenin şimdiki türü)
##   no      : kaçıncı deprem (belirlenimcilik için)
## Dönüş: {"kapanan": [Vector2i], "yeni": {Vector2i: karo türü}}
static func hesapla(kazilan: Dictionary, karo: Callable, korunan: Array,
		tohum: int, no: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(tohum, no * 7919 + 13))
	var yasak := _koruma_kumesi(korunan)

	# Sıra belirlenimci olmalı: Dictionary anahtar sırası güvenilir değil.
	var acik: Array = kazilan.keys()
	acik.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))

	var kapanan: Array = []
	var kalan: Array = []
	for h: Vector2i in acik:
		if h.y < EN_SIG or yasak.has(h):
			kalan.append(h)
			continue
		if rng.randf() < KAPANMA_ORAN:
			kapanan.append(h)
		else:
			kalan.append(h)

	var yeni := {}
	for h: Vector2i in kapanan:
		yeni[h] = _dolgu(h.y)

	# Yeni gaz cepleri ve damarlar: hâlâ açık olan tünellerin duvarlarına konur,
	# yani oyuncunun eski yolunda yeni şeyler belirir.
	var duvar: Array = []
	var gorulen := {}
	for h: Vector2i in kalan:
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var k := h + d
			if gorulen.has(k) or yasak.has(k) or yeni.has(k) or kazilan.has(k):
				continue
			if k.y < EN_SIG or k.y >= Ayarlar.CEKIRDEK_DERINLIK - 2:
				continue
			gorulen[k] = true
			if not Ayarlar.VARYANTLI.has(int(karo.call(k))):
				continue   ## yalnız sade taban kayası dönüştürülür
			duvar.append(k)
	duvar.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))

	for i in mini(YENI_GAZ + YENI_DAMAR, duvar.size()):
		var k: Vector2i = duvar[rng.randi() % duvar.size()]
		if yeni.has(k):
			continue
		yeni[k] = Ayarlar.GAZ if i < YENI_GAZ else _maden(k.y)

	return {"kapanan": kapanan, "yeni": yeni}

## Kapanan hücreyi dolduran karo: her zaman o katmanın kazılabilir taban kayası.
static func _dolgu(y: int) -> int:
	return int(Ayarlar.KATMANLAR[Ayarlar.katman(y)]["taban"])

static func _maden(y: int) -> int:
	return int(Ayarlar.KATMANLAR[Ayarlar.katman(y)]["maden"])
