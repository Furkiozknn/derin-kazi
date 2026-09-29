class_name Ceviri
extends RefCounted
## Arayuz metinleri: KAYNAK dil Turkce (tr() anahtari Turkce metnin kendisi),
## Ingilizce tablo asagida (scripts/ceviri_en.gd). Turkce icin tablo gerekmez:
## anahtar bulunamazsa Godot metni aynen doner (proje ayari: yedek dil "tr").
##
## Yeni bir arayuz metni eklerken:
##   1. Kodda tr("Turkce metin") (Node metotlarinda) ya da Ceviri.t("...") (static
##      metotlarda, sabit tablolarda) yaz;
##   2. ceviri_en.gd -> EN tablosuna ayni anahtarla Ingilizcesini ekle
##      (bicim belirteclerinin sayisi ve sirasi ayni kalsin: %d, %s, %.1f);
##   3. tests/test_calistir.gd -> _ceviri_testleri eksik anahtari ve belirtec
##      uyusmazligini yakalar.
##
## Ingilizce metinler dogal ve kisa, dizgi dizgi ceviri degil: videolar X ve
## YouTube'da Ingilizce yayinlaniyor.

static var _kuruldu := false


## Ingilizce tabloyu TranslationServer'a yukler (birden cok cagri zararsiz).
static func kur() -> void:
	if _kuruldu:
		return
	_kuruldu = true
	var t := Translation.new()
	t.locale = "en"
	for k in CeviriEn.EN:
		t.add_message(k, CeviriEn.EN[k])
	TranslationServer.add_translation(t)


## Static metotlarda ve sabit tablolarda tr() yok (Object metodu): ayni ceviriyi buradan al.
static func t(metin: String) -> String:
	return TranslationServer.translate(metin)


## Kaynak anahtarin belirtec (%d, %s, %.1f, %%) dizisi: ceviri ile ayni olmali.
static func belirtecler(m: String) -> PackedStringArray:
	var sonuc := PackedStringArray()
	var r := RegEx.new()
	r.compile("%[-+ 0#]*[0-9]*(?:\\.[0-9]+)?[dsf]")
	for e in r.search_all(m):
		sonuc.append(e.get_string())
	return sonuc
