## Matkaplı araç. Sağ/sol/aşağı kazar, yukarı sadece pervaneyle çıkar.
## Kazmak için zemine basmak gerekir; havada asılıyken kazılmaz.
class_name Arac
extends CharacterBody2D

signal maden_toplandi(tur: int, alindi: bool)
signal cekirdege_ulasildi
signal yakit_bitti

const YAN_UZANIM := 9.0    ## kazma hedefi ararken merkeze eklenen piksel
const ALT_UZANIM := 9.0
const YOK := Vector2i(1 << 30, 1 << 30)   ## "hedef yok"

var durum: Durum
var dunya: Dunya
var kilitli := false       ## menü/duraklatma açıkken hareket yok

var _hedef := YOK
var _ilerleme := 0.0

@onready var _matkap_gorsel: Polygon2D = $Matkap

func _physics_process(delta: float) -> void:
	if kilitli or durum == null or durum.bitti or durum.kazandi:
		return

	durum.sure += delta
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

	move_and_slide()
	# Yüzeyde kenardan uçup gitmeyi engelle (yerin üstünde duvar karosu yok).
	global_position.x = clampf(global_position.x, Ayarlar.KARO * 1.5, (Ayarlar.GENISLIK - 1.5) * Ayarlar.KARO)

	var derinlik := maxi(0, floori(global_position.y / Ayarlar.KARO))
	durum.en_derin = maxi(durum.en_derin, derinlik)
	_matkap_gorsel.position = Vector2(yon.x, yon.y) * 7.0

	if durum.bitti:
		yakit_bitti.emit()

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
		return true   ## dokunmak yeter, kazma ilerlemesi bunu hemen bitirir
	return float(Ayarlar.SERTLIK.get(t, -1.0)) > 0.0

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

	_ilerleme += delta * durum.matkap_hizi()
	if _ilerleme < float(Ayarlar.SERTLIK[tur]):
		return

	dunya.karo_kir(h)
	_ilerleme = 0.0
	_hedef = YOK
	if Ayarlar.MADEN_DEGER.has(tur):
		maden_toplandi.emit(tur, durum.maden_ekle(tur))

func usse_don() -> void:
	global_position = Vector2(Ayarlar.US_X, -24.0)
	velocity = Vector2.ZERO
	_hedef = YOK
	_ilerleme = 0.0

func usste_mi() -> bool:
	return global_position.y < 8.0 and absf(global_position.x - Ayarlar.US_X) < Ayarlar.US_YARICAP
