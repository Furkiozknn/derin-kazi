extends SceneTree
## Proje temasini (assets/tema.tres) kodla uretir. .tres'i elle yazmak BOM/kacis
## tuzaklarina aciktir; ResourceSaver dogru yazar.
##   godot --headless --path . -s res://tools/tema_uret.gd
## Sonra: godot --headless --path . --import
##
## Video dili: duz dolgu, golgesiz. Birincil dugme = amber + murekkep yazi
## (derin-kazi videosunun amber vurgusu); ikincil = seffaf + kagit
## 2 px cizgi. Kart = kagit zemin, murekkep yazi. Kaydirici tutamagi ve
## anahtar simgeleri asagida kodla cizilir, tema icine gomulur (PNG dosyasi yok).

const KAGIT := Color("f3e8d7")
const MUREKKEP := Color("1c130d")
const AMBER := Color("f3a33d")
const TURUNCU := Color("f3a33d")
const PANEL := Color("2a1e16")


func _initialize() -> void:
	var t := Theme.new()
	var govde := _font("res://assets/fonts/InstrumentSans-Regular.ttf", 0)
	var kalin := _font("res://assets/fonts/InstrumentSans-Bold.ttf", 0)
	var mono := _font("res://assets/fonts/JetBrainsMono-Regular.ttf", 1)
	var mono_kalin := _font("res://assets/fonts/JetBrainsMono-Bold.ttf", 1)
	t.default_font = govde
	t.default_font_size = 12

	# --- Label ---
	t.set_color("font_color", "Label", KAGIT)
	t.set_font("font", "Label", govde)
	t.set_font_size("font_size", "Label", 12)
	_varyasyon(t, "Govde", "Label", govde, 12, KAGIT)
	_varyasyon(t, "Baslik", "Label", kalin, 40, KAGIT)
	_varyasyon(t, "Baslik2", "Label", kalin, 20, KAGIT)
	_varyasyon(t, "Etiket", "Label", mono, 8, Color(KAGIT, 0.7))
	_varyasyon(t, "EtiketKalin", "Label", mono_kalin, 8, KAGIT)
	_varyasyon(t, "KartBaslik", "Label", kalin, 20, MUREKKEP)
	_varyasyon(t, "KartYazi", "Label", govde, 12, MUREKKEP)
	_varyasyon(t, "KartEtiket", "Label", mono, 8, Color(MUREKKEP, 0.65))
	_varyasyon(t, "Odul", "Label", mono_kalin, 9, Color("ffc21a"))
	_varyasyon(t, "Vurgu", "Label", mono_kalin, 8, TURUNCU)

	# --- Button (ikincil): seffaf + kagit cizgi ---
	t.set_font("font", "Button", kalin)
	t.set_font_size("font_size", "Button", 12)
	for renk_adi in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(renk_adi, "Button", KAGIT)
	t.set_color("font_disabled_color", "Button", Color(KAGIT, 0.35))
	t.set_stylebox("normal", "Button", _kutu(Color(KAGIT, 0.0), Color(KAGIT, 0.85), 2, 3, 10, 5))
	t.set_stylebox("hover", "Button", _kutu(Color(KAGIT, 0.10), KAGIT, 2, 3, 10, 5))
	t.set_stylebox("pressed", "Button", _kutu(Color(KAGIT, 0.22), KAGIT, 2, 3, 10, 5))
	t.set_stylebox("disabled", "Button", _kutu(Color(KAGIT, 0.0), Color(KAGIT, 0.22), 2, 3, 10, 5))
	t.set_stylebox("focus", "Button", _kutu(Color(AMBER, 0.0), AMBER, 2, 3, 10, 5))
	t.set_constant("outline_size", "Button", 0)

	# --- Button/Birincil: amber dolgu, murekkep yazi ---
	t.add_type("Birincil")
	t.set_type_variation("Birincil", "Button")
	t.set_font("font", "Birincil", kalin)
	t.set_font_size("font_size", "Birincil", 20)
	for renk_adi in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(renk_adi, "Birincil", MUREKKEP)
	t.set_color("font_disabled_color", "Birincil", Color(MUREKKEP, 0.5))
	t.set_stylebox("normal", "Birincil", _kutu(AMBER, AMBER, 0, 3, 16, 8))
	t.set_stylebox("hover", "Birincil", _kutu(Color("f7bd6a"), Color("f7bd6a"), 0, 3, 16, 8))
	t.set_stylebox("pressed", "Birincil", _kutu(Color("d18b26"), Color("d18b26"), 0, 3, 16, 8))
	t.set_stylebox("focus", "Birincil", _kutu(Color(KAGIT, 0.0), KAGIT, 2, 3, 16, 8))
	t.set_stylebox("disabled", "Birincil", _kutu(Color(AMBER, 0.3), Color(AMBER, 0.3), 0, 3, 16, 8))

	# --- Button/KartDugme: kagit kart ustunde ikincil dugme (murekkep cizgi) ---
	t.add_type("KartDugme")
	t.set_type_variation("KartDugme", "Button")
	t.set_font("font", "KartDugme", kalin)
	t.set_font_size("font_size", "KartDugme", 12)
	for renk_adi in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(renk_adi, "KartDugme", MUREKKEP)
	t.set_color("font_disabled_color", "KartDugme", Color(MUREKKEP, 0.3))
	t.set_stylebox("normal", "KartDugme", _kutu(Color(MUREKKEP, 0.0), Color(MUREKKEP, 0.85), 2, 3, 10, 5))
	t.set_stylebox("hover", "KartDugme", _kutu(Color(MUREKKEP, 0.08), MUREKKEP, 2, 3, 10, 5))
	t.set_stylebox("pressed", "KartDugme", _kutu(Color(MUREKKEP, 0.16), MUREKKEP, 2, 3, 10, 5))
	t.set_stylebox("disabled", "KartDugme", _kutu(Color(MUREKKEP, 0.0), Color(MUREKKEP, 0.2), 2, 3, 10, 5))
	t.set_stylebox("focus", "KartDugme", _kutu(Color(AMBER, 0.0), AMBER, 2, 3, 10, 5))

	# --- Button/KartMetin: kart ustunde cizgisiz metin dugmesi ---
	t.add_type("KartMetin")
	t.set_type_variation("KartMetin", "Button")
	t.set_font("font", "KartMetin", govde)
	t.set_font_size("font_size", "KartMetin", 10)
	for renk_adi in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(renk_adi, "KartMetin", Color(MUREKKEP, 0.7))
	t.set_stylebox("normal", "KartMetin", _kutu(Color(MUREKKEP, 0.0), Color(MUREKKEP, 0.0), 0, 3, 8, 3))
	t.set_stylebox("hover", "KartMetin", _kutu(Color(MUREKKEP, 0.08), Color(MUREKKEP, 0.0), 0, 3, 8, 3))
	t.set_stylebox("pressed", "KartMetin", _kutu(Color(MUREKKEP, 0.16), Color(MUREKKEP, 0.0), 0, 3, 8, 3))
	t.set_stylebox("focus", "KartMetin", _kutu(Color(AMBER, 0.0), AMBER, 2, 3, 8, 3))

	# --- Button/Kucuk: satir ve izgara hucreleri (Bolum Sec) ---
	t.add_type("Kucuk")
	t.set_type_variation("Kucuk", "Button")
	t.set_font("font", "Kucuk", govde)
	t.set_font_size("font_size", "Kucuk", 10)
	t.set_stylebox("normal", "Kucuk", _kutu(Color(KAGIT, 0.07), Color(KAGIT, 0.0), 0, 2, 4, 3))
	t.set_stylebox("hover", "Kucuk", _kutu(Color(KAGIT, 0.16), Color(KAGIT, 0.0), 0, 2, 4, 3))
	t.set_stylebox("pressed", "Kucuk", _kutu(Color(KAGIT, 0.28), Color(KAGIT, 0.0), 0, 2, 4, 3))
	t.set_stylebox("disabled", "Kucuk", _kutu(Color(KAGIT, 0.03), Color(KAGIT, 0.0), 0, 2, 4, 3))
	t.set_stylebox("focus", "Kucuk", _kutu(Color(AMBER, 0.0), AMBER, 2, 2, 4, 3))

	# --- OptionButton (ikincil dugme gibi) + acilir liste ---
	t.set_font("font", "OptionButton", kalin)
	t.set_font_size("font_size", "OptionButton", 11)
	for renk_adi in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(renk_adi, "OptionButton", KAGIT)
	for d in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(d, "OptionButton", t.get_stylebox(d, "Button"))
	t.set_stylebox("panel", "PopupMenu", _kutu(PANEL, Color(KAGIT, 0.4), 2, 2, 6, 4))
	t.set_stylebox("hover", "PopupMenu", _kutu(Color(KAGIT, 0.16), Color(KAGIT, 0.0), 0, 2, 4, 2))
	t.set_font("font", "PopupMenu", govde)
	t.set_font_size("font_size", "PopupMenu", 11)
	t.set_color("font_color", "PopupMenu", KAGIT)
	t.set_color("font_hover_color", "PopupMenu", KAGIT)

	# --- Panel: koyu kart, kagit kart, perde, rozet ---
	t.set_stylebox("panel", "Panel", _kutu(PANEL, Color(KAGIT, 0.22), 2, 8, 0, 0))
	t.set_stylebox("panel", "PanelContainer", _kutu(PANEL, Color(KAGIT, 0.22), 2, 8, 0, 0))
	t.add_type("Kagit")
	t.set_type_variation("Kagit", "Panel")
	t.set_stylebox("panel", "Kagit", _kutu(KAGIT, KAGIT, 0, 12, 0, 0))
	t.add_type("Perde")
	t.set_type_variation("Perde", "Panel")
	t.set_stylebox("panel", "Perde", _kutu(Color(MUREKKEP, 0.78), Color(MUREKKEP, 0.0), 0, 0, 0, 0))
	t.add_type("Rozet")
	t.set_type_variation("Rozet", "Panel")
	t.set_stylebox("panel", "Rozet", _kutu(Color(MUREKKEP, 0.86), Color(MUREKKEP, 0.0), 0, 3, 0, 0))

	# --- Kaydirici ---
	t.set_stylebox("slider", "HSlider", _kutu(Color(KAGIT, 0.22), Color(KAGIT, 0.0), 0, 2, 0, 0, 4))
	t.set_stylebox("grabber_area", "HSlider", _kutu(AMBER, AMBER, 0, 2, 0, 0, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", _kutu(Color("f7bd6a"), Color("f7bd6a"), 0, 2, 0, 0, 4))
	var tutamak := _daire_simge(14, AMBER)
	var tutamak_ust := _daire_simge(14, Color("f7bd6a"))
	t.set_icon("grabber", "HSlider", tutamak)
	t.set_icon("grabber_highlight", "HSlider", tutamak_ust)
	t.set_icon("grabber_disabled", "HSlider", _daire_simge(14, Color(KAGIT, 0.4)))
	t.set_constant("center_grabber", "HSlider", 0)

	# --- Anahtar (acik: amber iz, murekkep dugme; kapali: soluk iz, kagit dugme) ---
	var acik := _anahtar_simge(true, false)
	var kapali := _anahtar_simge(false, false)
	var acik_pasif := _anahtar_simge(true, true)
	var kapali_pasif := _anahtar_simge(false, true)
	t.set_icon("checked", "CheckButton", acik)
	t.set_icon("unchecked", "CheckButton", kapali)
	t.set_icon("checked_disabled", "CheckButton", acik_pasif)
	t.set_icon("unchecked_disabled", "CheckButton", kapali_pasif)
	t.set_icon("checked_mirrored", "CheckButton", acik)
	t.set_icon("unchecked_mirrored", "CheckButton", kapali)
	t.set_icon("checked_disabled_mirrored", "CheckButton", acik_pasif)
	t.set_icon("unchecked_disabled_mirrored", "CheckButton", kapali_pasif)
	t.set_font("font", "CheckButton", govde)
	t.set_font_size("font_size", "CheckButton", 12)
	for renk_adi in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color"]:
		t.set_color(renk_adi, "CheckButton", KAGIT)
	t.set_color("font_disabled_color", "CheckButton", Color(KAGIT, 0.4))
	var bos := StyleBoxEmpty.new()
	for d in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		t.set_stylebox(d, "CheckButton", bos)
	t.set_stylebox("focus", "CheckButton", _kutu(Color(AMBER, 0.0), AMBER, 2, 6, 2, 1))

	var hata := ResourceSaver.save(t, "res://assets/tema.tres")
	print("tema.tres yazildi: ", "TAMAM" if hata == OK else "HATA %d" % hata)
	quit(0 if hata == OK else 1)


func _font(yol: String, aralik: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = load(yol)
	f.fallbacks = [load("res://assets/fonts/simgeler.ttf")]
	f.spacing_glyph = aralik
	return f


func _varyasyon(t: Theme, ad: String, taban: String, font: Font, boyut: int, renk: Color) -> void:
	t.add_type(ad)
	t.set_type_variation(ad, taban)
	t.set_font("font", ad, font)
	t.set_font_size("font_size", ad, boyut)
	t.set_color("font_color", ad, renk)


func _kutu(dolgu: Color, cerceve: Color, kalinlik: int, yaricap: int,
		yatay: int, dikey: int, yukseklik: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = dolgu
	s.border_color = cerceve
	s.set_border_width_all(kalinlik)
	s.set_corner_radius_all(yaricap)
	s.content_margin_left = yatay
	s.content_margin_right = yatay
	s.content_margin_top = dikey
	s.content_margin_bottom = dikey
	if yukseklik > 0:
		s.content_margin_top = yukseklik / 2.0
		s.content_margin_bottom = yukseklik / 2.0
	s.anti_aliasing = true
	return s


# --- Kodla cizilen simgeler (4x alt ornekleme ile yumusak kenar) ----------

## Kaplama orani: (px, py) noktasinin sekle ne kadar girdigi 0..1 (4x4 ornek).
func _boya(g: int, y: int, sekil: Callable) -> Image:
	var im := Image.create(g, y, false, Image.FORMAT_RGBA8)
	for py in y:
		for px in g:
			var toplam := Color(0, 0, 0, 0)
			var alfa := 0.0
			for sy in 4:
				for sx in 4:
					var c: Color = sekil.call(px + (sx + 0.5) / 4.0, py + (sy + 0.5) / 4.0)
					if c.a > 0.0:
						toplam += Color(c.r * c.a, c.g * c.a, c.b * c.a, c.a)
						alfa += c.a
			if alfa > 0.0:
				im.set_pixel(px, py, Color(toplam.r / alfa, toplam.g / alfa, toplam.b / alfa, alfa / 16.0))
	return im


func _daire_simge(boy: int, renk: Color) -> ImageTexture:
	var r := boy / 2.0
	var im := _boya(boy, boy, func(x: float, y: float) -> Color:
		return renk if Vector2(x - r, y - r).length() <= r - 0.5 else Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(im)


func _anahtar_simge(acik: bool, pasif: bool) -> ImageTexture:
	var g := 30
	var y := 16
	var iz := AMBER if acik else Color(KAGIT, 0.22)
	var dugme := MUREKKEP if acik else KAGIT
	if pasif:
		iz = Color(iz, iz.a * 0.4)
		dugme = Color(dugme, 0.5)
	var im := _boya(g, y, func(x: float, py: float) -> Color:
		var yr := y / 2.0 - 1.0
		# hap: iki yari daire + orta dikdortgen
		var cx := clampf(x, yr + 1.0, g - yr - 1.0)
		if Vector2(x - cx, py - y / 2.0).length() <= yr:
			var kx := (g - yr - 3.0) if acik else (yr + 3.0)
			if Vector2(x - kx, py - y / 2.0).length() <= yr - 2.0:
				return dugme
			return iz
		return Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(im)
