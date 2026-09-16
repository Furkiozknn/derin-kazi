## Tüm oyun sabitleri tek yerde. Dengeyi buradan ayarla.
class_name Ayarlar
extends RefCounted

# --- dünya ---
const KARO := 16                 ## piksel
const GENISLIK := 60             ## karo
const DERINLIK := 320            ## karo (1 karo = 1 metre)
const PARCA := 32                ## chunk yüksekliği (karo)
const CEKIRDEK_DERINLIK := 250   ## hedef

# --- karo türleri (karolar.png atlasındaki sütun) ---
const BOS := -1
const TOPRAK := 0
const TAS := 1
const SERT := 2
const BAKIR := 3
const DEMIR := 4
const ALTIN := 5
const ELMAS := 6
const KAYA := 7        ## kazılamaz
const CEKIRDEK := 8    ## hedef nesne

## Kazma süresi (saniye, matkap seviye 0'da). -1 = kazılamaz.
const SERTLIK := {
	0: 0.30, 1: 0.60, 2: 1.10,
	3: 0.45, 4: 0.75, 5: 1.00, 6: 1.40,
	7: -1.0, 8: -1.0,
}

const MADEN_DEGER := {3: 12, 4: 30, 5: 85, 6: 240}
const MADEN_AD := {3: "Bakır", 4: "Demir", 5: "Altın", 6: "Elmas"}

## [tür, en sığ karo, en bol olduğu karo, en derin karo, tepe olasılık]
const MADEN_TABLO := [
	[3, 4, 55, 170, 0.110],
	[4, 45, 130, 250, 0.090],
	[5, 120, 220, 320, 0.060],
	[6, 195, 300, 320, 0.035],
]
const MAGARA_ESIK := 0.46      ## üstündeki gürültü = boşluk
const KAYA_ESIK := 0.64        ## üstündeki gürültü = kazılamaz kaya
const KAPALI_UST := 7          ## ilk bu kadar sıra hep dolu (yüzey garantisi)

# --- araç ---
const YATAY_HIZ := 70.0
const YERCEKIMI := 420.0
const ITKI := 620.0            ## pervane ivmesi
const TIRMANIS_HIZ := 100.0    ## pervaneyle en fazla bu hızla yükselir
const MAX_DUSUS := 300.0

# --- kaynaklar (dizinin indeksi = geliştirme seviyesi 0..3) ---
const YAKIT_SEVIYE := [100.0, 160.0, 250.0, 380.0]
const YUK_SEVIYE := [12, 20, 32, 50]
const MATKAP_SEVIYE := [1.0, 1.35, 1.8, 2.4]   ## kazma hızı çarpanı
const FIYAT := [0, 150, 450, 1200]
const EN_YUKSEK_SEVIYE := 3

const YAKIT_BOSTA := 0.15      ## birim/sn
const YAKIT_HAREKET := 1.20
const YAKIT_ITKI := 4.00
const YAKIT_KAZMA := 1.60
const YAKIT_BIRIM_FIYAT := 0.25
const ACIL_YAKIT_ORAN := 0.25  ## yakıt bitince bedava verilen pay (kilitlenmeyi önler)

# --- üs ---
const US_KARO_X := 30
const US_X := 488.0            ## US_KARO_X * KARO + KARO / 2
const US_YARICAP := 56.0

const GELISTIRMELER := ["matkap", "depo", "kasa"]
const GELISTIRME_AD := {"matkap": "Matkap hızı", "depo": "Yakıt deposu", "kasa": "Yük kapasitesi"}
