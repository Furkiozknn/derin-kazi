## Denge simülasyonu (bot): godot --headless --path . --script res://tests/test_denge.gd
##
## Gerçek dünya üreticisi ve gerçek ekonomi kurallarıyla bir "oyuncu" simüle eder:
## şafttan in, yol üstündeki madenleri topla, yakıt/yük sınırına gelince dön, sat,
## bir geliştirme al, tekrarla. Ölçtüğü şey görev hedefi: "2–4 dk'lık her turda
## ~1 geliştirme" ve rakip analizindeki "ilk 10 dakika" akışı.
##
## Bot ölçümü bir insanı temsil etmez — burada ölçülen şey ekonominin eğrisi,
## oyunun ne kadar eğlenceli olduğu değil.
extends SceneTree

const DUSUS_HIZ := 150.0        ## açık tünelde serbest iniş (px/sn)
const GUVENLIK := 1.25          ## dönüş yakıtı payı
const YAN_TARAMA := 2           ## kaç karo yandaki madene sapılır
const EN_COK_TUR := 400

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
	print("== Denge simülasyonu ==")
	var toplam := {}
	var tohum_sonuc := []
	for tohum in [11, 4242, 90210]:
		var s := _simule(tohum)
		tohum_sonuc.append(s)
		print("\n-- tohum %d --" % tohum)
		_yazdir(s)
		if toplam.is_empty():
			toplam = s.duplicate(true)
		else:
			for anahtar in ["ilk8_ort_sure", "on_dk_derinlik", "on_dk_gelistirme",
					"ilk8_gelistirme", "cekirdek_dk", "tur_sayisi"]:
				toplam[anahtar] = float(toplam[anahtar]) + float(s[anahtar])
	for anahtar in ["ilk8_ort_sure", "on_dk_derinlik", "on_dk_gelistirme",
			"ilk8_gelistirme", "cekirdek_dk", "tur_sayisi"]:
		toplam[anahtar] = float(toplam[anahtar]) / 3.0

	print("\n-- 3 tohum ortalaması --")
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
	# uzun oynar. 60-200 sn'lik bot turu, hedeflenen 2-4 dk'lık insan turudur.
	dogru(float(toplam["ilk8_ort_sure"]) >= 60.0 and float(toplam["ilk8_ort_sure"]) <= 200.0,
		"bot turu 60-200 sn (insan için ~2-4 dk) (%.0f sn)" % float(toplam["ilk8_ort_sure"]))
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
	# Çekirdeğe varış süresi botun yol bulmasına çok bağlı (insanınki değil);
	# burada yalnız "dünya bitirilebiliyor mu" sınanıyor.
	var ulasan := 0
	var en_az_tur := 999
	for t in tohum_sonuc:
		if int(t["cekirdek_tur"]) > 0:
			ulasan += 1
			en_az_tur = mini(en_az_tur, int(t["cekirdek_tur"]))
	dogru(ulasan >= 2, "3 tohumun en az 2'sinde çekirdeğe ulaşıldı (%d)" % ulasan)
	dogru(en_az_tur >= 8, "çekirdek en erken %d. turda (yeterince uzun bir yol)" % en_az_tur)
	print("== %d sınama, %d hata ==" % [_sayac, _hata])
	quit(1 if _hata > 0 else 0)

func _yazdir(s: Dictionary) -> void:
	print("  tur  süre   derinlik  kazanç  gelişt.  para")
	for r in Array(s["turlar"]).slice(0, 10):
		print("  %3d %5.0fs %7d m %7d %7d %7d" % [r["no"], r["sure"], r["derinlik"],
			r["kazanc"], r["gelistirme"], r["para"]])
	print("  ...  çekirdek %d. turda, %.0f dk" % [int(s["tur_sayisi"]), float(s["cekirdek_dk"])])

# --- simülasyon -----------------------------------------------------------

func _simule(tohum: int) -> Dictionary:
	var u := DunyaUretici.new(tohum)
	var d := Durum.new(tohum)
	var kazilan := {}           ## açılmış tünel hücreleri
	var x := Ayarlar.US_KARO_X
	var tunel := 0              ## şaftın ulaştığı derinlik
	var zaman := 0.0
	var turlar := []
	var on_dk := {"derinlik": 0, "gelistirme": 0}
	var toplam_gelistirme := 0
	var cekirdek_zaman := -1.0
	var cekirdek_bulundu := false
	var katman_gelir := {}
	var katman_tur := {}

	for tur in range(1, EN_COK_TUR + 1):
		d.can = d.can_kapasitesi()
		d.yuk.clear()
		d.yuk_bonus = 0
		d.zincir_tur = Ayarlar.BOS
		d.zincir_adet = 0
		var tur_sure := 0.0
		var y := 0

		# 1) Yakıtın el verdiği çalışma derinliğini seç (oyuncu da parası azken
		#    dibe inmez, sığda çalışır), sonra var olan tünelden in.
		var hedef_y := _calisma_derinligi(d, tunel)
		var us := _en_yakin_istasyon(d, mini(tunel, hedef_y))
		if us > 0:
			y = us
			tur_sure += 2.0
			d.yakit -= Ayarlar.ISINLAMA_YAKIT
		var inis := float(maxi(hedef_y - y, 0)) * Ayarlar.KARO / DUSUS_HIZ
		tur_sure += inis
		d.yakit -= Ayarlar.YAKIT_BOSTA * inis
		y = hedef_y

		# 2) Aşağı kaz. Altı kazılamazsa yana tünel açar; 250 m'ye yaklaşınca
		#    çekirdek sütununa yanaşır (HUD oyuncuya da yönü söylüyor).
		var kapi := hedef_y < tunel   ## şaftın dibine inemedi: bu katmanda çalış
		var tikanma := 0
		var yon := 1
		for adim in 4000:
			if y + 1 >= Ayarlar.DERINLIK - 1:
				break
			if not d.matkap_yeterli_mi(y + 1):
				kapi = true
				break
			if d.yakit < float(_donus_maliyeti(d, y)["yakit"]) * GUVENLIK 				or d.yuk_dolu() or d.can <= 1:
				break

			# Çekirdeğe yaklaşırken sütunu hizala.
			if y >= Ayarlar.CEKIRDEK_DERINLIK - 12 and x != u.cekirdek_x:
				var sx := x + signi(u.cekirdek_x - x)
				var st := _karo(u, kazilan, sx, y)
				if st != Ayarlar.KAYA and st != Ayarlar.LAV:
					tur_sure += _kaz(d, kazilan, sx, y, st)
					tur_sure += float(Ayarlar.KARO) / Ayarlar.YATAY_HIZ
					x = sx
					continue

			var t := _karo(u, kazilan, x, y + 1)
			if t == Ayarlar.CEKIRDEK:
				if cekirdek_zaman < 0.0:
					cekirdek_zaman = zaman + tur_sure
				y += 1
				break
			if t == Ayarlar.KAYA or t == Ayarlar.LAV:
				tikanma += 1
				if tikanma > 120:
					kapi = true
					break
				if y > 195 and x != u.cekirdek_x:
					yon = signi(u.cekirdek_x - x)
				var nx := x + yon
				if nx <= 2 or nx >= Ayarlar.GENISLIK - 3:
					yon = -yon
					continue
				var yan := _karo(u, kazilan, nx, y)
				if yan == Ayarlar.KAYA or yan == Ayarlar.LAV:
					yon = -yon
					continue
				tur_sure += _kaz(d, kazilan, nx, y, yan)
				tur_sure += float(Ayarlar.KARO) / Ayarlar.YATAY_HIZ
				x = nx
				continue

			tikanma = 0
			tur_sure += _kaz(d, kazilan, x, y + 1, t)
			y += 1
			tunel = maxi(tunel, y)
			# 3) Yanda maden varsa sap.
			tur_sure += _yan_maden(d, u, kazilan, x, y)

		# 3b) Kapıya takıldıysa bu katmanda yatay galeri aç (oyuncu da bunu yapar:
		#     derine inemiyorsan bulunduğun katmanı tara).
		if kapi:
			tur_sure += _yatay_galeri(d, u, kazilan, x, y)

		# 4) Dönüş.
		var don := _donus_maliyeti(d, y)
		tur_sure += float(don["sure"])
		d.yakit -= float(don["yakit"])
		d.en_derin = maxi(d.en_derin, y)

		# 5) Sat, yakıt al, geliştir.
		var kazanc := d.sat()
		d.yakit_doldur()
		var alinan := _gelistir(d, y)
		toplam_gelistirme += alinan
		zaman += tur_sure + 8.0   ## üste geçen süre

		turlar.append({"no": tur, "sure": tur_sure, "derinlik": y,
			"kazanc": kazanc, "gelistirme": alinan, "para": d.para})
		if kazanc > 0:
			# Dakika başına gelir: tur uzunluğu katmanlar arasında çok değiştiği
			# için ham tur geliri yanıltıcı olur.
			var kat := Ayarlar.katman(y)
			katman_gelir[kat] = float(katman_gelir.get(kat, 0.0)) + float(kazanc)
			katman_tur[kat] = float(katman_tur.get(kat, 0.0)) + tur_sure / 60.0
		if zaman <= 600.0:
			on_dk["derinlik"] = maxi(int(on_dk["derinlik"]), y)
			on_dk["gelistirme"] = toplam_gelistirme
		if cekirdek_zaman >= 0.0:
			cekirdek_bulundu = true
			break

	if cekirdek_zaman < 0.0:
		cekirdek_zaman = zaman

	var ilk8 := Array(turlar).slice(0, 8)
	var ort := 0.0
	var g8 := 0
	for r in ilk8:
		ort += float(r["sure"])
		g8 += int(r["gelistirme"])
	var kat_ort := []
	var kat_sure := []
	for k in Ayarlar.KATMANLAR.size():
		var dk := float(katman_tur.get(k, 0.0))
		kat_sure.append(dk)
		kat_ort.append(float(katman_gelir.get(k, 0.0)) / maxf(dk, 0.01))
	return {
		"katman_gelir": kat_ort,
		"katman_sure": kat_sure,
		"turlar": turlar,
		"tur_sayisi": turlar.size(),
		"ilk8_ort_sure": ort / maxf(float(ilk8.size()), 1.0),
		"ilk8_gelistirme": g8,
		"on_dk_derinlik": on_dk["derinlik"],
		"on_dk_gelistirme": on_dk["gelistirme"],
		"cekirdek_dk": cekirdek_zaman / 60.0,
		"cekirdek_tur": turlar.size() if cekirdek_bulundu else 0,
	}

func _karo(u: DunyaUretici, kazilan: Dictionary, x: int, y: int) -> int:
	if kazilan.has(Vector2i(x, y)):
		return Ayarlar.BOS
	return u.karo(x, y)

## Bir karoyu kazar: süreyi döner, yakıtı ve yükü günceller.
func _kaz(d: Durum, kazilan: Dictionary, x: int, y: int, t: int) -> float:
	if t == Ayarlar.BOS:
		return float(Ayarlar.KARO) / DUSUS_HIZ
	var sure := float(Ayarlar.SERTLIK[t]) / d.matkap_hizi()
	d.yakit -= (Ayarlar.YAKIT_BOSTA + Ayarlar.YAKIT_KAZMA) * sure
	kazilan[Vector2i(x, y)] = true
	if Ayarlar.MADEN_DEGER.has(t):
		d.maden_ekle(t)
	elif t == Ayarlar.GAZ:
		d.hasar_al(Ayarlar.HASAR_GAZ)
	elif t == Ayarlar.SANDIK:
		d.para += 70
	return sure

## Aynı derinlikte yandaki madene sapma (zincir çarpanı da buradan besleniyor).
func _yan_maden(d: Durum, u: DunyaUretici, kazilan: Dictionary, x: int, y: int) -> float:
	var sure := 0.0
	for yon: int in [-1, 1]:
		for i in range(1, YAN_TARAMA + 1):
			var hx := x + yon * i
			var t := _karo(u, kazilan, hx, y)
			if t == Ayarlar.KAYA or t == Ayarlar.LAV:
				break
			if not Ayarlar.MADEN_DEGER.has(t):
				continue
			if d.yuk_dolu():
				return sure
			# araya kalan karoları da kaz
			for j in range(1, i + 1):
				var ax := x + yon * j
				sure += _kaz(d, kazilan, ax, y, _karo(u, kazilan, ax, y))
			sure += float(Ayarlar.KARO) * float(i) / Ayarlar.YATAY_HIZ
			break
	return sure

## Derine inilemiyorken bulunulan katmanda yatay galeri açar: sıra sonuna
## gelince bir üst sıraya geçer (oyuncu da kapıya takılınca katmanı tarar).
func _yatay_galeri(d: Durum, u: DunyaUretici, kazilan: Dictionary, x: int, y: int) -> float:
	var sure := 0.0
	var hx := x
	var hy := y
	var yon := 1
	for i in 3000:
		if d.yuk_dolu() or d.can <= 1 or hy < 2:
			break
		if d.yakit < float(_donus_maliyeti(d, hy)["yakit"]) * GUVENLIK:
			break
		hx += yon
		if hx <= 2 or hx >= Ayarlar.GENISLIK - 3:
			yon = -yon
			hy -= 1
			hx = clampi(hx, 3, Ayarlar.GENISLIK - 4)
			continue
		var t := _karo(u, kazilan, hx, hy)
		if t == Ayarlar.KAYA or t == Ayarlar.LAV or t == Ayarlar.CEKIRDEK:
			continue
		sure += _kaz(d, kazilan, hx, hy, t)
		sure += float(Ayarlar.KARO) / Ayarlar.YATAY_HIZ
	return sure

## Yakıtın %60'ı kazmaya kalacak şekilde inilebilecek en derin nokta.
func _calisma_derinligi(d: Durum, tunel: int) -> int:
	var en := tunel
	while en > 6:
		if float(_donus_maliyeti(d, en)["yakit"]) * GUVENLIK <= d.yakit * 0.6:
			break
		en -= 4
	return maxi(mini(en, tunel), 6)

## En derin istasyonun derinliği (tünelden sığ olanı), yoksa 0.
func _en_yakin_istasyon(d: Durum, tunel: int) -> int:
	var en := 0
	for h in d.istasyonlar:
		if int(h.y) <= tunel:
			en = maxi(en, int(h.y))
	return en

## Yüzeye (ya da en yakın istasyona) dönüşün süresi ve yakıtı.
func _donus_maliyeti(d: Durum, y: int) -> Dictionary:
	var hedef := 0
	for h in d.istasyonlar:
		if int(h.y) <= y:
			hedef = maxi(hedef, int(h.y))
	var mesafe := float(y - hedef) * Ayarlar.KARO
	var sure := mesafe / Ayarlar.TIRMANIS_HIZ
	var yakit := (Ayarlar.YAKIT_BOSTA + Ayarlar.YAKIT_ITKI) * sure
	if hedef > 0:
		yakit += Ayarlar.ISINLAMA_YAKIT
		sure += 2.0
	return {"sure": sure, "yakit": yakit}

## Üste dönünce alınan geliştirmeler. Kapı varsa önce matkap.
func _gelistir(d: Durum, y: int) -> int:
	var alinan := 0
	for i in 6:
		# Bir sonraki katmanın kapısı kapalıysa matkap önceliklidir; parası
		# yetmiyorsa BİRİKTİRİR — yoksa oyuncu ucuz geliştirmelere para yatırıp
		# kapının önünde kilitlenir (simülasyonun yakaladığı gerçek tuzak).
		var gereken := Durum.gereken_matkap(mini(y + 2, Ayarlar.CEKIRDEK_DERINLIK))
		if d.matkap < gereken:
			if d.satin_al("matkap"):
				alinan += 1
				continue
			break
		# Lav katmanına inmeden ısı kalkanı al.
		if y >= 130 and not d.alet_var("kalkan") and d.alet_al("kalkan"):
			continue
		# Derinleştikçe istasyon kur (dönüş angaryasını kısaltır).
		if y >= Ayarlar.ISTASYON_EN_SIG and d.istasyon_kiti == 0 \
			and d.istasyon_kurulabilir_derinlik(y) and d.para > Ayarlar.ISTASYON_FIYAT * 3:
			if d.istasyon_kiti_al():
				d.istasyon_kur(Vector2i(Ayarlar.US_KARO_X, y))
				continue
		var en_iyi := ""
		var en_ucuz := 1 << 30
		for alan in ["depo", "kasa", "matkap", "govde"]:
			var f := d.fiyat(alan)
			if f > 0 and f <= d.para and f < en_ucuz:
				en_ucuz = f
				en_iyi = alan
		if en_iyi == "" or not d.satin_al(en_iyi):
			break
		alinan += 1
	return alinan
