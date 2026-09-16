## Üretilen sprite'ları 6x büyütüp tek bir sayfada toplar — gözle denetim için.
##   godot --headless --path . --script res://tools/onizleme.gd
## Çıktı: docs/sprite-onizleme.png  (depoya girmez, sadece bakmak için)
extends SceneTree

const KAT := 6

func _initialize() -> void:
	var dosyalar := ["karolar.png", "arac.png", "simgeler.png", "us.png",
		"istasyon.png", "logo.png", "tepeler.png", "kasaba.png", "fon_kaya.png"]
	var kok := ProjectSettings.globalize_path("res://assets/sprites/")
	var yuklu := []
	var g := 0
	var y := 0
	for d in dosyalar:
		var im := Image.load_from_file(kok + d)
		if im == null:
			continue
		im.resize(im.get_width() * KAT, im.get_height() * KAT, Image.INTERPOLATE_NEAREST)
		yuklu.append(im)
		g = maxi(g, im.get_width())
		y += im.get_height() + 8
	var sayfa := Image.create(g, y, false, Image.FORMAT_RGBA8)
	sayfa.fill(Color(0.10, 0.10, 0.14, 1.0))
	var oy := 0
	for im in yuklu:
		sayfa.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, oy))
		oy += im.get_height() + 8
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/"))
	sayfa.save_png(ProjectSettings.globalize_path("res://docs/sprite-onizleme.png"))
	print("docs/sprite-onizleme.png  %dx%d" % [sayfa.get_width(), sayfa.get_height()])
	quit(0)
