## Oyun içi alt ipucu, deprem uyarı panosu ve mağaza satırlarının metinleri.
## Saf sınıf: sahne, düğüm ve girdi gerektirmez, böylece testler doğrudan
## sınayabiliyor (tests/test_calistir.gd → _ipucu_testleri).
##
## Dokunmatikte klavye YOK: aynı metin masaüstünde tuşları, telefonda
## $Dokunmatik altındaki düğmeleri ve dokunma alanlarını anlatır. İki metin de
## aynı yerden çıksın diye tek dosyada toplandı — v0.3'te telefonda
## "E — Üs • T — ışınlanma • M — harita" yazıyordu, oysa o tuşlar orada yok.
##
## v0.8: bütün metinler Ceviri.t ile TR/EN. Sabitler Türkçe KAYNAK kalır (const
## içinde fonksiyon çağrılamaz); çeviri kullanım yerinde yapılır.
class_name Ipucu
extends RefCounted

## Dokunmatik düğme/alan adları (scripts/oyun.gd → _dokunmatik_kur ile aynı).
const DUGME_US := "Üs düğmesi"
const DUGME_HARITA := "Harita düğmesi"
const DUGME_DINAMIT := "DİNAMİT düğmesi"
const DUGME_RADAR := "RADAR düğmesi"
const DUGME_ISARET := "İŞARET düğmesi"
const ALAN_KAZ := "▼ KAZ"
const ALAN_UC := "▲ UÇ"

## Duraklatma ekranındaki tam tuş listesi (menüde yalnız tek satır var).
const TUSLAR := "A/D veya ←/→ yürü ve yana kaz  ·  S veya ↓ aşağı kaz  ·  W/Boşluk pervane\nE üs  ·  T ışınlanma  ·  R dönüş işareti  ·  Q radar  ·  F dinamit  ·  M harita  ·  Esc duraklat\nGamepad: sol çubuk, A pervane, X üs, LB radar, RB ışınlanma, B işaret, Y dinamit, Start duraklat"
const TUSLAR_DOKUNMA := "Alt sol / alt sağ köşe: o yöne yürü ve yana kaz  ·  Alt orta: aşağı kaz  ·  ▲ alanı: pervaneyle yüksel\nSağ üst: Üs · Harita · ■ duraklat  ·  Sol: DİNAMİT · RADAR · İŞARET"

## Işınlama işareti (v0.7). Öğretme ipucu oturumda bir kez, 30 m'yi ilk geçişte gösterilir.
static func isaret_ogret(dokunmatik: bool) -> String:
	if dokunmatik:
		return Ceviri.t("%s — buraya dönüş işareti koy; üsten tek seferlik ışınlanırsın.") % Ceviri.t(DUGME_ISARET)
	return Ceviri.t("R — buraya dönüş işareti koy; üsten T ile tek seferlik ışınlanırsın.")

static func isaret_kondu(derinlik: int, dokunmatik: bool) -> String:
	if dokunmatik:
		return Ceviri.t("İşaret %d m'de. Üsten %s ile tek seferlik ışınlan.") % [derinlik, Ceviri.t(DUGME_US)]
	return Ceviri.t("İşaret %d m'de. Üsten T ile tek seferlik ışınlan.") % derinlik

## Mağaza satırlarının tuş/düğme anlatımı: [masaüstü, dokunmatik] (Türkçe kaynak;
## `magaza()` çevirir). v0.4'te dinamit ve radar telefonda kullanılamıyordu ama mağaza
## onları hâlâ "F ile", "Q —" diye anlatıyordu.
const MAGAZA := {
	"radar": ["Q — en yakın madeni HUD'da gösterir",
		"%s — en yakın madeni HUD'da gösterir"],
	"kalkan": ["Lav ve sıcak katmanlarda hasar almazsın",
		"Lav ve sıcak katmanlarda hasar almazsın"],
	"dinamit": ["F ile 3x3 patlat", "%s ile 3x3 patlat"],
	"istasyon": ["T ile kur, anında yolculuk", "%s ile kur, anında yolculuk"],
}
const MAGAZA_DUGME := {"radar": DUGME_RADAR, "dinamit": DUGME_DINAMIT, "istasyon": DUGME_US}

static func magaza(anahtar: String, dokunmatik: bool) -> String:
	var m := Ceviri.t(String(MAGAZA[anahtar][1 if dokunmatik else 0]))
	if dokunmatik and MAGAZA_DUGME.has(anahtar):
		return m % Ceviri.t(String(MAGAZA_DUGME[anahtar]))
	return m

## Deprem uyarı panosunun satırları: [geri sayım, yüzeye çıkmanın karşılığı,
## derinde kalmanın karşılığı]. Oyuncunun kararı bu üç satırda; HUD'ın alt
## ipucu şeridi 13 px tek satırdı ve v0.4'te kaçırılıyordu.
static func deprem_pano(kalan: float, derinlik: int, dokunmatik: bool) -> Array:
	var sayac := Ceviri.t("DEPREM  %0.1f sn") % kalan
	if derinlik <= Deprem.GUVENLI_DERINLIK:
		return [sayac, Ceviri.t("Güvendesin — yüzeye yakın kal."), ""]
	var kacis := Ceviri.t("%s ile YÜZEYE ÇIK") % Ceviri.t(ALAN_UC) if dokunmatik else Ceviri.t("W ile YÜZEYE ÇIK")
	return [sayac,
		Ceviri.t("%s   →   +%d ₺ ikramiye") % [kacis, Deprem.odul(derinlik)],
		Ceviri.t("DERİNDE KAL   →   %d hasar") % Deprem.hasar(derinlik)]

## Duruma göre alt ipucu. Boş dize = ipucu yok.
static func metin(durum: Durum, derinlik: int, usste: bool, dokunmatik: bool) -> String:
	if durum.kacis:
		return Ceviri.t("KAÇIŞ! Yakıt bitmeden yüzeye çık.")
	if usste:
		if dokunmatik:
			return Ceviri.t("%s — sat, geliştir, yakıt   •   %s — mini harita") % [Ceviri.t(DUGME_US), Ceviri.t(DUGME_HARITA)]
		return Ceviri.t("E — Üs (sat, geliştir, yakıt)   •   T — ışınlanma   •   M — harita")
	if durum.yuk_dolu():
		return Ceviri.t("Yük dolu! Satmak için üsse dön.")
	if durum.can <= 1:
		return Ceviri.t("Can azaldı — üsse dön, onarım bedava.")
	if durum.yakit < durum.yakit_kapasitesi() * 0.25:
		if dokunmatik:
			return Ceviri.t("Yakıt azalıyor — %s ile ışınlanma panelini aç.") % Ceviri.t(DUGME_US)
		return Ceviri.t("Yakıt azalıyor — üsse dön (T ile ışınlanabilirsin).")
	if derinlik < 3 and durum.en_derin < 8:
		if dokunmatik:
			return Ceviri.t("%s alanına basılı tut. İlk bakır damarı hemen altında.") % Ceviri.t(ALAN_KAZ)
		return Ceviri.t("S / ↓ ile aşağı kaz. İlk bakır damarı hemen altında.")
	if durum.en_derin < 20 and durum.yuk_toplam() > 0:
		if dokunmatik:
			return Ceviri.t("Madeni sat: %s ile yüzeye çık, sonra %s.") % [Ceviri.t(ALAN_UC), Ceviri.t(DUGME_US)]
		return Ceviri.t("Madeni sat: W ile yüzeye çık, üste E'ye bas.")
	return ""
