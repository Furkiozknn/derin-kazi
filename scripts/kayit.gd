## user://kayit.cfg okuma/yazma. Bölümler:
##   [oyun]   ana ilerleme (para, geliştirme, eserler, istasyonlar, kazılan hücreler)
##   [gunluk] günlük dünya — ayrı yuva, ana ilerlemeyi hiç etkilemez
##   [ayar]   ses düzeyleri, tam ekran, oyun hissi
##
## `aktif` hangi yuvanın oynandığını söyler; menü sahne değiştirmeden önce ayarlar.
## Statik değişken olduğu için sahne geçişinde korunur, uygulama kapanınca "oyun"a döner.
class_name Kayit
extends RefCounted

const YOL := "user://kayit.cfg"
const ANA := "oyun"
const GUNLUK := "gunluk"

static var aktif := ANA

const AYAR_VARSAYILAN := {
	"muzik_ses": 0.7, "efekt_ses": 0.85,
	"muzik_acik": true, "efekt_acik": true,
	"tam_ekran": false, "sarsinti": true,
}

static func _cfg() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(YOL)
	return cfg

static func _oku(bolum: String, varsayilan: Dictionary) -> Dictionary:
	var cfg := _cfg()
	var d := varsayilan.duplicate()
	if cfg.has_section(bolum):
		for anahtar in cfg.get_section_keys(bolum):
			d[anahtar] = cfg.get_value(bolum, anahtar)
	return d

static func _yaz(bolum: String, d: Dictionary) -> void:
	var cfg := _cfg()
	for anahtar in d:
		cfg.set_value(bolum, anahtar, d[anahtar])
	cfg.save(YOL)

static func yukle(bolum := "") -> Dictionary:
	var cfg := _cfg()
	var b := bolum if bolum != "" else aktif
	if not cfg.has_section(b):
		return {}
	var d := {}
	for anahtar in cfg.get_section_keys(b):
		d[anahtar] = cfg.get_value(b, anahtar)
	return d

static func kaydet(d: Dictionary, bolum := "") -> void:
	_yaz(bolum if bolum != "" else aktif, d)

static func sil(bolum := "") -> void:
	var cfg := _cfg()
	var b := bolum if bolum != "" else aktif
	if cfg.has_section(b):
		cfg.erase_section(b)
	cfg.save(YOL)

static func var_mi() -> bool:
	return not yukle().is_empty()

# --- günlük dünya ---------------------------------------------------------

## Bugünün etiketi ("2026-09-16"). Günlük tohum bundan türer.
static func bugun() -> String:
	var t := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(t["year"]), int(t["month"]), int(t["day"])]

## Tarihten türeyen tohum — aynı gün herkeste aynı dünya.
static func gunluk_tohum(gun := "") -> int:
	return absi(hash("derin-kazi-" + (gun if gun != "" else bugun()))) & 0xFFFFFFFF

## Günlük yuvayı bugüne hazırlar: gün değiştiyse yuva sıfırlanır, dünkü en derin
## nokta `dun_derin` olarak saklanır. Dönüş: o günün kaydı.
static func gunluk_hazirla() -> Dictionary:
	var g := bugun()
	var k := yukle(GUNLUK)
	if String(k.get("gun", "")) == g:
		return k
	var dun := int(k.get("en_derin", 0))
	sil(GUNLUK)
	var yeni := {"tohum": gunluk_tohum(g), "gun": g, "dun_derin": dun}
	kaydet(yeni, GUNLUK)
	return yeni

# --- ayarlar --------------------------------------------------------------

static func ayar_yukle() -> Dictionary:
	return _oku("ayar", AYAR_VARSAYILAN)

static func ayar_kaydet(d: Dictionary) -> void:
	_yaz("ayar", d)
