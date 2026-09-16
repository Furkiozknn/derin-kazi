## Yayın paketi görselleri: 4 ekran görüntüsü (1280x720) + kapak (630x500).
## Gerçek oyundan kare alır — montaj yok.
##   godot --path . --script res://tools/ekran_al.gd     (--headless ile ÇALIŞMAZ: render gerekiyor)
## Çıktı: yayin/ekran-1..4.png, yayin/kapak.png
extends SceneTree

const CIKTI := "res://yayin/"

var sahne: Node
var arac: Arac
var dunya: Dunya
var durum: Durum

func _initialize() -> void:
	_calis()

func _kare(n: int) -> void:
	for i in n:
		await physics_frame
	await process_frame
	await process_frame

func _yaz(ad: String) -> void:
	await _kare(3)
	var im := root.get_texture().get_image()
	im.save_png(ProjectSettings.globalize_path(CIKTI + ad))
	print("  %s  %dx%d" % [ad, im.get_width(), im.get_height()])

## Aracın çevresini oyar: derine ışınlanınca kayanın içinde gömülü görünmesin.
func _oda_ac(merkez: Vector2i, gx: int, gy: int) -> void:
	for dy in range(-gy, gy + 1):
		for dx in range(-gx, gx + 1):
			dunya.karo_kir(merkez + Vector2i(dx, dy))

func _calis() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CIKTI))
	Kayit.sil()
	sahne = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(sahne)
	await _kare(40)
	arac = sahne.get_node("Arac")
	dunya = sahne.get_node("Dunya")
	durum = sahne.durum
	print("ekran görüntüleri (%dx%d):" % [root.get_texture().get_width(), root.get_texture().get_height()])

	# 1 — yüzey kasabası: üs, gökyüzü, parallaks, HUD
	durum.para = 1240
	durum.dinamit = 3
	await _kare(30)
	await _yaz("ekran-1.png")

	# 2 — kazarken: tünel, maden, uçan yazı, parçacık
	durum.matkap = 2
	durum.kasa = 2
	Input.action_press("asagi")
	await _kare(700)
	Input.action_release("asagi")
	await _kare(20)
	await _yaz("ekran-2.png")
	# Kapak arka planı: aynı kare, HUD kapalı.
	sahne.get_node("HUD").visible = false
	await _yaz("kapak-fon.png")
	sahne.get_node("HUD").visible = true

	# 3 — üs menüsü: satış, geliştirme, alet listesi
	durum.para = 1240
	arac.usse_don()
	await _kare(20)
	sahne.call("_magaza_ac")
	await _kare(20)
	await _yaz("ekran-3.png")
	sahne.call("_panelleri_kapat")
	await _kare(10)

	# 4 — derin katman: bazalt, mini harita, radar, istasyon
	durum.matkap = Ayarlar.EN_YUKSEK_SEVIYE
	durum.depo = 3
	durum.govde = 2
	durum.aletler["radar"] = true
	durum.aletler["kalkan"] = true
	durum.yakit = durum.yakit_kapasitesi()
	var derin := Vector2i(dunya.uretici.cekirdek_x, 168)
	_oda_ac(derin, 5, 3)
	arac.isinlan(dunya.hucre_merkezi(derin))
	durum.istasyon_kiti = 1
	durum.istasyon_kur(derin + Vector2i(3, 0))
	sahne.call("_nesne_yenile")
	sahne.set("_radar_acik", true)
	sahne.get_node("HUD/Harita").visible = true
	for i in 30:
		sahne.call("_harita_ac", derin + Vector2i(randi_range(-8, 8), randi_range(-30, 6)))
	await _kare(40)
	Input.action_press("sag")
	await _kare(40)
	Input.action_release("sag")
	await _yaz("ekran-4.png")

	await _kapak()
	quit(0)

## Kapak: gerçek oyundan bir kare + logo + başlık, 630x500.
func _kapak() -> void:
	sahne.queue_free()
	await _kare(5)
	var k: Node = load("res://scenes/kapak.tscn").instantiate()
	root.add_child(k)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(630, 500)
	await _kare(20)
	var im := root.get_texture().get_image()
	im.save_png(ProjectSettings.globalize_path(CIKTI + "kapak.png"))
	print("  kapak.png  %dx%d" % [im.get_width(), im.get_height()])
