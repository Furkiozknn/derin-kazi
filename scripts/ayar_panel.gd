## Ayarlar ekranının içeriğini bir VBoxContainer'a kurar.
## Hem ana menü hem duraklatma menüsü aynı kodu kullanır; değerler
## `user://kayit.cfg` içindeki [ayar] bölümüne Ses üzerinden yazılır.
class_name AyarPanel
extends RefCounted

static func kur(kap: VBoxContainer, kapat: Callable) -> void:
	for c in kap.get_children():
		kap.remove_child(c)
		c.queue_free()

	_kaydirici(kap, "Müzik", "muzik_ses")
	_anahtar(kap, "Müzik açık", "muzik_acik")
	_kaydirici(kap, "Efekt", "efekt_ses")
	_anahtar(kap, "Efektler açık", "efekt_acik")
	_anahtar(kap, "Ekran sarsıntısı", "sarsinti")
	if not OS.has_feature("web"):
		_anahtar(kap, "Tam ekran", "tam_ekran")

	var b := Button.new()
	b.text = "Kapat"
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(func() -> void:
		Ses.cal("menu")
		kapat.call())
	kap.add_child(b)

static func _satir(kap: VBoxContainer, metin: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", 11)
	l.custom_minimum_size = Vector2(120, 0)
	h.add_child(l)
	kap.add_child(h)
	return h

static func _kaydirici(kap: VBoxContainer, metin: String, anahtar: String) -> void:
	var h := _satir(kap, metin)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Ses.ayar.get(anahtar, 0.8))
	s.custom_minimum_size = Vector2(150, 0)
	var yuzde := Label.new()
	yuzde.text = "%d%%" % int(s.value * 100.0)
	yuzde.add_theme_font_size_override("font_size", 11)
	yuzde.custom_minimum_size = Vector2(44, 0)
	s.value_changed.connect(func(v: float) -> void:
		yuzde.text = "%d%%" % int(v * 100.0)
		Ses.ayarla(anahtar, v))
	h.add_child(s)
	h.add_child(yuzde)

static func _anahtar(kap: VBoxContainer, metin: String, anahtar: String) -> void:
	var c := CheckButton.new()
	c.text = metin
	c.add_theme_font_size_override("font_size", 11)
	c.button_pressed = bool(Ses.ayar.get(anahtar, true))
	c.toggled.connect(func(acik: bool) -> void:
		Ses.cal("menu")
		Ses.ayarla(anahtar, acik))
	kap.add_child(c)
