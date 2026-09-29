extends SceneTree
## Ölçüm aracı: oyun sahnesini gerçek render ile çalıştırır, kare süresini ölçer.
##   godot --path . -s res://tools/fps.gd -- <kare_sayisi> [derin_m]
## Vsync kapalı, 90 kare ısınma. Araç `derin_m` metreye ışınlanıp açık bir oda kazılır,
## sonra aşağı ve yana kazma girdisi verilir (tünel, parçacık, sis, HUD çalışsın).
## Sonuç: ortalama ms, %99 ms, FPS. docs/TASARIM.md'deki önce/sonra tablosu buradan.

func _initialize() -> void:
	var arg := OS.get_cmdline_user_args()
	var kare_n := int(arg[0]) if arg.size() > 0 else 600
	var derin := int(arg[1]) if arg.size() > 1 else 60
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242})
	var sahne: Node = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(sahne)
	_kos.call_deferred(sahne, kare_n, derin)


func _kos(sahne: Node, kare_n: int, derin: int) -> void:
	await process_frame
	var arac: Arac = sahne.get_node("Arac")
	var dunya: Dunya = sahne.get_node("Dunya")
	sahne.durum.yakit = 99999.0
	sahne.durum.matkap = 4
	var h := Vector2i(Ayarlar.US_KARO_X, derin)
	for dy in range(-3, 4):
		for dx in range(-5, 6):
			dunya.karo_kir(h + Vector2i(dx, dy))
	arac.isinlan(dunya.hucre_merkezi(h))
	var sureler: Array[float] = []
	var son := Time.get_ticks_usec()
	var i := 0
	while i < kare_n + 90:
		await process_frame
		var s := Time.get_ticks_usec()
		if i >= 90:
			sureler.append(float(s - son) / 1000.0)
		son = s
		if i % 120 == 0:
			Input.action_press("asagi")
			Input.action_release("sag")
		elif i % 120 == 60:
			Input.action_release("asagi")
			Input.action_press("sag")
		i += 1
	Input.action_release("asagi")
	Input.action_release("sag")
	sureler.sort()
	var top := 0.0
	for x in sureler:
		top += x
	var ort := top / float(sureler.size())
	var p99 := sureler[int(sureler.size() * 0.99)]
	print("FPS_OLCUM derinlik=%d kare=%d ort_ms=%.2f p99_ms=%.2f fps=%.1f renderer=%s" % [
		derin, sureler.size(), ort, p99, 1000.0 / ort, RenderingServer.get_video_adapter_name()])
	sahne.queue_free()
	quit(0)
