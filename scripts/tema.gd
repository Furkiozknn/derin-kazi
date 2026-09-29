class_name Tema
extends RefCounted
## Tanitim videosundaki dunya: DUZ renk, golgesiz, disi cizgisiz. Renk kodlari
## derin-kazi'nin kendi videosundan (docs/TASARIM.md) piksel ornekleyerek alindi:
## koyu kahve zemin, toprak bantlari, kagit rengi matkap, kirmizi-turuncu uc,
## amber maden kareleri. Marka tabani (yazi tipi, dugme, etiket) diger oyunlarla ortak.

const MUREKKEP := Color("1c130d")    ## video zemini / koyu tunel
const ZEMIN := Color("2d2019")       ## video kabugu, gok
const KAGIT := Color("f3e8d7")       ## video kagit yuzeyi / metin / matkap govdesi
const AMBER := Color("f3a33d")       ## vurgu: maden karesi, birincil dugme, en iyi
const TEHLIKE := Color("e94f36")     ## tehlike: lav, deprem, hasar
const UC := Color("e2552c")          ## matkap ucu, cekirdek
const CEKIRDEK_KIRMIZI := Color("571d13")  ## cekirdek kabugu (videodaki kirmizi bant)
const TOPRAK := Color("896843")      ## yuzey toprak
const TOPRAK_KOYU := Color("6d4f33")
const CAMGOBEGI := Color("7dd4e7")   ## elmas, radar, istasyon
const YESIL := Color("6fc38a")       ## gaz, "SAT" damgasi
const SARI := Color("ffc21a")        ## yalniz odul: yeni rekor, sandik
const PANEL := Color("2a1e16")       ## kart / perde yuzeyi

const F_GOVDE := "res://assets/fonts/InstrumentSans-Regular.ttf"
const F_KALIN := "res://assets/fonts/InstrumentSans-Bold.ttf"
const F_MONO := "res://assets/fonts/JetBrainsMono-Regular.ttf"
const F_MONO_KALIN := "res://assets/fonts/JetBrainsMono-Bold.ttf"
const F_SIMGE := "res://assets/fonts/simgeler.ttf"
const TEMA_YOLU := "res://assets/tema.tres"


## Mono etiketlerin rengi: kagit %70 opaklik.
static func etiket_rengi() -> Color:
	return Color(KAGIT, 0.7)


## Turkce duyarli buyuk harf: i -> İ, ı -> I. Ingilizcede duz to_upper.
static func buyuk(s: String) -> String:
	if TranslationServer.get_locale().begins_with("tr"):
		return s.replace("i", "İ").replace("ı", "I").to_upper()
	return s.to_upper()


## "01 / TOPRAK" (katman no + cevrilmis ad).
static func kisa_baslik(no: int, ad: String) -> String:
	return "%02d / %s" % [no, buyuk(Ceviri.t(ad))]


## Duz dolgulu kutu (HUD rozeti, kartlar).
static func kutu(dolgu: Color, yaricap: int = 3, yatay: int = 0, dikey: int = 0,
		cerceve: Color = Color(0, 0, 0, 0), kalinlik: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = dolgu
	s.border_color = cerceve
	s.set_border_width_all(kalinlik)
	s.set_corner_radius_all(yaricap)
	s.content_margin_left = yatay
	s.content_margin_right = yatay
	s.content_margin_top = dikey
	s.content_margin_bottom = dikey
	s.anti_aliasing = true
	return s


## Etiket: mono ya da govde, boyut/renk burada.
static func etiket(metin: String, boyut: int, renk: Color, mono := true, kalin := false) -> Label:
	var e := Label.new()
	e.text = metin
	if mono:
		e.theme_type_variation = &"EtiketKalin" if kalin else &"Etiket"
	else:
		e.theme_type_variation = &"Baslik" if kalin else &"Govde"
	e.add_theme_font_size_override("font_size", boyut)
	e.add_theme_color_override("font_color", renk)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e


## Günlük video imkânlarından alınan renk akışı ve geçiş aileleri
## (sosyal/uret/tema.mjs TEMALAR, docs/TASARIM.md "Günlük video imkânlarından alınanlar").
## Dünya DÜZ kalır; akış yalnız geçişlerde, derinlik sayacında ve rekor damgasında.
## Dizin = derinlik teması (0 toprak + kaya, 1 bazalt + çekirdek; Ayarlar.AMBIYANS bandına göre).
## "vurgu" sırayla döner (video: renkAkisi); yazı rengi vurgunun üstünde kodla seçilir (en az ESIK).
## Renkler videodaki klasik akışın (sarı, camgöbeği, turuncu, mercan, krem) derin-kazi'nin kendi
## dünyasıyla değiştirilmiş hali: amber, elmas camgöbeği, uç turuncusu, gaz yeşili, kâğıt.
const GECIS_TURLERI: Array[StringName] = [&"iris", &"glitch", &"bloklar", &"itme", &"perde", &"flas", &"kararma", &"zoom"]
const ESIK := 4.5                  ## okunurluk alt sınırı (video 5:1, burada 4,5:1)
const AKIS: Array = [
	{"kaynak": "klasik", "acik": KAGIT, "koyu": MUREKKEP,
		"vurgu": [AMBER, CAMGOBEGI, UC, YESIL, KAGIT],
		"gecis": [&"itme", &"bloklar", &"iris", &"perde"]},
	{"kaynak": "klasik+harita", "acik": KAGIT, "koyu": MUREKKEP,
		"vurgu": [UC, SARI, TEHLIKE, AMBER, KAGIT],
		"gecis": [&"glitch", &"zoom", &"flas", &"kararma"]},
]


## Derinlik teması: bazalt bandından (150 m) itibaren 1.
static func derinlik_temasi(d: int) -> int:
	return 1 if Ayarlar.ambiyans(d) >= 2 else 0


## WCAG göreli parlaklık.
static func parlaklik(c: Color) -> float:
	var k: Array[float] = []
	for v in [c.r, c.g, c.b]:
		k.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * k[0] + 0.7152 * k[1] + 0.0722 * k[2]


static func kontrast(a: Color, b: Color) -> float:
	var x := parlaklik(a)
	var y := parlaklik(b)
	return (maxf(x, y) + 0.05) / (minf(x, y) + 0.05)


## Vurgu rengi üzerindeki yazı: açık ya da koyu, hangisi daha okunuyorsa.
static func yazi_rengi(zemin: Color, tema: int) -> Color:
	var a: Dictionary = AKIS[clampi(tema, 0, AKIS.size() - 1)]
	return a["acik"] if kontrast(zemin, a["acik"]) >= kontrast(zemin, a["koyu"]) else a["koyu"]


## Akış paletinden k. renk (sarmal).
static func akis_rengi(tema: int, k: int) -> Color:
	var v: Array = AKIS[clampi(tema, 0, AKIS.size() - 1)]["vurgu"]
	return v[posmod(k, v.size())]
