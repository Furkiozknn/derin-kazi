## Ham oynanış kaydı sürücüsü (sosyal medya klibi): yazısız, sessiz. tools/kayit.ps1 çalıştırır:
##   godot --path . --write-movie <kare.png> --fixed-fps 60 --scene res://tools/kayit.tscn
##
## Gerçek oyun sahnesi oynanır; araç "insan bandında" sürülür: karar her 0,14-0,30 sn'de bir
## verilir (tepki gecikmesi), yakındaki madene yanal sapar, gaz/lav/kazılamaz kayayı gördüğünde
## yön değiştirir, ara sıra yanlış yöne basar. Ortada bir ölüm (can 0 → yüzeye çekilme, tehlike
## flaşı) bilerek tetiklenir; klip gerçek bir sahne geçişiyle (Gecis renk bandı) açılır.
## Arayüz katmanı ve uçan yazılar gizli. BU BİR BOT KAYDIDIR: insan hissinin kanıtı değil.
extends Node

const SURE := 19.0          ## saniye (oyun zamanı; --fixed-fps ile kare = 1/fps)
const OLUM_ZAMANI := 11.0   ## sn: bu anda can 0'a iner (yüzeye çekilme + flaş)
const HEDEF_DERIN := 62

var _sahne: Node
var _arac: Arac
var _dunya: Dunya
var _durum: Durum
var _zaman := 0.0
var _karar := 0.0
var _yon := 0               ## -1 sol, 0 yok, 1 sağ
var _asagi := false
var _olum_oldu := false
var _uyari_kapandi := false
var _rng := RandomNumberGenerator.new()
var _bitti := false

func _ready() -> void:
	_rng.seed = 20260929
	Ses.ayar["muzik_acik"] = false
	Ses.ayar["efekt_acik"] = false
	Ses.ayarlari_uygula()
	Kayit.sil()
	# Gelişmiş bir kayıt: matkap Sv3 (kazı hızlı, klipte hareket bol), geniş kasa, bol yakıt.
	Kayit.kaydet({"tohum": 4242, "matkap": 4, "depo": 3, "kasa": 3, "govde": 2, "para": 400})
	Gecis.kapat_hemen(Tema.AMBER)   ## klip renk bandıyla açılır (bant zaten örtülü başlar)
	_sahne = load("res://scenes/oyun.tscn").instantiate()
	add_child(_sahne)
	await get_tree().process_frame
	_sahne.get_node("HUD").visible = false
	_sahne.yazi_gizli = true
	_arac = _sahne.get_node("Arac")
	_dunya = _sahne.get_node("Dunya")
	_durum = _sahne.durum
	_durum.yakit = _durum.yakit_kapasitesi()
	await get_tree().create_timer(0.35).timeout
	Gecis.ac()

func _physics_process(delta: float) -> void:
	if _arac == null or _bitti:
		return
	_zaman += delta
	if _zaman >= SURE:
		_bitti = true
		_birak()
		print("KAYIT SURUCU BITTI: %.1f sn, en derin %d m, olum %s" % [_zaman, _durum.en_derin, str(_olum_oldu)])
		get_tree().quit(0)
		return
	if _olum_oldu and not _uyari_kapandi and _zaman >= OLUM_ZAMANI + 0.9:
		_uyari_kapandi = true
		_sahne.call("_uyari_kapat")   ## "yüzeye çekildin" paneli (HUD gizli, ama araç kilitli kalmasın)
	if not _olum_oldu and _zaman >= OLUM_ZAMANI:
		_olum_oldu = true
		_arac._dokunulmaz = 0.0
		_arac.hasar(99, _arac.global_position)   ## can → 0: oyun kendi yüzeye çekilme akışını çalıştırır
		_birak()
		return
	_durum.yakit = maxf(_durum.yakit, 30.0)
	_karar -= delta
	if _karar <= 0.0:
		_karar = _rng.randf_range(0.14, 0.30)   ## insan tepki bandı
		_dusun()
	Input.action_release("sol")
	Input.action_release("sag")
	if _yon < 0:
		Input.action_press("sol")
	elif _yon > 0:
		Input.action_press("sag")
	if _asagi:
		Input.action_press("asagi")
	else:
		Input.action_release("asagi")

func _birak() -> void:
	for e in ["sol", "sag", "asagi", "yukari"]:
		Input.action_release(e)
	_yon = 0
	_asagi = false

func _tehlikeli(t: int) -> bool:
	return t == Ayarlar.GAZ or t == Ayarlar.LAV or t == Ayarlar.GEVSEK or t == Ayarlar.KAYA

func _kazilir(h: Vector2i) -> bool:
	var t := _dunya.karo_tur(h)
	return t != Ayarlar.BOS and _dunya.kazilabilir_mi(t) and not _tehlikeli(t) \
		and _durum.matkap_yeterli_mi(h.y)

func _dusun() -> void:
	var m := _arac.hucre()
	# Yüzeydeyken önce şafta yürü: birkaç karo sağa, sonra kaz.
	if m.y < 1 and _zaman < 1.4:
		_yon = 1 if _zaman > 0.5 else 0
		_asagi = false
		return
	# Yakın maden (aynı sıra, ±4 karo): yana kaz.
	var en_yakin := 99
	var yon_maden := 0
	for dx in range(-2, 3):
		if dx == 0:
			continue
		var t := _dunya.karo_tur(m + Vector2i(dx, 0))
		if Ayarlar.MADEN_DEGER.has(t) and absi(dx) < en_yakin and _kazilir(m + Vector2i(signi(dx), 0)):
			en_yakin = absi(dx)
			yon_maden = signi(dx)
	if yon_maden != 0 and _rng.randf() < 0.35 and m.y < HEDEF_DERIN:
		_yon = yon_maden
		_asagi = false
		return
	# Altı tehlikeliyse ya da kazılamazsa yan tarafa sap.
	var alt := m + Vector2i.DOWN
	if not _kazilir(alt) and _dunya.karo_tur(alt) != Ayarlar.BOS:
		var sol_ok := _kazilir(m + Vector2i.LEFT)
		var sag_ok := _kazilir(m + Vector2i.RIGHT)
		_yon = -1 if (sol_ok and (not sag_ok or _rng.randf() < 0.5)) else (1 if sag_ok else 0)
		_asagi = false
		return
	# Ara sıra (yüzde 8) yanlış yöne bas: insan hatası.
	if _rng.randf() < 0.08:
		_yon = -1 if _rng.randf() < 0.5 else 1
		_asagi = false
		return
	_yon = 0
	_asagi = m.y < HEDEF_DERIN

func signi(x: int) -> int:
	return 1 if x > 0 else -1
