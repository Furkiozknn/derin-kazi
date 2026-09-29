extends CanvasLayer
## Sahne geçişi (autoload "Gecis"). Günlük videolardaki geçiş aileleri ekran-uzayı
## shader'ı ile (assets/gecis.gdshader): iris, glitch, bloklar, itme, perde, flaş,
## kararma, zoom. Örtme ~260 ms, açma ~200 ms (stil rehberi). Renkler derinlik
## temasının video akış paletinden (Tema.AKIS) sırayla döner; tür, temanın havuzundan
## art arda tekrarlanmadan seçilir. Bant sırasında ikinci çağrı yok sayılır.
## Hareket azaltma ("Sade geçişler" ayarı ya da tarayıcıda prefers-reduced-motion)
## açıkken geçiş ANINDA: efekt yok, bekleme yok. Duraklatma sırasında da çalışır.

const ORTME := 0.26
const ACMA := 0.20
const SHADER := preload("res://assets/gecis.gdshader")

var son_tur: StringName = &""        ## test/ölçüm için: en son kullanılan aile
var acilis_yapildi: bool = false     ## menü açılış iris'i yalnız ilk açılışta
var _kaplama: ColorRect
var _mat: ShaderMaterial
var _mesgul := false
var _ipucu: Label
var _dikey_kart: Panel
var _ipucu_sayac := 0.0
var _tween: Tween = null
var _sayac := 0                      ## renk akışı sırası
var _sistem_azalt := false           ## tarayıcı "hareketi azalt" istiyor


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_kaplama = ColorRect.new()
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_kaplama.material = _mat
	_kaplama.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kaplama.visible = false
	add_child(_kaplama)
	_kaplama.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if OS.has_feature("web"):
		_sistem_azalt = bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	# Dikey telefon: oyun 16:9'a kilitli, yatay tutmak gerekir. Pencere dikeye
	# dönünce 4 sn'lik bir ipucu çıkar.
	_dikey_kart = Panel.new()
	_dikey_kart.theme_type_variation = &"Kagit"
	_dikey_kart.position = Vector2(40.0, 110.0)
	_dikey_kart.size = Vector2(560.0, 140.0)
	_dikey_kart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dikey_kart.visible = false
	add_child(_dikey_kart)
	_ipucu = Label.new()
	_ipucu.theme_type_variation = &"KartBaslik"
	_ipucu.add_theme_font_size_override("font_size", 24)
	_ipucu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ipucu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ipucu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ipucu.position = Vector2(20.0, 10.0)
	_ipucu.size = Vector2(520.0, 120.0)
	_ipucu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dikey_kart.add_child(_ipucu)
	get_tree().root.size_changed.connect(_boyut_degisti)
	_boyut_degisti.call_deferred()


func mesgul_mu() -> bool:
	return _mesgul


## Hareket azaltma: ayar açıksa ya da tarayıcı istiyorsa geçiş anındadır.
func sade() -> bool:
	return bool(Ses.ayar.get("sade_gecis", false)) or _sistem_azalt


## Temanın havuzundan sonraki geçiş ailesi (video: gecisHavuz); bir öncekini tekrarlamaz.
func sec(tema: int) -> StringName:
	var havuz: Array = Tema.AKIS[clampi(tema, 0, Tema.AKIS.size() - 1)]["gecis"]
	return havuz[(havuz.find(son_tur) + 1) % havuz.size()]    # havuzu sırayla gezer: tekrar yok, hepsi kullanılır


## Örtme öncesi: shader'ı bu geçişin tür ve renkleriyle kurar. Kaplama açma (ac)
## çağrılana kadar aynı renkte durur. `renk` (alfa > 0) akış rengini ezer (çekilme kırmızısı).
func _kur(tur: StringName, tema: int, renk: Color = Color(0, 0, 0, 0)) -> void:
	if tur == &"":
		tur = sec(tema)
	son_tur = tur
	var a: Dictionary = Tema.AKIS[clampi(tema, 0, Tema.AKIS.size() - 1)]
	var r1: Color = Tema.akis_rengi(tema, _sayac)
	var r2: Color = Tema.akis_rengi(tema, _sayac + 2)
	if tur == &"flas":
		r1 = a["acik"]
	elif tur == &"kararma":
		r1 = a["koyu"]
	if renk.a > 0.0:
		r1 = renk
	_sayac += 1
	_mat.set_shader_parameter("tur", maxi(Tema.GECIS_TURLERI.find(tur), 0))
	_mat.set_shader_parameter("renk", r1)
	_mat.set_shader_parameter("renk2", r2)
	_mat.set_shader_parameter("p", 0.0)


func _p_yaz(v: float) -> void:
	_mat.set_shader_parameter("p", v)
	_mat.set_shader_parameter("adim", floorf(Time.get_ticks_msec() / 33.0))


## Ekranı örter (await edilebilir). Sade kipte hiçbir şey yapmaz ve bekletmez.
func kapat(tur: StringName = &"", tema: int = 0, sure: float = ORTME) -> void:
	if sade():
		return
	_kur(tur, tema)
	_kaplama.visible = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(_p_yaz, 0.0, 1.0, sure)
	await _tween.finished


## Örtüyü açar; bekletmek istemeyen çağıran await etmez (oyun akışı sürer).
func ac(sure: float = ACMA, baslangic: float = 1.0) -> void:
	if not _kaplama.visible:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(_p_yaz, baslangic, 0.0, sure)
	await _tween.finished
	_kaplama.visible = false


## Kapalı başla, aç: menü açılışı, duraklatma perdesi, oyun sonu gibi "içerik açılır" anları.
func acilis(tur: StringName = &"iris", tema: int = 0, sure: float = ACMA + 0.1, baslangic: float = 1.0) -> void:
	if sade():
		return
	_kur(tur, tema)
	_kaplama.visible = true
	_p_yaz(baslangic)
	await ac(sure, baslangic)


## Bekletmeyen tek vuruş: kaplama `tepe` örtmeyle belirir, `sure`de söner. Oyun akışını ve
## girdiyi kilitlemez; başka bir geçiş sürüyorsa hiçbir şey yapmaz. `renk` (alfa > 0) akış rengini ezer.
func vurus(tur: StringName, tema: int, tepe: float = 0.5, sure: float = 0.3, renk: Color = Color(0, 0, 0, 0)) -> void:
	if sade() or _mesgul or _kaplama.visible:
		return
	_kur(tur, tema, renk)
	_kaplama.visible = true
	_p_yaz(tepe)
	await ac(sure, tepe)


## Yüzeye çekilme: tehlike rengiyle kısa flaş (eski API; artık shader'ın flaş ailesi).
func yanip_son() -> void:
	await vurus(&"flas", 1, 0.34, 0.30, Tema.TEHLIKE)


## Klip başlangıcı gibi "zaten örtülü başla" durumları (tools/kayit.gd): sonra ac() çağrılır.
func kapat_hemen(tur: StringName = &"itme", tema: int = 0) -> void:
	_kur(tur, tema)
	_kaplama.visible = true
	_p_yaz(1.0)


## Yerinde geçiş: ört, `degistir`i çağır (metin/sahne değişimi), aç.
func ara(tur: StringName, tema: int, degistir: Callable) -> void:
	if _mesgul:
		degistir.call()    # başka bir geçiş sürüyor: değişiklik kaybolmasın, efekt yok
		return
	_mesgul = true
	await kapat(tur, tema, ORTME * 0.7)
	degistir.call()
	if not sade():
		await get_tree().process_frame
		await get_tree().process_frame
	await ac(ACMA)
	_mesgul = false


## Sahneyi değiştirir. Bant sırasında ikinci çağrı yok sayılır (çift tık).
func git(yol: String, tema: int = 0, tur: StringName = &"") -> void:
	if _mesgul:
		return
	_mesgul = true
	if sade():
		get_tree().change_scene_to_file(yol)
		_mesgul = false
		return
	await kapat(tur, tema)
	get_tree().change_scene_to_file(yol)
	await get_tree().process_frame
	await get_tree().process_frame
	await ac(ACMA)
	_mesgul = false


## Pencere dikeyse (telefon) "yatay tut" ipucu; yataya donunce kaybolur.
func _boyut_degisti() -> void:
	var boyut := get_tree().root.size
	var dikey: bool = boyut.y > boyut.x
	_ipucu.text = tr("Cihazını yatay çevir")
	_dikey_kart.visible = dikey
	_ipucu_sayac = 4.0 if dikey else 0.0


func _process(delta: float) -> void:
	if _ipucu_sayac > 0.0:
		_ipucu_sayac -= delta
		if _ipucu_sayac <= 0.0:
			_dikey_kart.visible = false
