## Denetim / kanıt ekran görüntüleri (v0.8): menü, ayarlar, HUD, duraklat, mağaza, çekilme,
## oyun sonu, dokunmatik — Türkçe ve İngilizce. Gerçek oyundan kare alır (pencereli):
##   godot --path . --script res://tools/kanit_al.gd -- <cikti_klasoru>
## Kayıt dosyasını değiştirir (test paketleri gibi); dil ayarı sonunda otomatiğe döner.
extends SceneTree

var _dir := ""
var _sahne: Node
var _arac: Arac
var _dunya: Dunya
var _durum: Durum

func _initialize() -> void:
	var arg := OS.get_cmdline_user_args()
	_dir = arg[0] if arg.size() > 0 else "res://docs/ekran/"
	DirAccess.make_dir_recursive_absolute(_dir if not _dir.begins_with("res://") else ProjectSettings.globalize_path(_dir))
	_calis.call_deferred()

func _kare(n: int) -> void:
	for i in n:
		await physics_frame
	await process_frame
	await process_frame

func _yaz(ad: String) -> void:
	await _kare(3)
	var im := root.get_texture().get_image()
	var yol := _dir.path_join(ad + ".png")
	if yol.begins_with("res://"):
		yol = ProjectSettings.globalize_path(yol)
	im.save_png(yol)
	print("  %s  %dx%d" % [ad, im.get_width(), im.get_height()])

func _oda_ac(merkez: Vector2i, gx: int, gy: int) -> void:
	for dy in range(-gy, gy + 1):
		for dx in range(-gx, gx + 1):
			_dunya.karo_kir(merkez + Vector2i(dx, dy))

func _calis() -> void:
	var ses = root.get_node("Ses")
	await process_frame
	for dil in ["tr", "en"]:
		ses.ayarla("dil", dil)
		await _menu(dil)
		await _oyun(dil)
	await _dokunmatik()
	ses.ayarla("dil", "")
	Kayit.sil()
	quit(0)

func _menu(dil: String) -> void:
	# Yeni oyuncu (kayıt yok) ve dönen oyuncu.
	Kayit.sil()
	Kayit.sil(Kayit.DERIN)
	var m: Node = load("res://scenes/menu.tscn").instantiate()
	root.add_child(m)
	await _kare(50)
	await _yaz("menu_ilk_%s" % dil)
	m.queue_free()
	await _kare(3)
	Kayit.kaydet({"tohum": 4242, "para": 1240, "en_derin": 170, "eserler": PackedInt32Array([0, 1, 2])})
	m = load("res://scenes/menu.tscn").instantiate()
	root.add_child(m)
	await _kare(50)
	await _yaz("menu_%s" % dil)
	m.call("_ayar_ac")
	await _kare(6)
	await _yaz("ayarlar_%s" % dil)
	m.call("_ayar_kapat")
	if dil == "tr":
		m.call("_tohum_ac")
		await _kare(6)
		await _yaz("tohum_tr")
		m.call("_tohum_kapat")
	m.queue_free()
	await _kare(3)

func _oyun(dil: String) -> void:
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242})
	_sahne = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(_sahne)
	await process_frame
	await _kare(40)
	_arac = _sahne.get_node("Arac")
	_dunya = _sahne.get_node("Dunya")
	_durum = _sahne.durum
	# HUD, yüzey (ilk oyun ipucu görünür)
	await _kare(20)
	await _yaz("hud_yuzey_%s" % dil)
	# Kazı
	_durum.matkap = 2
	_durum.kasa = 2
	_durum.para = 1240
	Input.action_press("asagi")
	await _kare(560)
	Input.action_release("asagi")
	await _kare(20)
	await _yaz("hud_kazi_%s" % dil)
	# Derin katman + deprem uyarısı
	_durum.matkap = Ayarlar.EN_YUKSEK_SEVIYE
	_durum.aletler["radar"] = true
	_durum.yakit = _durum.yakit_kapasitesi()
	var derin := Vector2i(_dunya.uretici.cekirdek_x, 168)
	_oda_ac(derin, 5, 3)
	_arac.isinlan(_dunya.hucre_merkezi(derin))
	_sahne.set("_radar_acik", true)
	for i in 30:
		_sahne.call("_harita_ac", derin + Vector2i(randi_range(-8, 8), randi_range(-30, 6)))
	_sahne.get_node("HUD/Harita").visible = true
	await _kare(40)
	_sahne.set("_deprem_uyari_derinlik", _arac.derinlik())
	_sahne.set("_deprem_uyari", 7.4)
	_sahne.call("_hud_yenile")
	await _yaz("hud_deprem_%s" % dil)
	_sahne.set("_deprem_uyari", 0.0)
	_sahne.get_node("HUD/Harita").visible = false
	# Duraklat, ayarlar, mağaza
	_arac.usse_don()
	await _kare(60)
	_sahne.call("_unhandled_input", _tus("duraklat"))
	await _kare(6)
	await _yaz("duraklat_%s" % dil)
	_sahne.call("_ayar_ac")
	await _kare(6)
	await _yaz("duraklat_ayarlar_%s" % dil)
	_sahne.call("_panelleri_kapat")
	await _kare(4)
	_durum.para = 1240
	_sahne.call("_magaza_ac")
	await _kare(6)
	await _yaz("magaza_%s" % dil)
	_sahne.call("_panelleri_kapat")
	await _kare(4)
	# Yüzeye çekilme (uyarı paneli)
	_sahne.call("_uyari_goster", Ceviri.t("Yüzeye çekildin.") + "\n" + Ceviri.t("Çekme ücreti: %d ₺") % 42)
	await _kare(6)
	await _yaz("cekildin_%s" % dil)
	_sahne.call("_uyari_kapat")
	# Oyun sonu
	_durum.en_derin = 250
	_durum.kazilan_karo = maxi(_durum.kazilan_karo, 120)
	await _kare(10)
	_sahne.call("_kazandi")
	await _kare(10)
	await _yaz("bitis_%s" % dil)
	_sahne.queue_free()
	await _kare(4)

func _dokunmatik() -> void:
	root.get_node("Ses").ayarla("dil", "en")
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242})
	_sahne = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(_sahne)
	await process_frame
	await _kare(40)
	_arac = _sahne.get_node("Arac")
	_dunya = _sahne.get_node("Dunya")
	_durum = _sahne.durum
	_sahne.set("_dokunmatik", true)
	_sahne.get_node("Dokunmatik").visible = true
	_sahne.call("dokunmatik_kur")
	_durum.dinamit = 3
	_durum.aletler["radar"] = true
	var eski := root.size
	root.size = Vector2i(915, 412)
	await _kare(30)
	await _yaz("dokunmatik_en")
	root.size = eski
	_sahne.queue_free()
	await _kare(4)

func _tus(eylem: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = StringName(eylem)
	ev.pressed = true
	return ev
