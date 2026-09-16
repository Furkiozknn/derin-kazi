## Oyun içi alt ipucu metni. Saf sınıf: sahne, düğüm ve girdi gerektirmez,
## böylece testler doğrudan sınayabiliyor (tests/test_calistir.gd → _ipucu_testleri).
##
## Dokunmatikte klavye YOK: aynı ipucu masaüstünde tuşları, telefonda
## $Dokunmatik altındaki düğmeleri ve dokunma alanlarını anlatır. İki metin de
## aynı yerden çıksın diye tek fonksiyonda toplandı — v0.3'te telefonda
## "E — Üs • T — ışınlanma • M — harita" yazıyordu, oysa o tuşlar orada yok.
class_name Ipucu
extends RefCounted

## Dokunmatik düğme/alan adları (scripts/oyun.gd → _dokunmatik_izler ile aynı).
const DUGME_US := "Üs düğmesi"
const DUGME_HARITA := "Harita düğmesi"
const ALAN_KAZ := "▼ KAZ"
const ALAN_UC := "▲ UÇ"

## Deprem uyarısı sürerken HUD'daki geri sayım. Oyuncunun kararı bu satırda:
## yukarı mı çıksın, bir karo daha mı kazsın.
static func deprem_metni(kalan: float, derinlik: int, dokunmatik: bool) -> String:
	var kacis := "%s ile yüzeye çık" % ALAN_UC if dokunmatik else "W ile yüzeye çık"
	if derinlik <= Deprem.GUVENLI_DERINLIK:
		return "DEPREM %0.1f sn — güvendesin, yüzeye yakın kal." % kalan
	return "DEPREM %0.1f sn — %s (+%d ₺) ya da derinde kal (%d hasar)." % [
		kalan, kacis, Deprem.odul(derinlik), Deprem.hasar(derinlik)]

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
