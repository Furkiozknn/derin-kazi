## Oyun içi alt ipucu, deprem uyarı panosu ve mağaza satırlarının metinleri.
## Saf sınıf: sahne, düğüm ve girdi gerektirmez, böylece testler doğrudan
## sınayabiliyor (tests/test_calistir.gd → _ipucu_testleri).
##
## Dokunmatikte klavye YOK: aynı metin masaüstünde tuşları, telefonda
## $Dokunmatik altındaki düğmeleri ve dokunma alanlarını anlatır. İki metin de
## aynı yerden çıksın diye tek dosyada toplandı — v0.3'te telefonda
## "E — Üs • T — ışınlanma • M — harita" yazıyordu, oysa o tuşlar orada yok.
class_name Ipucu
extends RefCounted

## Dokunmatik düğme/alan adları (scripts/oyun.gd → _dokunmatik_kur ile aynı).
const DUGME_US := "Üs düğmesi"
const DUGME_HARITA := "Harita düğmesi"
const DUGME_DINAMIT := "DİNAMİT düğmesi"
const DUGME_RADAR := "RADAR düğmesi"
const ALAN_KAZ := "▼ KAZ"
const ALAN_UC := "▲ UÇ"

## Mağaza satırlarının tuş/düğme anlatımı: [masaüstü, dokunmatik].
## v0.4'te dinamit ve radar telefonda kullanılamıyordu ama mağaza onları hâlâ
## "F ile", "Q —" diye anlatıyordu. Düğmeler geldi, metinler de onları anlatıyor.
const MAGAZA := {
	"radar": ["Q — en yakın madeni HUD'da gösterir",
		"%s — en yakın madeni HUD'da gösterir" % DUGME_RADAR],
	"kalkan": ["Lav ve sıcak katmanlarda hasar almazsın",
		"Lav ve sıcak katmanlarda hasar almazsın"],
	"dinamit": ["F ile 3x3 patlat", "%s ile 3x3 patlat" % DUGME_DINAMIT],
	"istasyon": ["T ile kur, anında yolculuk", "%s ile kur, anında yolculuk" % DUGME_US],
}

static func magaza(anahtar: String, dokunmatik: bool) -> String:
	return String(MAGAZA[anahtar][1 if dokunmatik else 0])

## Deprem uyarı panosunun satırları: [geri sayım, yüzeye çıkmanın karşılığı,
## derinde kalmanın karşılığı]. Oyuncunun kararı bu üç satırda; HUD'ın alt
## ipucu şeridi 13 px tek satırdı ve v0.4'te kaçırılıyordu.
static func deprem_pano(kalan: float, derinlik: int, dokunmatik: bool) -> Array:
	var sayac := "DEPREM  %0.1f sn" % kalan
	if derinlik <= Deprem.GUVENLI_DERINLIK:
		return [sayac, "Güvendesin — yüzeye yakın kal.", ""]
	var kacis := "%s ile YÜZEYE ÇIK" % ALAN_UC if dokunmatik else "W ile YÜZEYE ÇIK"
	return [sayac,
		"%s   →   +%d ₺ ikramiye" % [kacis, Deprem.odul(derinlik)],
		"DERİNDE KAL   →   %d hasar" % Deprem.hasar(derinlik)]

## Duruma göre alt ipucu. Boş dize = ipucu yok.
static func metin(durum: Durum, derinlik: int, usste: bool, dokunmatik: bool) -> String:
	if durum.kacis:
		return "KAÇIŞ! Yakıt bitmeden yüzeye çık."
	if usste:
		if dokunmatik:
			return "%s — sat, geliştir, yakıt   •   %s — mini harita" % [DUGME_US, DUGME_HARITA]
		return "E — Üs (sat, geliştir, yakıt)   •   T — ışınlanma   •   M — harita"
	if durum.yuk_dolu():
		return "Yük dolu! Satmak için üsse dön."
	if durum.can <= 1:
		return "Can azaldı — üsse dön, onarım bedava."
	if durum.yakit < durum.yakit_kapasitesi() * 0.25:
		if dokunmatik:
			return "Yakıt azalıyor — %s ile ışınlanma panelini aç." % DUGME_US
		return "Yakıt azalıyor — üsse dön (T ile ışınlanabilirsin)."
	if derinlik < 3 and durum.en_derin < 8:
		if dokunmatik:
			return "%s alanına basılı tut. İlk bakır damarı hemen altında." % ALAN_KAZ
		return "S / ↓ ile aşağı kaz. İlk bakır damarı hemen altında."
	if durum.en_derin < 20 and durum.yuk_toplam() > 0:
		if dokunmatik:
			return "Madeni sat: %s ile yüzeye çık, sonra %s." % [ALAN_UC, DUGME_US]
		return "Madeni sat: W ile yüzeye çık, üste E'ye bas."
	return ""
