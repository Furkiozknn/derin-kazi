## İnsan benzeri ölçüm: godot --headless --path . --script res://tests/test_insan.gd
##
## `tests/test_denge.gd` kusussuz botla ekonominin eğrisini ölçüyor. Burada aynı
## simülasyon, tepki gecikmesi + duraksama + yanlış rota olasılığı olan bir botla
## 7 tohumda çalıştırılıyor. Cevaplanan iki soru:
##   1. İlk 10 dakikada oyuncu nereye varıyor? (derinlik, geliştirme, tur sayısı)
##   2. Çekirdeğe kaç dakikada varılıyor?
##
## Dört bot yan yana ölçülüyor:
##   Bot.INSAN_SISLI — ANA SAYI. Yol bulması yalnız KEŞFEDİLENİ biliyor, yani
##                     oyuncunun bilgisiyle oynuyor (keşif sisi, v0.5).
##   Bot.INSAN_DERIN — aynı bot DERİN MOD x1'de (v0.6): altı eser elde, kaya sert,
##                     yakıt hızlı, maden değerli, ışık 3 karo, deprem 4 seferde bir.
##   Bot.INSAN       — aynı insan gürültüsü, ama bütün dünyayı görüyor. Sisin
##                     ölçüme kaç dakika eklediğini görmek için duruyor.
##   Bot.MUKEMMEL    — duraksamayan robot; ekonominin eğrisi.
##
## Bu hâlâ bir bottur; gerçek bir insanın yerini tutmaz. Ama "duraksamayan robot"
## varsayımını sayıya döküp bandı daraltıyor: v0.2 raporundaki "insan 1,5-2 kat
## yavaş oynar" varsayımı burada ölçülen orana karşı kontrol ediliyor.
extends SceneTree

const TOHUMLAR := [11, 4242, 90210, 1337, 20260916, 7, 555000]

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
	print("== İnsan benzeri ölçüm (%d tohum) ==" % TOHUMLAR.size())
	print("  bot ayarı (ana): %s" % str(Bot.INSAN_SISLI))
	var insan := []       ## keşif sisli — ana ölçüm
	var derin := []       ## aynı bot Derin Mod x1'de (v0.6)
	var acik := []        ## sissiz (bütün dünyayı gören) insan botu
	var robot := []
	for tohum in TOHUMLAR:
		insan.append(Bot.calistir(tohum, Bot.INSAN_SISLI))
		derin.append(Bot.calistir(tohum, Bot.INSAN_DERIN))
		acik.append(Bot.calistir(tohum, Bot.INSAN))
		robot.append(Bot.calistir(tohum, Bot.MUKEMMEL))

	print("\n| tohum | kod | tur sn | 10. dk derinlik | 10. dk gelist. | cekirdek dk | cekirdek tur |")
	print("|---|---|---|---|---|---|---|")
	for s in insan:
		print("| %d | %s | %.0f | %d m | %d | %s | %s |" % [
			int(s["tohum"]), TohumKodu.kodla(int(s["tohum"])), float(s["ilk8_ort_sure"]),
			int(s["on_dk_derinlik"]), int(s["on_dk_gelistirme"]),
			("%.0f" % float(s["cekirdek_dk"])) if int(s["cekirdek_tur"]) > 0 else "ULASILMADI",
			str(int(s["cekirdek_tur"])) if int(s["cekirdek_tur"]) > 0 else "-"])

	print("\n-- Derin Mod x1 (sisli insan botu, altı eserle; ilk oyunla yan yana) --")
	print("| tohum | tur sn (derin / ilk) | 10. dk derinlik | 10. dk gelist. | cekirdek dk (derin / ilk) | cekirdek tur |")
	print("|---|---|---|---|---|---|")
	for i in derin.size():
		var s: Dictionary = derin[i]
		var s0: Dictionary = insan[i]
		print("| %d | %.0f / %.0f | %d m | %d | %s / %.0f | %s |" % [
			int(s["tohum"]), float(s["ilk8_ort_sure"]), float(s0["ilk8_ort_sure"]),
			int(s["on_dk_derinlik"]), int(s["on_dk_gelistirme"]),
			("%.0f" % float(s["cekirdek_dk"])) if int(s["cekirdek_tur"]) > 0 else "ULASILMADI",
			float(s0["cekirdek_dk"]),
			str(int(s["cekirdek_tur"])) if int(s["cekirdek_tur"]) > 0 else "-"])

	var i_tur := _ort(insan, "ilk8_ort_sure")
	var a_tur := _ort(acik, "ilk8_ort_sure")
	var a_cek := _ort(acik, "cekirdek_dk")
	var r_tur := _ort(robot, "ilk8_ort_sure")
	var i_derin := _ort(insan, "on_dk_derinlik")
	var i_gel := _ort(insan, "on_dk_gelistirme")
	var i_cek := _ort(insan, "cekirdek_dk")
	var r_cek := _ort(robot, "cekirdek_dk")
	var ulasan := 0
	var en_yavas := 0.0
	for s in insan:
		if int(s["cekirdek_tur"]) > 0:
			ulasan += 1
			en_yavas = maxf(en_yavas, float(s["cekirdek_dk"]))

	var a_ulasan := 0
	for s in acik:
		if int(s["cekirdek_tur"]) > 0:
			a_ulasan += 1

	print("\n-- ortalama --")
	print("  tur süresi          : sisli %.0f sn  •  sissiz %.0f sn  •  robot %.0f sn  •  oran x%.2f"
		% [i_tur, a_tur, r_tur, i_tur / maxf(r_tur, 0.01)])
	print("  10. dakikada        : %.0f m derinlik, %.1f geliştirme" % [i_derin, i_gel])
	print("  çekirdeğe varış     : sisli %.0f dk  •  sissiz %.0f dk  •  robot %.0f dk"
		% [i_cek, a_cek, r_cek])
	print("  çekirdeğe ulaşan    : %d/%d tohum (en yavaşı %.0f dk)"
		% [ulasan, TOHUMLAR.size(), en_yavas])
	print("  sisin bedeli        : tur %+.0f sn, çekirdek %+.0f dk (sissiz %d/%d ulaştı)"
		% [i_tur - a_tur, i_cek - a_cek, a_ulasan, TOHUMLAR.size()])
	# Sis yalnız BFS rotasını etkiler; rota hiç kurulmadıysa bedelin 0 çıkması
	# normaldir (fay koridoru botu tıkamıyor). Kaç tohumda kurulduğu burada.
	var rotali := 0
	var rota_toplam := 0
	var kirilma := 0
	for s in insan:
		if int(s["rota"]) > 0:
			rotali += 1
		rota_toplam += int(s["rota"])
		kirilma += int(s["sis_kirilma"])
	print("  BFS rotası kurulan  : %d/%d tohum (toplam %d rota, %d sis kırılması)"
		% [rotali, TOHUMLAR.size(), rota_toplam, kirilma])
	var d_tur := _ort(derin, "ilk8_ort_sure")
	var d_cek := _ort(derin, "cekirdek_dk")
	var d_derin := _ort(derin, "on_dk_derinlik")
	var d_ulasan := 0
	var d_deprem := 0
	var d_rota := 0
	for s in derin:
		if int(s["cekirdek_tur"]) > 0:
			d_ulasan += 1
		d_deprem += int(s["deprem"])
		d_rota += int(s["rota"])
	print("  Derin Mod x1        : tur %.0f sn (%+.0f), 10. dk %.0f m, çekirdek %.0f dk (%+.0f), %d/%d ulaştı, %d deprem, %d rota"
		% [d_tur, d_tur - i_tur, d_derin, d_cek, d_cek - i_cek, d_ulasan, TOHUMLAR.size(), d_deprem, d_rota])

	print("\n- hedefler")
	# ÖLÇÜLEN (2026-09-16, v0.3): tur 108 sn, çekirdeğe 23 dk.
	# Buradaki bantlar bir hedef değil, GERİLEME BEKÇİSİ: denge sabitleri
	# değiştiğinde oturum uzunluğunun sessizce kaymasını yakalar.
	#
	# Rakip analizindeki "çekirdeğe 60-90 dk" hedefi bilerek BIRAKILDI: aynı
	# analizde Motherload'ın şikâyeti "çok uzun", A Game About Digging A Hole'ün
	# şikâyeti "1-2 saat ve geliştirmeler erken bitiyor". Ölçülen ~25 dk'lık ilk
	# oyun + Derin Mod'un uzun kuyruğu bu iki şikâyetin arasındaki bant.
	# Gerekçe README.md "Oturum uzunluğu" başlığında.
	dogru(i_tur >= 80.0 and i_tur <= 260.0,
		"insan turu 1,5-4,5 dk bandında (%.0f sn)" % i_tur)
	# v0.2 raporundaki "insan 1,5-2 kat yavaş" varsayımı ölçüldü.
	dogru(i_tur / maxf(r_tur, 0.01) >= 1.3, "insan botu robottan en az %%30 yavaş (x%.2f)"
		% (i_tur / maxf(r_tur, 0.01)))
	# Rakip analizindeki "ilk 10 dakika" akışı: 9:30'da eser ve ilk istasyon.
	dogru(i_derin >= 25.0, "10. dakikada en az 25 m (%.0f m)" % i_derin)
	dogru(i_gel >= 3.0, "10. dakikada en az 3 geliştirme (%.1f)" % i_gel)
	# Dome Keeper şikâyeti: kötü dünya üretimi oyunu bitirilemez yapmasın.
	dogru(ulasan == TOHUMLAR.size(), "her tohumda çekirdeğe ulaşıldı (%d/%d)"
		% [ulasan, TOHUMLAR.size()])
	# Oturum uzunluğu: ölçülen 23 dk. Bot ölüm, çekilme, düşen kaya kaçınması,
	# müze okuma ve deprem gecikmesi yaşamıyor — gerçek oyuncu daha uzun oynar.
	dogru(i_cek >= 15.0 and i_cek <= 60.0,
		"çekirdeğe varış 15-60 dk bandında (%.0f dk)" % i_cek)
	# Derin Mod x1 (v0.6): dar ışık + sık deprem oyunu bitirilemez yapmamalı ve
	# "uzun kuyruk" ilk oyunla aynı düzende kalmalı. Bantlar ölçüldükten sonra
	# gerileme bekçisi olarak kondu (rapor 2026-09-16-derin-kazi-gelistirme-5.md).
	dogru(d_ulasan == TOHUMLAR.size(), "Derin Mod x1'de her tohumda çekirdeğe ulaşıldı (%d/%d)"
		% [d_ulasan, TOHUMLAR.size()])
	dogru(d_cek >= 15.0 and d_cek <= 90.0, "Derin Mod x1 çekirdeğe varış 15-90 dk bandında (%.0f dk)" % d_cek)
	dogru(d_tur >= 80.0 and d_tur <= 300.0, "Derin Mod x1 turu 1,3-5 dk bandında (%.0f sn)" % d_tur)
	dogru(d_deprem > 0, "Derin Mod botu depremi yaşıyor (%d deprem / 7 tohum)" % d_deprem)
	print("== %d sınama, %d hata ==" % [_sayac, _hata])
	quit(1 if _hata > 0 else 0)

func _ort(liste: Array, anahtar: String) -> float:
	var t := 0.0
	for s in liste:
		t += float(s[anahtar])
	return t / maxf(float(liste.size()), 1.0)
