## Üretilen sprite'ları büyütüp tek bir sayfada toplar — gözle denetim için.
##   godot --headless --path . --script res://tools/onizleme.gd
## Çıktı: docs/sprite-onizleme.png (hepsi, 6x) ve docs/v07-kareler.png (yüzey karosu,
## 9 araç karesi, işaret — 10x; v0.7 raporunun görseli)
extends SceneTree

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/"))
	_sayfa(["karolar.png", "yuzey.png", "arac.png", "isaret.png", "simgeler.png", "us.png",
		"istasyon.png", "logo.png", "tepeler.png", "kasaba.png", "fon_kaya.png"], 6, "sprite-onizleme.png")
	_sayfa(["yuzey.png", "arac.png", "isaret.png"], 10, "v07-kareler.png")
	quit(0)

func _sayfa(dosyalar: Array, kat: int, cikti: String) -> void:
	var kok := ProjectSettings.globalize_path("res://assets/sprites/")
	var yuklu := []
	var g := 0
	var y := 0
	for d in dosyalar:
		var im := Image.load_from_file(kok + d)
		if im == null:
			continue
		im.resize(im.get_width() * kat, im.get_height() * kat, Image.INTERPOLATE_NEAREST)
		yuklu.append(im)
		g = maxi(g, im.get_width())
		y += im.get_height() + 8
	var sayfa := Image.create(g, y, false, Image.FORMAT_RGBA8)
	sayfa.fill(Color(0.10, 0.10, 0.14, 1.0))
	var oy := 0
	for im in yuklu:
		sayfa.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, oy))
		oy += im.get_height() + 8
	sayfa.save_png(ProjectSettings.globalize_path("res://docs/" + cikti))
	print("docs/%s  %dx%d" % [cikti, sayfa.get_width(), sayfa.get_height()])
