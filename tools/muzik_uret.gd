extends SceneTree
## Basit chiptune üretici (döngü müziği ve kısa jingle). Harici araç gerekmez.
##
## Kullanım (proje kökünde, bu dosyayı tools/ altına kopyaladıktan sonra):
##   godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik.wav --ruh hizli --tohum 3
##   godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/bitis.wav --tur jingle --ruh neseli
##
## Seçenekler:
##   --cikti <yol>        res:// ya da mutlak yol (.wav)
##   --tur dongu|jingle   dongu: 8 ölçü, döngü noktalı; jingle: 2 ölçü, döngüsüz (varsayılan dongu)
##   --ruh hizli|sakin|gizemli|neseli|gergin   (varsayılan hizli)
##   --tohum <sayi>       aynı tohum = aynı parça (varsayılan 1)
##   --bpm <sayi>         ruhun temposunu ezer
##   --olcu <sayi>        döngü uzunluğu (ölçü), varsayılan 8
##
## Çıktı: 22050 Hz, 16 bit, mono WAV. Döngü parçasında loop noktaları yazılır; Godot'ta
## içe aktarma ayarında "Loop Mode: Forward" seçili değilse AudioStreamPlayer'ın
## finished sinyalinde play() çağırmak da yeterli.

const HZ := 22050

const RUHLAR := {
	"hizli":   {"bpm": 150, "kok": 57, "olcek": [0, 2, 4, 5, 7, 9, 11], "ilerleme": [0, 5, 3, 4], "davul": 2},
	"neseli":  {"bpm": 128, "kok": 60, "olcek": [0, 2, 4, 5, 7, 9, 11], "ilerleme": [0, 3, 4, 0], "davul": 2},
	"sakin":   {"bpm": 92,  "kok": 60, "olcek": [0, 2, 4, 7, 9],        "ilerleme": [0, 3, 1, 2], "davul": 1},
	"gizemli": {"bpm": 108, "kok": 52, "olcek": [0, 2, 3, 5, 7, 8, 10], "ilerleme": [0, 5, 6, 4], "davul": 1},
	"gergin":  {"bpm": 140, "kok": 50, "olcek": [0, 1, 3, 5, 7, 8, 10], "ilerleme": [0, 1, 0, 6], "davul": 2},
}

var rng := RandomNumberGenerator.new()
var tampon := PackedFloat32Array()
var adim_ornek := 0  # 16'lık nota başına örnek sayısı


func _initialize() -> void:
	var a := _argumanlar()
	var cikti: String = a.get("cikti", "res://muzik.wav")
	var tur: String = a.get("tur", "dongu")
	var ruh_adi: String = a.get("ruh", "hizli")
	if not RUHLAR.has(ruh_adi):
		push_error("Bilinmeyen ruh: %s (%s)" % [ruh_adi, ", ".join(RUHLAR.keys())])
		quit(1)
		return
	var ruh: Dictionary = RUHLAR[ruh_adi].duplicate(true)
	if a.has("bpm"):
		ruh["bpm"] = int(a["bpm"])
	rng.seed = int(a.get("tohum", "1"))
	var olcu := 2 if tur == "jingle" else int(a.get("olcu", "8"))

	adim_ornek = int(round(HZ * 60.0 / float(ruh["bpm"]) / 4.0))
	var toplam := adim_ornek * 16 * olcu
	var kuyruk := HZ / 2 if tur == "jingle" else 0
	tampon.resize(toplam + kuyruk)
	tampon.fill(0.0)

	if tur == "jingle":
		_jingle(ruh)
	else:
		_dongu(ruh, olcu)

	var wav := _wav(tur != "jingle", toplam)
	var yol := cikti
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(yol).get_base_dir())
	var e := wav.save_to_wav(yol)
	if e != OK:
		push_error("Kaydedilemedi: %s (%d)" % [yol, e])
		quit(1)
		return
	print("Müzik üretildi: %s (%s, %s, %.1f sn, tohum %d)" % [yol, tur, ruh_adi, float(tampon.size()) / HZ, rng.seed])
	quit(0)


func _argumanlar() -> Dictionary:
	var d := {}
	var liste := OS.get_cmdline_user_args()
	var i := 0
	while i < liste.size():
		var k: String = liste[i]
		if k.begins_with("--") and i + 1 < liste.size():
			d[k.substr(2)] = liste[i + 1]
			i += 2
		else:
			i += 1
	return d


# ------------------------------------------------------------------ besteleme
func _nota(ruh: Dictionary, derece: int, oktav: int = 0) -> int:
	var o: Array = ruh["olcek"]
	var n := o.size()
	var ek := floori(float(derece) / n)
	return int(ruh["kok"]) + int(o[posmod(derece, n)]) + 12 * (ek + oktav)


func _dongu(ruh: Dictionary, olcu: int) -> void:
	var ilerleme: Array = ruh["ilerleme"]
	var n_olcek: int = (ruh["olcek"] as Array).size()
	# İki motif üret: A (soru) ve B (cevap). Döngü: A A' B A'' ...
	var motif_a := _motif(n_olcek)
	var motif_b := _motif(n_olcek)
	for m in olcu:
		var akor: int = ilerleme[m % ilerleme.size()]
		var bas := m * 16
		# Bas: sekizlik kök + beşli
		for s in range(0, 16, 2):
			var d := akor if (s / 2) % 4 != 3 else akor + 4
			_ekle(bas + s, 2, _frekans(_nota(ruh, d, -2)), "ucgen", 0.24, 0.9)
		# Arpej: onaltılık akor notaları
		for s in 16:
			var d2: int = akor + int([0, 2, 4, 2][s % 4])
			_ekle(bas + s, 1, _frekans(_nota(ruh, d2, 0)), "kare12", 0.06, 0.6)
		# Melodi
		var motif: Array = motif_a if (m % 4) != 2 else motif_b
		var degisim: int = 0 if m % 2 == 0 else int([0, 1, -1, 2][m % 4])
		for olay in motif:
			var d3: int = akor + int(olay["d"]) + (degisim if olay["zayif"] else 0)
			_ekle(bas + int(olay["s"]), int(olay["u"]), _frekans(_nota(ruh, d3, 1)), "kare25", 0.16, 0.85)
		# Davul
		_davul(bas, int(ruh["davul"]), m == olcu - 1)


func _motif(n_olcek: int) -> Array:
	var olaylar := []
	var s := 0
	while s < 16:
		var uzunluk: int = int([1, 2, 2, 2, 3, 4][rng.randi_range(0, 5)])
		if s + uzunluk > 16:
			uzunluk = 16 - s
		var guclu := s % 4 == 0
		if rng.randf() < (0.95 if guclu else 0.6):
			var d: int = int([0, 2, 4][rng.randi_range(0, 2)]) if guclu else rng.randi_range(-1, n_olcek)
			olaylar.append({"s": s, "u": uzunluk, "d": d, "zayif": not guclu})
		s += uzunluk
	return olaylar


func _jingle(ruh: Dictionary) -> void:
	var akor: int = (ruh["ilerleme"] as Array)[0]
	var dizi := [0, 2, 4, 7, 9, 11, 14]
	for i in dizi.size():
		_ekle(i * 2, 2, _frekans(_nota(ruh, akor + int(dizi[i]), 1)), "kare25", 0.2, 0.8)
		_ekle(i * 2, 2, _frekans(_nota(ruh, akor + int(dizi[i]), 0)), "kare12", 0.08, 0.6)
	_ekle(14, 18, _frekans(_nota(ruh, akor + 7, 1)), "kare25", 0.2, 0.9)
	_ekle(14, 18, _frekans(_nota(ruh, akor + 4, 0)), "kare12", 0.1, 0.9)
	_ekle(0, 32, _frekans(_nota(ruh, akor, -2)), "ucgen", 0.25, 1.0)
	_davul(0, 1, true)


func _davul(bas: int, yogunluk: int, dolgu: bool) -> void:
	for s in 16:
		var t := (bas + s) * adim_ornek
		if s == 0 or s == 8 or (yogunluk >= 2 and s == 10):
			_tekme(t)
		if s == 4 or s == 12:
			_gurultu(t, 0.14, 0.22, 0.0)
		if yogunluk >= 2 and s % 2 == 1:
			_gurultu(t, 0.025, 0.06, 0.8)
		elif yogunluk == 1 and s % 4 == 2:
			_gurultu(t, 0.025, 0.05, 0.8)
		if dolgu and s >= 12:
			_gurultu(t, 0.06, 0.15, 0.3)


# ------------------------------------------------------------------ sentez
func _frekans(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


func _ekle(adim: int, uzunluk: int, frekans: float, dalga: String, ses: float, dolu: float) -> void:
	var bas := adim * adim_ornek
	var n := int(uzunluk * adim_ornek * dolu)
	var birakma := mini(int(0.03 * HZ), n / 2)
	var faz := 0.0
	var adim_faz := frekans / HZ
	for i in n:
		var j := bas + i
		if j >= tampon.size():
			break
		var zarf := 1.0
		if i < 60:
			zarf = i / 60.0
		elif i > n - birakma:
			zarf = float(n - i) / birakma
		zarf *= 1.0 - 0.35 * float(i) / n
		var x := 0.0
		var f := fposmod(faz, 1.0)
		match dalga:
			"kare25":
				x = (1.0 if f < 0.25 else -1.0) + 0.5    # DC'yi sıfırla (ortalama -0.5)
			"kare12":
				x = (1.0 if f < 0.125 else -1.0) + 0.75  # DC'yi sıfırla (ortalama -0.75)
			"ucgen":
				x = 4.0 * absf(f - 0.5) - 1.0
		tampon[j] += x * ses * zarf
		faz += adim_faz


func _tekme(bas: int) -> void:
	var n := int(0.12 * HZ)
	var faz := 0.0
	for i in n:
		var j := bas + i
		if j >= tampon.size():
			break
		var t := float(i) / n
		var f := lerpf(140.0, 42.0, sqrt(t))
		faz += f / HZ
		tampon[j] += sin(TAU * faz) * 0.45 * (1.0 - t) * (1.0 - t)


func _gurultu(bas: int, sure: float, ses: float, parlaklik: float) -> void:
	var n := int(sure * HZ)
	var onceki := 0.0
	for i in n:
		var j := bas + i
		if j >= tampon.size():
			break
		var r := rng.randf_range(-1.0, 1.0)
		# parlaklık düşükse basit alçak geçiren süzgeç
		onceki = lerpf(onceki, r, 0.25 + 0.75 * parlaklik)
		var t := float(i) / n
		tampon[j] += onceki * ses * (1.0 - t) * (1.0 - t)


func _wav(dongu: bool, dongu_sonu: int) -> AudioStreamWAV:
	# DC engelleyici (tek kutuplu yüksek geçiren) + tepe normalizasyonu
	var onceki_x := 0.0
	var onceki_y := 0.0
	for i in tampon.size():
		var x := tampon[i]
		var y := x - onceki_x + 0.995 * onceki_y
		onceki_x = x
		onceki_y = y
		tampon[i] = y
	# Yumuşatma: sert kare dalga tınısını törpüleyen hafif alçak geçiren süzgeç
	var lp := 0.0
	for i in tampon.size():
		lp = lerpf(lp, tampon[i], 0.55)
		tampon[i] = lp
	var tepe := 0.0001
	for x in tampon:
		tepe = maxf(tepe, absf(x))
	var kazanc := 0.9 / tepe
	var veri := PackedByteArray()
	veri.resize(tampon.size() * 2)
	for i in tampon.size():
		var y := tampon[i] * kazanc
		y = y / (1.0 + 0.25 * absf(y)) * 1.25  # yumuşak sınırlama
		veri.encode_s16(i * 2, int(clampf(y, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = veri
	if dongu:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = dongu_sonu
	return w
