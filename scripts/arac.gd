## Matkaplı araç. Sağ/sol/aşağı kazar, yukarı sadece pervaneyle çıkar.
## Kazmak için zemine basmak gerekir; havada asılıyken kazılmaz.
## Katman sertliği matkap seviyesine kapılı: yetmezse "Matkap Sv2 gerekli".
class_name Arac
extends CharacterBody2D

signal maden_toplandi(tur: int, alindi: bool, konum: Vector2)
signal karo_kirildi(tur: int, konum: Vector2)
signal cekirdege_ulasildi
signal kosu_bitti
signal matkap_yetersiz(gereken: int)
signal hasar_alindi(miktar: int, konum: Vector2)
signal patlama(konum: Vector2, yaricap: int)
signal sandik_acildi(tur: int, konum: Vector2)
signal kazma_degisti(kaziyor: bool)   ## matkap sesi (v0.7): kazı başlayınca true, kısa kuyruktan sonra false

const YAN_UZANIM := 9.0    ## kazma hedefi ararken merkeze eklenen piksel
const ALT_UZANIM := 9.0
const YOK := Vector2i(1 << 30, 1 << 30)   ## "hedef yok"
const DOKUNULMAZ := 0.9    ## hasar sonrası saniye

## Animasyon kareleri (arac.png; düzen tools/sprite_uret.gd → _arac ve oyun.tscn hframes ile aynı).
const KARE_BEKLE := 0
const KARE_KAZ := 1        ## 2 kare: matkap dişleri kayar
const KARE_PALET := 3      ## 3 kare (v0.7): palet deseni yerde yürürken kayar
const KARE_UCUS := 6       ## 3 kare (v0.7): pervane alevi
const KARE_SAYISI := 9
const KAZ_KARE := 2
const PALET_KARE := 3
const UCUS_KARE := 3
const KAZ_HIZ := 14.0      ## kazma animasyonu, kare/sn
const UCUS_HIZ := 12.0     ## alev, kare/sn
const PALET_PIKSEL := 3.0  ## palet deseni bir kare kaymak için kaç px yol (desen 3 px periyotlu)
const KAZMA_KUYRUK := 0.3  ## kazı kesilince matkap sesi bu kadar sn daha sürer: karo arası düşüşte kesilmesin

var durum: Durum
var dunya: Dunya
var kilitli := false       ## menü/duraklatma açıkken hareket yok

var _hedef := YOK
var _ilerleme := 0.0
var _dokunulmaz := 0.0
var _kare_faz := 0.0       ## animasyon fazı (kaz/palet/uçuş ortak, 6'ya göre sarılır)
var _kaziyor := false      ## kazma_degisti'nin son bildirdiği değer
var _kazma_kuyruk := 0.0
var _en_hizli_dusus := 0.0
var _lav_birikim := 0.0
var _uyari_bekle := 0.0

@onready var _gorsel: Sprite2D = $Gorsel

func _physics_process(delta: float) -> void:
	if kilitli or durum == null or durum.bitti or durum.kazandi:
		_kazma_bildir(false)
		return

	durum.sure += delta
	durum.zincir_isle(delta)
	_dokunulmaz = maxf(0.0, _dokunulmaz - delta)
	_uyari_bekle = maxf(0.0, _uyari_bekle - delta)

	var yatay := Input.get_axis("sol", "sag")
	var itiyor := Input.is_action_pressed("yukari")

	# Kazma hedefi: önce aşağı, sonra yana. İkisi de zemine basmayı ister.
	var yon := _kazma_yonu(yatay)
	if yon != Vector2i.ZERO:
		_kaz(yon, delta)
	else:
		_hedef = YOK
		_ilerleme = 0.0
		velocity.x = yatay * Ayarlar.YATAY_HIZ

	if itiyor:
		velocity.y = move_toward(velocity.y, -Ayarlar.TIRMANIS_HIZ, Ayarlar.ITKI * delta)
	else:
		velocity.y = minf(velocity.y + Ayarlar.YERCEKIMI * delta, Ayarlar.MAX_DUSUS)

	# Yakıt: boşta bile azalır, hareket/kazma/pervane daha çok yer.
	var tuketim := Ayarlar.YAKIT_BOSTA
	if absf(velocity.x) > 1.0:
		tuketim += Ayarlar.YAKIT_HAREKET
	if itiyor:
		tuketim += Ayarlar.YAKIT_ITKI
	if _hedef != YOK:
		tuketim += Ayarlar.YAKIT_KAZMA
	durum.yakit_harca(tuketim * delta)

	_en_hizli_dusus = maxf(_en_hizli_dusus, velocity.y)
	var havadaydi := not is_on_floor()
	move_and_slide()
	if havadaydi and is_on_floor():
		_dusme_carpmasi()
	# Yüzeyde kenardan uçup gitmeyi engelle (yerin üstünde duvar karosu yok).
	global_position.x = clampf(global_position.x, Ayarlar.KARO * 1.5, (Ayarlar.GENISLIK - 1.5) * Ayarlar.KARO)

	durum.en_derin = maxi(durum.en_derin, derinlik())
	_lav_kontrol(delta)
	_gorsel_yenile(yatay, itiyor, delta)

	# Matkap sesi: kazarken sürer, kesilince KAZMA_KUYRUK kadar daha çalar. Karo kırılıp
	# araç bir sonraki karoya düşerken hedef bir an YOK oluyor; kuyruk olmasa ses her
	# karoda kesilip baştan başlardı.
	if _hedef != YOK:
		_kazma_kuyruk = KAZMA_KUYRUK
	else:
		_kazma_kuyruk = maxf(0.0, _kazma_kuyruk - delta)
	_kazma_bildir(_kazma_kuyruk > 0.0)

	if durum.bitti:
		kosu_bitti.emit()

func _kazma_bildir(kaziyor: bool) -> void:
	if kaziyor == _kaziyor:
		return
	_kaziyor = kaziyor
	kazma_degisti.emit(kaziyor)

func kaziyor_mu() -> bool:
	return _kaziyor

func derinlik() -> int:
	return maxi(0, floori(global_position.y / Ayarlar.KARO))

func hucre() -> Vector2i:
	return dunya.hucre(global_position)

# --- görsel ---------------------------------------------------------------

func _gorsel_yenile(yatay: float, itiyor: bool, delta: float) -> void:
	if absf(yatay) > 0.1:
		_gorsel.flip_h = yatay < 0.0
	var k := animasyon_durumu(_hedef != YOK, itiyor, is_on_floor(), velocity.x)
	_kare_faz = faz_ilerlet(_kare_faz, k, velocity.x, delta)
	_gorsel.frame = kare_sec(k, _kare_faz)
	# hasar sonrası yanıp sönme
	_gorsel.modulate.a = 1.0 if _dokunulmaz <= 0.0 else (0.35 if int(_dokunulmaz * 14.0) % 2 == 0 else 1.0)

## Animasyon durumu: "kaz" | "ucus" | "palet" | "bekle". Saf — girdi ve düğüm okumaz,
## testler doğrudan sınıyor; bot bu kareleri hiç bilmez (ölçüm görsele bağlı değil).
static func animasyon_durumu(kaziyor: bool, itiyor: bool, yerde: bool, yatay_hiz: float) -> String:
	if kaziyor:
		return "kaz"
	if itiyor and not yerde:
		return "ucus"
	if yerde and absf(yatay_hiz) > 1.0:
		return "palet"
	return "bekle"

## Fazı ilerletir. Palet fazı YOLLA ilerler (hız × süre / PALET_PIKSEL): hızlı araçta
## palet hızlı döner, duran araçta durur. Yön flip_h'ten gelir — kare sırası aynı
## kalır, ayna görüntü zaten tersini gösterir. Faz 6'ya göre sarılır (2 ve 3 karenin
## ortak katı), uzun oturumda float büyümesin.
static func faz_ilerlet(faz: float, durum_k: String, yatay_hiz: float, delta: float) -> float:
	var artis := 0.0
	match durum_k:
		"kaz":
			artis = delta * KAZ_HIZ
		"ucus":
			artis = delta * UCUS_HIZ
		"palet":
			artis = absf(yatay_hiz) * delta / PALET_PIKSEL
	return fposmod(faz + artis, 6.0)

static func kare_sec(durum_k: String, faz: float) -> int:
	match durum_k:
		"kaz":
			return KARE_KAZ + int(faz) % KAZ_KARE
		"ucus":
			return KARE_UCUS + int(faz) % UCUS_KARE
		"palet":
			return KARE_PALET + int(faz) % PALET_KARE
	return KARE_BEKLE

# --- kazma ----------------------------------------------------------------

## Kazılacak komşu hücrenin yönü. Kazacak bir şey yoksa ZERO.
func _kazma_yonu(yatay: float) -> Vector2i:
	if not is_on_floor():
		return Vector2i.ZERO
	if Input.is_action_pressed("asagi"):
		if _kazilabilir(dunya.hucre(global_position + Vector2(0, ALT_UZANIM))):
			return Vector2i.DOWN
	if absf(yatay) > 0.5:
		var d := 1 if yatay > 0.0 else -1
		if _kazilabilir(dunya.hucre(global_position + Vector2(d * YAN_UZANIM, 0))):
			return Vector2i(d, 0)
	return Vector2i.ZERO

func _kazilabilir(h: Vector2i) -> bool:
	var t := dunya.karo_tur(h)
	if t == Ayarlar.BOS:
		return false
	if t == Ayarlar.CEKIRDEK:
		return true   ## dokunmak yeter
	return dunya.kazilabilir_mi(t)

func _kaz(yon: Vector2i, delta: float) -> void:
	var uzanim := Vector2(yon.x * YAN_UZANIM, yon.y * ALT_UZANIM)
	var h := dunya.hucre(global_position + uzanim)
	if h != _hedef:
		_hedef = h
		_ilerleme = 0.0
	velocity.x = 0.0

	var tur := dunya.karo_tur(h)
	if tur == Ayarlar.CEKIRDEK:
		cekirdege_ulasildi.emit()
		return

	# Katman kapısı: matkap yetmiyorsa ilerleme yok.
	if not durum.matkap_yeterli_mi(h.y):
		_hedef = YOK
		_ilerleme = 0.0
		if _uyari_bekle <= 0.0:
			_uyari_bekle = 1.5
			matkap_yetersiz.emit(Durum.gereken_matkap(h.y) + 1)
		return

	_ilerleme += delta * durum.matkap_hizi()
	if _ilerleme < float(Ayarlar.SERTLIK[tur]):
		return

	_ilerleme = 0.0
	_hedef = YOK
	kir(h)

## Bir hücreyi kırar ve içeriğini işler (maden, gaz, sandık, eser).
func kir(h: Vector2i) -> void:
	var tur := dunya.karo_tur(h)
	if tur == Ayarlar.BOS or not dunya.kazilabilir_mi(tur):
		return
	if not dunya.karo_kir(h):
		return
	var konum := dunya.hucre_merkezi(h)
	durum.kazilan_karo += 1   ## bitiş istatistiği (v0.7): dinamit dahil, düşen kaya hariç
	karo_kirildi.emit(tur, konum)
	match tur:
		Ayarlar.GAZ:
			hasar(Ayarlar.HASAR_GAZ, konum)
			patlama.emit(konum, 1)
		Ayarlar.SANDIK, Ayarlar.ESER:
			sandik_acildi.emit(tur, konum)
		_:
			if Ayarlar.MADEN_DEGER.has(tur):
				maden_toplandi.emit(tur, durum.maden_ekle(tur), konum)

# --- hasar ----------------------------------------------------------------

func hasar(miktar: int, konum: Vector2) -> void:
	if _dokunulmaz > 0.0 or durum == null or durum.bitti:
		return
	_dokunulmaz = DOKUNULMAZ
	durum.hasar_al(miktar)
	hasar_alindi.emit(miktar, konum)
	if durum.bitti:
		kosu_bitti.emit()

func _dusme_carpmasi() -> void:
	if _en_hizli_dusus >= Ayarlar.DUSME_HASAR_HIZ:
		hasar(1, global_position)
	_en_hizli_dusus = 0.0

## Lav yakındaysa (ve ısı kalkanı yoksa) saniyede bir hasar.
func _lav_kontrol(delta: float) -> void:
	if durum.alet_var("kalkan"):
		_lav_birikim = 0.0
		return
	var m := hucre()
	var yakin := false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dunya.karo_tur(m + Vector2i(dx, dy)) == Ayarlar.LAV:
				yakin = true
	if not yakin:
		_lav_birikim = 0.0
		return
	_lav_birikim += delta
	if _lav_birikim >= 1.0:
		_lav_birikim = 0.0
		_dokunulmaz = 0.0   ## lav sürekli yakar, dokunulmazlık işlemez
		hasar(Ayarlar.HASAR_LAV, global_position)

# --- aletler --------------------------------------------------------------

## 3x3 patlatma. Yönü aşağı/yana girdiye göre seçer, yoksa aracın altını patlatır.
func dinamit_at() -> bool:
	if durum.dinamit <= 0 or not is_on_floor():
		return false
	durum.dinamit -= 1
	var merkez := hucre() + Vector2i.DOWN
	var yatay := Input.get_axis("sol", "sag")
	if absf(yatay) > 0.5 and not Input.is_action_pressed("asagi"):
		merkez = hucre() + Vector2i(1 if yatay > 0.0 else -1, 0)
	var r := Ayarlar.DINAMIT_YARICAP
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var h := merkez + Vector2i(dx, dy)
			if durum.matkap_yeterli_mi(h.y):
				kir(h)
	patlama.emit(dunya.hucre_merkezi(merkez), r + 1)
	return true

## Üsün üstünde, altı DOLU bir hücrenin merkezi. Oyuncu şaftı üssün tam altına
## kazıyor; v0.5'e kadar üsse ışınlanan ya da çekilen araç (520, -24)'e konup kendi
## şaftına düşüyordu — mağaza açılamıyor, depremden ışınlanan ikramiyeyi kaçırıyordu
## (v0.6 sahne testi "istasyondan bedava kaçış" senaryosunda yakaladı). Şaftın
## yanındaki ilk dolu sütuna iner; üs yarıçapı (60 px) ±3 karoyu kapsıyor.
func yuzey_konumu() -> Vector2:
	var x := Ayarlar.US_KARO_X
	if dunya != null:
		for dx in [0, 1, -1, 2, -2, 3, -3]:
			if dunya.karo_tur(Vector2i(Ayarlar.US_KARO_X + dx, 0)) != Ayarlar.BOS:
				x = Ayarlar.US_KARO_X + dx
				break
	return Vector2(float(x) * Ayarlar.KARO + Ayarlar.KARO * 0.5, -24.0)

func isinlan(hedef: Vector2) -> void:
	global_position = yuzey_konumu() if hedef.y < 0.0 else hedef
	velocity = Vector2.ZERO
	_hedef = YOK
	_ilerleme = 0.0
	_en_hizli_dusus = 0.0
	durum.yakit_harca(Ayarlar.ISINLAMA_YAKIT)

func usse_don() -> void:
	global_position = yuzey_konumu()
	velocity = Vector2.ZERO
	_hedef = YOK
	_ilerleme = 0.0
	_en_hizli_dusus = 0.0
	_lav_birikim = 0.0

func usste_mi() -> bool:
	return global_position.y < 8.0 and absf(global_position.x - Ayarlar.US_X) < Ayarlar.US_YARICAP
