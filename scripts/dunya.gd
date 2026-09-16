## Karo haritası. TileSet'i kodda kurar (ayrı .tres yok), dünyayı 16x16 chunk'larla üretir.
## Yalnız aracın çevresindeki chunk'lar TileMapLayer'da durur; uzaktakiler boşaltılır.
## Kazılan hücreler `kazilan` sözlüğünde fark olarak tutulur ve kayda yazılır —
## oyun kapatılıp açılınca tüneller yerinde kalır.
class_name Dunya
extends TileMapLayer

const YARICAP := 1          ## kaç chunk uzaklığa kadar yüklü kalsın

var uretici: DunyaUretici
var kazilan := {}           ## Vector2i -> true
var _yuklu := {}            ## chunk Vector2i -> true
var toplam_uretim := 0      ## ölçüm: oturum boyunca üretilen karo (bkz. yuklu_karo)

func kur(tohum: int, p_kazilan := {}) -> void:
	uretici = DunyaUretici.new(tohum)
	kazilan = p_kazilan.duplicate()
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
	for i in Ayarlar.KARO_SAYISI:
		kaynak.create_tile(Vector2i(i, 0))
		var veri := kaynak.get_tile_data(Vector2i(i, 0), 0)
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
			if kazilan.has(h):
				continue
			var t := uretici.karo(x, y)
			if t != Ayarlar.BOS:
				set_cell(h, 0, Vector2i(t, 0))
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
	return uretici.karo(h.x, h.y)

func kazilabilir_mi(t: int) -> bool:
	return float(Ayarlar.SERTLIK.get(t, -1.0)) > 0.0

## Karoyu kırar ve farkı kaydeder. Zaten boşsa false döner.
func karo_kir(h: Vector2i) -> bool:
	if kazilan.has(h) or uretici.karo(h.x, h.y) == Ayarlar.BOS:
		return false
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

## Kayıt: kazılan hücreleri düz bir tamsayı dizisine çevirir (ConfigFile dostu).
func kazilan_dizi() -> PackedInt32Array:
	var d := PackedInt32Array()
	for h in kazilan:
		d.append(h.x)
		d.append(h.y)
	return d

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
