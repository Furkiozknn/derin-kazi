## Koşu + ilerleme durumu ve tüm ekonomi kuralları.
## Node değil: testler doğrudan kurup sınayabilir (tests/test_calistir.gd, tests/test_denge.gd).
class_name Durum
extends RefCounted

var tohum := 0
var para := 0
var en_derin := 0
var sure := 0.0

# geliştirme seviyeleri 0..EN_YUKSEK_SEVIYE
var matkap := 0
var depo := 0
var kasa := 0
var govde := 0

var aletler := {"radar": false, "kalkan": false}
var dinamit := 0
var istasyon_kiti := 0
var istasyonlar := []       ## Vector2i hücreler
var eserler := []           ## toplanan eser indeksleri (Ayarlar.ESERLER)

var yakit := 0.0
var can := 0
var yuk := {}               ## karo türü -> adet
var yuk_bonus := 0          ## kazı zincirinden gelen ek para
var dusen_sandiklar := []   ## her biri: h (Vector2i), yuk (Dictionary), bonus (int)

var zincir_tur := Ayarlar.BOS
var zincir_adet := 0
var zincir_zaman := 0.0

var sefer := 0              ## tamamlanan sefer sayısı (in-çık); deprem sayacı bunu kullanır
var deprem := 0             ## uygulanan deprem sayısı
var deprem_bekliyor := false ## bu seferde deprem olacak (üste dönünce kuruldu)
var derin_seviye := 0       ## Derin Mod turu: 0 = ilk oyun

var bitti := false          ## koşu başarısız (yakıt/can)
var cekirdek_bulundu := false
var kacis := false          ## çekirdeğe dokunuldu, yüzeye kaçış sürüyor
var kazandi := false

# --- istatistik (v0.7) ----------------------------------------------------
## Bitiş ekranının dökümü. Bu yuvanın sayaçları burada (deprem ve sure yukarıda);
## bütün yuvaların toplamı [oyuncu] kayıt bölümünde birikir: her kayıtta
## istatistik_farki() son aktarımdan bu yana biriken farkı verir, Kayit.oyuncu_biriktir
## toplama ekler — kayıttan yüklenen değerler aktarılmış sayılır, iki kez sayılmaz.
var kazilan_karo := 0       ## oyuncunun kırdığı karo (dinamit dahil, düşen kaya hariç)
var olum := 0               ## yüzeye çekilme sayısı — oyunda ölüm yok, "ölüm" bu
var satis_toplam := 0       ## üste satılan toplam ₺
var _birikmis := {}         ## [oyuncu] bölümüne en son aktarılan değerler

## Işınlama işareti (v0.7): istasyon dışında TEK KULLANIMLIK dönüş noktası. Yeraltında
## koyulur (R / İŞARET düğmesi), ışınlanma panelinden üs ya da istasyondan gidilir,
## gidince silinir. Bot bilmez — ölçüm değişmez. Eski kayıtta yok → işaretsiz açılır.
const ISARET_YOK := Vector2i(-1, -1)
var isaret := ISARET_YOK

func _init(p_tohum := 0) -> void:
	tohum = p_tohum
	yakit = yakit_kapasitesi()
	can = can_kapasitesi()

func isaret_var() -> bool:
	return isaret != ISARET_YOK

func istatistik() -> Dictionary:
	return {"kazilan_karo": kazilan_karo, "deprem": deprem, "olum": olum,
		"satis_toplam": satis_toplam, "sure": sure}

## Son aktarımdan bu yana biriken fark; çağrıdan sonra sayaç sıfırdan başlar.
func istatistik_farki() -> Dictionary:
	var simdi := istatistik()
	var fark := {}
	for k in simdi:
		fark[k] = simdi[k] - _birikmis.get(k, 0)
	_birikmis = simdi
	return fark

# --- müze bonusları -------------------------------------------------------

## Toplanan eserlerin verdiği kalıcı pasif bonusun toplamı.
func eser_bonus(tur: String) -> float:
	var t := 0.0
	for i in eserler:
		var e: Dictionary = Ayarlar.ESERLER[int(i) % Ayarlar.ESERLER.size()]
		if String(e["bonus"]) == tur:
			t += float(e["deger"])
	return t

# --- Derin Mod zorluğu ----------------------------------------------------
## Derin Mod her turda kazmayı ve yakıt tüketimini zorlaştırır, madeni değerlendirir.
## Eser bonusları korunduğu için ilerleme eğrisi aynı bantta kalır.
const DERIN_KAZMA := 0.15
const DERIN_YAKIT := 0.12
const DERIN_DEGER := 0.25

func zorluk_kazma() -> float:
	return 1.0 + DERIN_KAZMA * float(derin_seviye)

func zorluk_yakit() -> float:
	return 1.0 + DERIN_YAKIT * float(derin_seviye)

func zorluk_deger() -> float:
	return 1.0 + DERIN_DEGER * float(derin_seviye)

func derin_mi() -> bool:
	return derin_seviye > 0

## Derin Mod'un kimliği (v0.6) çarpanlardan ibaret değil:
##   - ışık dar (3 karo; 7. eser bir karo geri verir),
##   - deprem daha sık (4 seferde bir),
##   - 7. eser yalnız burada bulunur.
## Üçü de buradan okunur; sahne ve bot aynı fonksiyonları kullanıyor.
func isik_yaricap() -> int:
	return Ayarlar.isik_yaricap(derin_mi()) + int(eser_bonus("isik"))

func deprem_araligi() -> int:
	return Deprem.aralik(derin_mi())

## Bu modda bulunabilecek eser sayısı (Derin Mod'a özel olanlar ilk oyunda sayılmaz).
func eser_sayisi() -> int:
	var n := 0
	for i in Ayarlar.ESERLER.size():
		if derin_mi() or not Ayarlar.eser_derin_mi(i):
			n += 1
	return n

## Toplanmış eserlerden bu modda görünenlerin sayısı.
func eser_toplanan() -> int:
	var n := 0
	for i in eserler:
		if derin_mi() or not Ayarlar.eser_derin_mi(int(i)):
			n += 1
	return n

## Bir sonraki bulunacak eser; hepsi toplandıysa -1. Derin Mod'a özel eser varsa
## ÖNCE o gelir — modun kimliği ilk gizli odada belli olsun — sonra kalan sıra.
func sonraki_eser() -> int:
	var sira: Array = []
	for i in Ayarlar.ESERLER.size():
		if eserler.has(i):
			continue
		var derin := Ayarlar.eser_derin_mi(i)
		if derin and not derin_mi():
			continue
		if derin:
			sira.push_front(i)
		else:
			sira.append(i)
	return int(sira[0]) if not sira.is_empty() else -1

# --- geliştirmeden türeyen değerler ---------------------------------------

func yakit_kapasitesi() -> float:
	return float(Ayarlar.YAKIT_SEVIYE[depo]) * (1.0 + eser_bonus("yakit"))

func yuk_kapasitesi() -> int:
	return int(Ayarlar.YUK_SEVIYE[kasa]) + int(eser_bonus("yuk"))

func matkap_hizi() -> float:
	return float(Ayarlar.MATKAP_SEVIYE[matkap]) * (1.0 + eser_bonus("matkap")) / zorluk_kazma()

func can_kapasitesi() -> int:
	return int(Ayarlar.GOVDE_SEVIYE[govde])

func maden_degeri(maden: int) -> int:
	return int(round(float(Ayarlar.MADEN_DEGER.get(maden, 0))
		* (1.0 + eser_bonus("deger")) * zorluk_deger()))

func seviye(alan: String) -> int:
	match alan:
		"matkap": return matkap
		"depo": return depo
		"kasa": return kasa
		"govde": return govde
	return 0

func _seviye_ayarla(alan: String, deger: int) -> void:
	match alan:
		"matkap": matkap = deger
		"depo": depo = deger
		"kasa": kasa = deger
		"govde": govde = deger

## Bir sonraki seviyenin fiyatı. -1 = zaten en üst seviye.
func fiyat(alan: String) -> int:
	return Ayarlar.gelistirme_fiyati(alan, seviye(alan))

## Bu derinliği kazabilmek için gereken matkap seviyesi (indeks).
static func gereken_matkap(y: int) -> int:
	return int(Ayarlar.KATMANLAR[Ayarlar.katman(y)]["matkap"])

func matkap_yeterli_mi(y: int) -> bool:
	return matkap >= gereken_matkap(y)

# --- yük ------------------------------------------------------------------

## Yükün ağırlığı (kapasite bunu sayar), parça adedi değil.
func yuk_toplam() -> int:
	var t := 0
	for tur in yuk:
		t += int(Ayarlar.MADEN_AGIRLIK.get(tur, 1)) * int(yuk[tur])
	return t

## Yükteki parça adedi (arayüzde "x3 Altın" gibi göstermek için).
func yuk_adet() -> int:
	var t := 0
	for adet in yuk.values():
		t += int(adet)
	return t

## Bir sonraki parça sığmıyorsa yük dolu sayılır.
func yuk_dolu(tur := Ayarlar.BOS) -> bool:
	var agirlik := int(Ayarlar.MADEN_AGIRLIK.get(tur, 1))
	return yuk_toplam() + agirlik > yuk_kapasitesi()

## Madeni yüke ekler ve kazı zincirini işler. Yük doluysa eklemez ve false döner.
func maden_ekle(tur: int) -> bool:
	if not Ayarlar.MADEN_DEGER.has(tur):
		return false
	if yuk_dolu(tur):
		return false
	yuk[tur] = int(yuk.get(tur, 0)) + 1
	if tur == zincir_tur:
		zincir_adet += 1
	else:
		zincir_tur = tur
		zincir_adet = 1
	zincir_zaman = Ayarlar.ZINCIR_SURE
	var carpan := Ayarlar.zincir_carpani(zincir_adet)
	yuk_bonus += int(round(float(maden_degeri(tur)) * (carpan - 1.0)))
	return true

## Zincir sayacını işletir (saniye). Süre dolarsa zincir sıfırlanır.
func zincir_isle(delta: float) -> void:
	if zincir_adet == 0:
		return
	zincir_zaman -= delta
	if zincir_zaman <= 0.0:
		zincir_tur = Ayarlar.BOS
		zincir_adet = 0

func zincir_carpani() -> float:
	return Ayarlar.zincir_carpani(zincir_adet)

func yuk_degeri() -> int:
	var t := yuk_bonus
	for tur in yuk:
		t += maden_degeri(tur) * int(yuk[tur])
	return t

## Yükü satar, parayı artırır, kazanılan tutarı döner.
func sat() -> int:
	var kazanc := yuk_degeri()
	para += kazanc
	satis_toplam += kazanc
	yuk.clear()
	yuk_bonus = 0
	return kazanc

# --- geliştirme ve alet ---------------------------------------------------

## Parası yeterse seviyeyi artırır ve parayı düşer. Yetmezse hiçbir şey yapmaz.
func satin_al(alan: String) -> bool:
	var f := fiyat(alan)
	if f < 0 or para < f:
		return false
	para -= f
	_seviye_ayarla(alan, seviye(alan) + 1)
	if alan == "govde":
		can = can_kapasitesi()
	return true

func alet_al(ad: String) -> bool:
	if bool(aletler.get(ad, false)):
		return false
	var f := int(Ayarlar.ALET_FIYAT.get(ad, -1))
	if f < 0 or para < f:
		return false
	para -= f
	aletler[ad] = true
	return true

## Finalde (kaçış) tüm aletler açık: rakip analizi "final aletleri elden almaz".
func alet_var(ad: String) -> bool:
	return kacis or bool(aletler.get(ad, false))

func dinamit_al(adet := 1) -> bool:
	var f := Ayarlar.DINAMIT_FIYAT * adet
	if para < f:
		return false
	para -= f
	dinamit += adet
	return true

func istasyon_kiti_al() -> bool:
	if para < Ayarlar.ISTASYON_FIYAT:
		return false
	para -= Ayarlar.ISTASYON_FIYAT
	istasyon_kiti += 1
	return true

## Bu derinlikte 50 m bandı boş mu? (kit sayısından bağımsız)
func istasyon_kurulabilir_derinlik(y: int) -> bool:
	if y < Ayarlar.ISTASYON_EN_SIG:
		return false
	for i in istasyonlar:
		if absi(int(i.y) - y) < Ayarlar.ISTASYON_ARALIK:
			return false
	return true

## Bu hücreye istasyon kurulabilir mi? (kit var, yeterince derin, 50 m bandı boş)
func istasyon_kurulabilir(h: Vector2i) -> bool:
	return istasyon_kiti > 0 and istasyon_kurulabilir_derinlik(h.y)

## Işınlanma yalnız üste ya da bir istasyona yakınken yapılır (asansör modeli):
## "her yerden anında kaç" olsaydı yakıt gerilimi kalmazdı.
## Yakındaki istasyonun indeksi, yoksa -1.
func isinlanma_duragi(h: Vector2i) -> int:
	for i in istasyonlar.size():
		if Vector2i(istasyonlar[i]).distance_squared_to(h) <= 9:
			return i
	return -1

func istasyon_kur(h: Vector2i) -> bool:
	if not istasyon_kurulabilir(h):
		return false
	istasyon_kiti -= 1
	istasyonlar.append(h)
	istasyonlar.sort_custom(func(a, b): return a.y < b.y)
	return true

# --- yakıt ve can ---------------------------------------------------------

## Üs ikramının üstünde kalan, ücretli kısım.
func bedava_yakit() -> float:
	return yakit_kapasitesi() * Ayarlar.BEDAVA_YAKIT_ORAN

func yakit_dolum_fiyati() -> int:
	return int(ceil((yakit_kapasitesi() - maxf(yakit, bedava_yakit())) * Ayarlar.YAKIT_BIRIM_FIYAT))

## Üsteki ikramı bedava verir, kalanını paranın yettiği kadar doldurur.
## Harcanan parayı döner.
func yakit_doldur() -> int:
	yakit = maxf(yakit, bedava_yakit())
	var eksik := yakit_kapasitesi() - yakit
	if eksik <= 0.01:
		return 0
	var alinabilir := minf(eksik, float(para) / Ayarlar.YAKIT_BIRIM_FIYAT)
	var maliyet := int(floor(alinabilir * Ayarlar.YAKIT_BIRIM_FIYAT))
	yakit += alinabilir
	para -= maliyet
	return maliyet

func yakit_harca(miktar: float) -> void:
	yakit = maxf(0.0, yakit - miktar * zorluk_yakit())
	if yakit <= 0.0:
		bitti = true

func hasar_al(miktar: int) -> void:
	can = maxi(0, can - miktar)
	if can <= 0:
		bitti = true

func onar() -> void:
	can = can_kapasitesi()

func cekme_ucreti(derinlik: int) -> int:
	var ham := float(Ayarlar.CEKME_TABAN + int(float(derinlik) * Ayarlar.CEKME_CARPAN))
	return int(round(ham * (1.0 - eser_bonus("cekme"))))

## Yumuşak ceza: ölüm yok. Yüzeye çekilir, ücret alınır, yükün yarısı
## olduğu yerde sandık olarak kalır (geri alınabilir).
func kosu_basarisiz(h: Vector2i) -> Dictionary:
	var ucret := mini(cekme_ucreti(h.y), para)
	para -= ucret
	olum += 1
	var birakilan := {}
	for tur in yuk.keys():
		var yarim := int(yuk[tur]) / 2
		if yarim > 0:
			birakilan[tur] = yarim
			yuk[tur] = int(yuk[tur]) - yarim
		if int(yuk[tur]) <= 0:
			yuk.erase(tur)
	var bonus_yarim := yuk_bonus / 2
	yuk_bonus -= bonus_yarim
	if not birakilan.is_empty() or bonus_yarim > 0:
		dusen_sandiklar.append({"h": h, "yuk": birakilan, "bonus": bonus_yarim})
	yakit = 0.0
	can = can_kapasitesi()
	bitti = false
	zincir_tur = Ayarlar.BOS
	zincir_adet = 0
	return {"ucret": ucret, "birakilan": birakilan}

## Düşen sandığı geri alır. Yük kapasitesi aşılırsa kalanı sandıkta bırakır.
func sandik_al(indeks: int) -> Dictionary:
	var s: Dictionary = dusen_sandiklar[indeks]
	var alinan := {}
	var kalan := {}
	for tur in s["yuk"]:
		for i in int(s["yuk"][tur]):
			if maden_ekle(tur):
				alinan[tur] = int(alinan.get(tur, 0)) + 1
			else:
				kalan[tur] = int(kalan.get(tur, 0)) + 1
	yuk_bonus += int(s["bonus"])
	if kalan.is_empty():
		dusen_sandiklar.remove_at(indeks)
	else:
		s["yuk"] = kalan
		s["bonus"] = 0
	return alinan

# --- kayıt ----------------------------------------------------------------

func sozluge() -> Dictionary:
	var ist := PackedInt32Array()
	for h in istasyonlar:
		ist.append(h.x)
		ist.append(h.y)
	var sand := []
	for s in dusen_sandiklar:
		var d := PackedInt32Array([s["h"].x, s["h"].y, int(s["bonus"])])
		for tur in s["yuk"]:
			d.append(tur)
			d.append(int(s["yuk"][tur]))
		sand.append(d)
	return {
		"tohum": tohum, "para": para, "en_derin": en_derin, "sure": sure,
		"sefer": sefer, "deprem": deprem, "deprem_bekliyor": deprem_bekliyor,
		"derin_seviye": derin_seviye,
		"matkap": matkap, "depo": depo, "kasa": kasa, "govde": govde,
		"radar": bool(aletler["radar"]), "kalkan": bool(aletler["kalkan"]),
		"dinamit": dinamit, "istasyon_kiti": istasyon_kiti,
		"istasyonlar": ist, "eserler": PackedInt32Array(eserler),
		"sandiklar": sand, "cekirdek_bulundu": cekirdek_bulundu, "kazandi": kazandi,
		"kazilan_karo": kazilan_karo, "olum": olum, "satis_toplam": satis_toplam,
		"isaret": PackedInt32Array([isaret.x, isaret.y]),
	}

func sozlukten(d: Dictionary) -> void:
	tohum = int(d.get("tohum", tohum))
	para = int(d.get("para", 0))
	en_derin = int(d.get("en_derin", 0))
	sure = float(d.get("sure", 0.0))
	sefer = int(d.get("sefer", 0))
	deprem = int(d.get("deprem", 0))
	deprem_bekliyor = bool(d.get("deprem_bekliyor", false))
	derin_seviye = int(d.get("derin_seviye", 0))
	matkap = clampi(int(d.get("matkap", 0)), 0, Ayarlar.EN_YUKSEK_SEVIYE)
	depo = clampi(int(d.get("depo", 0)), 0, Ayarlar.EN_YUKSEK_SEVIYE)
	kasa = clampi(int(d.get("kasa", 0)), 0, Ayarlar.EN_YUKSEK_SEVIYE)
	govde = clampi(int(d.get("govde", 0)), 0, Ayarlar.EN_YUKSEK_SEVIYE)
	aletler["radar"] = bool(d.get("radar", false))
	aletler["kalkan"] = bool(d.get("kalkan", false))
	dinamit = int(d.get("dinamit", 0))
	istasyon_kiti = int(d.get("istasyon_kiti", 0))
	cekirdek_bulundu = bool(d.get("cekirdek_bulundu", false))
	kazandi = bool(d.get("kazandi", false))
	istasyonlar.clear()
	var ist := PackedInt32Array(d.get("istasyonlar", PackedInt32Array()))
	var i := 0
	while i + 1 < ist.size():
		istasyonlar.append(Vector2i(ist[i], ist[i + 1]))
		i += 2
	eserler.clear()
	for e in PackedInt32Array(d.get("eserler", PackedInt32Array())):
		eserler.append(int(e))
	dusen_sandiklar.clear()
	for s in Array(d.get("sandiklar", [])):
		var a := PackedInt32Array(s)
		if a.size() < 3:
			continue
		var y := {}
		var j := 3
		while j + 1 < a.size():
			y[a[j]] = a[j + 1]
			j += 2
		dusen_sandiklar.append({"h": Vector2i(a[0], a[1]), "yuk": y, "bonus": a[2]})
	kazilan_karo = int(d.get("kazilan_karo", 0))
	olum = int(d.get("olum", 0))
	satis_toplam = int(d.get("satis_toplam", 0))
	_birikmis = istatistik()   ## yüklenen sayaçlar [oyuncu] toplamına zaten girmiş sayılır
	var isr := PackedInt32Array(d.get("isaret", PackedInt32Array()))
	isaret = Vector2i(isr[0], isr[1]) if isr.size() == 2 else ISARET_YOK
	yakit = yakit_kapasitesi()
	can = can_kapasitesi()
