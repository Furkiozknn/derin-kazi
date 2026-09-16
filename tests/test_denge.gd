## Denge simülasyonu (kusursuz bot): godot --headless --path . --script res://tests/test_denge.gd
##
## Simülasyonun kendisi `tests/bot.gd` içinde. Burada yalnız hedefler sınanıyor:
## "2–4 dk'lık her turda ~1 geliştirme" ve rakip analizindeki "ilk 10 dakika" akışı.
##
## Bu dosya ekonominin EĞRİSİNİ ölçer (bot duraksamaz, hata yapmaz).
## İnsana benzetilmiş ölçüm ayrı dosyada: tests/test_insan.gd
extends SceneTree

const TOHUMLAR := [11, 4242, 90210]

var _hata := 0
var _sayac := 0

func dogru(kosul: bool, ad: String) -> void:
	_sayac += 1
	if kosul:
		print("  [OK] ", ad)
	else:
		_hata += 1
		printerr("  [HATA] ", ad)

func _initialize() -> void:
	print("== Denge simülasyonu (kusursuz bot) ==")
	var toplam := {}
	var tohum_sonuc := []
	var anahtarlar := ["ilk8_ort_sure", "on_dk_derinlik", "on_dk_gelistirme",
		"ilk8_gelistirme", "cekirdek_dk", "tur_sayisi"]
	for tohum in TOHUMLAR:
		var s := Bot.calistir(tohum, Bot.MUKEMMEL)
		tohum_sonuc.append(s)
		print("\n-- tohum %d --" % tohum)
		_yazdir(s)
		if toplam.is_empty():
			toplam = s.duplicate(true)
		else:
			for anahtar in anahtarlar:
				toplam[anahtar] = float(toplam[anahtar]) + float(s[anahtar])
	for anahtar in anahtarlar:
		toplam[anahtar] = float(toplam[anahtar]) / float(TOHUMLAR.size())

	print("\n-- %d tohum ortalaması --" % TOHUMLAR.size())
	print("  ilk 8 turun ortalama süresi : %.0f sn" % float(toplam["ilk8_ort_sure"]))
	print("  ilk 8 turda geliştirme      : %.1f" % float(toplam["ilk8_gelistirme"]))
	print("  10. dakikada derinlik       : %.0f m" % float(toplam["on_dk_derinlik"]))
	print("  10. dakikada geliştirme     : %.1f" % float(toplam["on_dk_gelistirme"]))
	print("  çekirdeğe varış             : %.0f dk (%.0f tur)"
		% [float(toplam["cekirdek_dk"]), float(toplam["tur_sayisi"])])

	print("\n  katman basina gelir (dakika basina TL, >=2 dk ornek):")
	var carpanlar := PackedFloat32Array()
	for t in tohum_sonuc:
		var satir := PackedStringArray()
		var kat: Array = t["katman_gelir"]
		var sure: Array = t["katman_sure"]
		var gecerli := PackedFloat32Array()
		for k in kat.size():
			if float(sure[k]) >= 2.0:
				gecerli.append(float(kat[k]))
				satir.append("%.0f" % float(kat[k]))
			else:
				satir.append("-")
		if gecerli.size() >= 3:
			var f: float = pow(gecerli[gecerli.size() - 1] / gecerli[0], 1.0 / float(gecerli.size() - 1))
			carpanlar.append(f)
			satir.append("  (katman basina x%.2f)" % f)
		print("    %s" % " -> ".join(satir))
	var ort_carpan := 0.0
	for f in carpanlar:
		ort_carpan += f
	ort_carpan /= maxf(float(carpanlar.size()), 1.0)

	print("\n- hedefler")
	# Bot en kısa yolu seçer ve hiç duraksamaz; insan aynı turu kabaca 1,5-2 kat
	# uzun oynar (tests/test_insan.gd bunu ölçüyor).
	dogru(float(toplam["ilk8_ort_sure"]) >= 60.0 and float(toplam["ilk8_ort_sure"]) <= 200.0,
		"bot turu 60-200 sn (%.0f sn)" % float(toplam["ilk8_ort_sure"]))
	dogru(float(toplam["ilk8_gelistirme"]) >= 6.0,
		"ilk 8 turda ~1 tur = 1 geliştirme (%.1f)" % float(toplam["ilk8_gelistirme"]))
	dogru(float(toplam["on_dk_derinlik"]) >= 30.0,
		"10. dakikada en az 30 m (%.0f m)" % float(toplam["on_dk_derinlik"]))
	dogru(float(toplam["on_dk_gelistirme"]) >= 3.0,
		"10. dakikada en az 3 geliştirme (%.1f)" % float(toplam["on_dk_gelistirme"]))
	# Görev hedefi: "katman başına gelir ~×1,5". Ölçülen şey maden değeri değil,
	# dakika başına kazanç — maden ağırlığı adedi düşürdüğü için ikisi aynı değil.
	dogru(ort_carpan >= 1.2 and ort_carpan <= 2.2,
		"katman başına gelir çarpanı 1,2-2,2 (ölçülen ×%.2f)" % ort_carpan)
	# v0.3: fay hattı garantisi sayesinde her tohumda çekirdeğe ulaşılmalı.
	var ulasan := 0
	var en_az_tur := 999
	for t in tohum_sonuc:
		if int(t["cekirdek_tur"]) > 0:
			ulasan += 1
			en_az_tur = mini(en_az_tur, int(t["cekirdek_tur"]))
	dogru(ulasan == TOHUMLAR.size(), "her tohumda çekirdeğe ulaşıldı (%d/%d)"
		% [ulasan, TOHUMLAR.size()])
	dogru(en_az_tur >= 8, "çekirdek en erken %d. turda (yeterince uzun bir yol)" % en_az_tur)
	print("== %d sınama, %d hata ==" % [_sayac, _hata])
	quit(1 if _hata > 0 else 0)

func _yazdir(s: Dictionary) -> void:
	print("  tur  süre   derinlik  kazanç  gelişt.  para")
	for r in Array(s["turlar"]).slice(0, 10):
		print("  %3d %5.0fs %7d m %7d %7d %7d" % [r["no"], r["sure"], r["derinlik"],
			r["kazanc"], r["gelistirme"], r["para"]])
	print("  ...  çekirdek %d. turda, %.0f dk" % [int(s["tur_sayisi"]), float(s["cekirdek_dk"])])
