extends SceneTree
## Ölçüm aracı: oyun sahnesini gerçek render ile çalıştırır, kare süresini ölçer.
##   godot --path . -s res://tools/fps.gd -- <kare_sayisi> [derin_m] [gecis]
## "gecis" verilirse 0,7 sn arayla sirayla sekiz gecis ailesi (Gecis autoload) oynatilir;
## kaplama gorunurken olculen kareler ayri satirda basilir (FPS_GECIS).
## Vsync kapalı, 90 kare ısınma. Araç `derin_m` metreye ışınlanıp açık bir oda kazılır,
## sonra aşağı ve yana kazma girdisi verilir (tünel, parçacık, sis, HUD çalışsın).
## Sonuç: ortalama ms, %99 ms, FPS. docs/TASARIM.md'deki önce/sonra tablosu buradan.

const TURLER: Array = [&"iris", &"glitch", &"bloklar", &"itme", &"perde", &"flas", &"kararma", &"zoom"]


func _initialize() -> void:
	var arg := OS.get_cmdline_user_args()
	var kare_n := int(arg[0]) if arg.size() > 0 else 600
	var derin := int(arg[1]) if arg.size() > 1 else 60
	var gecis_ac: bool = arg.size() > 2 and arg[2] == "gecis"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242})
	var sahne: Node = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(sahne)
	_kos.call_deferred(sahne, kare_n, derin, gecis_ac)


func _kos(sahne: Node, kare_n: int, derin: int, gecis_ac: bool) -> void:
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
	var g: Node = root.get_node("Gecis")
	var gecis_sureler: Array[float] = []
	var k := 0
	var son := Time.get_ticks_usec()
	var i := 0
	while i < kare_n + 90:
		await process_frame
		var s := Time.get_ticks_usec()
		if i >= 90:
			if gecis_ac and g.get("_kaplama").visible:
				gecis_sureler.append(float(s - son) / 1000.0)
			else:
				sureler.append(float(s - son) / 1000.0)
		if gecis_ac and i >= 90 and (i - 90) % 42 == 21 and not g.get("_kaplama").visible:
			g.call("acilis", TURLER[k % TURLER.size()], k % 2, 0.46, 1.0)   # ortu tam kapali baslar, acilir
			k += 1
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
	if gecis_ac and not gecis_sureler.is_empty():
		gecis_sureler.sort()
		var gt := 0.0
		for x in gecis_sureler:
			gt += x
		var gort := gt / float(gecis_sureler.size())
		print("FPS_GECIS kare=%d ort_ms=%.2f p99_ms=%.2f en_kotu_ms=%.2f fps=%.1f gecis_sayisi=%d" % [
			gecis_sureler.size(), gort, gecis_sureler[int(gecis_sureler.size() * 0.99)], gecis_sureler[-1], 1000.0 / gort, k])
	sahne.queue_free()
	quit(0)
