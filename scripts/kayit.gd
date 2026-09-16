## user://kayit.cfg okuma/yazma. İki bölüm:
##   [oyun] ilerleme (para, geliştirme, eserler, istasyonlar, kazılan hücreler)
##   [ayar] ses düzeyleri, tam ekran, oyun hissi
class_name Kayit
extends RefCounted

const YOL := "user://kayit.cfg"

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

static func yukle() -> Dictionary:
	var cfg := _cfg()
	if not cfg.has_section("oyun"):
		return {}
	var d := {}
	for anahtar in cfg.get_section_keys("oyun"):
		d[anahtar] = cfg.get_value("oyun", anahtar)
	return d

static func kaydet(d: Dictionary) -> void:
	_yaz("oyun", d)

static func sil() -> void:
	var cfg := _cfg()
	if cfg.has_section("oyun"):
		cfg.erase_section("oyun")
	cfg.save(YOL)

static func var_mi() -> bool:
	return not yukle().is_empty()

static func ayar_yukle() -> Dictionary:
	return _oku("ayar", AYAR_VARSAYILAN)

static func ayar_kaydet(d: Dictionary) -> void:
	_yaz("ayar", d)
