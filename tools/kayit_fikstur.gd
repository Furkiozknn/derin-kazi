## Kayıt fikstürü üretir: GERÇEK oyun sahnesini kurar, 15 sn kazar, üsse döner,
## kaydeder ve user://kayit.cfg'nin [oyun] bölümünü verilen dosyaya kopyalar.
##
##   godot --headless --path . --script res://tools/kayit_fikstur.gd -- --cikti <dosya.cfg>
##
## tests/veri/kayit-v0.5.cfg bu betikle v0.5 ETİKETİNDEN üretildi (git worktree ile
## eski sürüm açılıp betik oraya kopyalandı): yeni sürümün eski kaydı açabildiğini
## sınayan testler (tests/test_calistir.gd → _kayit_testleri, tests/test_oynanis.gd)
## elle yazılmış değil, o sürümün kendi yazdığı dosyayı okuyor. Yeni bir sürüm
## etiketi için aynı yol: worktree aç, betiği kopyala, --cikti ile üret.
extends SceneTree

func _initialize() -> void:
	_calis()

func _kare(n: int) -> void:
	for i in n:
		await physics_frame

func _calis() -> void:
	var cikti := "res://tests/veri/kayit-fikstur.cfg"
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--cikti" and i + 1 < args.size():
			cikti = args[i + 1]
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242})
	var sahne: Node = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(sahne)
	await process_frame
	await _kare(30)
	var arac: Node = sahne.get_node("Arac")
	var durum = sahne.durum
	# Sıradan bir oyunun ortası: birkaç geliştirme, iki eser, biraz para, 3 sefer.
	durum.matkap = 2
	durum.kasa = 1
	durum.para = 333
	durum.dinamit = 2
	durum.istasyon_kiti = 1
	durum.eserler = [0, 1]
	durum.sefer = 3
	Input.action_press("asagi")
	await _kare(900)
	Input.action_release("asagi")
	await _kare(10)
	arac.usse_don()
	await _kare(5)
	sahne.call("_kaydet")
	var cfg := ConfigFile.new()
	cfg.load(Kayit.YOL)
	var out := ConfigFile.new()
	for k in cfg.get_section_keys(Kayit.ANA):
		out.set_value(Kayit.ANA, k, cfg.get_value(Kayit.ANA, k))
	var yol := ProjectSettings.globalize_path(cikti) if cikti.begins_with("res://") else cikti
	DirAccess.make_dir_recursive_absolute(yol.get_base_dir())
	var e := out.save(yol)
	print("fikstür: %s (%s) — anahtarlar: %s" % [yol, error_string(e), str(out.get_section_keys(Kayit.ANA))])
	Kayit.sil()
	quit(0 if e == OK else 1)
