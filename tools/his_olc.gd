## Oyun hissi ölçümü (v0.8). Gerçek sahne, gerçek zaman, PENCERELİ (headless'ta
## Input.parse_input_event çalışmaz):
##   godot --path . --script res://tools/his_olc.gd -- [deneme]
## Üç şey ölçülür ve docs/TASARIM.md'ye yazılır:
##  1. Girdi gecikmesi: tuş olayı → ilk tepki (matkap sinyali, yürüyüş, pervane), ms.
##  2. Kazma sürekliliği: A basılı tutulurken karo başına süre ve boşlukta (havada) kalan pay.
##  3. Dinamit tamponu: F, inişten ne kadar ÖNCE basılırsa da atılıyor mu (kojot + tampon).
## Bot bunu ölçemez (bot Arac'ı sürmüyor); sayılar insan gözüne yakın bir gösterge, yargı değil.
extends SceneTree

var _sahne: Node
var _arac: Arac
var _durum: Durum
var _dunya: Dunya
var _t0 := 0
var _bekle := ""
var _kaz_ms: Array[float] = []

func _initialize() -> void:
	_kos.call_deferred()

func _olay(eylem: StringName, basildi: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = eylem
	ev.pressed = basildi
	Input.parse_input_event(ev)

func _kare(n: int) -> void:
	for i in n:
		await physics_frame

func _kur() -> void:
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242})
	_sahne = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(_sahne)
	await process_frame
	await _kare(40)
	_arac = _sahne.get_node("Arac")
	_dunya = _sahne.get_node("Dunya")
	_durum = _sahne.durum
	_durum.dinamit = 99
	_durum.yakit = 9999.0

func _yerlestir() -> void:
	_arac.usse_don()
	_arac.velocity = Vector2.ZERO

func _ort(a: Array) -> float:
	var t := 0.0
	for x in a:
		t += float(x)
	return t / maxf(1.0, float(a.size()))

func _yuzde95(a: Array) -> float:
	var b := a.duplicate()
	b.sort()
	return float(b[int(b.size() * 0.95)]) if b.size() > 0 else 0.0

func _kos() -> void:
	var n := 40
	var arg := OS.get_cmdline_user_args()
	if arg.size() > 0:
		n = int(arg[0])
	if arg.has("agile"):
		Input.use_accumulated_input = false
	await _kur()
	print("HIS_OLCUM renderer=%s deneme=%d" % [RenderingServer.get_video_adapter_name(), n])

	# 1. girdi gecikmesi --------------------------------------------------
	var yuru_ms: Array[float] = []
	var ucus_ms: Array[float] = []
	_arac.kazma_degisti.connect(func(k: bool) -> void:
		if _bekle == "kaz" and k and _t0 > 0:
			_kaz_ms.append(float(Time.get_ticks_usec() - _t0) / 1000.0)
			_t0 = 0)
	for i in n:
		# kazma: yerdeyken A'ya bas, matkap sinyaline kadar
		_yerlestir()
		await _kare(30)
		_olay(&"asagi", false)
		await create_timer(0.1 + randf() * 0.0167).timeout   # rastgele fizik fazı
		_bekle = "kaz"
		_t0 = Time.get_ticks_usec()
		_olay(&"asagi", true)
		var tavan := Time.get_ticks_usec() + 400000
		while _t0 > 0 and Time.get_ticks_usec() < tavan:
			await process_frame
		_olay(&"asagi", false)
		_bekle = ""
		_t0 = 0
		# yürüyüş
		_yerlestir()
		await _kare(30)
		await create_timer(randf() * 0.0167).timeout
		var y0 := Time.get_ticks_usec()
		_olay(&"sag", true)
		var y_tavan := y0 + 400000
		while absf(_arac.velocity.x) < 1.0 and Time.get_ticks_usec() < y_tavan:
			await physics_frame
		yuru_ms.append(float(Time.get_ticks_usec() - y0) / 1000.0)
		_olay(&"sag", false)
		# pervane
		_yerlestir()
		await _kare(30)
		await create_timer(randf() * 0.0167).timeout
		var u0 := Time.get_ticks_usec()
		_olay(&"yukari", true)
		var u_tavan := u0 + 400000
		while _arac.velocity.y > -1.0 and Time.get_ticks_usec() < u_tavan:
			await physics_frame
		ucus_ms.append(float(Time.get_ticks_usec() - u0) / 1000.0)
		_olay(&"yukari", false)
	print("HIS_GECIKME kazma_ort=%.1f kazma_p95=%.1f yuruyus_ort=%.1f yuruyus_p95=%.1f pervane_ort=%.1f pervane_p95=%.1f ms (n=%d/%d/%d)" % [
		_ort(_kaz_ms), _yuzde95(_kaz_ms), _ort(yuru_ms), _yuzde95(yuru_ms), _ort(ucus_ms), _yuzde95(ucus_ms),
		_kaz_ms.size(), yuru_ms.size(), ucus_ms.size()])

	# 2. kazma sürekliliği: 12 sn aşağı basılı --------------------------------
	_yerlestir()
	_durum.matkap = 4
	await _kare(30)
	_olay(&"asagi", true)
	var kare := 0
	var kazan := 0
	var havada := 0
	var d0 := _arac.derinlik()
	var t_bas := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t_bas < 12000000:
		await physics_frame
		kare += 1
		if not _arac.is_on_floor():
			havada += 1
		if _arac.kaziyor_mu():
			kazan += 1
	_olay(&"asagi", false)
	var d1 := _arac.derinlik()
	var sn := float(Time.get_ticks_usec() - t_bas) / 1e6
	print("HIS_KAZMA sure=%.1f sn derinlik=%d m havada_pay=%.0f%% kazma_pay=%.0f%% karo_basina=%.2f sn" % [
		sn, d1 - d0, 100.0 * float(havada) / float(kare), 100.0 * float(kazan) / float(kare),
		sn / maxf(1.0, float(d1 - d0))])

	# 2b. kazı hizalama: gövde deliğin ortasından `d` px kaymışken aşağı kazmaya başlar. 12 px'lik
	# gövde 16 px'lik deliğe ±2 px'ten fazla kaymışsa kenarı komşu karoda asılı kalabiliyor.
	_sahne.queue_free()
	await process_frame
	await _kur()
	_durum.matkap = 4
	var hiz_say := {}
	var basari := 0
	var top := 0
	for k in range(-5, 6):
		var kolon := 4 + (k + 5) * 3
		var x := float(kolon) * Ayarlar.KARO + Ayarlar.KARO * 0.5 + float(k)
		_arac.global_position = Vector2(x, -40.0)
		_arac.velocity = Vector2.ZERO
		await _kare(40)
		_olay(&"asagi", true)
		await create_timer(1.6).timeout
		_olay(&"asagi", false)
		var indi := _arac.global_position.y > 12.0
		hiz_say[k] = "1" if indi else "0"
		top += 1
		if indi:
			basari += 1
	print("HIS_HIZALAMA kayma_px->deliğe düştü(1)/asıldı(0) %s  toplam %d/%d  KAZI_HIZALAMA=%.1f" % [str(hiz_say), basari, top, Arac.KAZI_HIZALAMA])

	# 3. dinamit tamponu: inişten önce F -----------------------------------
	# Önce aynı düşüşün süresi ölçülür (2 kare sonra başlayıp zemine oturana dek); sonra F,
	# inişten `on_ms` önce basılır. Her koşulda sahne yeniden kurulur ve her deneme başka
	# bir sütuna düşer (patlama zemini oyuyor; oyulmuş zemine düşmek süreyi bozar).
	var say := {}
	var t_dus := 0.0
	for on_ms in [0, 40, 80, 120, 160, 240]:
		_sahne.queue_free()
		await process_frame
		await _kur()
		var atilan := 0
		var toplam := 8
		for i in toplam:
			var x := 96.0 + float(i) * 48.0
			_arac.global_position = Vector2(x, -60.0)
			_arac.velocity = Vector2.ZERO
			await _kare(2)
			if t_dus == 0.0:
				var d_t0 := Time.get_ticks_usec()
				while not _arac.is_on_floor() and Time.get_ticks_usec() - d_t0 < 2000000:
					await physics_frame
				t_dus = float(Time.get_ticks_usec() - d_t0) / 1e6
				_arac.global_position = Vector2(x, -60.0)
				_arac.velocity = Vector2.ZERO
				await _kare(2)
			var ilk := _durum.dinamit
			await create_timer(maxf(0.0, t_dus - float(on_ms) / 1000.0)).timeout
			_olay(&"dinamit", true)
			_olay(&"dinamit", false)
			await create_timer(0.5).timeout
			if _durum.dinamit < ilk:
				atilan += 1
		say[on_ms] = "%d/%d" % [atilan, toplam]
	print("HIS_DINAMIT_TAMPON dusus=%.2f sn (inisten kac ms once basildi -> atildi) %s" % [t_dus, str(say)])
	quit(0)
