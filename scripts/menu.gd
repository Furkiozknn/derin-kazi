## Ana menü. "Başla" kayıtlı dünyayı sürdürür, "Yeni dünya" yeni tohumla sıfırdan başlatır.
extends Control

@onready var _bilgi: Label = $M/V/Bilgi

func _ready() -> void:
	$M/V/Basla.pressed.connect(_basla)
	$M/V/Yeni.pressed.connect(_yeni)
	$M/V/Cikis.pressed.connect(func(): get_tree().quit())
	$M/V/Basla.grab_focus()
	_bilgi_yenile()

func _bilgi_yenile() -> void:
	var k := Kayit.yukle()
	if k.is_empty():
		_bilgi.text = "Kayıt yok — yeni bir dünya üretilecek."
		$M/V/Basla.text = "Başla (yeni dünya)"
	else:
		_bilgi.text = "Tohum %d  •  Para %d  •  En derin %d m\nHedef: %d m derinlikteki çekirdek" % [
			int(k.get("tohum", 0)), int(k.get("para", 0)),
			int(k.get("en_derin", 0)), Ayarlar.CEKIRDEK_DERINLIK
		]
		$M/V/Basla.text = "Başla (kayıttan devam)"

func _basla() -> void:
	get_tree().change_scene_to_file("res://scenes/oyun.tscn")

func _yeni() -> void:
	Kayit.kaydet({"tohum": randi(), "para": 0, "en_derin": 0, "matkap": 0, "depo": 0, "kasa": 0})
	_bilgi_yenile()
	_basla()
