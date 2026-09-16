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
const EN_SIG := 10             ## bu derinliğin üstünde hiçbir şey değişmez (üs korunur)

# --- oyuncunun kararı -----------------------------------------------------
##
## v0.3'te deprem saf bir olaydı: uyarı geliyor, tüneller değişiyor, oyuncunun
## verecek bir kararı yoktu. Rakip analizindeki Dome Keeper dersi tam burada:
## oyunu tutan şey dalga sayacının kurduğu "bir blok daha kazayım mı?" bahsi.
## Şimdi uyarı bir bahis: yüzeye çıkan KABUK NÖBETİ İKRAMİYESİ alır (kaybettiği
## kazı süresinin karşılığı), derinde kalan hasar yer. Üçüncü seçenek de var:
## istasyon kurmuşsan ışınlanıp ikramiyeyi bedavaya alırsın — istasyonun
## v0.3'te olmayan ikinci bir gerekçesi oldu.
##
## Sıkışma güvenceleri (yukarıdaki üç kural) aynen duruyor: risk hasar ve para,
## asla "kapalı boşlukta kaldın".
const GUVENLI_DERINLIK := 12   ## uyarı bitince bu derinlikten sığdaysan güvendesin
const UYARI_TABAN := 4.0       ## uyarı süresi (saniye) = TABAN + derinlik * METRE
const UYARI_METRE := 0.06      ## 100 m'de 10 sn, 250 m'de 19 sn — karar verilebilsin
const UYARI_EN_COK := 20.0
const ODUL_TABAN := 25         ## ikramiye = TABAN + uyarı anındaki derinlik * METRE
const ODUL_METRE := 1.0
const HASAR_TABAN := 1         ## derinde kalanın hasarı = TABAN + derinlik / HASAR_METRE
const HASAR_METRE := 100
## Tavan: deprem TEK BAŞINA öldürmesin — en zayıf gövde 3 can, en derin deprem 2.
## Ceza hâlâ gerçek (canı yarılanmış oyuncu yüzeye çekilir), ama "uyarıyı kaçırdın,
## koşu bitti" değil. Sıkışma güvenceleri gibi bu da koda bağlı, ayara değil.
const HASAR_EN_COK := 2

## Uyarı ne kadar sürer? Derinde daha uzun: 250 m'den yüzeye çıkmak 40 sn sürer,
## yani derin oyuncunun kararı "tırman" değil "ışınlan ya da göğüsle".
static func uyari_suresi(derinlik: int) -> float:
	return minf(UYARI_TABAN + float(maxi(derinlik, 0)) * UYARI_METRE, UYARI_EN_COK)

## Yüzeye çıkanın ikramiyesi. Uyarı anındaki derinliğe göre: ne kadar derinden
## döndüyse o kadar kazı süresinden vazgeçmiştir.
static func odul(uyari_derinlik: int) -> int:
	return ODUL_TABAN + int(float(maxi(uyari_derinlik, 0)) * ODUL_METRE)

## Derinde kalanın hasarı: 1 can, 100 m'de 2, 200 m'de 3.
static func hasar(patlama_derinlik: int) -> int:
	return mini(HASAR_TABAN + int(maxi(patlama_derinlik, 0) / HASAR_METRE), HASAR_EN_COK)

## Depremin oyuncuya sonucu. Saf: yalnız iki derinliğe bakar.
##   uyari_derinlik   : uyarı başladığında neredeydi
##   patlama_derinlik : uyarı bitince nerede
static func karar(uyari_derinlik: int, patlama_derinlik: int) -> Dictionary:
	if patlama_derinlik <= GUVENLI_DERINLIK:
		return {"guvende": true, "odul": odul(uyari_derinlik), "hasar": 0}
	return {"guvende": false, "odul": 0, "hasar": hasar(patlama_derinlik)}

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
