## Günlük video imkânları (v0.9) kanıt kareleri: sekiz geçiş ailesi yarım örtüde (iki derinlik paleti),
## derinlik sayacı renk akışı, YENİ REKOR damgası, duraklat perdesi, çekilme flaşı, deprem glitch'i,
## oyun sonu iris'i, menü açılış iris'i ve dil değişimi glitch'i. Gerçek oyundan kare alır (pencereli):
##   godot --path . --script res://tools/gecis_kanit.gd -- <cikti_klasoru>
## Kayıt dosyasını değiştirir (test paketleri gibi); ayar ve kayıt sonunda temizlenir.
extends SceneTree

var _dir := ""
var _sahne: Node
var _arac: Arac
var _dunya: Dunya
var _g: Node

func _initialize() -> void:
	var arg := OS.get_cmdline_user_args()
	_dir = arg[0] if arg.size() > 0 else "res://docs/ekran/"
	DirAccess.make_dir_recursive_absolute(_dir if not _dir.begins_with("res://") else ProjectSettings.globalize_path(_dir))
	_calis.call_deferred()

func _bekle(s: float) -> void:
	await create_timer(s).timeout
	await process_frame

func _yaz(ad: String, bolge := Rect2i()) -> void:
	await process_frame
	var im := root.get_texture().get_image()
	if bolge.size.x > 0:
		im = im.get_region(bolge)
	var yol := _dir.path_join(ad + ".png")
	if yol.begins_with("res://"):
		yol = ProjectSettings.globalize_path(yol)
	im.save_png(yol)
	print("  %s  %dx%d" % [ad, im.get_width(), im.get_height()])

func _dondur(tur: StringName, tema: int, p: float) -> void:
	_g._kur(tur, tema)
	_g._kaplama.visible = true
	_g._p_yaz(p)
	await _bekle(0.1)
	_g._p_yaz(p)

func _ac_kapat() -> void:
	_g._kaplama.visible = false

func _oda(d: int) -> void:
	var h := Vector2i(Ayarlar.US_KARO_X, d)
	for dy in range(-3, 4):
		for dx in range(-6, 7):
			_dunya.karo_kir(h + Vector2i(dx, dy))
	_arac.isinlan(_dunya.hucre_merkezi(h))

func _oyun_ac(en_derin: int) -> void:
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242, "en_derin": en_derin, "matkap": 3, "depo": 2, "para": 240})
	_sahne = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(_sahne)
	await _bekle(0.5)
	_arac = _sahne.get_node("Arac")
	_dunya = _sahne.get_node("Dunya")
	_sahne.durum.yakit = 99999.0

func _calis() -> void:
	var ses = root.get_node("Ses")
	_g = root.get_node("Gecis")
	ses.ayarla("dil", "tr")
	ses.ayarla("sade_gecis", false)
	ses.ayar["muzik_acik"] = false
	ses.ayar["efekt_acik"] = false
	ses.ayarlari_uygula()
	_g.acilis_yapildi = true
	await _oyun_ac(60)
	_oda(45)
	await _bekle(0.6)
	# Sekiz aile, yarım örtü; ilk dört toprak/kaya paleti, son dört bazalt/çekirdek paleti
	var plan := [[&"perde", 0], [&"itme", 0], [&"bloklar", 0], [&"iris", 0],
		[&"glitch", 1], [&"zoom", 1], [&"flas", 1], [&"kararma", 1]]
	for pl in plan:
		await _dondur(pl[0], pl[1], 0.55)
		await _yaz("gecis-%s" % pl[0])
		_ac_kapat()
	await _dondur(&"bloklar", 1, 0.85)
	await _yaz("gecis-bloklar-cekirdek-yogun")
	_ac_kapat()
	# Derinlik sayacı: üç ardışık kademe, üç akış rengi (üst şerit)
	for k in 3:
		_sahne.set("_vurgu_kalan", 0.0)
		_sahne.call("_derinlik_vurgula")
		await _bekle(0.05)
		await _yaz("sayac-akis-%d" % (k + 1), Rect2i(700, 0, 580, 60))
		_sahne.call("_derinlik_boya", false)
	# YENİ REKOR damgası (en derin 60 iken 61 m)
	_arac.global_position = Vector2(_arac.global_position.x, 61.5 * Ayarlar.KARO)
	_sahne.set("_rekor_esigi", 60)
	_sahne.set("_rekor_verildi", false)
	_sahne.call("_derinlik_izle", 61)
	await _bekle(1.0)
	await _yaz("yeni-rekor-damga")
	# Duraklat perdesi (yarım)
	_sahne.call("_duraklat_ac")
	await _bekle(0.05)
	await _dondur(&"perde", 0, 0.5)
	await _yaz("duraklat-perde")
	_ac_kapat()
	_sahne.call("_duraklat_kapat")
	# Yüzeye çekilme: tehlike flaşı; deprem: glitch
	await _bekle(0.3)
	_sahne.call("_kosu_bitti")
	await _bekle(0.04)
	await _yaz("cekilme-flas")
	await _bekle(0.5)
	_sahne.call("_uyari_kapat")
	_oda(30)
	await _bekle(0.5)
	_sahne.set("_deprem_uyari_derinlik", 30)
	_sahne.call("_deprem_uygula")
	await _bekle(0.03)
	await _yaz("deprem-glitch")
	await _bekle(0.5)
	# Oyun sonu iris (doğal akışta, açılırken)
	_sahne.call("_kazandi")
	await _bekle(0.12)
	await _yaz("oyun-sonu-iris")
	await _bekle(0.6)
	_sahne.queue_free()
	await _bekle(0.3)
	# Menü: açılış iris'i ve dil glitch'i
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242, "en_derin": 64, "para": 321})
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await _bekle(1.2)
	await _dondur(&"iris", 0, 0.6)
	await _yaz("menu-acilis-iris")
	_ac_kapat()
	await _dondur(&"glitch", 0, 0.5)
	await _yaz("dil-glitch")
	_ac_kapat()
	menu.queue_free()
	await _bekle(0.2)
	Kayit.sil()
	ses.ayarla("dil", "")
	ses.ayarla("sade_gecis", false)
	ses.ayarla("muzik_acik", true)   ## başta kapatılmıştı: kayıtlı ayar temiz kalsın
	ses.ayarla("efekt_acik", true)
	quit(0)
