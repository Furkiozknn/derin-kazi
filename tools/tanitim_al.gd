## Tanıtım karesi dizisi: kazı → maden → deprem uyarısı → deprem (≤ 4 sn).
## Gerçek oyundan alınır, montaj yok.
##   godot --path . --script res://tools/tanitim_al.gd   (--headless ile ÇALIŞMAZ)
## Çıktı: build/tanitim/kare-00..NN.png  →  yayin/tanitim.gif (ffmpeg, bkz. README)
extends SceneTree

const CIKTI := "res://build/tanitim/"
const ARALIK := 5      ## kaç fizik karesinde bir kare alınır (60/5 = 12 fps)
const KARE_SAYISI := 48

var sahne: Node
var arac: Arac
var dunya: Dunya
var durum: Durum
var _no := 0

func _initialize() -> void:
	_calis()

func _bekle(n: int) -> void:
	for i in n:
		await physics_frame
	await process_frame

## ARALIK fizik karesi ilerletir ve bir kare yazar.
func _kare_al() -> void:
	await _bekle(ARALIK)
	var im := root.get_texture().get_image()
	im.resize(640, 360, Image.INTERPOLATE_NEAREST)
	im.save_png(ProjectSettings.globalize_path(CIKTI + "kare-%02d.png" % _no))
	_no += 1

func _kareler(n: int) -> void:
	for i in n:
		await _kare_al()

func _calis() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CIKTI))
	Kayit.sil()
	sahne = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(sahne)
	await _bekle(40)
	arac = sahne.get_node("Arac")
	dunya = sahne.get_node("Dunya")
	durum = sahne.durum
	durum.matkap = 2
	durum.kasa = 2
	durum.depo = 2
	durum.para = 640
	durum.yakit = durum.yakit_kapasitesi()

	# Sahne kurulumu: taş katmanında kazılmış bir tünelin dibi, altında bakır damarı.
	# Kareler gerçek oyundan; yalnız başlangıç durumu kuruluyor (ekran_al.gd gibi).
	var yer := Vector2i(Ayarlar.US_KARO_X, 34)
	for dy in range(-6, 1):
		for dx in range(-1, 2):
			dunya.karo_kir(yer + Vector2i(dx, dy))
	var damar := {}
	for dy in range(1, 5):
		damar[yer + Vector2i(0, dy)] = Ayarlar.BAKIR
		if dy % 2 == 1:
			damar[yer + Vector2i(1, dy)] = Ayarlar.BAKIR
	dunya.degistir([], damar)
	arac.isinlan(dunya.hucre_merkezi(yer))
	dunya.hazirla(arac.global_position)
	sahne.get_node("Arac/Kamera").reset_smoothing()
	await _bekle(30)

	# 1) Kazı ve maden: damarı aşağı doğru kazıyor, "+₺" uçuyor.
	Input.action_press("asagi")
	await _kareler(20)
	# 2) Deprem uyarısı: oyunun kendi akışı kurar (sarsıntı + HUD geri sayımı).
	durum.deprem_bekliyor = true
	await _kareler(16)
	# 3) Uyarıyı kısaltıp depremin kendisini de kareye al.
	sahne.set("_deprem_uyari", minf(float(sahne.get("_deprem_uyari")), 0.4))
	await _kareler(maxi(KARE_SAYISI - _no, 1))
	Input.action_release("asagi")
	print("tanıtım: %d kare -> %s" % [_no, CIKTI])
	quit(0)
