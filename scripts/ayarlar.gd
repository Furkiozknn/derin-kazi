## Tüm oyun sabitleri tek yerde. DENGE BURADAN AYARLANIR.
## tests/test_denge.gd bu dosyadaki sayıları simüle eder; değiştirince testi çalıştır.
class_name Ayarlar
extends RefCounted

# --- dünya ---
const KARO := 16                 ## piksel
const GENISLIK := 64             ## karo (4 chunk)
const DERINLIK := 272            ## karo (17 chunk) — 1 karo = 1 metre
const PARCA := 16                ## chunk kenarı (karo)
const CEKIRDEK_DERINLIK := 250   ## hedef
const KAPALI_UST := 6            ## ilk bu kadar sıra hep dolu (yüzey garantisi)

# --- karo türleri (karolar.png atlasındaki sütun) ---
const TOPRAK := 0
const TAS := 1
const SERT := 2
const BAZALT := 3
const OBSIDYEN := 4
const BAKIR := 5
const DEMIR := 6
const ALTIN := 7
const ELMAS := 8
const PLATIN := 9
const KAYA := 10        ## kazılamaz
const CEKIRDEK := 11    ## hedef
const GAZ := 12         ## kazınca patlar (parlak ipucu var)
const GEVSEK := 13      ## altı boşalınca titrer ve düşer
const LAV := 14         ## ısı kalkanı olmadan yaklaşılmaz
const SANDIK := 15      ## para/dinamit/yakıt
const ESER := 16        ## müzeye gider, kalıcı bonus
const BOS := -1
const KARO_SAYISI := 17

## Doku varyantı: karolar.png'de her karo türünün VARYANT_SAYISI satırı var.
## Sayı KATMANLAR.size() ile aynı, çünkü satırların iki işi var:
##   - taban kayaları: aynı 16 px doku yan yana tekrarlayınca desen fark ediliyordu,
##     satırlar farklı gürültü/degrade veriyor (seçim hücrenin konumundan).
##   - maden damarları: satır = KATMAN. Damarın zemini bulunduğu katmanın kayası
##     olsun diye (v0.3'te her zemin aynı mavi-gri taştı; toprak katmanında bakır
##     damarı yapıştırılmış mavi bir kare gibi duruyordu).
const VARYANT_SAYISI := 5
## Taban kayaları: varyant konumdan gelir.
const VARYANTLI := [TOPRAK, TAS, SERT, BAZALT, OBSIDYEN]

## Karonun atlastaki satırı. Tehlike karolarının (gaz, gevşek, lav, sandık, eser)
## varyantı YOK — deseni bir bakışta tanınmalı.
static func varyant(x: int, y: int, t: int) -> int:
	if MADEN_DEGER.has(t):
		return katman(y)          ## damarın zemini = o derinliğin taban kayası
	if not VARYANTLI.has(t):
		return 0
	return absi(hash(Vector2i(x * 31 + 7, y * 17 + 3))) % VARYANT_SAYISI

## Kazma süresi (saniye, matkap seviye 0'da). -1 = kazılamaz.
const SERTLIK := {
	TOPRAK: 0.55, TAS: 0.85, SERT: 1.20, BAZALT: 1.60, OBSIDYEN: 2.10,
	BAKIR: 0.70, DEMIR: 1.00, ALTIN: 1.40, ELMAS: 1.85, PLATIN: 2.40,
	KAYA: -1.0, CEKIRDEK: -1.0, LAV: -1.0,
	GAZ: 0.30, GEVSEK: 0.40, SANDIK: 0.50, ESER: 0.70,
}

const MADEN_DEGER := {BAKIR: 10, DEMIR: 25, ALTIN: 62, ELMAS: 117, PLATIN: 240}
## Yük ağırlığı: derin maden hem değerli hem hantal. Kasa kapasitesi ağırlık sayar.
## Gelirin katman başına ~×1,5 kalmasını sağlayan ayar bu. Birim ağırlık başına
## değer: 10,0 / 12,5 / 15,5 / 19,5 / 24,0 — katman başına ~×1,25. Kasa da
## ~×1,3 büyüdüğü için tur geliri ~×1,6 artıyor (tests/test_denge.gd ölçüyor).
const MADEN_AGIRLIK := {BAKIR: 1, DEMIR: 2, ALTIN: 4, ELMAS: 6, PLATIN: 10}
const MADEN_AD := {BAKIR: "Bakır", DEMIR: "Demir", ALTIN: "Altın", ELMAS: "Elmas", PLATIN: "Platin"}

# --- 5 katman ---
## y0: başlangıç derinliği · taban: dolgu karosu · matkap: gereken matkap seviyesi (indeks)
## maden: o katmanda yeni çıkan maden · yogunluk: maden tepe olasılığı
## tehlike: karo türü ya da BOS · tehlike_sans: 0..1
const KATMANLAR := [
	{"ad": "Toprak", "y0": 0, "taban": TOPRAK, "matkap": 0, "maden": BAKIR,
		"yogunluk": 0.130, "tehlike": GEVSEK, "tehlike_sans": 0.020, "renk": Color(0.44, 0.24, 0.15)},
	{"ad": "Taş", "y0": 40, "taban": TAS, "matkap": 1, "maden": DEMIR,
		"yogunluk": 0.105, "tehlike": GAZ, "tehlike_sans": 0.022, "renk": Color(0.22, 0.24, 0.30)},
	{"ad": "Sert Taş", "y0": 90, "taban": SERT, "matkap": 2, "maden": ALTIN,
		"yogunluk": 0.080, "tehlike": GEVSEK, "tehlike_sans": 0.034, "renk": Color(0.18, 0.18, 0.22)},
	{"ad": "Bazalt", "y0": 150, "taban": BAZALT, "matkap": 3, "maden": ELMAS,
		"yogunluk": 0.060, "tehlike": LAV, "tehlike_sans": 0.028, "renk": Color(0.13, 0.10, 0.14)},
	{"ad": "Çekirdek Kabuğu", "y0": 210, "taban": OBSIDYEN, "matkap": 4, "maden": PLATIN,
		"yogunluk": 0.046, "tehlike": LAV, "tehlike_sans": 0.040, "renk": Color(0.16, 0.06, 0.09)},
]

## y derinliğindeki katmanın indeksi (0..4).
static func katman(y: int) -> int:
	var k := 0
	for i in KATMANLAR.size():
		if y >= int(KATMANLAR[i]["y0"]):
			k = i
	return k

const MAGARA_ESIK := 0.50      ## üstündeki gürültü = boşluk
const KAYA_ESIK := 0.66        ## üstündeki gürültü = kazılamaz kaya
const ODA_SANS := 0.22         ## chunk başına hazır oda olasılığı
const BASLANGIC_DAMAR := 5     ## elle yerleştirilen bakır damarının derinliği (m)

# --- araç ---
const YATAY_HIZ := 74.0
const YERCEKIMI := 420.0
const ITKI := 620.0            ## pervane ivmesi
const TIRMANIS_HIZ := 104.0    ## pervaneyle en fazla bu hızla yükselir
const MAX_DUSUS := 300.0
const DUSME_HASAR_HIZ := 250.0 ## bu hızın üstünde yere çarpmak 1 can götürür

# --- geliştirmeler (dizinin indeksi = seviye 0..4) ---
const EN_YUKSEK_SEVIYE := 4
const YAKIT_SEVIYE := [110.0, 160.0, 230.0, 330.0, 470.0]
const YUK_SEVIYE := [20, 26, 34, 44, 58]
const MATKAP_SEVIYE := [1.0, 1.40, 1.90, 2.60, 3.40]   ## kazma hızı çarpanı
const GOVDE_SEVIYE := [3, 4, 6, 8, 11]                 ## can

## Fiyat = taban * 1.35^seviye (görev gereği).
const FIYAT_TABAN := {"matkap": 180, "depo": 120, "kasa": 140, "govde": 220}
const FIYAT_ARTIS := 1.35

const GELISTIRMELER := ["matkap", "depo", "kasa", "govde"]
const GELISTIRME_AD := {
	"matkap": "Matkap", "depo": "Yakıt deposu", "kasa": "Yük kasası", "govde": "Gövde zırhı",
}

## alan'ın s → s+1 seviyesinin fiyatı. s en üstteyse -1.
static func gelistirme_fiyati(alan: String, s: int) -> int:
	if s >= EN_YUKSEK_SEVIYE:
		return -1
	return int(round(float(FIYAT_TABAN[alan]) * pow(FIYAT_ARTIS, float(s))))

# --- aletler (bir kez alınır) ---
const ALET_FIYAT := {"radar": 260, "kalkan": 620}
const ALET_AD := {"radar": "Maden radarı", "kalkan": "Isı kalkanı"}
const ALET_ACIKLAMA := {
	"radar": "Q — en yakın madeni HUD'da gösterir",
	"kalkan": "Lav ve sıcak katmanlarda hasar almazsın",
}
const DINAMIT_FIYAT := 45      ## adet
const DINAMIT_YARICAP := 1     ## 1 = 3x3
const ISTASYON_FIYAT := 150
const ISTASYON_ARALIK := 50    ## her 50 m'de en fazla bir istasyon
const ISTASYON_EN_SIG := 40    ## bu derinlikten sığa istasyon kurulmaz
const ISINLAMA_YAKIT := 5.0

# --- yakıt ---
const YAKIT_BOSTA := 0.10      ## birim/sn
const YAKIT_HAREKET := 0.50
const YAKIT_ITKI := 2.20
const YAKIT_KAZMA := 0.55
const YAKIT_BIRIM_FIYAT := 0.25
## Üs ikramı: deponun bu kadarı her zaman bedava dolar. Parasız + yakıtsız
## kilitlenme olmasın diye; üstü ücretli, yani yakıt hâlâ bir kaynak.
const BEDAVA_YAKIT_ORAN := 0.30
const CEKME_TABAN := 20        ## yüzeye çekilme ücreti = taban + derinlik * carpan
const CEKME_CARPAN := 1.5

# --- hasar ---
const HASAR_GAZ := 2
const HASAR_KAYA := 2
const HASAR_LAV := 1           ## saniyede
const LAV_YARICAP := 20.0      ## piksel

# --- kazı zinciri ---
const ZINCIR_ESIK := [3, 5, 8]
const ZINCIR_CARPAN := [1.25, 1.6, 2.0]
const ZINCIR_SURE := 6.0       ## saniye içinde aynı madeni bulamazsan sıfırlanır

## adet kadar art arda aynı maden toplandığında para çarpanı.
static func zincir_carpani(adet: int) -> float:
	var c := 1.0
	for i in ZINCIR_ESIK.size():
		if adet >= int(ZINCIR_ESIK[i]):
			c = float(ZINCIR_CARPAN[i])
	return c

# --- eserler (müze) ---
## Her eser kalıcı bir pasif bonus verir ve `hikaye` ile çekirdeğin sırrından bir
## parça anlatır. Sıra önemli: 1'den 6'ya doğru okununca tek bir hikâye çıkar.
const ESERLER := [
	{"ad": "Kırık Pusula", "bonus": "matkap", "deger": 0.05, "metin": "Matkap hızı +%5",
		"hikaye": "İbresi aşağıyı gösteriyor ve hiç şaşmıyor. Kasabanın kurucuları bu pusulayı bir kuyunun dibinde bulmuş; \"aşağıda bizi çeken bir şey var\" demişler ve kazmaya başlamışlar."},
	{"ad": "Bakır Madalyon", "bonus": "deger", "deger": 0.04, "metin": "Maden değeri +%4",
		"hikaye": "Arkasında bir sayı kazılı: 250. Madalyonu takanlar bir ölçü ekibiydi. Ölçtükleri şey derinlik değil, sıcaklığın nereden geldiğiydi — ve cevap yukarıdan değildi."},
	{"ad": "Kadim Depo Kapağı", "bonus": "yakit", "deger": 0.08, "metin": "Yakıt kapasitesi +%8",
		"hikaye": "Kapağın iç yüzünde bir liste var: inen ekiplerin adları. Son satır yarım kalmış. Deponun kendisi hiç bulunamadı; yakıtı aşağıdan çıkarıyorlardı, yukarıdan indirmiyorlardı."},
	{"ad": "Taş Tablet", "bonus": "yuk", "deger": 2.0, "metin": "Yük kapasitesi +2",
		"hikaye": "Tablette tek bir cümle var: \"Kabuk her beş nöbette bir kımıldar, tünelleri geri alır.\" Depremleri bir felaket değil, nefes alma sayıyorlardı."},
	{"ad": "Isıyutan Levha", "bonus": "cekme", "deger": 0.20, "metin": "Çekme ücreti -%20",
		"hikaye": "Lavın içinde soğuk duruyor. Bu levhayı yapan atölye 210 metrenin altındaydı — yani çekirdeğin kabuğunda. Birileri oraya kadar inmiş, yerleşmiş ve çalışmış."},
	{"ad": "Çekirdek Parçası", "bonus": "matkap", "deger": 0.08, "metin": "Matkap hızı +%8",
		"hikaye": "Elde tutulunca kendi ritmiyle atıyor. Çekirdek bir maden yatağı değil: canlı, yavaş ve sabırlı bir şey. Aşağı inen ekipler onu çıkarmaya değil, uyandırmaya gitmişti."},
]

## Müzede eser bulunmadan önce görünen "kilitli" satırı.
const ESER_KILITLI := "…  ??? — yeraltındaki gizli odalarda"

# --- üs ---
const US_KARO_X := 32
const US_X := 520.0            ## US_KARO_X * KARO + KARO / 2
const US_YARICAP := 60.0

# --- sunum ---
const EKRAN_G := 640
const EKRAN_Y := 360
