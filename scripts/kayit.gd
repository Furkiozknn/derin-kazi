## user://kayit.cfg okuma/yazma.
## Kazılmış karolar saklanmaz: yeni koşu = aynı tohumla temiz dünya (görev gereği).
class_name Kayit
extends RefCounted

const YOL := "user://kayit.cfg"

static func yukle() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(YOL) != OK:
		return {}
	if not cfg.has_section("oyun"):
		return {}
	var d := {}
	for anahtar in cfg.get_section_keys("oyun"):
		d[anahtar] = cfg.get_value("oyun", anahtar)
	return d

static func kaydet(d: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for anahtar in d:
		cfg.set_value("oyun", anahtar, d[anahtar])
	cfg.save(YOL)

static func var_mi() -> bool:
	return FileAccess.file_exists(YOL)
