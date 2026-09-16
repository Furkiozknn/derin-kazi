## Karo haritası. TileSet'i kodda kurar (ayrı .tres yok), dünyayı parça parça üretir.
## Parça = PARCA satır. Aracın 26 karo üstü/altı hazır tutulur; geri kalanı hiç oluşturulmaz.
class_name Dunya
extends TileMapLayer

const GORUS_KARO := 26

var uretici: DunyaUretici
var _parcalar := {}        ## parça indeksi -> true
var uretilen_karo := 0     ## ölçüm için

func kur(tohum: int) -> void:
	uretici = DunyaUretici.new(tohum)
	tile_set = _tileset_kur()
	clear()
	_parcalar.clear()
	uretilen_karo = 0

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
	for i in 9:
		kaynak.create_tile(Vector2i(i, 0))
		var veri := kaynak.get_tile_data(Vector2i(i, 0), 0)
		veri.add_collision_polygon(0)
		veri.set_collision_polygon_points(0, 0, kare)
	return ts

## Verilen piksel yüksekliğinin çevresindeki parçaların üretildiğinden emin olur.
func hazirla(y_piksel: float) -> void:
	var y := floori(y_piksel / Ayarlar.KARO)
	var ilk := floori(float(y - GORUS_KARO) / Ayarlar.PARCA)
	var son := floori(float(y + GORUS_KARO) / Ayarlar.PARCA)
	for p in range(maxi(ilk, 0), son + 1):
		_parca_uret(p)

func _parca_uret(p: int) -> void:
	if _parcalar.has(p):
		return
	_parcalar[p] = true
	var y0 := p * Ayarlar.PARCA
	if y0 >= Ayarlar.DERINLIK:
		return
	for y in range(y0, mini(y0 + Ayarlar.PARCA, Ayarlar.DERINLIK)):
		for x in Ayarlar.GENISLIK:
			var t := uretici.karo(x, y)
			if t != Ayarlar.BOS:
				set_cell(Vector2i(x, y), 0, Vector2i(t, 0))
				uretilen_karo += 1

## Hücredeki karo türü. Boşsa Ayarlar.BOS.
func karo_tur(hucre: Vector2i) -> int:
	var a := get_cell_atlas_coords(hucre)
	return a.x if a.x >= 0 else Ayarlar.BOS

func karo_kir(hucre: Vector2i) -> void:
	erase_cell(hucre)

## Dünya konumundan karo hücresine.
func hucre(dunya_konum: Vector2) -> Vector2i:
	return local_to_map(to_local(dunya_konum))
