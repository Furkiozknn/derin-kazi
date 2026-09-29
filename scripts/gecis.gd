extends CanvasLayer
## Sahne gecisi (autoload "Gecis"): tam ekran renk bandi soldan girer (~260 ms),
## sahne degisir, bant saga cikar (~200 ms). Stil rehberi: amber bant.
## Olumde sahne degismez: ekran kisa bir tehlike rengi flasiyla yanip soner.
## Duraklatma sirasinda da calisir (PROCESS_MODE_ALWAYS).

const ORTME := 0.26
const ACMA := 0.20
const GENISLIK := 660.0
const FLAS := 0.30

var _bant: ColorRect
var _flas: ColorRect
var _mesgul := false
var _ipucu: Label
var _dikey_kart: Panel
var _ipucu_sayac := 0.0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bant = ColorRect.new()
	_bant.color = Tema.AMBER
	_bant.size = Vector2(GENISLIK, 380.0)
	_bant.position = Vector2(-GENISLIK, -10.0)
	_bant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bant.visible = false
	add_child(_bant)
	_flas = ColorRect.new()
	_flas.color = Color(Tema.TEHLIKE, 0.0)
	_flas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flas)
	# Dikey telefon: oyun 16:9'a kilitli, yatay tutmak gerekir. Pencere dikeye
	# donunce 4 sn'lik bir ipucu cikar.
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


## Sahneyi bantla degistirir. Bant sirasinda ikinci cagri yok sayilir (cift tik).
func git(yol: String, renk: Color = Tema.AMBER) -> void:
	if _mesgul:
		return
	_mesgul = true
	await kapat(renk)
	get_tree().change_scene_to_file(yol)
	await get_tree().process_frame
	await get_tree().process_frame
	await ac()
	_mesgul = false


## Bant ekrani soldan ORTER (260 ms, ease-out). tools/rota.gd kayit kipi de bunu
## sahne degistirmeden kullanir.
func kapat(renk: Color = Tema.AMBER) -> void:
	_bant.color = renk
	_bant.position.x = -GENISLIK
	_bant.visible = true
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_bant, "position:x", -10.0, ORTME)
	await t.finished


## Bandi beklemeden ORTULU baslatir (tools/kayit.gd: klip bir gecisle acilsin).
func kapat_hemen(renk: Color = Tema.AMBER) -> void:
	_bant.color = renk
	_bant.position.x = -10.0
	_bant.visible = true


## Bant saga cikip ekrani ACAR (200 ms, ease-in).
func ac() -> void:
	var t := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_bant, "position:x", GENISLIK, ACMA)
	await t.finished
	_bant.visible = false


## Sahne degistirmeden kisa flas (olum, bolum basa alma). Girdiyi kilitlemez.
func yanip_son() -> void:
	_flas.color = Color(Tema.TEHLIKE, 0.34)
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_flas, "color:a", 0.0, FLAS)


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
