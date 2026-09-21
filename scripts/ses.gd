## Ses yöneticisi (autoload "Ses"). Muzik ve Efekt veri yolları üzerinden çalar.
## Efektler rFXGen ön ayarlarından üretildi; çeşitlilik perde (pitch) ile sağlanıyor —
## rFXGen --generate aynı ön ayar için hep aynı dalgayı veriyor (denendi), bu yüzden
## 7 ham dosya + perde eşlemesi 11 ayrı olayı karşılıyor. v0.7'de iki dosya daha
## kodla sentezlendi (tools/ses_uret.gd): matkap.wav (kazı DÖNGÜSÜ) ve deprem.wav
## (depreme özel gürültü — patlama sesinden ayrı).
##
## Döngü sesleri (v0.7): `dongu_baslat/dongu_durdur/dongu_caliyor`. Efekt kanallarından
## ayrı, olay başına tek oyuncu; başlat çalanı baştan almaz, durdur kısa sönümle keser.
## `gecmis` son 32 olayı tutar — sesi duyamıyoruz, testler "hangi ses çaldı"yı buradan okur.
##
## Müzik (v0.6): İKİ oyuncu var (_muzik_a / _muzik_b). `muzik_cal(ad, gecis)` gecis > 0
## verilirse yeni parça öteki oyuncuda başlar ve ikisi birden sesi çaprazlar
## (crossfade); süre bitince eski durur. Böylece derinlik bantları arasında
## (toprak → kaya → bazalt → çekirdek) kesinti yok. Bütün parçalar açılışta
## belleğe alınır (MUZIKLER): web'de ilk `load()` bant sınırında takılma yapmasın.
extends Node

const KLASOR := "res://assets/audio/"
const SESLER := 10   ## eşzamanlı efekt kanalı
const SESSIZ_DB := -40.0   ## crossfade'in başladığı/bittiği düzey

## Açılışta önyüklenen müzikler (ambiyans bantları + menü + bitiş).
const MUZIKLER := ["muzik_menu", "muzik", "muzik_derin", "muzik_bazalt", "muzik_cekirdek", "bitis"]

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
	"deprem": ["deprem", 1.0, -2.0],          ## depremin kendisi (v0.7, patlamadan ayrı dosya)
	"deprem_uyari": ["deprem", 1.45, -11.0],  ## uyarının başladığı an: aynı gürültü, tiz ve kısık
}

## Döngü sesleri: olay -> [dosya, perde, ses (dB)].
const DONGU := {
	"matkap": ["matkap", 1.0, -13.0],
}
const DONGU_SONUM := 0.12   ## döngü durunca sönüm (sn)

var _kanallar: Array[AudioStreamPlayer] = []
var _donguler := {}         ## olay -> AudioStreamPlayer
var _sonenler := {}         ## olay -> Tween (sönmekte olan döngü; dongu_caliyor false sayar)
var gecmis: Array[String] = []   ## son 32 olay (testler için)
var _sonraki := 0
var _muzik_a: AudioStreamPlayer
var _muzik_b: AudioStreamPlayer
var _muzik: AudioStreamPlayer     ## şu an "aktif" olan (yeni parça hep ötekine gider)
var _gecis: Tween
var _akis := {}
var _suanki_muzik := ""
var ayar := {}

func _ready() -> void:
	# Web'de gömülü yazı tipinde olmayan simgeler (₺ ← ↑ → ↓ ▲ ▶ ▼ ◀ ✔) kutu çıkıyordu.
	# Autoload olduğu için bir kez burada kurmak menü ve oyun sahnesini birden kapsar.
	Simgeler.kur()
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SESLER:
		var p := AudioStreamPlayer.new()
		p.bus = "Efekt"
		add_child(p)
		_kanallar.append(p)
	_muzik_a = _muzik_oyuncu()
	_muzik_b = _muzik_oyuncu()
	_muzik = _muzik_a
	for ad in MUZIKLER:
		_akis_al(ad)
	ayar = Kayit.ayar_yukle()
	ayarlari_uygula()

func _muzik_oyuncu() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Muzik"
	add_child(p)
	# Döngü noktası olmayan bir parça biterse başa sar (stop() bunu tetiklemez).
	p.finished.connect(func() -> void:
		if p == _muzik:
			p.play())
	return p

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
	_gec(olay)

func _gec(olay: String) -> void:
	gecmis.append(olay)
	if gecmis.size() > 32:
		gecmis.pop_front()

# --- döngü sesleri (v0.7) -------------------------------------------------

## Döngüyü başlatır; zaten çalıyorsa yalnız perdeyi günceller (baştan almaz).
## Sönmekteyse sönüm iptal edilir ve ses geri gelir — karo arası kesintide takırtı yok.
func dongu_baslat(olay: String, perde_carpan := 1.0) -> void:
	if not DONGU.has(olay) or not bool(ayar.get("efekt_acik", true)):
		return
	var e: Array = DONGU[olay]
	var p: AudioStreamPlayer = _donguler.get(olay)
	if p == null:
		var akis := _akis_al(String(e[0]))
		if akis == null:
			return
		if akis is AudioStreamWAV:
			akis.loop_mode = AudioStreamWAV.LOOP_FORWARD
			akis.loop_begin = 0
			akis.loop_end = int(akis.get_length() * float(akis.mix_rate))   ## 0 bırakma (v0.6 dersi)
		p = AudioStreamPlayer.new()
		p.bus = "Efekt"
		p.stream = akis
		add_child(p)
		_donguler[olay] = p
	if _sonenler.has(olay):
		var t: Tween = _sonenler[olay]
		if t != null and t.is_valid():
			t.kill()
		_sonenler.erase(olay)
	p.pitch_scale = clampf(float(e[1]) * perde_carpan, 0.05, 4.0)
	p.volume_db = float(e[2])
	if not p.playing:
		p.play()
		_gec(olay)

## Döngüyü kısa bir sönümle durdurur; dongu_caliyor hemen false döner.
func dongu_durdur(olay: String) -> void:
	var p: AudioStreamPlayer = _donguler.get(olay)
	if p == null or not p.playing or _sonenler.has(olay):
		return
	var t := create_tween()
	t.tween_property(p, "volume_db", SESSIZ_DB, DONGU_SONUM)
	t.tween_callback(p.stop)
	_sonenler[olay] = t

func dongu_caliyor(olay: String) -> bool:
	var p: AudioStreamPlayer = _donguler.get(olay)
	return p != null and p.playing and not _sonenler.has(olay)

## Müzik çalar. `gecis` > 0 ise çalan parçadan yenisine o kadar saniyede çaprazlar;
## 0 ise anında değişir (menü → bitiş jingle'ı gibi).
func muzik_cal(ad: String, gecis := 0.0) -> void:
	if _suanki_muzik == ad:
		return
	_suanki_muzik = ad
	var akis := _akis_al(ad)
	if akis == null:
		return
	if akis is AudioStreamWAV:
		akis.loop_mode = AudioStreamWAV.LOOP_FORWARD
		akis.loop_begin = 0
		# Döngü sonu AÇIKÇA son örnek: 0 bırakılınca (v0.5) parça 18 sn sonra
		# bitiyor ve `finished` ile yeniden başlatılıyordu — arada bir karelik
		# sessizlik ve crossfade'in "eski parça çalmıyor" sanıp sert geçiş yapması.
		akis.loop_end = int(akis.get_length() * float(akis.mix_rate))
	var acik := bool(ayar.get("muzik_acik", true))
	if _gecis != null and _gecis.is_valid():
		_gecis.kill()
	if gecis <= 0.0 or not _muzik.playing:
		_oteki().stop()
		_muzik.stream = akis
		_muzik.volume_db = 0.0
		if acik:
			_muzik.play()
		return
	# Crossfade: yeni parça öteki oyuncuda sessiz başlar, ikisi birlikte kayar.
	var eski := _muzik
	var yeni := _oteki()
	_muzik = yeni
	# Aynı parça hâlâ sönmekteyse (bant sınırında gidip gelme) baştan başlatma.
	if yeni.stream != akis or not yeni.playing:
		yeni.stream = akis
		yeni.volume_db = SESSIZ_DB
		if acik:
			yeni.play()
	_gecis = create_tween().set_parallel(true)
	_gecis.tween_property(yeni, "volume_db", 0.0, gecis)
	_gecis.tween_property(eski, "volume_db", SESSIZ_DB, gecis)
	_gecis.chain().tween_callback(eski.stop)

func _oteki() -> AudioStreamPlayer:
	return _muzik_b if _muzik == _muzik_a else _muzik_a

func muzik_durdur() -> void:
	_suanki_muzik = ""
	if _gecis != null and _gecis.is_valid():
		_gecis.kill()
	_muzik_a.stop()
	_muzik_b.stop()

## Çalan parçanın adı (testler ve HUD için).
func calan_muzik() -> String:
	return _suanki_muzik

## Şu an ses üreten müzik oyuncusu sayısı: crossfade sırasında 2, dışında 1 (ya da 0).
func calan_muzik_sayisi() -> int:
	return int(_muzik_a.playing) + int(_muzik_b.playing)

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
		_muzik_a.stop()
		_muzik_b.stop()
	elif _suanki_muzik != "" and not _muzik.playing:
		_muzik.volume_db = 0.0
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
