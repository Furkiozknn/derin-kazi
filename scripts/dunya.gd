## Karo haritası. TileSet'i kodda kurar (ayrı .tres yok), dünyayı 16x16 chunk'larla üretir.
## Yalnız aracın çevresindeki chunk'lar TileMapLayer'da durur; uzaktakiler boşaltılır.
## Kazılan hücreler `kazilan` sözlüğünde fark olarak tutulur ve kayda yazılır —
## oyun kapatılıp açılınca tüneller yerinde kalır.
class_name Dunya
extends TileMapLayer

const YARICAP := 1          ## kaç chunk uzaklığa kadar yüklü kalsın
const YUZEY_KAYNAK := 1     ## TileSet'te yüzey atlasının (yuzey.png) kaynak numarası; 0 = karolar.png

var uretici: DunyaUretici
var kazilan := {}           ## Vector2i -> true (kırılmış hücre)
var eklenen := {}           ## Vector2i -> karo türü (deprem sonrası kapanan/çıkan hücre)
## Keşif sisi: her hücre için 1 bayt (1 = görüldü). Dictionary değil düz dizi,
## çünkü ışık her karo değişiminde ~80 hücre işaretliyor ve bot simülasyonu
## bunu milyonlarca kez yapıyor. Kayda sıkıştırılmış olarak yazılır (kesif_dizi).
var kesfedilen := PackedByteArray()
var _yuklu := {}            ## chunk Vector2i -> true
var toplam_uretim := 0      ## ölçüm: oturum boyunca üretilen karo (bkz. yuklu_karo)

func kur(tohum: int, p_kazilan := {}, p_eklenen := {}, p_kesif := "") -> void:
	uretici = DunyaUretici.new(tohum)
	kazilan = p_kazilan.duplicate()
	eklenen = p_eklenen.duplicate()
	kesfedilen = diziden_kesif(p_kesif)
	# v0.4 ve öncesinin kaydında keşif yok: kazılmış tünellerin çevresini açarak
	# eski kayıt kapkaranlık başlamasın (kaydı bozmadan ileri uyumluluk).
	if p_kesif == "" and not kazilan.is_empty():
		for h in kazilan:
			kesfet(h, Ayarlar.ISIK_YARICAP)
	tile_set = _tileset_kur()
	clear()
	_yuklu.clear()
	toplam_uretim = 0

func _tileset_kur() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(Ayarlar.KARO, Ayarlar.KARO)
	var kaynak := TileSetAtlasSource.new()
	kaynak.texture = load("res://assets/sprites/karolar.png")
	kaynak.texture_region_size = Vector2i(Ayarlar.KARO, Ayarlar.KARO)
	# Sıra önemli: kaynak TileSet'e bağlanmadan ve fizik katmanı açılmadan
	# oluşturulan TileData çarpışma katmanını görmez (add_collision_polygon patlar).
	ts.add_source(kaynak, 0)
	ts.add_physics_layer(0)
	var y := float(Ayarlar.KARO) * 0.5
	var kare := PackedVector2Array([
		Vector2(-y, -y), Vector2(y, -y), Vector2(y, y), Vector2(-y, y)
	])
	# Her karo türünün VARYANT_SAYISI satırı var: aynı 16 px doku ekranda tekrarlamasın.
	for i in Ayarlar.KARO_SAYISI:
		for v in Ayarlar.VARYANT_SAYISI:
			var koord := Vector2i(i, v)
			kaynak.create_tile(koord)
			var veri := kaynak.get_tile_data(koord, 0)
			veri.add_collision_polygon(0)
			veri.set_collision_polygon_points(0, 0, kare)
	# Yüzey (v0.7): 0. satırın toprağı ikinci bir atlastan (yuzey.png) çizilir — çimen
	# üstü kırık kenarlı, gökyüzüyle birleşim düz çizgi değil. Çarpışma aynı tam kare;
	# mantıksal karo türü değişmedi (karo_tur hâlâ TOPRAK der).
	var yuzey := TileSetAtlasSource.new()
	yuzey.texture = load("res://assets/sprites/yuzey.png")
	yuzey.texture_region_size = Vector2i(Ayarlar.KARO, Ayarlar.KARO)
	ts.add_source(yuzey, YUZEY_KAYNAK)
	for v in Ayarlar.YUZEY_VARYANT:
		var koord := Vector2i(v, 0)
		yuzey.create_tile(koord)
		var veri := yuzey.get_tile_data(koord, 0)
		veri.add_collision_polygon(0)
		veri.set_collision_polygon_points(0, 0, kare)
	return ts

# --- chunk yönetimi -------------------------------------------------------

static func parca_no(hucre: Vector2i) -> Vector2i:
	return Vector2i(floori(float(hucre.x) / Ayarlar.PARCA), floori(float(hucre.y) / Ayarlar.PARCA))

## Verilen dünya konumunun çevresindeki chunk'ları yükler, uzaktakileri boşaltır.
func hazirla(konum: Vector2) -> void:
	var merkez := parca_no(hucre(konum))
	var gerekli := {}
	for dx in range(-YARICAP, YARICAP + 1):
		for dy in range(-YARICAP, YARICAP + 1):
			var p := merkez + Vector2i(dx, dy)
			gerekli[p] = true
			_parca_yukle(p)
	for p in _yuklu.keys():
		if not gerekli.has(p):
			_parca_bosalt(p)

func _parca_yukle(p: Vector2i) -> void:
	if _yuklu.has(p) or p.y < 0:
		return
	if p.x < 0 or p.x * Ayarlar.PARCA >= Ayarlar.GENISLIK or p.y * Ayarlar.PARCA >= Ayarlar.DERINLIK:
		return
	_yuklu[p] = true
	for y in range(p.y * Ayarlar.PARCA, mini((p.y + 1) * Ayarlar.PARCA, Ayarlar.DERINLIK)):
		for x in range(p.x * Ayarlar.PARCA, mini((p.x + 1) * Ayarlar.PARCA, Ayarlar.GENISLIK)):
			var h := Vector2i(x, y)
			var t := karo_tur(h)
			if t == Ayarlar.BOS:
				continue
			if y == 0 and t == Ayarlar.TOPRAK:
				set_cell(h, YUZEY_KAYNAK, Vector2i(Ayarlar.yuzey_varyant(x), 0))
			else:
				set_cell(h, 0, Vector2i(t, Ayarlar.varyant(x, y, t)))
			toplam_uretim += 1

func _parca_bosalt(p: Vector2i) -> void:
	_yuklu.erase(p)
	for y in range(p.y * Ayarlar.PARCA, mini((p.y + 1) * Ayarlar.PARCA, Ayarlar.DERINLIK)):
		for x in range(p.x * Ayarlar.PARCA, mini((p.x + 1) * Ayarlar.PARCA, Ayarlar.GENISLIK)):
			if get_cell_source_id(Vector2i(x, y)) >= 0:
				erase_cell(Vector2i(x, y))

func yuklu_parca_sayisi() -> int:
	return _yuklu.size()

## Şu an bellekte duran karo sayısı (ölçüm ve testler için).
func yuklu_karo() -> int:
	return get_used_cells().size()

# --- sorgular -------------------------------------------------------------

## Hücredeki mantıksal karo türü. Chunk yüklü olmasa da doğru cevap verir.
func karo_tur(h: Vector2i) -> int:
	if kazilan.has(h):
		return Ayarlar.BOS
	if eklenen.has(h):
		return int(eklenen[h])
	return uretici.karo(h.x, h.y)

func kazilabilir_mi(t: int) -> bool:
	return float(Ayarlar.SERTLIK.get(t, -1.0)) > 0.0

## Karoyu kırar ve farkı kaydeder. Zaten boşsa false döner.
func karo_kir(h: Vector2i) -> bool:
	if karo_tur(h) == Ayarlar.BOS:
		return false
	eklenen.erase(h)
	kazilan[h] = true
	if get_cell_source_id(h) >= 0:
		erase_cell(h)
	return true

## Dünya konumundan karo hücresine.
func hucre(dunya_konum: Vector2) -> Vector2i:
	return local_to_map(to_local(dunya_konum))

func hucre_merkezi(h: Vector2i) -> Vector2:
	return to_global(map_to_local(h))

## En yakın madenin hücresi (radar için). Bulamazsa false dönen Vector2i(0,0) yerine boş dizi.
func en_yakin_maden(merkez: Vector2i, menzil := 14) -> Array:
	var en_iyi := []
	var en_uzak := 1e9
	for dy in range(-menzil, menzil + 1):
		for dx in range(-menzil, menzil + 1):
			var h := merkez + Vector2i(dx, dy)
			if not Ayarlar.MADEN_DEGER.has(karo_tur(h)):
				continue
			var u := float(dx * dx + dy * dy)
			if u < en_uzak:
				en_uzak = u
				en_iyi = [h]
	return en_iyi

# --- keşif sisi -----------------------------------------------------------

static func _sis_boyut() -> int:
	return Ayarlar.GENISLIK * Ayarlar.DERINLIK

func kesfedildi_mi(h: Vector2i) -> bool:
	if h.x < 0 or h.y < 0 or h.x >= Ayarlar.GENISLIK or h.y >= Ayarlar.DERINLIK:
		return true   ## dünyanın dışı (gökyüzü, kenar) hep görünür
	return kesfedilen[h.y * Ayarlar.GENISLIK + h.x] == 1

## `merkez`in çevresindeki daireyi kalıcı olarak açar.
## Dönüş: YENİ açılan hücreler (mini haritayı yalnız onlar için boyamak yeter).
func kesfet(merkez: Vector2i, yaricap: int) -> Array:
	var yeni: Array = []
	for dy in range(-yaricap, yaricap + 1):
		var y := merkez.y + dy
		if y < 0 or y >= Ayarlar.DERINLIK:
			continue
		var satir := y * Ayarlar.GENISLIK
		for dx in range(-yaricap, yaricap + 1):
			if dx * dx + dy * dy > yaricap * yaricap:
				continue
			var x := merkez.x + dx
			if x < 0 or x >= Ayarlar.GENISLIK:
				continue
			if kesfedilen[satir + x] == 1:
				continue
			kesfedilen[satir + x] = 1
			yeni.append(Vector2i(x, y))
	return yeni

func kesif_sayisi() -> int:
	var n := 0
	for b in kesfedilen:
		n += b
	return n

## Kayıt: 17 408 baytlık keşif haritası sıkıştırılıp base64'e çevriliyor.
## Düz dizi olarak yazılsa ConfigFile'a yüz binlerce karakter giriyordu.
func kesif_dizi() -> String:
	return Marshalls.raw_to_base64(kesfedilen.compress(FileAccess.COMPRESSION_DEFLATE))

static func diziden_kesif(s) -> PackedByteArray:
	var bos := PackedByteArray()
	bos.resize(_sis_boyut())
	if s == null or String(s) == "":
		return bos
	var ham := Marshalls.base64_to_raw(String(s))
	if ham.is_empty():
		return bos
	var acik := ham.decompress(_sis_boyut(), FileAccess.COMPRESSION_DEFLATE)
	return acik if acik.size() == _sis_boyut() else bos

## Deprem sonucunu uygular: kapanan tüneller dolar, yeni gaz/damar hücreleri açılır.
## Yüklü chunk'lar boşaltılır — bir sonraki hazirla() çağrısı yeniden üretir.
func degistir(kapanan: Array, yeni: Dictionary) -> void:
	for h in kapanan:
		kazilan.erase(h)
	for h in yeni:
		kazilan.erase(h)
		eklenen[h] = int(yeni[h])
	clear()
	_yuklu.clear()


## Kayıt: kazılan hücreleri düz bir tamsayı dizisine çevirir (ConfigFile dostu).
func kazilan_dizi() -> PackedInt32Array:
	var d := PackedInt32Array()
	for h in kazilan:
		d.append(h.x)
		d.append(h.y)
	return d

## Kayıt: eklenen hücreler (x, y, karo) üçlüleri.
func eklenen_dizi() -> PackedInt32Array:
	var d := PackedInt32Array()
	for h in eklenen:
		d.append(h.x)
		d.append(h.y)
		d.append(int(eklenen[h]))
	return d

static func diziden_eklenen(d) -> Dictionary:
	var s := {}
	if d == null:
		return s
	var a := PackedInt32Array(d)
	var i := 0
	while i + 2 < a.size():
		s[Vector2i(a[i], a[i + 1])] = a[i + 2]
		i += 3
	return s

static func diziden_kazilan(d) -> Dictionary:
	var s := {}
	if d == null:
		return s
	var a := PackedInt32Array(d)
	var i := 0
	while i + 1 < a.size():
		s[Vector2i(a[i], a[i + 1])] = true
		i += 2
	return s
