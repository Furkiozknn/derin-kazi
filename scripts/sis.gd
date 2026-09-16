## Keşif sisi örtüsü. Dünyanın üstüne karo karo koyu dikdörtgen çizer:
## keşfedilmemiş hücre kapkaranlık, keşfedilmiş hücre yarı karanlık ("hatıra"),
## aracın ışık yarıçapının içi tamamen açık. Radar açıkken daha geniş bir daire
## GEÇİCİ olarak seyreltilir — keşif saymaz, radar kapanınca sis geri gelir.
##
## Neden Light2D değil: hedef donanım tümleşik Intel UHD + GL Compatibility ve
## ışığın kesmesi gereken şey karo ızgarası. Ekranda en fazla ~700 karo var,
## karo başına bir `draw_rect` bedava; Light2D yolu her karo için bir
## LightOccluder2D poligonu demekti.
##
## Işık yakıt harcamaz. Rakip analizindeki SteamWorld Dig şikâyeti "lamba
## yakıtı angarya" — sis burada bir kaynak yönetimi değil, bir BİLGİ kısıtı.
class_name Sis
extends Node2D

## Merkezin kaç karo sağına/soluna çizilir. Görüntü 640x360 ve kamera 2x, yani
## ekranda 20x11 karo var; pencere kameranın yumuşatma gecikmesine de paylı.
const PENCERE_X := 14
const PENCERE_Y := 12

var dunya: Dunya
var merkez := Vector2i.ZERO
var radar := false

## Bir hücrenin sis örtüsünün yoğunluğu (0 = açık, 1 = kapkaranlık).
## Saf ve statik: testler sahne kurmadan sınıyor (test_calistir.gd → _sis_testleri).
##   uzaklik2 : hücrenin araca karo cinsinden uzaklığının KARESİ
##   derinlik : hücrenin y'si (gün ışığı buna bakıyor)
static func ortu(uzaklik2: int, derinlik: int, kesfedildi: bool, radar_acik: bool) -> float:
	if derinlik < 0:
		return 0.0           ## gökyüzü
	var u := sqrt(float(uzaklik2))
	# Işık kenarı yumuşak: sert daire kenarı karo ızgarasında merdiven gibi duruyor.
	var isik := clampf((u - (float(Ayarlar.ISIK_YARICAP) - Ayarlar.ISIK_YUMUSAMA))
		/ Ayarlar.ISIK_YUMUSAMA, 0.0, 1.0)
	var a := (Ayarlar.SIS_HATIRA if kesfedildi else 1.0) * isik
	if radar_acik and u <= float(Ayarlar.RADAR_SIS_YARICAP):
		a = minf(a, Ayarlar.SIS_RADAR)
	# Gün ışığı: yüzeyde sis yok, GUN_ISIGI metresinde tam.
	return a * clampf(float(derinlik) / float(Ayarlar.GUN_ISIGI), 0.0, 1.0)

## Araç yeni bir hücreye geçti / radar açıldı: yeniden çiz.
func yenile(yeni_merkez: Vector2i, radar_acik: bool) -> void:
	merkez = yeni_merkez
	radar = radar_acik
	queue_redraw()

func _draw() -> void:
	if dunya == null:
		return
	var k := float(Ayarlar.KARO)
	for dy in range(-PENCERE_Y, PENCERE_Y + 1):
		for dx in range(-PENCERE_X, PENCERE_X + 1):
			var h := merkez + Vector2i(dx, dy)
			var a := ortu(dx * dx + dy * dy, h.y, dunya.kesfedildi_mi(h), radar)
			if a <= 0.01:
				continue
			draw_rect(Rect2(float(h.x) * k, float(h.y) * k, k, k),
				Color(Ayarlar.SIS_RENK, a))
