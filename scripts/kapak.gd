## Kapak görseli (630x500). Arkaplanı gerçek oyundan alınan ekran görüntüsü.
extends Control

const OYUN_KARE := "res://yayin/kapak-fon.png"

func _ready() -> void:
	var yol := ProjectSettings.globalize_path(OYUN_KARE)
	if not FileAccess.file_exists(yol):
		return
	var im := Image.load_from_file(yol)
	if im == null:
		return
	# Ortadan 630x350 oranında bir şerit al.
	var g := mini(im.get_width(), 1120)
	var y := int(float(g) * 350.0 / 630.0)
	im = im.get_region(Rect2i((im.get_width() - g) / 2, (im.get_height() - y) / 2, g, y))
	im.resize(630, 350, Image.INTERPOLATE_NEAREST)
	$Oyun.texture = ImageTexture.create_from_image(im)
