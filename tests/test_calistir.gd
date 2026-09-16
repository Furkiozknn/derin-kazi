## Headless birim testleri: godot --headless --path . --script res://tests/test_calistir.gd
## Çıkış kodu 0 = geçti, 1 = kaldı.
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
	print("== Derin Kazı birim testleri ==")
	_dunya_testleri()
	_katman_testleri()
	_maden_testleri()
	_oda_testleri()
	_ekonomi_testleri()
	_zincir_testleri()
	_alet_istasyon_testleri()
	_yakit_can_testleri()
	_eser_testleri()
	_kayit_testleri()
	_fay_testleri()
	_deprem_testleri()
	_ipucu_testleri()
	_varyant_testleri()
	_tohum_kodu_testleri()
	_derin_mod_testleri()
	_simge_testleri()
	print("== %d sınama, %d hata ==" % [_sayac, _hata])
	quit(1 if _hata > 0 else 0)

# --- dünya üretimi --------------------------------------------------------

func _dunya_testleri() -> void:
	print("- dünya üretimi")
	var a := DunyaUretici.new(12345)
	var b := DunyaUretici.new(12345)
	var c := DunyaUretici.new(99999)

	var ayni := true
	var farkli := 0
	var ornekler := [Vector2i(5, 10), Vector2i(20, 80), Vector2i(31, 150),
		Vector2i(44, 205), Vector2i(12, 245), Vector2i(50, 260)]
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
	dogru(a.karo(5, Ayarlar.DERINLIK - 1) == Ayarlar.KAYA, "en alt sıra taban kayası")
	dogru(a.karo(a.cekirdek_x, Ayarlar.CEKIRDEK_DERINLIK) == Ayarlar.CEKIRDEK,
		"çekirdek %d m'de" % Ayarlar.CEKIRDEK_DERINLIK)

	var ust_bos := 0
	for x in range(2, Ayarlar.GENISLIK - 2):
		for y in Ayarlar.KAPALI_UST:
			if a.karo(x, y) == Ayarlar.BOS:
				ust_bos += 1
	dogru(ust_bos == 0, "yüzeyin ilk %d sırası dolu" % Ayarlar.KAPALI_UST)

	# Üsün altındaki elle yerleştirilmiş bakır damarı (rakip analizi: 0:30'da ilk "+$")
	var bakir := 0
	for x in range(Ayarlar.US_KARO_X - 3, Ayarlar.US_KARO_X + 4):
		for y in range(0, 12):
			if a.karo(x, y) == Ayarlar.BAKIR:
				bakir += 1
	dogru(bakir >= 4, "ilk 12 m'de garantili bakır damarı (%d karo)" % bakir)
	dogru(c.karo(Ayarlar.US_KARO_X, Ayarlar.BASLANGIC_DAMAR) == Ayarlar.BAKIR,
		"damar her tohumda aynı yerde")

# --- katmanlar ------------------------------------------------------------

func _katman_testleri() -> void:
	print("- katmanlar")
	dogru(Ayarlar.KATMANLAR.size() == 5, "5 katman tanımlı")
	dogru(Ayarlar.katman(0) == 0 and Ayarlar.katman(39) == 0 and Ayarlar.katman(40) == 1,
		"katman sınırı doğru (40 m'de 2. katman)")
	dogru(Ayarlar.katman(249) == 4, "çekirdek katmanı en derin (%d)" % Ayarlar.katman(249))

	var oncekiler := -1
	var artiyor := true
	var matkap_artiyor := true
	var onceki_matkap := -1
	for k in Ayarlar.KATMANLAR:
		var sertlik := float(Ayarlar.SERTLIK[int(k["taban"])])
		if sertlik <= float(oncekiler):
			artiyor = false
		oncekiler = sertlik
		if int(k["matkap"]) < onceki_matkap:
			matkap_artiyor = false
		onceki_matkap = int(k["matkap"])
	dogru(artiyor, "katman tabanları derinleştikçe sertleşiyor")
	dogru(matkap_artiyor, "matkap kapısı derinleştikçe yükseliyor")

	var d := Durum.new(1)
	dogru(d.matkap_yeterli_mi(10), "başlangıç matkabı 1. katmanı kazar")
	dogru(not d.matkap_yeterli_mi(100), "başlangıç matkabı 3. katmanı kazamaz")
	d.matkap = Ayarlar.EN_YUKSEK_SEVIYE
	dogru(d.matkap_yeterli_mi(240), "en üst matkap her katmanı kazar")

	# Her katmanın kendi madeni ve tehlikesi var
	var madenler := {}
	for k in Ayarlar.KATMANLAR:
		madenler[int(k["maden"])] = true
	dogru(madenler.size() == 5, "her katmanın ayrı madeni var")

# --- maden dağılımı -------------------------------------------------------

func _maden_testleri() -> void:
	print("- maden dağılımı")
	var u := DunyaUretici.new(4242)
	var sayim := {}
	var derinlik_toplam := {}
	for tur in Ayarlar.MADEN_DEGER:
		sayim[tur] = 0
		derinlik_toplam[tur] = 0
	var tehlike := {Ayarlar.GAZ: 0, Ayarlar.GEVSEK: 0, Ayarlar.LAV: 0}
	for x in range(1, Ayarlar.GENISLIK - 1):
		for y in Ayarlar.DERINLIK:
			var t := u.karo(x, y)
			if sayim.has(t):
				sayim[t] += 1
				derinlik_toplam[t] += y
			elif tehlike.has(t):
				tehlike[t] += 1

	for tur in Ayarlar.MADEN_DEGER:
		dogru(sayim[tur] > 20, "%s bulundu (%d adet)" % [Ayarlar.MADEN_AD[tur], sayim[tur]])
	for t in tehlike:
		dogru(tehlike[t] > 20, "tehlike %d dünyada var (%d adet)" % [t, tehlike[t]])

	var elmas_sig := 0
	var bakir_sig := 0
	for x in range(1, Ayarlar.GENISLIK - 1):
		for y in 100:
			var t2 := u.karo(x, y)
			if t2 == Ayarlar.ELMAS:
				elmas_sig += 1
			elif t2 == Ayarlar.BAKIR:
				bakir_sig += 1
	dogru(elmas_sig == 0, "elmas ilk 100 m'de hiç yok")
	dogru(bakir_sig > 0, "bakır sığ katmanda var (%d adet)" % bakir_sig)

	var ort := {}
	for tur in Ayarlar.MADEN_DEGER:
		ort[tur] = float(derinlik_toplam[tur]) / maxf(float(sayim[tur]), 1.0)
	var sira := [Ayarlar.BAKIR, Ayarlar.DEMIR, Ayarlar.ALTIN, Ayarlar.ELMAS, Ayarlar.PLATIN]
	for i in range(sira.size() - 1):
		dogru(ort[sira[i]] < ort[sira[i + 1]],
			"%s ortalaması %s'den sığ (%.0f < %.0f)" % [Ayarlar.MADEN_AD[sira[i]],
				Ayarlar.MADEN_AD[sira[i + 1]], ort[sira[i]], ort[sira[i + 1]]])
	# Değer de derinlikle artmalı
	for i in range(sira.size() - 1):
		dogru(int(Ayarlar.MADEN_DEGER[sira[i]]) < int(Ayarlar.MADEN_DEGER[sira[i + 1]]),
			"%s değeri %s'den düşük" % [Ayarlar.MADEN_AD[sira[i]], Ayarlar.MADEN_AD[sira[i + 1]]])

	# Asıl güvence: dünya bitirilebilir olmalı. Yüzeyden çekirdeğe kazılabilir
	# (ya da boş) hücrelerden kesintisiz bir yol var mı? Kazılamaz kaya ve lav duvar.
	var ulasilan := _ulasilabilir(u)
	dogru(ulasilan.has(Vector2i(u.cekirdek_x, Ayarlar.CEKIRDEK_DERINLIK)),
		"çekirdeğe yüzeyden kazılabilir bir yol var")
	var en_derin := 0
	for h in ulasilan:
		en_derin = maxi(en_derin, int(h.y))
	dogru(en_derin >= Ayarlar.CEKIRDEK_DERINLIK, "ulaşılabilir en derin nokta %d m" % en_derin)

# --- odalar ---------------------------------------------------------------

func _oda_testleri() -> void:
	print("- mağara ve gizli odalar")
	var u := DunyaUretici.new(777)
	var oda_sayi := 0
	var sandik := 0
	var eser := 0
	for cy in range(2, Ayarlar.DERINLIK / Ayarlar.PARCA):
		for cx in range(0, Ayarlar.GENISLIK / Ayarlar.PARCA):
			var o := u.oda(cx, cy)
			if o.is_empty():
				continue
			oda_sayi += 1
			if int(o["tur"]) == Ayarlar.SANDIK:
				sandik += 1
			else:
				eser += 1
	dogru(oda_sayi >= 4, "dünyada gizli oda var (%d)" % oda_sayi)
	dogru(sandik > 0 and eser > 0, "hem sandık hem eser odası var (%d / %d)" % [sandik, eser])
	dogru(u.oda(0, 0).is_empty() and u.oda(0, 1).is_empty(), "yüzey chunk'larında oda yok")

	# Oda gerçekten dünyada boşluk açıyor mu?
	var bulundu := false
	for cy in range(2, Ayarlar.DERINLIK / Ayarlar.PARCA):
		for cx in range(0, Ayarlar.GENISLIK / Ayarlar.PARCA):
			var o := u.oda(cx, cy)
			if o.is_empty():
				continue
			if u.karo(int(o["x0"]), int(o["y0"])) == Ayarlar.BOS \
				and u.karo(int(o["x0"]) + DunyaUretici.ODA_G / 2, int(o["y0"]) + DunyaUretici.ODA_Y - 1) == int(o["tur"]):
				bulundu = true
	dogru(bulundu, "oda dünyada boşluk + ödül karosu olarak beliriyor")

# --- ekonomi --------------------------------------------------------------

func _ekonomi_testleri() -> void:
	print("- satış ve geliştirme")
	var d := Durum.new(7)
	d.maden_ekle(Ayarlar.BAKIR)
	d.maden_ekle(Ayarlar.ALTIN)
	var beklenen := int(Ayarlar.MADEN_DEGER[Ayarlar.BAKIR]) + int(Ayarlar.MADEN_DEGER[Ayarlar.ALTIN])
	dogru(d.yuk_degeri() == beklenen, "yük değeri doğru (%d)" % beklenen)
	var kazanc := d.sat()
	dogru(kazanc == beklenen and d.para == beklenen, "satış parayı doğru artırdı")
	dogru(d.yuk_toplam() == 0 and d.yuk_bonus == 0, "satıştan sonra yük ve ikramiye sıfır")

	# Fiyat eğrisi taban * 1.35^seviye
	for alan in Ayarlar.GELISTIRMELER:
		var taban := int(Ayarlar.FIYAT_TABAN[alan])
		dogru(Ayarlar.gelistirme_fiyati(alan, 0) == taban, "%s ilk seviye tabanı %d" % [alan, taban])
		dogru(Ayarlar.gelistirme_fiyati(alan, 2)
			== int(round(float(taban) * pow(Ayarlar.FIYAT_ARTIS, 2.0))),
			"%s 3. seviye fiyatı 1.35^2 eğrisinde" % alan)
		dogru(Ayarlar.gelistirme_fiyati(alan, Ayarlar.EN_YUKSEK_SEVIYE) == -1,
			"%s tavanda fiyat yok" % alan)

	var e := Durum.new(7)
	e.para = int(Ayarlar.FIYAT_TABAN["matkap"]) - 1
	dogru(not e.satin_al("matkap"), "para yetmezse geliştirme alınmaz")
	dogru(e.matkap == 0, "başarısız alımda seviye değişmez")

	e.para = 100000
	var onceki := e.para
	dogru(e.satin_al("matkap"), "para yeterken geliştirme alınır")
	dogru(e.matkap == 1 and e.para == onceki - int(Ayarlar.FIYAT_TABAN["matkap"]),
		"seviye arttı, para fiyat kadar düştü")
	dogru(e.matkap_hizi() > 1.0, "matkap hızı arttı")
	for i in 9:
		e.satin_al("matkap")
	dogru(e.matkap == Ayarlar.EN_YUKSEK_SEVIYE, "seviye tavanda durur (%d)" % Ayarlar.EN_YUKSEK_SEVIYE)

	var k := Durum.new(7)
	var yuk0 := k.yuk_kapasitesi()
	var yakit0 := k.yakit_kapasitesi()
	var can0 := k.can_kapasitesi()
	k.para = 100000
	k.satin_al("kasa")
	k.satin_al("depo")
	k.satin_al("govde")
	dogru(k.yuk_kapasitesi() > yuk0, "kasa yük kapasitesini artırdı")
	dogru(k.yakit_kapasitesi() > yakit0, "depo yakıt kapasitesini artırdı")
	dogru(k.can_kapasitesi() > can0 and k.can == k.can_kapasitesi(), "gövde canı artırdı ve doldurdu")

# --- kazı zinciri ---------------------------------------------------------

func _zincir_testleri() -> void:
	print("- kazı zinciri")
	var d := Durum.new(1)
	d.kasa = Ayarlar.EN_YUKSEK_SEVIYE
	dogru(is_equal_approx(Ayarlar.zincir_carpani(1), 1.0), "tek maden çarpansız")
	dogru(Ayarlar.zincir_carpani(int(Ayarlar.ZINCIR_ESIK[0])) > 1.0, "3 aynı maden → çarpan")
	for i in 3:
		d.maden_ekle(Ayarlar.BAKIR)
	dogru(d.zincir_adet == 3 and d.zincir_carpani() > 1.0, "zincir sayacı işliyor")
	dogru(d.yuk_bonus > 0, "zincir ikramiyesi yüke eklendi (%d)" % d.yuk_bonus)
	var bonuslu := d.yuk_degeri()
	dogru(bonuslu > 3 * int(Ayarlar.MADEN_DEGER[Ayarlar.BAKIR]), "zincirli yük daha değerli")

	d.maden_ekle(Ayarlar.DEMIR)
	dogru(d.zincir_adet == 1, "farklı maden zinciri sıfırlar")
	d.maden_ekle(Ayarlar.DEMIR)
	d.zincir_isle(Ayarlar.ZINCIR_SURE + 1.0)
	dogru(d.zincir_adet == 0, "süre dolunca zincir düşer")

# --- alet, istasyon, sandık -----------------------------------------------

func _alet_istasyon_testleri() -> void:
	print("- aletler, istasyon, düşen sandık")
	var d := Durum.new(1)
	dogru(not d.alet_var("radar"), "radar başta yok")
	dogru(not d.alet_al("radar"), "parası yetmezse alet alınmaz")
	d.para = 100000
	dogru(d.alet_al("radar") and d.alet_var("radar"), "alet satın alındı")
	dogru(not d.alet_al("radar"), "aynı alet iki kez alınmaz")

	var f := Durum.new(1)
	dogru(not f.alet_var("kalkan"), "kalkan başta yok")
	f.kacis = true
	dogru(f.alet_var("kalkan"), "finalde tüm aletler açık (aletler elden alınmaz)")

	# İstasyon: 50 m aralık kuralı
	var i := Durum.new(1)
	i.para = 100000
	i.istasyon_kiti_al()
	dogru(not i.istasyon_kurulabilir(Vector2i(10, 20)), "sığ derinliğe istasyon kurulmaz")
	dogru(i.istasyon_kur(Vector2i(10, 60)), "60 m'ye istasyon kuruldu")
	i.istasyon_kiti_al()
	dogru(not i.istasyon_kurulabilir(Vector2i(12, 80)), "50 m'den yakına ikinci istasyon yok")
	dogru(i.istasyon_kur(Vector2i(12, 120)), "120 m'ye ikinci istasyon kuruldu")
	dogru(i.istasyonlar.size() == 2 and i.istasyonlar[0].y < i.istasyonlar[1].y,
		"istasyonlar derinliğe göre sıralı")

	# Yumuşak ceza: yarım yük sandıkta kalır, geri alınabilir
	var b := Durum.new(1)
	b.kasa = 2
	b.para = 500
	for j in 8:
		b.maden_ekle(Ayarlar.DEMIR)
	var yuk0 := b.yuk_toplam()
	var para0 := b.para
	b.yakit_harca(10000.0)
	dogru(b.bitti, "yakıt 0 → koşu biter")
	var sonuc := b.kosu_basarisiz(Vector2i(20, 70))
	dogru(not b.bitti, "yumuşak ceza: ölüm yok, koşu sürer")
	dogru(b.para == para0 - int(sonuc["ucret"]) and int(sonuc["ucret"]) > 0,
		"çekme ücreti alındı (%d ₺)" % int(sonuc["ucret"]))
	dogru(b.yuk_toplam() == yuk0 - yuk0 / 2, "yükün yarısı araçta kaldı")
	dogru(b.dusen_sandiklar.size() == 1, "diğer yarısı yerinde sandık oldu")
	dogru(Vector2i(b.dusen_sandiklar[0]["h"]) == Vector2i(20, 70), "sandık düşülen yerde")
	var once := b.yuk_toplam()
	b.sandik_al(0)
	dogru(b.yuk_toplam() > once and b.dusen_sandiklar.is_empty(), "sandık geri alındı")

	# Kapasite dolarsa sandıkta kalan kısım korunur
	var c := Durum.new(1)
	c.dusen_sandiklar.append({"h": Vector2i(5, 50), "yuk": {Ayarlar.BAKIR: 99}, "bonus": 0})
	c.sandik_al(0)
	dogru(c.yuk_dolu() and c.dusen_sandiklar.size() == 1, "yük dolunca kalanı sandıkta kalır")

	# Çekme ücreti derinlikle artar
	dogru(c.cekme_ucreti(200) > c.cekme_ucreti(50), "çekme ücreti derinlikle artar")

# --- yakıt ve can ---------------------------------------------------------

func _yakit_can_testleri() -> void:
	print("- yakıt, yük ve can")
	var d := Durum.new(7)
	dogru(d.yakit == d.yakit_kapasitesi(), "koşu dolu depoyla başlar")
	dogru(d.can == d.can_kapasitesi() and d.can > 0, "araç tam canla başlar")
	d.yakit_harca(d.yakit_kapasitesi() * 0.5)
	dogru(not d.bitti, "yarı yakıtta koşu sürer")
	d.yakit_harca(1000.0)
	dogru(d.yakit == 0.0 and d.bitti, "yakıt 0 → koşu biter")

	var h := Durum.new(7)
	h.hasar_al(1)
	dogru(h.can == h.can_kapasitesi() - 1 and not h.bitti, "hasar canı düşürür")
	h.hasar_al(99)
	dogru(h.can == 0 and h.bitti, "can 0 → koşu biter")
	h.onar()
	dogru(h.can == h.can_kapasitesi(), "onarım canı doldurur")

	var y := Durum.new(7)
	for i in y.yuk_kapasitesi():
		y.maden_ekle(Ayarlar.BAKIR)
	dogru(y.yuk_dolu(), "kapasite kadar maden yükü doldurdu")
	dogru(not y.maden_ekle(Ayarlar.ALTIN), "yük doluyken maden eklenmez")
	dogru(not y.maden_ekle(Ayarlar.TAS), "maden olmayan karo yüke girmez")

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

# --- eserler / müze -------------------------------------------------------

func _eser_testleri() -> void:
	print("- eserler ve müze")
	var d := Durum.new(1)
	var matkap0 := d.matkap_hizi()
	var yakit0 := d.yakit_kapasitesi()
	dogru(is_equal_approx(d.eser_bonus("matkap"), 0.0), "eser yokken bonus yok")
	d.eserler.append(0)   ## Kırık Pusula: matkap +%5
	dogru(d.matkap_hizi() > matkap0, "eser matkap hızını kalıcı artırdı")
	d.eserler.append(2)   ## Kadim Depo Kapağı: yakıt +%8
	dogru(d.yakit_kapasitesi() > yakit0, "eser yakıt kapasitesini kalıcı artırdı")
	var hepsi := true
	for e in Ayarlar.ESERLER:
		if not ["matkap", "deger", "yakit", "yuk", "cekme"].has(String(e["bonus"])):
			hepsi = false
	dogru(hepsi, "her eserin tanınan bir bonus türü var")

# --- kayıt ----------------------------------------------------------------

func _kayit_testleri() -> void:
	print("- kayıt gidiş-dönüş")
	var k := Durum.new(4242)
	k.para = 1234
	k.matkap = 2
	k.depo = 1
	k.kasa = 3
	k.govde = 2
	k.dinamit = 5
	k.istasyon_kiti = 1
	k.aletler["radar"] = true
	k.eserler = [0, 3]
	k.istasyonlar = [Vector2i(9, 60), Vector2i(11, 140)]
	k.dusen_sandiklar = [{"h": Vector2i(7, 88), "yuk": {Ayarlar.DEMIR: 3}, "bonus": 12}]
	k.cekirdek_bulundu = true

	var y := Durum.new(0)
	y.sozlukten(k.sozluge())
	dogru(y.tohum == k.tohum and y.para == k.para, "tohum ve para korunuyor")
	dogru(y.matkap == 2 and y.depo == 1 and y.kasa == 3 and y.govde == 2, "geliştirme seviyeleri korunuyor")
	dogru(y.dinamit == 5 and y.istasyon_kiti == 1 and bool(y.aletler["radar"]), "alet ve sarf korunuyor")
	dogru(y.eserler == [0, 3], "eserler korunuyor")
	dogru(y.istasyonlar.size() == 2 and Vector2i(y.istasyonlar[1]) == Vector2i(11, 140),
		"istasyonlar korunuyor")
	dogru(y.dusen_sandiklar.size() == 1
		and Vector2i(y.dusen_sandiklar[0]["h"]) == Vector2i(7, 88)
		and int(y.dusen_sandiklar[0]["yuk"][Ayarlar.DEMIR]) == 3
		and int(y.dusen_sandiklar[0]["bonus"]) == 12, "düşen sandık korunuyor")
	dogru(y.cekirdek_bulundu, "çekirdek bulundu bayrağı korunuyor")

	# Kazılan hücreler: oyun kapanıp açılınca tüneller durmalı
	var kazilan := {Vector2i(3, 9): true, Vector2i(3, 10): true, Vector2i(4, 10): true}
	var dizi := PackedInt32Array()
	for h in kazilan:
		dizi.append(h.x)
		dizi.append(h.y)
	var geri := Dunya.diziden_kazilan(dizi)
	dogru(geri.size() == 3 and geri.has(Vector2i(4, 10)), "kazılan hücreler gidiş-dönüş korunuyor")
	dogru(Dunya.diziden_kazilan(null).is_empty(), "kayıt yoksa kazılan hücre listesi boş")
	dogru(Dunya.parca_no(Vector2i(17, 33)) == Vector2i(1, 2), "chunk numarası 16x16 ızgarada doğru")


# --- garantili fay hattı --------------------------------------------------

func _fay_testleri() -> void:
	print("- fay hattı (dünya her tohumda bitirilebilir)")
	var u := DunyaUretici.new(4242)

	# Koridor kopmamalı: satır başına en fazla 1 karo kayabilir.
	var en_buyuk_adim := 0
	for y in range(0, Ayarlar.CEKIRDEK_DERINLIK):
		en_buyuk_adim = maxi(en_buyuk_adim, absi(u.fay_x(y + 1) - u.fay_x(y)))
	dogru(en_buyuk_adim <= 1, "fay koridoru satır başına en fazla 1 karo kayıyor (%d)"
		% en_buyuk_adim)

	# Koridorun içinde asla kazılamaz kaya ya da lav olmamalı — 12 tohumda.
	# (Bir tohumda bakmak yetmez: garanti "her tohumda" iddiasında bulunuyor.)
	var tohumlar := [11, 4242, 90210, 1337, 7, 555000, 20260916, 1, 2, 3, 999999, 123456]
	var engel := 0
	for tohum in tohumlar:
		var uu := DunyaUretici.new(tohum)
		for y in range(Ayarlar.KAPALI_UST, Ayarlar.CEKIRDEK_DERINLIK):
			for dx in range(-DunyaUretici.FAY_YARICAP, DunyaUretici.FAY_YARICAP + 1):
				var t := uu.karo(uu.fay_x(y) + dx, y)
				if t == Ayarlar.KAYA or t == Ayarlar.LAV:
					engel += 1
	dogru(engel == 0, "12 tohumun fay koridorunda kazılamaz engel yok (%d)" % engel)
	dogru(u.fay_x(0) == Ayarlar.US_KARO_X, "koridor üssün altından başlıyor (%d)" % u.fay_x(0))
	dogru(absi(u.fay_x(Ayarlar.CEKIRDEK_DERINLIK) - u.cekirdek_x) <= DunyaUretici.FAY_YARICAP,
		"koridor çekirdek sütununda bitiyor (%d ~ %d)"
		% [u.fay_x(Ayarlar.CEKIRDEK_DERINLIK), u.cekirdek_x])

	# Yüzeyden çekirdeğe kazılabilir yol 12 tohumda da var. NOT: bu, fay hattı
	# KAPALIYKEN de geçiyor (tests/test_fay_olcum.gd ölçtü) — dünya üretimi zaten
	# bitirilemez bir dünya üretmiyordu. Fay hattı yolu VAR yapmıyor, aşağı kazan
	# bir oyuncunun BULABİLECEĞİ yer yapıyor.
	var basarisiz := PackedInt32Array()
	for tohum in tohumlar:
		var uu2 := DunyaUretici.new(tohum)
		if not _ulasilabilir(uu2).has(Vector2i(uu2.cekirdek_x, Ayarlar.CEKIRDEK_DERINLIK)):
			basarisiz.append(tohum)
	dogru(basarisiz.is_empty(), "12 tohumun hepsinde çekirdeğe yol var (%s)"
		% ("hepsi tamam" if basarisiz.is_empty() else str(basarisiz)))

# --- deprem (canlı yeraltı) -----------------------------------------------

func _deprem_testleri() -> void:
	print("- deprem")
	var u := DunyaUretici.new(4242)
	# Üsten aşağı düz bir şaft + yanlara birkaç galeri: sahte bir "oynanmış" dünya.
	var kazilan := {}
	for y in range(Ayarlar.KAPALI_UST, 120):
		for dx in range(-2, 3):
			kazilan[Vector2i(Ayarlar.US_KARO_X + dx, y)] = true
	var karo := func(h: Vector2i) -> int:
		return Ayarlar.BOS if kazilan.has(h) else u.karo(h.x, h.y)

	var arac := Vector2i(Ayarlar.US_KARO_X, 100)
	var istasyonlar := [Vector2i(Ayarlar.US_KARO_X, 60)]
	var korunan := Deprem.korunan_hucreler(istasyonlar, arac)
	var s := Deprem.hesapla(kazilan, karo, korunan, 4242, 1)
	var kapanan: Array = s["kapanan"]
	var yeni: Dictionary = s["yeni"]

	dogru(kapanan.size() > 0, "deprem eski tünellerin bir kısmını kapattı (%d karo)"
		% kapanan.size())
	dogru(float(kapanan.size()) / float(kazilan.size()) < 0.5,
		"tünelin yarısından azı kapandı (%.0f%%)"
		% (100.0 * float(kapanan.size()) / float(kazilan.size())))

	# 1. kural: kapanan her hücre KAZILABİLİR bir karoyla dolar — oyuncu asla
	# kapalı bir boşlukta sıkışmaz, her zaman kendini dışarı kazabilir.
	var kazilamaz := 0
	for h in kapanan:
		if float(Ayarlar.SERTLIK.get(int(yeni[h]), -1.0)) <= 0.0:
			kazilamaz += 1
	dogru(kazilamaz == 0, "kapanan hücreler kazılabilir kayayla doluyor (%d istisna)" % kazilamaz)

	# 2. kural: araç, üs ve istasyon çevresi korunur.
	var ihlal := 0
	for m in korunan:
		for dy in range(-Deprem.KORUMA, Deprem.KORUMA + 1):
			for dx in range(-Deprem.KORUMA, Deprem.KORUMA + 1):
				var h: Vector2i = Vector2i(m) + Vector2i(dx, dy)
				if kapanan.has(h) or yeni.has(h):
					ihlal += 1
	dogru(ihlal == 0, "araç/üs/istasyon çevresine dokunulmadı (%d ihlal)" % ihlal)

	# 3. kural: yüzey (üs) hiç etkilenmez.
	var sig := 0
	for h in kapanan:
		if h.y < Deprem.EN_SIG:
			sig += 1
	dogru(sig == 0, "yüzeydeki ilk %d m korunuyor" % Deprem.EN_SIG)

	# Yeni gaz cebi ve damar çıkmalı.
	var gaz := 0
	var maden := 0
	for h in yeni:
		if int(yeni[h]) == Ayarlar.GAZ:
			gaz += 1
		elif Ayarlar.MADEN_DEGER.has(int(yeni[h])):
			maden += 1
	dogru(gaz > 0, "yeni gaz cebi çıktı (%d)" % gaz)
	dogru(maden > 0, "yeni maden damarı çıktı (%d)" % maden)

	# Belirlenimcilik: aynı girdi = aynı deprem, farklı numara = farklı deprem.
	var s2 := Deprem.hesapla(kazilan, karo, korunan, 4242, 1)
	var s3 := Deprem.hesapla(kazilan, karo, korunan, 4242, 2)
	dogru(Array(s2["kapanan"]) == kapanan, "aynı deprem numarası aynı sonucu veriyor")
	dogru(Array(s3["kapanan"]) != kapanan, "sonraki deprem başka hücreleri kapatıyor")
	dogru(Deprem.ARALIK == 5, "deprem her 5 seferde bir")

	# --- oyuncunun kararı (v0.4) ---
	# Uyarı derinlikle uzuyor ki karar verilebilsin, ama tavanı var.
	dogru(Deprem.uyari_suresi(200) > Deprem.uyari_suresi(20),
		"uyarı derinde daha uzun (%.1f > %.1f sn)"
		% [Deprem.uyari_suresi(200), Deprem.uyari_suresi(20)])
	dogru(Deprem.uyari_suresi(2000) <= Deprem.UYARI_EN_COK,
		"uyarı süresinin tavanı var (%.1f sn)" % Deprem.uyari_suresi(2000))
	dogru(Deprem.uyari_suresi(0) >= 3.0, "en sığda bile uyarı var (%.1f sn)" % Deprem.uyari_suresi(0))

	var yuzeyde := Deprem.karar(120, 4)
	var derinde := Deprem.karar(120, 120)
	dogru(bool(yuzeyde["guvende"]) and int(yuzeyde["odul"]) > 0 and int(yuzeyde["hasar"]) == 0,
		"yüzeye çıkan ikramiye alır, hasar almaz (+%d ₺)" % int(yuzeyde["odul"]))
	dogru(not bool(derinde["guvende"]) and int(derinde["hasar"]) > 0 and int(derinde["odul"]) == 0,
		"derinde kalan hasar alır, ikramiye almaz (-%d can)" % int(derinde["hasar"]))
	dogru(Deprem.odul(200) > Deprem.odul(40),
		"ikramiye derinlikle büyüyor (%d > %d ₺)" % [Deprem.odul(200), Deprem.odul(40)])
	dogru(Deprem.hasar(220) > Deprem.hasar(20),
		"risk derinlikle büyüyor (%d > %d can)" % [Deprem.hasar(220), Deprem.hasar(20)])
	# Karar ölümcül olmasın: en derinde bile en zayıf gövde hayatta kalır.
	dogru(Deprem.hasar(Ayarlar.CEKIRDEK_DERINLIK) < int(Ayarlar.GOVDE_SEVIYE[0]),
		"en derin deprem bile tek başına öldürmez (%d < %d can)"
		% [Deprem.hasar(Ayarlar.CEKIRDEK_DERINLIK), int(Ayarlar.GOVDE_SEVIYE[0])])
	dogru(Deprem.GUVENLI_DERINLIK >= Deprem.EN_SIG,
		"güvenli bant depremin dokunmadığı yüzey bandının içinde")

	# Dünya üstünde uygulanınca kayıt gidiş-dönüşü de korunmalı.
	var dd := Dunya.new()
	dd.kur(4242, kazilan)
	dd.degistir(kapanan, yeni)
	var geri := Dunya.diziden_eklenen(dd.eklenen_dizi())
	dogru(geri.size() == yeni.size(), "deprem farkı kayıtta gidiş-dönüş korunuyor")
	var ilk: Vector2i = kapanan[0]
	dogru(dd.karo_tur(ilk) != Ayarlar.BOS, "kapanan hücre artık dolu")
	dogru(dd.kazilabilir_mi(dd.karo_tur(ilk)), "kapanan hücre yeniden kazılabilir")
	dd.free()

# --- ipucu (dokunmatik / masaüstü) ----------------------------------------

func _ipucu_testleri() -> void:
	print("- oyun içi ipucu")
	# v0.3 kusuru: telefonda alt ipucu "E — Üs • T — ışınlanma • M — harita"
	# yazıyordu; o tuşlar dokunmatik cihazda yok.
	var tuslar := ["E — Üs", "T ile", "M — harita", "W ile", "S / ↓", "E'ye bas"]
	var d := Durum.new(1)
	var masa_us := Ipucu.metin(d, 0, true, false)
	var dokun_us := Ipucu.metin(d, 0, true, true)
	dogru(masa_us.contains("E — Üs") and masa_us.contains("M — harita"),
		"masaüstü ipucu tuşları anlatıyor (değişmedi)")
	dogru(dokun_us.contains(Ipucu.DUGME_US) and dokun_us.contains(Ipucu.DUGME_HARITA),
		"dokunmatik ipucu düğmeleri anlatıyor")

	# Bütün ipucu durumlarını gez: dokunmatik metinlerin hiçbirinde tuş geçmemeli.
	var durumlar := []
	durumlar.append([Durum.new(1), 0, true])                    ## üste
	var yeni := Durum.new(1)
	durumlar.append([yeni, 1, false])                           ## ilk kazı
	var yuklu := Durum.new(1)
	yuklu.en_derin = 10
	yuklu.maden_ekle(Ayarlar.BAKIR)
	durumlar.append([yuklu, 12, false])                         ## madeni sat
	var yakitsiz := Durum.new(1)
	yakitsiz.en_derin = 60
	yakitsiz.yakit = 1.0
	durumlar.append([yakitsiz, 60, false])                      ## yakıt azaldı
	var yarali := Durum.new(1)
	yarali.en_derin = 60
	yarali.can = 1
	durumlar.append([yarali, 60, false])                        ## can azaldı
	var dolu := Durum.new(1)
	dolu.en_derin = 60
	for i in 40:
		dolu.maden_ekle(Ayarlar.PLATIN)
	durumlar.append([dolu, 60, false])                          ## yük dolu
	var kacan := Durum.new(1)
	kacan.kacis = true
	durumlar.append([kacan, 240, false])                        ## kaçış

	var sizan := ""
	var bos := 0
	for veri in durumlar:
		var m := Ipucu.metin(veri[0], int(veri[1]), bool(veri[2]), true)
		if m == "":
			bos += 1
		for t in tuslar:
			if m.contains(t):
				sizan += "%s | " % m
	dogru(sizan == "", "dokunmatik ipuçlarında klavye tuşu yok (%s)" % sizan)
	dogru(bos == 0, "her durumun bir dokunmatik ipucu var (%d boş)" % bos)

	# Deprem geri sayımı: karar HUD'da okunabilir olsun.
	var sig := Ipucu.deprem_metni(3.0, 4, false)
	var derin := Ipucu.deprem_metni(9.0, 150, false)
	dogru(sig.contains("DEPREM") and sig.contains("güvende"),
		"yüzeydeyken geri sayım güvende olduğunu söylüyor")
	dogru(derin.contains("%d" % Deprem.odul(150)) and derin.contains("%d" % Deprem.hasar(150)),
		"derinde geri sayım hem ödülü hem riski yazıyor (%s)" % derin)
	dogru(not Ipucu.deprem_metni(9.0, 150, true).contains("W ile"),
		"dokunmatik geri sayımda klavye tuşu yok")

# --- karo varyantları -----------------------------------------------------

func _varyant_testleri() -> void:
	print("- karo varyantları")
	dogru(Ayarlar.VARYANT_SAYISI >= 2, "en az 2 varyant tanımlı (%d)" % Ayarlar.VARYANT_SAYISI)
	dogru(Ayarlar.varyant(5, 9, Ayarlar.TOPRAK) == Ayarlar.varyant(5, 9, Ayarlar.TOPRAK),
		"varyant seçimi belirlenimci (aynı hücre = aynı doku)")
	var dagilim := {}
	for x in 40:
		for y in 40:
			var v := Ayarlar.varyant(x, y, Ayarlar.TAS)
			dagilim[v] = int(dagilim.get(v, 0)) + 1
	dogru(dagilim.size() == Ayarlar.VARYANT_SAYISI,
		"bütün varyantlar kullanılıyor (%d tür)" % dagilim.size())
	var en_az := 1 << 30
	for v in dagilim:
		en_az = mini(en_az, int(dagilim[v]))
	dogru(en_az > 1600 / (Ayarlar.VARYANT_SAYISI * 3),
		"varyantlar dengeli dağılıyor (en seyreği %d/1600)" % en_az)
	for t in [Ayarlar.GAZ, Ayarlar.KAYA, Ayarlar.CEKIRDEK, Ayarlar.ESER, Ayarlar.GEVSEK]:
		dogru(Ayarlar.varyant(3, 7, t) == 0, "tehlike karosunun varyantı yok (%d)" % t)
	# Maden damarının satırı = KATMAN: zemini o derinliğin taban kayası olsun diye.
	# v0.3'te toprak katmanındaki bakır damarı mavi-gri bir kare gibi duruyordu.
	dogru(Ayarlar.VARYANT_SAYISI == Ayarlar.KATMANLAR.size(),
		"varyant satırı sayısı katman sayısıyla aynı (%d)" % Ayarlar.VARYANT_SAYISI)
	var maden_satiri := true
	for y in [5, 60, 120, 180, 240]:
		for t2 in Ayarlar.MADEN_DEGER:
			if Ayarlar.varyant(9, y, t2) != Ayarlar.katman(y):
				maden_satiri = false
	dogru(maden_satiri, "maden damarı bulunduğu katmanın satırından çiziliyor")
	dogru(Ayarlar.varyant(9, 5, Ayarlar.BAKIR) != Ayarlar.varyant(9, 180, Ayarlar.BAKIR),
		"aynı maden sığda ve derinde farklı zeminle çiziliyor")
	var atlas: Texture2D = load("res://assets/sprites/karolar.png")
	dogru(atlas != null and atlas.get_height() == Ayarlar.KARO * Ayarlar.VARYANT_SAYISI,
		"karolar.png %d satır içeriyor (%d px)"
		% [Ayarlar.VARYANT_SAYISI, 0 if atlas == null else atlas.get_height()])

# --- tohum kodu -----------------------------------------------------------

func _tohum_kodu_testleri() -> void:
	print("- tohum kodu")
	dogru(TohumKodu.ALFABE.length() == 32, "alfabe 32 harf (%d)" % TohumKodu.ALFABE.length())
	var karisan := ""
	for ch in "IO01":
		if TohumKodu.ALFABE.contains(ch):
			karisan += ch
	dogru(karisan == "", "karışan harfler alfabede yok (%s)" % karisan)

	var hepsi := true
	var uzunluk := true
	for t in [0, 1, 4242, 90210, 2147483647, 4294967295, 20260916]:
		var kod := TohumKodu.kodla(t)
		if kod.length() != TohumKodu.UZUNLUK:
			uzunluk = false
		if TohumKodu.coz(kod) != t:
			hepsi = false
	dogru(uzunluk, "kod hep %d karakter" % TohumKodu.UZUNLUK)
	dogru(hepsi, "tohum → kod → tohum gidiş-dönüş korunuyor")

	var farkli := TohumKodu.kodla(11) != TohumKodu.kodla(12)
	dogru(farkli, "farklı tohum farklı kod")
	dogru(TohumKodu.coz("ABC") == TohumKodu.GECERSIZ, "kısa kod geçersiz")
	dogru(TohumKodu.coz("ABCDEFI") == TohumKodu.GECERSIZ, "alfabe dışı harf geçersiz")
	# Tek harf değişince sağlama tutmamalı (kodun sessizce başka dünya açmaması).
	var dogru_kod := TohumKodu.kodla(4242)
	var bozuk := 0
	var deneme := 0
	for i in dogru_kod.length():
		for ch in TohumKodu.ALFABE:
			if ch == dogru_kod[i]:
				continue
			deneme += 1
			if TohumKodu.coz(dogru_kod.substr(0, i) + ch + dogru_kod.substr(i + 1)) == TohumKodu.GECERSIZ:
				bozuk += 1
	dogru(float(bozuk) / float(deneme) > 0.8,
		"tek harf hatasının %%%.0f'i yakalanıyor" % (100.0 * float(bozuk) / float(deneme)))
	dogru(TohumKodu.suz("a-b c!1d") == "ABCD", "giriş süzgeci alfabeye indirgiyor (%s)"
		% TohumKodu.suz("a-b c!1d"))

	# Günlük tohum: aynı gün aynı dünya, başka gün başka dünya.
	dogru(Kayit.gunluk_tohum("2026-09-16") == Kayit.gunluk_tohum("2026-09-16"),
		"günlük tohum aynı gün için sabit")
	dogru(Kayit.gunluk_tohum("2026-09-16") != Kayit.gunluk_tohum("2026-09-17"),
		"günlük tohum her gün değişiyor")
	dogru(Kayit.bugun().length() == 10, "bugün etiketi YYYY-AA-GG (%s)" % Kayit.bugun())

# --- Derin Mod ------------------------------------------------------------

func _derin_mod_testleri() -> void:
	print("- Derin Mod")
	var a := Durum.new(7)
	var b := Durum.new(7)
	b.derin_seviye = 2
	dogru(b.matkap_hizi() < a.matkap_hizi(), "Derin Mod'da kaya daha sert (%.2f < %.2f)"
		% [b.matkap_hizi(), a.matkap_hizi()])
	dogru(b.maden_degeri(Ayarlar.BAKIR) > a.maden_degeri(Ayarlar.BAKIR),
		"Derin Mod'da maden daha değerli")
	var ya := a.yakit
	var yb := b.yakit
	a.yakit_harca(10.0)
	b.yakit_harca(10.0)
	dogru((yb - b.yakit) > (ya - a.yakit), "Derin Mod'da yakıt daha hızlı bitiyor")

	# Eser bonusları korunur: Derin Mod turu eserleri taşır.
	var c := Durum.new(9)
	c.derin_seviye = 1
	c.eserler = [0, 5]
	dogru(c.eser_bonus("matkap") > 0.0, "Derin Mod'da eser bonusu duruyor")
	# Kayıt gidiş-dönüşü
	var d := Durum.new(3)
	d.sozlukten(b.sozluge())
	dogru(d.derin_seviye == 2, "Derin Mod seviyesi kayıtta korunuyor")
	b.sefer = 12
	b.deprem = 2
	b.deprem_bekliyor = true
	var e := Durum.new(0)
	e.sozlukten(b.sozluge())
	dogru(e.sefer == 12 and e.deprem == 2 and e.deprem_bekliyor,
		"sefer ve deprem sayaçları kayıtta korunuyor")

# --- simge yazı tipi ------------------------------------------------------

func _simge_testleri() -> void:
	print("- simge yazı tipi (web'de kutu çıkmasın)")
	var kullanilan := "₺←↑→↓▲▶▼◀✔■•—…"
	dogru(ResourceLoader.exists(Simgeler.YOL), "simgeler.ttf projede")
	dogru(FileAccess.file_exists("res://assets/fonts/LISANS-simgeler.txt"),
		"yazı tipi lisansı yanında duruyor")
	Simgeler.kur()
	var eksik := Simgeler.eksikler(kullanilan)
	dogru(eksik == "", "oyunda geçen bütün simgeler yazı tipi zincirinde (eksik: '%s')" % eksik)
	dogru(ThemeDB.fallback_font.has_char(0x20BA), "₺ (U+20BA) çiziliyor")
	dogru(ThemeDB.fallback_font.has_char(0x25A0), "■ (U+25A0) çiziliyor")

## Yüzeyden başlayıp kazılabilir/boş hücreler üzerinden genişleyen erişim kümesi.
func _ulasilabilir(u: DunyaUretici) -> Dictionary:
	var gorulen := {}
	var sira: Array[Vector2i] = [Vector2i(Ayarlar.US_KARO_X, 0)]
	gorulen[sira[0]] = true
	while not sira.is_empty():
		var h: Vector2i = sira.pop_back()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var k := h + d
			if k.x < 1 or k.y < 0 or k.x >= Ayarlar.GENISLIK - 1 or k.y >= Ayarlar.DERINLIK:
				continue
			if gorulen.has(k):
				continue
			var t := u.karo(k.x, k.y)
			if t == Ayarlar.KAYA or t == Ayarlar.LAV:
				continue
			gorulen[k] = true
			sira.append(k)
	return gorulen
