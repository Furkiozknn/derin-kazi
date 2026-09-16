## Ana menü. Üç yuva var:
##   ana oyun  — "Başla" kayıtlı dünyayı sürdürür (tüneller dahil)
##   günlük    — tarihten türeyen tohum, ayrı kayıt, günün en derin noktası
##   Derin Mod — çekirdek bulunduktan sonra yeni tohum + zorlaştırıcılar,
##               eser bonusları korunur
## Tohum kodu (7 karakter) dünyayı paylaşmak için: göster / gir.
extends Control

@onready var _bilgi: Label = $Bilgi
@onready var _kontroller: Label = $Kontroller
@onready var _ayar: PanelContainer = $Ayar
@onready var _tohum_panel: PanelContainer = $TohumPanel
@onready var _giris: LineEdit = $TohumPanel/M/V/Giris
@onready var _kod_durum: Label = $TohumPanel/M/V/Durum

const YARDIM_TUS := "A/D veya ←/→: yürü ve yana kaz  •  S veya ↓: aşağı kaz  •  W/Boşluk: pervane
E: üs  •  T: ışınlanma  •  Q: radar  •  F: dinamit  •  M: harita  •  Esc: duraklat
Gamepad: sol çubuk, A pervane, X üs, LB radar, RB ışınlanma, Y dinamit, Start duraklat"

const YARDIM_DOKUNMA := "Alt sol / alt sağ köşeye dokun: o yöne yürü ve yana kaz
Alt ortaya dokun: aşağı kaz  •  ▲ alanına (üst orta) dokun: pervaneyle yüksel
Sağ üstteki düğmeler: Üs • Harita • ■ duraklat"

func _ready() -> void:
	$M/V/Basla.pressed.connect(_basla)
	$M/V/Yeni.pressed.connect(_yeni)
	$M/V/Tohum.pressed.connect(_tohum_ac)
	$M/V/Gunluk.pressed.connect(_gunluk)
	$M/V/Derin.pressed.connect(_derin_mod)
	$M/V/Ayarlar.pressed.connect(_ayar_ac)
	$M/V/Cikis.pressed.connect(_cik)
	$M/V/Cikis.visible = not OS.has_feature("web")
	$TohumPanel/M/V/KodBasla.pressed.connect(_kodla_basla)
	$TohumPanel/M/V/Kapat.pressed.connect(_tohum_kapat)
	_giris.text_changed.connect(_kod_degisti)
	_giris.text_submitted.connect(func(_t: String) -> void: _kodla_basla())
	$M/V/Basla.grab_focus()
	# Dokunmatik cihazda klavye/gamepad yardımı yanlış bilgi: dokunma alanlarını anlat.
	_kontroller.text = YARDIM_DOKUNMA if DisplayServer.is_touchscreen_available() else YARDIM_TUS
	Ses.muzik_cal("muzik_menu")
	_bilgi_yenile()

func _bilgi_yenile() -> void:
	Kayit.aktif = Kayit.ANA
	var k := Kayit.yukle()
	var gunluk := Kayit.yukle(Kayit.GUNLUK)
	var gunluk_satir := "Günlük dünya: %s" % Kayit.bugun()
	if String(gunluk.get("gun", "")) == Kayit.bugun():
		gunluk_satir += "  •  bugünün en derin noktası %d m" % int(gunluk.get("en_derin", 0))
	$M/V/Gunluk.text = "Günlük dünya (%s)" % Kayit.bugun()

	if k.is_empty():
		_bilgi.text = "Kayıt yok — yeni bir dünya üretilecek.\n%s" % gunluk_satir
		$M/V/Basla.text = "Başla (yeni dünya)"
		$M/V/Derin.visible = false
		return
	var kazilan := PackedInt32Array(k.get("kazilan", PackedInt32Array())).size() / 2
	var eser := PackedInt32Array(k.get("eserler", PackedInt32Array())).size()
	var derin := int(k.get("derin_seviye", 0))
	var mod := "" if derin <= 0 else "  •  Derin Mod x%d" % derin
	_bilgi.text = "Tohum %s  •  %d ₺  •  En derin %d m  •  %d/%d eser%s\n%d karo kazılmış — tüneller yerinde duruyor\n%s" % [
		TohumKodu.kodla(int(k.get("tohum", 0))), int(k.get("para", 0)),
		int(k.get("en_derin", 0)), eser, Ayarlar.ESERLER.size(), mod, kazilan, gunluk_satir]
	$M/V/Basla.text = "Başla (kayıttan devam)"
	# Derin Mod yalnız çekirdek bir kez çıkarıldıysa açılır.
	$M/V/Derin.visible = bool(k.get("kazandi", false))
	$M/V/Derin.text = "Derin Mod x%d — yeni tohum, eserler kalır" % (derin + 1)

func _basla() -> void:
	Ses.cal("menu")
	get_tree().change_scene_to_file("res://scenes/oyun.tscn")

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

## Derin Mod: yeni tohum + zorlaştırıcılar, eserler ve Derin Mod seviyesi korunur.
func _derin_mod() -> void:
	Ses.cal("menu")
	Kayit.aktif = Kayit.ANA
	var k := Kayit.yukle()
	var eserler := PackedInt32Array(k.get("eserler", PackedInt32Array()))
	var seviye := int(k.get("derin_seviye", 0)) + 1
	Kayit.sil()
	Kayit.kaydet({"tohum": randi(), "eserler": eserler, "derin_seviye": seviye})
	_bilgi_yenile()
	_basla()

# --- tohum kodu -----------------------------------------------------------

func _tohum_ac() -> void:
	Ses.cal("menu")
	_tohum_panel.visible = true
	var k := Kayit.yukle(Kayit.ANA)
	var suanki := int(k.get("tohum", 0))
	$TohumPanel/M/V/Bilgi.text = "Şu anki dünyanın kodu: %s\n\nKodu bir arkadaşına ver, aynı dünyayı oynasın. Kod 7 harf; I, O, 0 ve 1 yok (karışmasın diye).\n\nBaşkasının kodunu girip yeni dünya açabilirsin — ana ilerlemen sıfırlanır." % (
		TohumKodu.kodla(suanki) if not k.is_empty() else "— (henüz dünya yok)")
	_giris.text = ""
	_kod_durum.text = ""
	_giris.grab_focus()

func _kod_degisti(metin: String) -> void:
	var temiz := TohumKodu.suz(metin)
	if temiz != metin:
		_giris.text = temiz
		_giris.caret_column = temiz.length()
	_kod_durum.text = "" if temiz.length() < TohumKodu.UZUNLUK \
		else ("Kod geçerli." if TohumKodu.coz(temiz) != TohumKodu.GECERSIZ else "Kod geçersiz — harfleri kontrol et.")

func _kodla_basla() -> void:
	var t := TohumKodu.coz(_giris.text)
	if t == TohumKodu.GECERSIZ:
		_kod_durum.text = "Kod geçersiz — 7 harf olmalı ve sağlaması tutmalı."
		Ses.cal("uyari")
		return
	_tohum_panel.visible = false
	_yeni(t)

func _tohum_kapat() -> void:
	Ses.cal("menu")
	_tohum_panel.visible = false
	$M/V/Tohum.grab_focus()

# --- ayarlar --------------------------------------------------------------

func _ayar_ac() -> void:
	Ses.cal("menu")
	_ayar.visible = true
	AyarPanel.kur($Ayar/M/V/Kaydir/Liste, _ayar_kapat)

func _ayar_kapat() -> void:
	_ayar.visible = false
	$M/V/Ayarlar.grab_focus()

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
