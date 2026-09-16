## Bot simülasyonu — gerçek dünya üreticisi ve gerçek ekonomiyle bir "oyuncu".
##
## Şafttan in, yol üstündeki madenleri topla, yakıt/yük sınırına gelince dön, sat,
## bir geliştirme al, tekrarla. İki ayarla çalışır:
##   Bot.MUKEMMEL  — duraksamayan, hata yapmayan robot. Ekonominin EĞRİSİNİ ölçer.
##   Bot.INSAN     — tepki gecikmesi, duraksama ve yanlış rota olasılığı olan oyuncu.
##                   "İlk 10 dakika" ve "çekirdeğe kaç dakikada varılır" bununla ölçülür.
##
## Bot ölçümü bir insanı TEMSİL ETMEZ; insana benzetilmiş bot da bir varsayımdır.
## Ölçülen şey oyunun eğlenceli olup olmadığı değil, sayıların tuttuğu banttır.
class_name Bot
extends RefCounted

const DUSUS_HIZ := 150.0        ## açık tünelde serbest iniş (px/sn)
const GUVENLIK := 1.25          ## dönüş yakıtı payı
const YAN_TARAMA := 2           ## kaç karo yandaki madene sapılır
const EN_COK_TUR := 400

## Kusursuz bot: her karar anında doğru, hiç duraksamıyor.
const MUKEMMEL := {
	"carpan": 1.0, "duraksama_sans": 0.0, "duraksama_sure": 0.0,
	"yanlis_rota": 0.0, "us_sure": 8.0, "karar": 0.0,
}

## İnsana benzetilmiş bot. Sayıların gerekçesi:
##   carpan 1.30        — tuşa basma/bırakma gecikmesi, hedefi tam tutturamama
##   karar 0.35 sn      — her yön değişiminde "nereye?" duraksaması
##   duraksama %7 / 1,1 sn — HUD'a bakma, yakıt hesabı, dikkat dağılması
##   yanlis_rota %12    — boşa kazılan bir karo (maden sandı, kör tünel açtı)
##   us_sure 22 sn      — üs menüsünde gezinme, okuma, karar verme
const INSAN := {
	"carpan": 1.30, "duraksama_sans": 0.07, "duraksama_sure": 1.1,
	"yanlis_rota": 0.12, "us_sure": 22.0, "karar": 0.35,
}

var _u: DunyaUretici
var _d: Durum
var _kazilan := {}
var _rng := RandomNumberGenerator.new()
var _ayar := {}

## Tek bir tohumu baştan sona simüle eder. Dönüş: ölçüm sözlüğü.
static func calistir(tohum: int, ayar: Dictionary) -> Dictionary:
	var b := Bot.new()
	return b._simule(tohum, ayar)

func _carpan() -> float:
	return float(_ayar.get("carpan", 1.0))

## Yön/karar değiştirme duraksaması.
func _karar() -> float:
	return float(_ayar.get("karar", 0.0))

## Kazılan her karodan sonraki insan gürültüsü: duraksama + boşa kazılan karo.
func _gurultu(x: int, y: int) -> float:
	var s := 0.0
	if _rng.randf() < float(_ayar.get("duraksama_sans", 0.0)):
		s += float(_ayar.get("duraksama_sure", 0.0))
	if _rng.randf() < float(_ayar.get("yanlis_rota", 0.0)):
		# Yanlış rota: yandaki karoyu boşuna kazar (maden sandı ya da kör tünel).
		var nx := x + (1 if _rng.randf() < 0.5 else -1)
		var t := _karo(nx, y)
		if t != Ayarlar.KAYA and t != Ayarlar.LAV and t != Ayarlar.CEKIRDEK:
			s += _kaz(nx, y, t)
			s += float(Ayarlar.KARO) / Ayarlar.YATAY_HIZ * _carpan()
	return s

# --- simülasyon -----------------------------------------------------------

func _simule(tohum: int, ayar: Dictionary) -> Dictionary:
	_ayar = ayar
	_u = DunyaUretici.new(tohum)
	_d = Durum.new(tohum)
	_kazilan = {}
	_rng.seed = hash(Vector2i(tohum, 99991))
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
	var us_sure := float(_ayar.get("us_sure", 8.0))

	for tur in range(1, EN_COK_TUR + 1):
		_d.can = _d.can_kapasitesi()
		_d.yuk.clear()
		_d.yuk_bonus = 0
		_d.zincir_tur = Ayarlar.BOS
		_d.zincir_adet = 0
		var tur_sure := 0.0
		var y := 0

		# 1) Yakıtın el verdiği çalışma derinliğini seç (oyuncu da parası azken
		#    dibe inmez, sığda çalışır), sonra var olan tünelden in.
		var hedef_y := _calisma_derinligi(tunel)
		var us := _en_yakin_istasyon(mini(tunel, hedef_y))
		if us > 0:
			y = us
			tur_sure += 2.0
			_d.yakit -= Ayarlar.ISINLAMA_YAKIT
		var inis := float(maxi(hedef_y - y, 0)) * Ayarlar.KARO / DUSUS_HIZ * _carpan()
		tur_sure += inis
		_d.yakit -= Ayarlar.YAKIT_BOSTA * inis
		y = hedef_y

		# 2) Aşağı kaz. Altı kazılamazsa yana tünel açar; 250 m'ye yaklaşınca
		#    çekirdek sütununa yanaşır (HUD oyuncuya da yönü söylüyor).
		var kapi := hedef_y < tunel   ## şaftın dibine inemedi: bu katmanda çalış
		var tikanma := 0
		var yon := 1
		for adim in 4000:
			if y + 1 >= Ayarlar.DERINLIK - 1:
				break
			if not _d.matkap_yeterli_mi(y + 1):
				kapi = true
				break
			if _d.yakit < float(_donus_maliyeti(y)["yakit"]) * GUVENLIK \
					or _d.yuk_dolu() or _d.can <= 1:
				break

			# Çekirdeğe yaklaşırken sütunu hizala.
			if y >= Ayarlar.CEKIRDEK_DERINLIK - 12 and x != _u.cekirdek_x:
				var sx := x + signi(_u.cekirdek_x - x)
				var st := _karo(sx, y)
				if st != Ayarlar.KAYA and st != Ayarlar.LAV:
					tur_sure += _kaz(sx, y, st)
					tur_sure += float(Ayarlar.KARO) / Ayarlar.YATAY_HIZ * _carpan()
					x = sx
					continue

			var t := _karo(x, y + 1)
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
				tur_sure += _karar()
				if y > 195 and x != _u.cekirdek_x:
					yon = signi(_u.cekirdek_x - x)
				var nx := x + yon
				if nx <= 2 or nx >= Ayarlar.GENISLIK - 3:
					yon = -yon
					continue
				var yan := _karo(nx, y)
				if yan == Ayarlar.KAYA or yan == Ayarlar.LAV:
					yon = -yon
					continue
				tur_sure += _kaz(nx, y, yan)
				tur_sure += float(Ayarlar.KARO) / Ayarlar.YATAY_HIZ * _carpan()
				x = nx
				continue

			tikanma = 0
			tur_sure += _kaz(x, y + 1, t)
			y += 1
			tunel = maxi(tunel, y)
			# 3) Yanda maden varsa sap, sonra insan gürültüsü.
			tur_sure += _yan_maden(x, y)
			tur_sure += _gurultu(x, y)

		# 3b) Kapıya takıldıysa bu katmanda yatay galeri aç (oyuncu da bunu yapar:
		#     derine inemiyorsan bulunduğun katmanı tara).
		if kapi:
			tur_sure += _yatay_galeri(x, y)

		# 4) Dönüş.
		var don := _donus_maliyeti(y)
		tur_sure += float(don["sure"]) * _carpan()
		_d.yakit -= float(don["yakit"])
		_d.en_derin = maxi(_d.en_derin, y)

		# 5) Sat, yakıt al, geliştir.
		var kazanc := _d.sat()
		_d.yakit_doldur()
		var alinan := _gelistir(y)
		toplam_gelistirme += alinan
		zaman += tur_sure + us_sure

		turlar.append({"no": tur, "sure": tur_sure, "derinlik": y,
			"kazanc": kazanc, "gelistirme": alinan, "para": _d.para})
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
		"tohum": tohum,
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
		"kazilan": _kazilan.size(),
	}

func _karo(x: int, y: int) -> int:
	if _kazilan.has(Vector2i(x, y)):
		return Ayarlar.BOS
	return _u.karo(x, y)

## Bir karoyu kazar: süreyi döner, yakıtı ve yükü günceller.
func _kaz(x: int, y: int, t: int) -> float:
	if t == Ayarlar.BOS:
		return float(Ayarlar.KARO) / DUSUS_HIZ * _carpan()
	var sure := float(Ayarlar.SERTLIK[t]) / _d.matkap_hizi()
	_d.yakit -= (Ayarlar.YAKIT_BOSTA + Ayarlar.YAKIT_KAZMA) * sure
	_kazilan[Vector2i(x, y)] = true
	if Ayarlar.MADEN_DEGER.has(t):
		_d.maden_ekle(t)
	elif t == Ayarlar.GAZ:
		_d.hasar_al(Ayarlar.HASAR_GAZ)
	elif t == Ayarlar.SANDIK:
		_d.para += 70
	return sure * _carpan()

## Aynı derinlikte yandaki madene sapma (zincir çarpanı da buradan besleniyor).
func _yan_maden(x: int, y: int) -> float:
	var sure := 0.0
	for yon: int in [-1, 1]:
		for i in range(1, YAN_TARAMA + 1):
			var hx := x + yon * i
			var t := _karo(hx, y)
			if t == Ayarlar.KAYA or t == Ayarlar.LAV:
				break
			if not Ayarlar.MADEN_DEGER.has(t):
				continue
			if _d.yuk_dolu():
				return sure
			sure += _karar()
			for j in range(1, i + 1):
				var ax := x + yon * j
				sure += _kaz(ax, y, _karo(ax, y))
			sure += float(Ayarlar.KARO) * float(i) / Ayarlar.YATAY_HIZ * _carpan()
			break
	return sure

## Derine inilemiyorken bulunulan katmanda yatay galeri açar: sıra sonuna
## gelince bir üst sıraya geçer (oyuncu da kapıya takılınca katmanı tarar).
func _yatay_galeri(x: int, y: int) -> float:
	var sure := 0.0
	var hx := x
	var hy := y
	var yon := 1
	for i in 3000:
		if _d.yuk_dolu() or _d.can <= 1 or hy < 2:
			break
		if _d.yakit < float(_donus_maliyeti(hy)["yakit"]) * GUVENLIK:
			break
		hx += yon
		if hx <= 2 or hx >= Ayarlar.GENISLIK - 3:
			yon = -yon
			hy -= 1
			hx = clampi(hx, 3, Ayarlar.GENISLIK - 4)
			continue
		var t := _karo(hx, hy)
		if t == Ayarlar.KAYA or t == Ayarlar.LAV or t == Ayarlar.CEKIRDEK:
			continue
		sure += _kaz(hx, hy, t)
		sure += float(Ayarlar.KARO) / Ayarlar.YATAY_HIZ * _carpan()
		sure += _gurultu(hx, hy)
	return sure

## Yakıtın %60'ı kazmaya kalacak şekilde inilebilecek en derin nokta.
func _calisma_derinligi(tunel: int) -> int:
	var en := tunel
	while en > 6:
		if float(_donus_maliyeti(en)["yakit"]) * GUVENLIK <= _d.yakit * 0.6:
			break
		en -= 4
	return maxi(mini(en, tunel), 6)

## En derin istasyonun derinliği (tünelden sığ olanı), yoksa 0.
func _en_yakin_istasyon(tunel: int) -> int:
	var en := 0
	for h in _d.istasyonlar:
		if int(h.y) <= tunel:
			en = maxi(en, int(h.y))
	return en

## Yüzeye (ya da en yakın istasyona) dönüşün süresi ve yakıtı.
func _donus_maliyeti(y: int) -> Dictionary:
	var hedef := 0
	for h in _d.istasyonlar:
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
func _gelistir(y: int) -> int:
	var alinan := 0
	for i in 6:
		# Bir sonraki katmanın kapısı kapalıysa matkap önceliklidir; parası
		# yetmiyorsa BİRİKTİRİR — yoksa oyuncu ucuz geliştirmelere para yatırıp
		# kapının önünde kilitlenir (simülasyonun yakaladığı gerçek tuzak).
		var gereken := Durum.gereken_matkap(mini(y + 2, Ayarlar.CEKIRDEK_DERINLIK))
		if _d.matkap < gereken:
			if _d.satin_al("matkap"):
				alinan += 1
				continue
			break
		# Lav katmanına inmeden ısı kalkanı al.
		if y >= 130 and not _d.alet_var("kalkan") and _d.alet_al("kalkan"):
			continue
		# Derinleştikçe istasyon kur (dönüş angaryasını kısaltır).
		if y >= Ayarlar.ISTASYON_EN_SIG and _d.istasyon_kiti == 0 \
			and _d.istasyon_kurulabilir_derinlik(y) and _d.para > Ayarlar.ISTASYON_FIYAT * 3:
			if _d.istasyon_kiti_al():
				_d.istasyon_kur(Vector2i(Ayarlar.US_KARO_X, y))
				continue
		var en_iyi := ""
		var en_ucuz := 1 << 30
		for alan in ["depo", "kasa", "matkap", "govde"]:
			var f := _d.fiyat(alan)
			if f > 0 and f <= _d.para and f < en_ucuz:
				en_ucuz = f
				en_iyi = alan
		if en_iyi == "" or not _d.satin_al(en_iyi):
			break
		alinan += 1
	return alinan
