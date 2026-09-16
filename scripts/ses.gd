## Ses yöneticisi (autoload "Ses"). Muzik ve Efekt veri yolları üzerinden çalar.
## Efektler rFXGen ön ayarlarından üretildi; çeşitlilik perde (pitch) ile sağlanıyor —
## rFXGen --generate aynı ön ayar için hep aynı dalgayı veriyor (denendi), bu yüzden
## 7 ham dosya + perde eşlemesi 11 ayrı olayı karşılıyor. Bkz. tools/sesler.md
extends Node

const KLASOR := "res://assets/audio/"
const SESLER := 10   ## eşzamanlı efekt kanalı

## olay -> [dosya, perde, ses (dB)]
const EFEKT := {
	"kaz": ["hit", 1.7, -14.0],
	"maden": ["coin", 1.0, -6.0],
	"sat": ["powerup", 1.0, -6.0],
	"gelistir": ["powerup", 0.75, -4.0],
	"patlama": ["explosion", 1.0, -4.0],
	"hasar": ["hit", 0.55, -3.0],
	"menu": ["blip", 1.0, -10.0],
	"isinlan": ["laser", 0.8, -6.0],
	"sandik": ["powerup", 1.35, -5.0],
	"uyari": ["blip", 0.6, -6.0],
	"pervane": ["jump", 1.2, -18.0],
}

var _kanallar: Array[AudioStreamPlayer] = []
var _sonraki := 0
var _muzik: AudioStreamPlayer
var _akis := {}
var _suanki_muzik := ""
var ayar := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SESLER:
		var p := AudioStreamPlayer.new()
		p.bus = "Efekt"
		add_child(p)
		_kanallar.append(p)
	_muzik = AudioStreamPlayer.new()
	_muzik.bus = "Muzik"
	add_child(_muzik)
	_muzik.finished.connect(func(): _muzik.play())
	ayar = Kayit.ayar_yukle()
	ayarlari_uygula()

func _akis_al(ad: String) -> AudioStream:
	if not _akis.has(ad):
		var yol := KLASOR + ad + ".wav"
		_akis[ad] = load(yol) if ResourceLoader.exists(yol) else null
	return _akis[ad]

## Efekt çalar. perde_carpan kazı zincirinde sesi tizleştirmek için kullanılır.
func cal(olay: String, perde_carpan := 1.0) -> void:
	if not bool(ayar.get("efekt_acik", true)) or not EFEKT.has(olay):
		return
	var e: Array = EFEKT[olay]
	var akis := _akis_al(String(e[0]))
	if akis == null:
		return
	var p := _kanallar[_sonraki]
	_sonraki = (_sonraki + 1) % _kanallar.size()
	p.stream = akis
	p.pitch_scale = clampf(float(e[1]) * perde_carpan, 0.05, 4.0)
	p.volume_db = float(e[2])
	p.play()

func muzik_cal(ad: String) -> void:
	if _suanki_muzik == ad and _muzik.playing:
		return
	_suanki_muzik = ad
	var akis := _akis_al(ad)
	if akis == null:
		return
	if akis is AudioStreamWAV:
		akis.loop_mode = AudioStreamWAV.LOOP_FORWARD
		akis.loop_begin = 0
		akis.loop_end = 0
	_muzik.stream = akis
	if bool(ayar.get("muzik_acik", true)):
		_muzik.play()

func muzik_durdur() -> void:
	_suanki_muzik = ""
	_muzik.stop()

# --- ayarlar --------------------------------------------------------------

static func _db(oran: float) -> float:
	return -80.0 if oran <= 0.001 else linear_to_db(clampf(oran, 0.0, 1.0))

func ayarlari_uygula() -> void:
	for ad in ["Muzik", "Efekt"]:
		var i := AudioServer.get_bus_index(ad)
		if i < 0:
			continue
		var anahtar := "muzik_ses" if ad == "Muzik" else "efekt_ses"
		var acik := bool(ayar.get("muzik_acik" if ad == "Muzik" else "efekt_acik", true))
		AudioServer.set_bus_volume_db(i, _db(float(ayar.get(anahtar, 0.8))))
		AudioServer.set_bus_mute(i, not acik)
	if not bool(ayar.get("muzik_acik", true)):
		_muzik.stop()
	elif _suanki_muzik != "" and not _muzik.playing:
		_muzik.play()
	if not OS.has_feature("web"):
		var mod := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(ayar.get("tam_ekran", false)) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mod:
			DisplayServer.window_set_mode(mod)

func ayarla(anahtar: String, deger) -> void:
	ayar[anahtar] = deger
	ayarlari_uygula()
	Kayit.ayar_kaydet(ayar)

func sarsinti_acik() -> bool:
	return bool(ayar.get("sarsinti", true))
