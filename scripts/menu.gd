## Ana menü. Üç yuva var:
##   ana oyun  — "Başla" kayıtlı dünyayı sürdürür (tüneller dahil)
##   günlük    — tarihten türeyen tohum, ayrı kayıt, günün en derin noktası
##   Derin Mod — çekirdek bulunduktan sonra açılır; v0.6'dan beri AYRI yuva
##               ([derin]): yeni tohum, dar ışık, sık deprem, 7. eser; eser
##               bonusları korunur, ana dünya yerinde kalır. Sağ üstte rozet.
## Tohum kodu (7 karakter) dünyayı paylaşmak için: göster / gir.
extends Control

@onready var _bilgi: Label = $Bilgi
@onready var _rozet: Label = $Rozet
@onready var _kontroller: Label = $M/V/Kontroller
@onready var _ayar: PanelContainer = $Ayar
@onready var _tohum_panel: PanelContainer = $TohumPanel
@onready var _giris: LineEdit = $TohumPanel/M/V/Giris
@onready var _kod_durum: Label = $TohumPanel/M/V/Durum

## Nasıl oynanır: TEK satır. Tam tuş listesi duraklatma ekranında.
const YARDIM_TUS := "A/D yürü  ·  S aşağı kaz  ·  W/Boşluk yüksel  ·  E üs"
const YARDIM_DOKUNMA := "Alt köşelere dokun: yürü  ·  ortaya: kaz  ·  ▲: yüksel"

## Kesit şeridi: videodaki gibi düz toprak bantları + kağıt matkap, ağır ağır iner.
const BANTLAR := [
	[60.0, Color("896843")], [130.0, Color("6d4f33")], [200.0, Color("55402c")],
	[262.0, Color("3b2b20")], [318.0, Color("571d13")],
]
const KESIT_G := 168.0
const SAFT_X := 76.0
var _matkap: Control
var _saft: ColorRect
var _yeni_bekliyor := false

func _ready() -> void:
	_kesit_kur()
	$M/V/Basla.pressed.connect(_basla)
	$M/V/Ikincil/Yeni.pressed.connect(_yeni_iste)
	$M/V/Ikincil/Tohum.pressed.connect(_tohum_ac)
	$M/V/Ikincil/Gunluk.pressed.connect(_gunluk)
	$M/V/Ikincil/Derin.pressed.connect(_derin_mod)
	$M/V/Ikincil/Ayarlar.pressed.connect(_ayar_ac)
	$M/V/Ikincil/Cikis.pressed.connect(_cik)
	$M/V/Ikincil/Cikis.visible = not OS.has_feature("web")
	$TohumPanel/M/V/KodBasla.pressed.connect(_kodla_basla)
	$TohumPanel/M/V/Kapat.pressed.connect(_tohum_kapat)
	_giris.text_changed.connect(_kod_degisti)
	_giris.text_submitted.connect(func(_t: String) -> void: _kodla_basla())
	$M/V/Basla.grab_focus()
	# Dokunmatik cihazda klavye yardımı yanlış bilgi: dokunma alanlarını anlat.
	_kontroller.text = tr(YARDIM_DOKUNMA if DisplayServer.is_touchscreen_available() else YARDIM_TUS)
	Ses.muzik_cal("muzik_menu", 0.8)   ## oyundan dönerken bant müziğinden yumuşak geçiş
	if not Gecis.acilis_yapildi and not Gecis.mesgul_mu():
		Gecis.acilis(&"iris", 0, 0.5)   ## menü açılışı: iris ortadan açılır (yalnız ilk açılışta)
	Gecis.acilis_yapildi = true
	_bilgi_yenile()
	UI.dugmeleri_bagla(self)
	UI.sirayla_gir([$Etiket, $M/V/Baslik, $M/V/AltBaslik, $M/V/Basla, _kontroller,
		$M/V/Ikincil, _bilgi])

## Kesit şeridini koddan kurar (düz ColorRect'ler; doku yok).
func _kesit_kur() -> void:
	var kesit: Control = $Kesit
	_dikdortgen(kesit, Rect2(0, 0, KESIT_G, 60), Tema.ZEMIN)
	var ust := 60.0
	for b in BANTLAR:
		var alt := float(b[0]) if float(b[0]) > ust else 130.0
		_dikdortgen(kesit, Rect2(0, ust, KESIT_G, alt - ust), b[1])
		ust = alt
	_dikdortgen(kesit, Rect2(0, ust, KESIT_G, 360.0 - ust), Tema.CEKIRDEK_KIRMIZI)
	# maden kareleri: amber, birkaç tane
	for k in [Vector2(20, 90), Vector2(126, 108), Vector2(34, 160), Vector2(118, 176),
			Vector2(24, 228), Vector2(132, 240), Vector2(112, 296)]:
		_dikdortgen(kesit, Rect2(k, Vector2(8, 8)), Tema.AMBER)
	# şaft + matkap (kağıt gövde, koyu göz, kırmızı uç)
	_saft = _dikdortgen(kesit, Rect2(SAFT_X, 60, 16, 0), Tema.MUREKKEP)
	_matkap = Control.new()
	_matkap.position = Vector2(SAFT_X - 4.0, 46.0)
	_dikdortgen(_matkap, Rect2(0, 0, 24, 20), Tema.KAGIT)
	_dikdortgen(_matkap, Rect2(14, 5, 5, 5), Tema.MUREKKEP)
	# Uç: basamaklı üçgen (ColorRect satırları; Polygon2D web'de WebGL uyarısı veriyordu).
	for i in 5:
		_dikdortgen(_matkap, Rect2(4 + i * 2, 20 + i * 3, 16 - i * 4, 3), Tema.UC)
	kesit.add_child(_matkap)
	_matkap_don()

static func _dikdortgen(ana: Control, r: Rect2, renk: Color) -> ColorRect:
	var c := ColorRect.new()
	c.color = renk
	c.position = r.position
	c.size = r.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ana.add_child(c)
	return c

## Matkap 250 m'yi 14 sn'de "iner", dibe varınca baştan (doğrusal; parlama yok).
func _matkap_don() -> void:
	var hedef := 300.0
	var t := create_tween().set_loops()
	t.tween_method(func(y: float) -> void:
		_matkap.position.y = y
		_saft.size.y = maxf(0.0, y - 60.0 + 20.0), 46.0, hedef, 14.0)
	t.tween_interval(0.6)

func _bilgi_yenile() -> void:
	Kayit.aktif = Kayit.ANA
	var k := Kayit.yukle()
	var gunluk := Kayit.yukle(Kayit.GUNLUK)
	var gunluk_satir := tr("GÜNLÜK %s") % Kayit.bugun()
	if String(gunluk.get("gun", "")) == Kayit.bugun():
		gunluk_satir += tr("  ·  BUGÜN EN DERİN %d m") % int(gunluk.get("en_derin", 0))
	_derin_yenile()
	if k.is_empty():
		_bilgi.text = tr("KAYIT YOK · YENİ DÜNYA ÜRETİLECEK") + "\n" + gunluk_satir
		return
	var kazilan := PackedInt32Array(k.get("kazilan", PackedInt32Array())).size() / 2
	var eser := PackedInt32Array(k.get("eserler", PackedInt32Array())).size()
	var derin := int(k.get("derin_seviye", 0))
	# v0.5 kaydı Derin Mod'u ana yuvada taşıyabilir; etiket ve eser sayısı ona göre.
	var mod := "" if derin <= 0 else "  ·  " + tr("DERİN MOD x%d") % derin
	var eser_toplam := Ayarlar.ESERLER.size() if derin > 0 else Ayarlar.ESERLER.size() - 1
	_bilgi.text = tr("TOHUM %s  ·  %d ₺  ·  EN DERİN %d m  ·  ESER %d/%d%s") % [
		TohumKodu.kodla(int(k.get("tohum", 0))), int(k.get("para", 0)),
		int(k.get("en_derin", 0)), eser, eser_toplam, mod] + "\n" \
		+ tr("%d KARO KAZILMIŞ") % kazilan + "  ·  " + gunluk_satir

## Derin Mod düğmesi ve sağ üstteki rozet. Düğme çekirdek bir kez çıkarıldıysa
## (ana yuva) ya da süren/bitmiş bir Derin Mod yuvası varsa açılır.
func _derin_yenile() -> void:
	var ana := Kayit.yukle(Kayit.ANA)
	var derin := Kayit.yukle(Kayit.DERIN)
	var seviye := Kayit.derin_seviyesi()
	var suruyor := not derin.is_empty() and not bool(derin.get("kazandi", false))
	$M/V/Ikincil/Derin.visible = bool(ana.get("kazandi", false)) or not derin.is_empty()
	if suruyor:
		$M/V/Ikincil/Derin.text = tr("Derin Mod x%d — devam et (%d m, %d ₺)") % [
			int(derin.get("derin_seviye", 1)), int(derin.get("en_derin", 0)), int(derin.get("para", 0))]
	else:
		$M/V/Ikincil/Derin.text = tr("Derin Mod x%d — yeni tohum, eserler kalır") % (seviye + 1)
	# Rozet: Derin Mod'a girilmişse (herhangi bir yuvada) menüde görünür kalır.
	_rozet.visible = seviye > 0
	if _rozet.visible:
		var eser := 0
		for e in PackedInt32Array(derin.get("eserler", PackedInt32Array())):
			eser = maxi(eser, 1 if Ayarlar.eser_derin_mi(int(e)) else 0)
		_rozet.text = "▼ " + tr("DERİN MOD x%d") % seviye + " ▼   " \
			+ (tr("7. eser bulundu") if eser > 0 else tr("7. eser yalnız burada"))

func _basla() -> void:
	Ses.cal("menu")
	Gecis.git("res://scenes/oyun.tscn", 0, &"zoom")   ## menü -> oyun: yeryüzüne dalış (zoom)

## "Yeni dünya" ilerlemeyi siler: ilk basış onay ister (3 sn içinde ikinci basış uygular).
func _yeni_iste() -> void:
	var d: Button = $M/V/Ikincil/Yeni
	if _yeni_bekliyor:
		_yeni_bekliyor = false
		_yeni()
		return
	_yeni_bekliyor = true
	Ses.cal("uyari")
	d.text = tr("Emin misin? Tekrar dokun")
	await get_tree().create_timer(3.0).timeout
	if _yeni_bekliyor:
		_yeni_bekliyor = false
		d.text = tr("Yeni dünya")

## Ana yuvada sıfırdan yeni dünya. Eserler de sıfırlanır (Derin Mod'dan farkı bu).
func _yeni(tohum := -1) -> void:
	Ses.cal("menu")
	Kayit.aktif = Kayit.ANA
	Kayit.sil()
	Kayit.kaydet({"tohum": randi() if tohum < 0 else tohum})
	_bilgi_yenile()
	_basla()

## Günlük dünya: tarihten tohum, ayrı yuva. Ana ilerlemeye dokunmaz.
func _gunluk() -> void:
	Ses.cal("menu")
	Kayit.gunluk_hazirla()
	Kayit.aktif = Kayit.GUNLUK
	_basla()

## Derin Mod: kendi yuvasında sürer ya da yeni tohumla bir üst seviye kurulur
## (Kayit.derin_mod_hazirla). Ana dünya yerinde kalır.
func _derin_mod() -> void:
	Ses.cal("menu")
	Kayit.derin_mod_hazirla()
	_basla()

# --- tohum kodu -----------------------------------------------------------

func _tohum_ac() -> void:
	Ses.cal("menu")
	_tohum_panel.visible = true
	var k := Kayit.yukle(Kayit.ANA)
	var suanki := int(k.get("tohum", 0))
	$TohumPanel/M/V/Bilgi.text = tr("Şu anki dünyanın kodu: %s\n\nKodu bir arkadaşına ver, aynı dünyayı oynasın. Kod 7 harf; I, O, 0 ve 1 yok (karışmasın diye).\n\nBaşkasının kodunu girip yeni dünya açabilirsin — ana ilerlemen sıfırlanır.") % (
		TohumKodu.kodla(suanki) if not k.is_empty() else tr("— (henüz dünya yok)"))
	_giris.text = ""
	_kod_durum.text = ""
	_giris.grab_focus()

func _kod_degisti(metin: String) -> void:
	var temiz := TohumKodu.suz(metin)
	if temiz != metin:
		_giris.text = temiz
		_giris.caret_column = temiz.length()
	_kod_durum.text = "" if temiz.length() < TohumKodu.UZUNLUK \
		else (tr("Kod geçerli.") if TohumKodu.coz(temiz) != TohumKodu.GECERSIZ else tr("Kod geçersiz — harfleri kontrol et."))

func _kodla_basla() -> void:
	var t := TohumKodu.coz(_giris.text)
	if t == TohumKodu.GECERSIZ:
		_kod_durum.text = tr("Kod geçersiz — 7 harf olmalı ve sağlaması tutmalı.")
		Ses.cal("uyari")
		return
	_tohum_panel.visible = false
	_yeni(t)

func _tohum_kapat() -> void:
	Ses.cal("menu")
	_tohum_panel.visible = false
	$M/V/Ikincil/Tohum.grab_focus()

# --- ayarlar --------------------------------------------------------------

func _ayar_ac() -> void:
	Ses.cal("menu")
	_ayar.visible = true
	AyarPanel.kur($Ayar/M/V/Kaydir/Liste, _ayar_kapat, _dil_degisti)

## Dil değişince: paneli yeniden kur, kontrol satırını ve bilgiyi yenile.
func _dil_degisti() -> void:
	AyarPanel.kur($Ayar/M/V/Kaydir/Liste, _ayar_kapat, _dil_degisti)
	_kontroller.text = tr(YARDIM_DOKUNMA if DisplayServer.is_touchscreen_available() else YARDIM_TUS)
	_bilgi_yenile()
	if not _yeni_bekliyor:
		$M/V/Ikincil/Yeni.text = tr("Yeni dünya")

func _ayar_kapat() -> void:
	_ayar.visible = false
	$M/V/Ikincil/Ayarlar.grab_focus()

func _cik() -> void:
	get_tree().quit()

func _unhandled_input(olay: InputEvent) -> void:
	if not olay.is_action_pressed("duraklat"):
		return
	if _ayar.visible:
		_ayar_kapat()
		get_viewport().set_input_as_handled()
	elif _tohum_panel.visible:
		_tohum_kapat()
		get_viewport().set_input_as_handled()
