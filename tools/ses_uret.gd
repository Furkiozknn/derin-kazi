## Kodla sentezlenen iki efekt — rFXGen ön ayarlarının veremediği sesler (v0.7):
##   matkap.wav  kazarken çalan DÖNGÜ (0,6 sn, dikişsiz): motor vızıltısı + uç takırtısı
##               + öğütme gürültüsü. Ses.dongu_baslat("matkap") çalar, kazı bitince söner.
##   deprem.wav  depreme özel gürültü (2,8 sn): açılış vuruşu + düşük frekanslı sarsıntı
##               (kahverengi gürültü, 3,5 Hz dalgalı) + kabuk çatırtısı (seyrek kısa
##               patlamalar). Patlama sesinden (explosion.wav) AYRI dosya.
## Deterministik: aynı tohum aynı örnekleri verir (tests/test_calistir.gd sınıyor).
##
##   godot --headless --path . --script res://tools/ses_uret.gd
extends SceneTree

const HZ := 22050
const MATKAP_SN := 0.6
const DEPREM_SN := 2.8
const TOHUM := 7

func _initialize() -> void:
	var kok := "res://assets/audio/"
	_yaz(kok + "matkap.wav", matkap(TOHUM))
	_yaz(kok + "deprem.wav", deprem(TOHUM))
	quit(0)

func _yaz(yol: String, ornek: PackedFloat32Array) -> void:
	var e := wav(ornek).save_to_wav(yol)
	print("%s  %.2f sn  tepe %.2f  %s" % [yol.get_file(), float(ornek.size()) / HZ, tepe(ornek),
		"OK" if e == OK else "HATA %d" % e])

## Matkap döngüsü. Motor 55 Hz (0,6 sn'de tam 33 devir; vibrato tam periyotlu, yani
## dikişte faz sıfır), üstüne 2. ve 3. harmonik; uç takırtısı 22 Hz'lik kısa gürültü
## vuruşları; öğütme = motorla genlik modüleli alçak geçirilmiş gürültü. Son 20 ms
## başa çaprazlanır ki döngü dikişi duyulmasın.
static func matkap(tohum: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = tohum
	var n := int(MATKAP_SN * HZ)
	var kuyruk := int(0.02 * HZ)
	var x := PackedFloat32Array()
	x.resize(n + kuyruk)
	var faz := 0.0
	var lp := 0.0
	var vurus := 0.0
	var takirti_aralik := int(HZ / 22.0)
	for i in n + kuyruk:
		var t := float(i) / HZ
		faz += (55.0 + 1.5 * sin(TAU * 5.0 * t)) / HZ   ## hafif vibrato: motor yük altında
		var f := fposmod(faz, 1.0)
		var motor := (2.0 * f - 1.0) * 0.45 + sin(TAU * 110.0 * t) * 0.18 + sin(TAU * 165.0 * t) * 0.08
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.35)
		var ogutme := lp * (0.35 + 0.65 * absf(sin(TAU * 55.0 * t))) * 0.30
		if i % takirti_aralik == 0:
			vurus = 1.0
		vurus *= 0.90
		x[i] = motor + ogutme + rng.randf_range(-1.0, 1.0) * vurus * 0.35
	for i in kuyruk:
		var a := float(i) / float(kuyruk)
		x[i] = x[i] * a + x[n + i] * (1.0 - a)
	x.resize(n)
	return _normalle(x, 0.8)

## Deprem gürültüsü: 0,35 sn açılış vuruşu (80 → 28 Hz süpürme), boydan boya
## 15-60 Hz sarsıntı (sızdıran integral gürültü + alçak geçiren, 3,5 Hz dalgalı),
## 0,2-2,2 sn arasında ortada yoğunlaşan çatırtılar, son 1,1 sn sönüm.
static func deprem(tohum: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = tohum + 1
	var n := int(DEPREM_SN * HZ)
	var x := PackedFloat32Array()
	x.resize(n)
	var kahve := 0.0
	var lp := 0.0
	var catirti := 0.0
	var hp := 0.0
	var onceki := 0.0
	var faz := 0.0
	for i in n:
		var t := float(i) / HZ
		var zarf := clampf(t / 0.08, 0.0, 1.0) * clampf((DEPREM_SN - t) / 1.1, 0.0, 1.0)
		kahve = kahve * 0.985 + rng.randf_range(-1.0, 1.0) * 0.08
		lp = lerpf(lp, kahve, 0.06)
		var sarsinti := lp * (0.7 + 0.3 * sin(TAU * 3.5 * t)) * 6.0
		var vurus := 0.0
		if t < 0.35:
			faz += lerpf(80.0, 28.0, t / 0.35) / HZ
			vurus = sin(TAU * faz) * (1.0 - t / 0.35) * 0.9
		var yogunluk := 0.0
		if t > 0.2 and t < 2.2:
			yogunluk = 0.0015 * sin(PI * (t - 0.2) / 2.0)
		if rng.randf() < yogunluk:
			catirti = rng.randf_range(0.5, 1.0)
		catirti *= 0.985
		var r := rng.randf_range(-1.0, 1.0)
		hp = 0.6 * (hp + r - onceki)   ## yüksek geçiren: çatırtı tiz kalsın
		onceki = r
		x[i] = (sarsinti + vurus + hp * catirti * 0.5) * zarf
	# DC engelleyici: kahverengi gürültü sürüklenir.
	var ox := 0.0
	var oy := 0.0
	for i in n:
		var y := x[i] - ox + 0.995 * oy
		ox = x[i]
		oy = y
		x[i] = y
	return _normalle(x, 0.9)

static func _normalle(x: PackedFloat32Array, hedef: float) -> PackedFloat32Array:
	var t := tepe(x)
	if t > 0.0001:
		for i in x.size():
			x[i] = x[i] * hedef / t
	return x

static func tepe(x: PackedFloat32Array) -> float:
	var t := 0.0
	for v in x:
		t = maxf(t, absf(v))
	return t

static func wav(x: PackedFloat32Array) -> AudioStreamWAV:
	var veri := PackedByteArray()
	veri.resize(x.size() * 2)
	for i in x.size():
		veri.encode_s16(i * 2, int(clampf(x[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = veri
	return w
