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
const RADAR_TARAMA := 3         ## radar alındıysa bu kadar daha uzağa bakar
const ROTA_TIKANMA := 8         ## bu kadar boşuna denemeden sonra BFS rotasına geçer
const ROTA_PENCERE := 80        ## rota kaç karo aşağıya kadar bakar (mini harita menzili)
const ROTA_YUKARI := 12         ## rota bu kadar karodan fazla yukarı sapmaz
const DINAMIT_DEGER := 2.0      ## dinamit ancak bu kadar saniye kazandırıyorsa atılır
const EN_COK_TUR := 400
## Sisli botun tur başına kaç kez rota hesaplayabildiği. Sis varken ilk rota
## bilinmeyen hücrelerin "sade kaya" varsayımına dayanır; varsayım kırılınca
## (kazılamaz kaya ya da lav çıkınca) yeniden hesaplamak gerekiyor. Sınır
## ölçümün dakikalara çıkmasını engelliyor (BFS tur başına ~17 000 hücre).
const ROTA_EN_COK_SISLI := 3

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

## İnsana benzetilmiş bot + KEŞİF SİSİ: yol bulma yalnız keşfedilmiş hücreleri
## biliyor, keşfedilmemiş olanı "o derinliğin sade kayası" sayıyor. Varsayım
## kırılınca (kaya/lav çıkınca) rota yeniden kuruluyor — yani sis bota da para
## ödetiyor. v0.4'ün bilinen sorunu buydu: "botun BFS'i oyuncunun bilgisinden
## fazlasını görüyor", ölçtüğü şey "oyun bitirilebilir mi"ydi, "oyuncu yolu
## bulabilir mi" değil. v0.5'te ölçülen ana sayı bu bot.
const INSAN_SISLI := {
	"carpan": 1.30, "duraksama_sans": 0.07, "duraksama_sure": 1.1,
	"yanlis_rota": 0.12, "us_sure": 22.0, "karar": 0.35, "sis": true,
}

## Sisli insan botu DERİN MOD'da (v0.6): x1 tur, ilk oyunun 6 eseri elde (bonuslar
## kalır), kaya %15 sert, yakıt %12 hızlı, maden %25 değerli, ışık 3 karo, deprem
## 4 seferde bir. Ölçülen: Derin Mod ilk oyundan ne kadar uzun/kısa?
const INSAN_DERIN := {
	"carpan": 1.30, "duraksama_sans": 0.07, "duraksama_sure": 1.1,
	"yanlis_rota": 0.12, "us_sure": 22.0, "karar": 0.35, "sis": true,
	"derin_seviye": 1, "eserler": [0, 1, 2, 3, 4, 5],
}

var _u: DunyaUretici
var _d: Durum
var _kazilan := {}
var _eklenen := {}      ## deprem sonrası değişen hücreler (Dunya.eklenen ile aynı fikir)
## DunyaUretici.karo() önbelleği. Üretici saf ve belirlenimci olduğu için güvenli;
## BFS aynı hücreyi defalarca soruyor ve her soru bir avuç gürültü hesabı demek.
var _uretim := {}
var _rng := RandomNumberGenerator.new()
var _ayar := {}
var _tohum := 0
var _sisli := false
## Keşif haritası (1 = görüldü). Dictionary değil düz dizi: ışık her karo
## değişiminde ~80 hücre işaretliyor, bir ölçümde milyonlarca yazma demek.
var _kesif := PackedByteArray()
var _rota_sayac := 0        ## ölçüm: kaç kez BFS rotası kuruldu
var _sis_kirilma := 0       ## ölçüm: kaç kez "sade kaya" varsayımı kaya/lava çarptı

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
	_tohum = tohum
	_u = DunyaUretici.new(tohum)
	_d = Durum.new(tohum)
	# Derin Mod ölçümü: seviye + taşınan eserler, kapasiteler eser bonusuyla.
	_d.derin_seviye = int(ayar.get("derin_seviye", 0))
	for e in Array(ayar.get("eserler", [])):
		_d.eserler.append(int(e))
	_d.yakit = _d.yakit_kapasitesi()
	_d.can = _d.can_kapasitesi()
	_kazilan = {}
	_eklenen = {}
	_uretim = {}
	_sisli = bool(ayar.get("sis", false))
	_kesif = PackedByteArray()
	_kesif.resize(Ayarlar.GENISLIK * Ayarlar.DERINLIK)
	_rota_sayac = 0
	_sis_kirilma = 0
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
		_d.sefer = tur
		var deprem_bekliyor := tur % _d.deprem_araligi() == 0
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
		_kesfet(x, y)

		# 2) Aşağı kaz. Altı kazılamazsa yana tünel açar; 250 m'ye yaklaşınca
		#    çekirdek sütununa yanaşır (HUD oyuncuya da yönü söylüyor).
		var kapi := hedef_y < tunel   ## şaftın dibine inemedi: bu katmanda çalış
		var tikanma := 0
		var yon := 1
		# Rota sissiz botta tur başına BİR kez hesaplanır (BFS pahalı). Sisli
		# botta varsayım kırılabildiği için birkaç kez hakkı var.
		var rota_hakki := ROTA_EN_COK_SISLI if _sisli else 1
		var kacti := false
		for adim in 4000:
			_kesfet(x, y)
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
				# Körlemesine yana gitmek yerine mini haritadan rota çıkar (BFS).
				# v0.3'te tohum 3 tam burada tıkanıyordu: yol vardı, bot göremiyordu.
				if tikanma == ROTA_TIKANMA and rota_hakki > 0:
					rota_hakki -= 1
					var r := _rota(x, y)
					if not r.is_empty():
						var iz := _rota_izle(r)
						tur_sure += float(iz["sure"])
						x = int(iz["x"])
						y = int(iz["y"])
						tunel = maxi(tunel, y)
						if bool(iz["cekirdek"]):
							if cekirdek_zaman < 0.0:
								cekirdek_zaman = zaman + tur_sure
							break
						if bool(iz["ilerledi"]):
							tikanma = 0
							continue
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
			# Sert kayada dinamit zaman kazandırır (oyuncu da öyle kullanıyor).
			if float(Ayarlar.SERTLIK.get(t, 0.0)) >= 1.2:
				var patlama := _dinamit(x, y)
				if patlama >= 0.0:
					tur_sure += patlama
					y += 1
					tunel = maxi(tunel, y)
					continue
			tur_sure += _kaz(x, y + 1, t)
			y += 1
			tunel = maxi(tunel, y)
			# Canlı yeraltı: sefer sayacı dolduysa deprem yeraltında patlar.
			if deprem_bekliyor and y >= 15:
				deprem_bekliyor = false
				var dp := _deprem(x, y)
				tur_sure += float(dp["sure"])
				if bool(dp["kacti"]):
					kacti = true
					break
			# 3) Yanda maden varsa sap, sonra insan gürültüsü.
			tur_sure += _yan_maden(x, y)
			tur_sure += _gurultu(x, y)

		# 3b) Kapıya takıldıysa bu katmanda yatay galeri aç (oyuncu da bunu yapar:
		#     derine inemiyorsan bulunduğun katmanı tara).
		if kapi and not kacti:
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
		"rota": _rota_sayac,
		"sis_kirilma": _sis_kirilma,
		"deprem": _d.deprem,
	}

# --- yol bulma (mini harita + BFS) ----------------------------------------

## Çekirdeğe (ya da matkabın izin verdiği en derin noktaya) giden hücre listesi.
## Oyuncunun mini haritası ve radarı ne söylüyorsa bot da onu "biliyor" sayılır:
## ölçüm botu bir insanı temsil etmiyor, oyunun BİTİRİLEBİLİRLİĞİNİ ölçüyor.
## Önce gaz cebine girmeyen yol aranır; yoksa gazı göze alan yol kabul edilir.
func _rota(x: int, y: int) -> Array:
	_rota_sayac += 1
	var hedef := Vector2i(_u.cekirdek_x, Ayarlar.CEKIRDEK_DERINLIK)
	for gaz_serbest in [false, true]:
		var yol := _bfs(Vector2i(x, y), hedef, gaz_serbest)
		if not yol.is_empty():
			return yol
	return []

## Genişlik öncelikli arama. Geçilebilir = kazılabilir + matkap yetiyor.
## KAYA ve LAV geçilmez (dinamit de açmıyor), CEKIRDEK hedeftir.
## Arama penceresi bilerek dar: bot bütün dünyayı değil, mini haritada
## gördüğü kadarını tarıyor (ve 17 000 hücrelik tam tarama her turda çok pahalı).
## Çekirdek pencerede değilse hedef, pencerede ulaşılabilen EN DERİN hücre olur.
func _bfs(bas: Vector2i, hedef: Vector2i, gaz_serbest: bool) -> Array:
	var onceki := {bas: bas}
	var sira: Array[Vector2i] = [bas]
	var en_derin := bas
	var i := 0
	var alt := bas.y + ROTA_PENCERE
	var ust := bas.y - ROTA_YUKARI
	while i < sira.size():
		var h: Vector2i = sira[i]
		i += 1
		if h == hedef:
			return _yol_cikar(onceki, bas, hedef)
		if h.y > en_derin.y:
			en_derin = h
		for d: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			var k := h + d
			if k.x < 1 or k.x >= Ayarlar.GENISLIK - 1 or k.y < ust or k.y > alt 					or k.y >= Ayarlar.DERINLIK - 1:
				continue
			if onceki.has(k):
				continue
			var t := _bfs_karo(k.x, k.y)
			if t == Ayarlar.KAYA or t == Ayarlar.LAV:
				continue
			if t == Ayarlar.GAZ and not gaz_serbest:
				continue
			if t != Ayarlar.BOS and t != Ayarlar.CEKIRDEK and not _d.matkap_yeterli_mi(k.y):
				continue
			onceki[k] = h
			sira.append(k)
	# Çekirdeğe pencereden varılmıyor: en azından en derin noktaya doğru git.
	if en_derin.y - bas.y >= 3:
		return _yol_cikar(onceki, bas, en_derin)
	return []

func _yol_cikar(onceki: Dictionary, bas: Vector2i, hedef: Vector2i) -> Array:
	var yol: Array = []
	var h := hedef
	while h != bas:
		yol.append(h)
		h = onceki[h]
	yol.reverse()
	return yol

## Rotayı yürür: kazar, madeni toplar, bütçe (yakıt/yük/can) bitince durur.
## Dönüş: {"sure", "x", "y", "cekirdek", "ilerledi"}
func _rota_izle(yol: Array) -> Dictionary:
	var sure := 0.0
	var x := 0
	var y := 0
	var ilk := true
	for adim in yol:
		var h: Vector2i = adim
		if ilk:
			ilk = false
			x = h.x
			y = h.y
		var t := _karo(h.x, h.y)
		if t == Ayarlar.CEKIRDEK:
			return {"sure": sure, "x": h.x, "y": h.y, "cekirdek": true, "ilerledi": true}
		# Sis varsayımı kırıldı: karanlıkta sade kaya sandığımız hücre kazılamaz
		# kaya ya da lav çıktı. Rota geçersiz, burada dur — çağıran yeniden kurar.
		if t == Ayarlar.KAYA or t == Ayarlar.LAV:
			_sis_kirilma += 1
			break
		if _d.yakit < float(_donus_maliyeti(y)["yakit"]) * GUVENLIK 				or _d.yuk_dolu() or _d.can <= 1:
			break
		if t != Ayarlar.BOS:
			if h.y > y and float(Ayarlar.SERTLIK[t]) >= 1.2:
				var patlama := _dinamit(x, y)
				if patlama >= 0.0:
					sure += patlama
					x = h.x
					y = h.y
					continue
			sure += _kaz(h.x, h.y, t)
		if h.y == y:
			sure += float(Ayarlar.KARO) / Ayarlar.YATAY_HIZ * _carpan()
		elif h.y > y:
			sure += float(Ayarlar.KARO) / DUSUS_HIZ * _carpan()
		else:
			sure += float(Ayarlar.KARO) / Ayarlar.TIRMANIS_HIZ * _carpan()
			_d.yakit -= Ayarlar.YAKIT_ITKI * float(Ayarlar.KARO) / Ayarlar.TIRMANIS_HIZ
		x = h.x
		y = h.y
		_kesfet(x, y)
		sure += _yan_maden(x, y)
		sure += _gurultu(x, y)
	return {"sure": sure, "x": x, "y": y, "cekirdek": false, "ilerledi": not ilk}

# --- deprem ---------------------------------------------------------------

## Yeraltında patlayan deprem: tünellerin bir kısmı kapanır, yeni gaz/damar çıkar.
## Karar (scripts/deprem.gd): uyarı süresi yüzeye çıkmaya yetiyorsa bot çıkar ve
## ikramiyeyi alır, yetmiyorsa derinde kalıp hasar yer. Bu, oyuncunun önündeki
## bahsin ölçümdeki karşılığı — v0.3'te bot depremi hiç yaşamıyordu.
func _deprem(x: int, y: int) -> Dictionary:
	_d.deprem += 1
	var korunan := Deprem.korunan_hucreler(_d.istasyonlar, Vector2i(x, y))
	var karo := func(h: Vector2i) -> int: return _karo(h.x, h.y)
	var sonuc := Deprem.hesapla(_kazilan, karo, korunan, _tohum, _d.deprem)
	for h in sonuc["kapanan"]:
		_kazilan.erase(h)
	var yeni: Dictionary = sonuc["yeni"]
	for h in yeni:
		_kazilan.erase(h)
		_eklenen[h] = int(yeni[h])

	var uyari := Deprem.uyari_suresi(y)
	# Işınlanma duraklı bir istasyon varsa kaçış bedava sayılır (oyuncu da öyle yapar).
	var durak := _d.isinlanma_duragi(Vector2i(x, y)) >= 0
	var tirmanis := float(y * Ayarlar.KARO) / Ayarlar.TIRMANIS_HIZ * _carpan()
	if durak or tirmanis <= uyari:
		var k := Deprem.karar(y, 0)
		_d.para += int(k["odul"])
		# Tırmanışın süresi turun sonundaki dönüş maliyetinde zaten sayılıyor;
		# burada yalnız kararın kendisi (ve varsa ışınlanma) süre yazar.
		return {"sure": 2.0, "kacti": true}
	var k2 := Deprem.karar(y, y)
	_d.hasar_al(int(k2["hasar"]))
	return {"sure": uyari, "kacti": false}

# --- keşif sisi -----------------------------------------------------------

## Aracın ışık yarıçapını kalıcı olarak açar. Sis kapalıysa hiçbir şey yapmaz
## (sisli olmayan ölçümler yavaşlamasın).
func _kesfet(x: int, y: int) -> void:
	if not _sisli:
		return
	var r := _d.isik_yaricap()   ## Derin Mod'da 3 — oyunla aynı fonksiyon
	for dy in range(-r, r + 1):
		var hy := y + dy
		if hy < 0 or hy >= Ayarlar.DERINLIK:
			continue
		var satir := hy * Ayarlar.GENISLIK
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue
			var hx := x + dx
			if hx >= 0 and hx < Ayarlar.GENISLIK:
				_kesif[satir + hx] = 1

func _bilinen(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= Ayarlar.GENISLIK or y >= Ayarlar.DERINLIK:
		return true
	return _kesif[y * Ayarlar.GENISLIK + x] == 1

## Yol bulmanın gördüğü karo. Sis varken keşfedilmemiş hücre "o derinliğin sade
## taban kayası" varsayılır: oyuncu da karanlıkta ne olduğunu bilmez, kazılabilir
## umar. Varsayım kırılınca rota `_rota_izle` içinde tıkanır ve yeniden kurulur.
func _bfs_karo(x: int, y: int) -> int:
	if not _sisli or _bilinen(x, y):
		return _karo(x, y)
	return int(Ayarlar.KATMANLAR[Ayarlar.katman(y)]["taban"])

func _karo(x: int, y: int) -> int:
	var h := Vector2i(x, y)
	if _kazilan.has(h):
		return Ayarlar.BOS
	if _eklenen.has(h):
		return int(_eklenen[h])
	if not _uretim.has(h):
		_uretim[h] = _u.karo(x, y)
	return int(_uretim[h])

## Bir karoyu kazar: süreyi döner, yakıtı ve yükü günceller.
func _kaz(x: int, y: int, t: int) -> float:
	if t == Ayarlar.BOS:
		return float(Ayarlar.KARO) / DUSUS_HIZ * _carpan()
	return _kir(x, y, t) * _carpan()

## Karoyu kırar ve içeriğini işler. Kazma süresini döner (çarpansız).
## `yakit` false ise yakıt harcanmaz — dinamit matkapla kazmıyor, patlatıyor.
func _kir(x: int, y: int, t: int, yakit := true) -> float:
	var sure := float(Ayarlar.SERTLIK[t]) / _d.matkap_hizi()
	if yakit:
		_d.yakit -= (Ayarlar.YAKIT_BOSTA + Ayarlar.YAKIT_KAZMA) * sure
	_kazilan[Vector2i(x, y)] = true
	_eklenen.erase(Vector2i(x, y))
	if Ayarlar.MADEN_DEGER.has(t):
		_d.maden_ekle(t)
	elif t == Ayarlar.GAZ:
		_d.hasar_al(Ayarlar.HASAR_GAZ)
	elif t == Ayarlar.SANDIK:
		_d.para += 70
	return sure

## Dinamit: 3x3'ü bir anda alır. Kazılamaz kayayı AÇMAZ (Arac.kir de açmıyor),
## yalnız zaman kazandırır — bu yüzden ancak sert kayada ve kazancı varsa atılır.
## Dönüş: harcanan süre, atılmadıysa -1.
func _dinamit(x: int, y: int) -> float:
	if _d.dinamit <= 0:
		return -1.0
	var merkez := Vector2i(x, y + 1)
	var hedefler := []
	var kazanc := 0.0
	for dy in range(-Ayarlar.DINAMIT_YARICAP, Ayarlar.DINAMIT_YARICAP + 1):
		for dx in range(-Ayarlar.DINAMIT_YARICAP, Ayarlar.DINAMIT_YARICAP + 1):
			var h := merkez + Vector2i(dx, dy)
			var t := _karo(h.x, h.y)
			if t == Ayarlar.BOS or t == Ayarlar.KAYA or t == Ayarlar.LAV or t == Ayarlar.CEKIRDEK:
				continue
			if not _d.matkap_yeterli_mi(h.y):
				continue
			hedefler.append([h, t])
			kazanc += float(Ayarlar.SERTLIK[t]) / _d.matkap_hizi()
	if kazanc < DINAMIT_DEGER:
		return -1.0
	_d.dinamit -= 1
	for veri in hedefler:
		_kir(veri[0].x, veri[0].y, int(veri[1]), false)
	return 0.6 * _carpan()

## Aynı derinlikte yandaki madene sapma (zincir çarpanı da buradan besleniyor).
func _yan_maden(x: int, y: int) -> float:
	var sure := 0.0
	var menzil := YAN_TARAMA + (RADAR_TARAMA if _d.alet_var("radar") else 0)
	for yon: int in [-1, 1]:
		for i in range(1, menzil + 1):
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
		_kesfet(hx, hy)
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
		# Radar yandaki madeni daha uzaktan görüyor; dinamit sert kayada zaman
		# kazandırıyor. İkisi de ancak PARA ARTTIYSA alınır — geliştirme eğrisini
		# bozmasınlar (tests/test_denge.gd bandı bunu yakalar).
		if y >= 50 and not _d.alet_var("radar") 				and _d.para > int(Ayarlar.ALET_FIYAT["radar"]) * 3 and _d.alet_al("radar"):
			continue
		if y >= 60 and _d.dinamit < 3 and _d.para > Ayarlar.DINAMIT_FIYAT * 12 				and _d.dinamit_al(3):
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
