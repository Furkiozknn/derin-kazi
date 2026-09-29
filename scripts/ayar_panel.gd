## Ayarlar ekranının içeriğini bir VBoxContainer'a kurar.
## Hem ana menü hem duraklatma menüsü aynı kodu kullanır; değerler
## `user://kayit.cfg` içindeki [ayar] bölümüne Ses üzerinden yazılır.
## v0.8: ses (müzik/efekt), ekran sarsıntısı, tam ekran ve DİL (TR/EN) — tek sütun.
class_name AyarPanel
extends RefCounted

## dil_degisti: dil düğmesine basılınca çağrılır (çağıran arayüzü yeniden kurar).
static func kur(kap: VBoxContainer, kapat: Callable, dil_degisti := Callable()) -> void:
	for c in kap.get_children():
		kap.remove_child(c)
		c.queue_free()

	_kaydirici(kap, Ceviri.t("Müzik"), "muzik_ses", "muzik_acik")
	_kaydirici(kap, Ceviri.t("Efekt"), "efekt_ses", "efekt_acik")
	_anahtar(kap, Ceviri.t("Ekran sarsıntısı"), "sarsinti")
	_anahtar(kap, Ceviri.t("Sade geçişler"), "sade_gecis", false)   ## hareket azaltma: geçiş efekti yok, anında
	if not OS.has_feature("web"):
		_anahtar(kap, Ceviri.t("Tam ekran"), "tam_ekran")
	_dil(kap, dil_degisti)

	var b := Button.new()
	b.text = Ceviri.t("Kapat")
	b.theme_type_variation = &"Birincil"
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(0, 26)
	b.pressed.connect(func() -> void:
		Ses.cal("menu")
		kapat.call())
	kap.add_child(b)
	UI.dugmeleri_bagla(kap)


static func _satir(kap: VBoxContainer, metin: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := Tema.etiket(Tema.buyuk(metin), 9, Tema.KAGIT)
	l.custom_minimum_size = Vector2(96, 0)
	h.add_child(l)
	kap.add_child(h)
	return h

## Kaydırıcı + açma/kapama: ses düzeyi ve "kapalı" aynı satırda (0 = sessiz yerine ayrı anahtar).
static func _kaydirici(kap: VBoxContainer, metin: String, anahtar: String, acik_anahtar: String) -> void:
	var h := _satir(kap, metin)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Ses.ayar.get(anahtar, 0.8))
	s.custom_minimum_size = Vector2(130, 14)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var yuzde := Tema.etiket("%d%%" % int(s.value * 100.0), 9, Tema.KAGIT)
	yuzde.custom_minimum_size = Vector2(30, 0)
	s.value_changed.connect(func(v: float) -> void:
		yuzde.text = "%d%%" % int(v * 100.0)
		Ses.ayarla(anahtar, v))
	h.add_child(s)
	h.add_child(yuzde)
	var c := CheckButton.new()
	c.button_pressed = bool(Ses.ayar.get(acik_anahtar, true))
	c.toggled.connect(func(acik: bool) -> void:
		Ses.cal("menu")
		Ses.ayarla(acik_anahtar, acik))
	h.add_child(c)

static func _anahtar(kap: VBoxContainer, metin: String, anahtar: String, varsayilan := true) -> void:
	var c := CheckButton.new()
	c.text = metin
	c.add_theme_font_size_override("font_size", 11)
	c.button_pressed = bool(Ses.ayar.get(anahtar, varsayilan))
	c.toggled.connect(func(acik: bool) -> void:
		Ses.cal("menu")
		Ses.ayarla(anahtar, acik))
	kap.add_child(c)

## Dil: etkin dilin karşısındakini gösteren düğme; basınca öbürüne geçer, tercih kaydedilir.
static func _dil(kap: VBoxContainer, degisti: Callable) -> void:
	var h := _satir(kap, Ceviri.t("Dil"))
	var d := Button.new()
	d.text = "English" if Kayit.dil_etkin(Ses.ayar) == "tr" else "Türkçe"
	d.add_theme_font_size_override("font_size", 11)
	d.pressed.connect(func() -> void:
		Ses.cal("menu")
		Gecis.ara(&"glitch", 0, func() -> void:   ## dil değişimi: glitch örtüsünün altında yeni metin
			Ses.ayarla("dil", "en" if Kayit.dil_etkin(Ses.ayar) == "tr" else "tr")
			if degisti.is_valid():
				degisti.call()))
	h.add_child(d)
