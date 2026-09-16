## Headless test: godot --headless --script res://tests/test_calistir.gd
## Çekirdek mekaniği sınar. Çıkış kodu 0 = geçti, 1 = kaldı.
extends SceneTree

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
	print("== Derin Kazı testleri ==")
	_dunya_testleri()
	_maden_testleri()
	_ekonomi_testleri()
	_yakit_yuk_testleri()
	print("== %d sınama, %d hata ==" % [_sayac, _hata])
	quit(1 if _hata > 0 else 0)

# --- dünya üretimi ---
func _dunya_testleri() -> void:
	print("- dünya üretimi")
	var a := DunyaUretici.new(12345)
	var b := DunyaUretici.new(12345)
	var c := DunyaUretici.new(99999)

	var ayni := true
	var farkli := 0
	var ornekler := [Vector2i(5, 10), Vector2i(20, 80), Vector2i(31, 150),
		Vector2i(44, 205), Vector2i(12, 260), Vector2i(50, 300)]
	for p in ornekler:
		if a.karo(p.x, p.y) != b.karo(p.x, p.y):
			ayni = false
		if a.karo(p.x, p.y) != c.karo(p.x, p.y):
			farkli += 1
	dogru(ayni, "aynı tohum → aynı harita")
	dogru(farkli > 0, "farklı tohum → farklı harita (%d/%d karo ayrıştı)" % [farkli, ornekler.size()])

	dogru(a.karo(0, 50) == Ayarlar.KAYA and a.karo(Ayarlar.GENISLIK - 1, 50) == Ayarlar.KAYA,
		"kenar sütunları kazılamaz kaya")
	dogru(a.karo(5, -3) == Ayarlar.BOS, "yüzeyin üstü boş")
	dogru(a.karo(5, Ayarlar.DERINLIK - 1) == Ayarlar.KAYA, "en alt sıra taban kayası (düşüp kaybolma yok)")
	dogru(a.karo(a.cekirdek_x, Ayarlar.CEKIRDEK_DERINLIK) == Ayarlar.CEKIRDEK,
		"çekirdek %d m'de" % Ayarlar.CEKIRDEK_DERINLIK)

	var ust_bos := 0
	for x in range(2, Ayarlar.GENISLIK - 2):
		for y in Ayarlar.KAPALI_UST:
			if a.karo(x, y) == Ayarlar.BOS:
				ust_bos += 1
	dogru(ust_bos == 0, "yüzeyin ilk %d sırası dolu" % Ayarlar.KAPALI_UST)

# --- maden dağılımı ---
func _maden_testleri() -> void:
	print("- maden dağılımı")
	var u := DunyaUretici.new(4242)
	var sayim := {}
	var derinlik_toplam := {}
	for tur in Ayarlar.MADEN_DEGER:
		sayim[tur] = 0
		derinlik_toplam[tur] = 0
	for x in range(1, Ayarlar.GENISLIK - 1):
		for y in Ayarlar.DERINLIK:
			var t := u.karo(x, y)
			if sayim.has(t):
				sayim[t] += 1
				derinlik_toplam[t] += y

	for tur in Ayarlar.MADEN_DEGER:
		dogru(sayim[tur] > 20, "%s bulundu (%d adet)" % [Ayarlar.MADEN_AD[tur], sayim[tur]])

	# Elmas sığ katmanda çıkmamalı, bakır derinde seyrelmeli.
	var elmas_sig := 0
	var bakir_sig := 0
	for x in range(1, Ayarlar.GENISLIK - 1):
		for y in 100:
			var t := u.karo(x, y)
			if t == Ayarlar.ELMAS:
				elmas_sig += 1
			elif t == Ayarlar.BAKIR:
				bakir_sig += 1
	dogru(elmas_sig == 0, "elmas ilk 100 m'de hiç yok")
	dogru(bakir_sig > 0, "bakır sığ katmanda var (%d adet)" % bakir_sig)

	# Ortalama derinlik sırası: bakır < demir < altın < elmas
	var ort := {}
	for tur in Ayarlar.MADEN_DEGER:
		ort[tur] = float(derinlik_toplam[tur]) / maxf(float(sayim[tur]), 1.0)
	dogru(ort[Ayarlar.BAKIR] < ort[Ayarlar.DEMIR], "bakır ortalaması demirden sığ (%.0f < %.0f)" % [ort[Ayarlar.BAKIR], ort[Ayarlar.DEMIR]])
	dogru(ort[Ayarlar.DEMIR] < ort[Ayarlar.ALTIN], "demir ortalaması altından sığ (%.0f < %.0f)" % [ort[Ayarlar.DEMIR], ort[Ayarlar.ALTIN]])
	dogru(ort[Ayarlar.ALTIN] < ort[Ayarlar.ELMAS], "altın ortalaması elmastan sığ (%.0f < %.0f)" % [ort[Ayarlar.ALTIN], ort[Ayarlar.ELMAS]])

	# Sertlik derinleştikçe artıyor
	dogru(float(Ayarlar.SERTLIK[Ayarlar.TOPRAK]) < float(Ayarlar.SERTLIK[Ayarlar.TAS])
		and float(Ayarlar.SERTLIK[Ayarlar.TAS]) < float(Ayarlar.SERTLIK[Ayarlar.SERT]),
		"toprak < taş < sert taş kazma süresi")
	# Sığ katmanın dolu karoları toprak (maden/boşluk dışında başka taş yok).
	var yabanci := 0
	for x in range(2, Ayarlar.GENISLIK - 2):
		for y in range(Ayarlar.KAPALI_UST, 60):
			var t2 := u.karo(x, y)
			if t2 != Ayarlar.BOS and t2 != Ayarlar.TOPRAK and not Ayarlar.MADEN_DEGER.has(t2) and t2 != Ayarlar.KAYA:
				yabanci += 1
	dogru(yabanci == 0, "sığ katman toprak tabanlı (%d yabancı karo)" % yabanci)

# --- ekonomi ---
func _ekonomi_testleri() -> void:
	print("- satış ve geliştirme")
	var d := Durum.new(7)
	d.maden_ekle(Ayarlar.BAKIR)
	d.maden_ekle(Ayarlar.BAKIR)
	d.maden_ekle(Ayarlar.ALTIN)
	var beklenen := 2 * int(Ayarlar.MADEN_DEGER[Ayarlar.BAKIR]) + int(Ayarlar.MADEN_DEGER[Ayarlar.ALTIN])
	dogru(d.yuk_degeri() == beklenen, "yük değeri doğru (%d)" % beklenen)
	var kazanc := d.sat()
	dogru(kazanc == beklenen and d.para == beklenen, "satış parayı doğru artırdı")
	dogru(d.yuk_toplam() == 0, "satıştan sonra yük boş")

	# Parası yetmezken geliştirme alınmaz.
	var e := Durum.new(7)
	e.para = int(Ayarlar.FIYAT[1]) - 1
	dogru(not e.satin_al("matkap"), "para yetmezse geliştirme alınmaz")
	dogru(e.matkap == 0 and e.para == int(Ayarlar.FIYAT[1]) - 1, "başarısız alımda para ve seviye değişmez")

	e.para = 100000
	var onceki := e.para
	dogru(e.satin_al("matkap"), "para yeterken geliştirme alınır")
	dogru(e.matkap == 1, "seviye arttı")
	dogru(e.para == onceki - int(Ayarlar.FIYAT[1]), "para fiyat kadar düştü")
	dogru(e.matkap_hizi() > 1.0, "matkap hızı arttı")

	# En üst seviyeden öteye satın alınmaz.
	for i in 5:
		e.satin_al("matkap")
	dogru(e.matkap == Ayarlar.EN_YUKSEK_SEVIYE, "seviye tavanda durur (%d)" % Ayarlar.EN_YUKSEK_SEVIYE)
	dogru(e.fiyat("matkap") == -1 and not e.satin_al("matkap"), "tavandayken alım reddedilir")

	# Kapasite geliştirmeleri gerçekten etkiliyor
	var k := Durum.new(7)
	var yuk0 := k.yuk_kapasitesi()
	var yakit0 := k.yakit_kapasitesi()
	k.para = 100000
	k.satin_al("kasa")
	k.satin_al("depo")
	dogru(k.yuk_kapasitesi() > yuk0, "kasa geliştirmesi yük kapasitesini artırdı")
	dogru(k.yakit_kapasitesi() > yakit0, "depo geliştirmesi yakıt kapasitesini artırdı")

	# Kayıt gidiş-dönüş
	var y := Durum.new(0)
	y.sozlukten(k.sozluge())
	dogru(y.tohum == k.tohum and y.para == k.para and y.kasa == k.kasa and y.depo == k.depo,
		"kayıt sözlüğü gidiş-dönüş korunuyor")

# --- yakıt ve yük ---
func _yakit_yuk_testleri() -> void:
	print("- yakıt ve yük")
	var d := Durum.new(7)
	dogru(d.yakit == d.yakit_kapasitesi(), "koşu dolu depoyla başlar")
	d.yakit_harca(d.yakit_kapasitesi() * 0.5)
	dogru(not d.bitti, "yarı yakıtta koşu sürer")
	d.yakit_harca(1000.0)
	dogru(d.yakit == 0.0 and d.bitti, "yakıt 0 → koşu biter")

	# Yük dolunca maden eklenmez.
	var y := Durum.new(7)
	for i in y.yuk_kapasitesi():
		y.maden_ekle(Ayarlar.BAKIR)
	dogru(y.yuk_dolu(), "kapasite kadar maden yükü doldurdu")
	dogru(not y.maden_ekle(Ayarlar.ALTIN), "yük doluyken maden eklenmez")
	dogru(y.yuk_toplam() == y.yuk_kapasitesi(), "yük kapasiteyi aşmadı")
	dogru(not y.maden_ekle(Ayarlar.TAS), "maden olmayan karo yüke girmez")

	# Koşu başarısız: yükün yarısı gider, acil yakıt verilir.
	var b := Durum.new(7)
	for i in 8:
		b.maden_ekle(Ayarlar.DEMIR)
	b.yakit_harca(10000.0)
	b.kosu_basarisiz()
	dogru(b.yuk.get(Ayarlar.DEMIR, 0) == 4, "yakıt bitince yükün yarısı kayboldu")
	dogru(b.yakit > 0.0 and not b.bitti, "acil yakıtla üsse dönülür (kilitlenme yok)")

	# Yakıt dolumu: parası kadar alır.
	var f := Durum.new(7)
	f.yakit = 0.0
	f.para = 10
	var harcanan := f.yakit_doldur()
	dogru(harcanan <= 10 and f.para == 10 - harcanan, "yakıt dolumu parayı doğru düşer")
	dogru(f.yakit > 0.0 and f.yakit < f.yakit_kapasitesi(), "az parayla kısmi dolum")
	f.para = 100000
	f.yakit_doldur()
	dogru(is_equal_approx(f.yakit, f.yakit_kapasitesi()), "para yeterken depo dolar")
	dogru(f.yakit_dolum_fiyati() == 0, "dolu depo için ücret yok")
