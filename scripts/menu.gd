## Ana menü. "Başla" kayıtlı dünyayı sürdürür (tüneller dahil),
## "Yeni dünya" yeni tohumla sıfırdan başlatır.
extends Control

@onready var _bilgi: Label = $M/V/Bilgi
@onready var _ayar: PanelContainer = $Ayar

func _ready() -> void:
	$M/V/Basla.pressed.connect(_basla)
	$M/V/Yeni.pressed.connect(_yeni)
	$M/V/Ayarlar.pressed.connect(_ayar_ac)
	$M/V/Cikis.pressed.connect(_cik)
	$M/V/Cikis.visible = not OS.has_feature("web")
	$M/V/Basla.grab_focus()
	Ses.muzik_cal("muzik_menu")
	_bilgi_yenile()

func _bilgi_yenile() -> void:
	var k := Kayit.yukle()
	if k.is_empty():
		_bilgi.text = "Kayıt yok — yeni bir dünya üretilecek."
		$M/V/Basla.text = "Başla (yeni dünya)"
		return
	var kazilan := PackedInt32Array(k.get("kazilan", PackedInt32Array())).size() / 2
	var eser := PackedInt32Array(k.get("eserler", PackedInt32Array())).size()
	_bilgi.text = "Tohum %d  •  %d ₺  •  En derin %d m  •  %d/%d eser\n%d karo kazılmış — tüneller yerinde duruyor" % [
		int(k.get("tohum", 0)), int(k.get("para", 0)), int(k.get("en_derin", 0)),
		eser, Ayarlar.ESERLER.size(), kazilan]
	$M/V/Basla.text = "Başla (kayıttan devam)"

func _basla() -> void:
	Ses.cal("menu")
	get_tree().change_scene_to_file("res://scenes/oyun.tscn")

func _yeni() -> void:
	Ses.cal("menu")
	Kayit.sil()
	Kayit.kaydet({"tohum": randi()})
	_bilgi_yenile()
	_basla()

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
	if olay.is_action_pressed("duraklat") and _ayar.visible:
		_ayar_kapat()
		get_viewport().set_input_as_handled()
