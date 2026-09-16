## Oyun sahnesi: HUD, üs menüsü, duraklatma, bitiş ve kayıt.
extends Node2D

@onready var dunya: Dunya = $Dunya
@onready var arac: Arac = $Arac

@onready var _lbl_derinlik: Label = $HUD/Ust/Derinlik
@onready var _lbl_yakit: Label = $HUD/Ust/Yakit
@onready var _lbl_yuk: Label = $HUD/Ust/Yuk
@onready var _lbl_para: Label = $HUD/Ust/Para
@onready var _lbl_ipucu: Label = $HUD/Ipucu

@onready var _magaza: Control = $HUD/Magaza
@onready var _magaza_bilgi: Label = $HUD/Magaza/M/V/Bilgi
@onready var _btn_sat: Button = $HUD/Magaza/M/V/Sat
@onready var _btn_yakit: Button = $HUD/Magaza/M/V/Yakit

@onready var _duraklat: Control = $HUD/Duraklat
@onready var _bitis: Control = $HUD/Bitis
@onready var _bitis_metin: Label = $HUD/Bitis/M/V/Metin
@onready var _uyari: Control = $HUD/Uyari
@onready var _uyari_metin: Label = $HUD/Uyari/M/V/Metin

var durum: Durum

func _ready() -> void:
	var kayitli := Kayit.yukle()
	durum = Durum.new(int(kayitli.get("tohum", randi())))
	durum.sozlukten(kayitli)

	dunya.kur(durum.tohum)
	arac.durum = durum
	arac.dunya = dunya
	arac.usse_don()
	dunya.hazirla(0.0)

	arac.maden_toplandi.connect(_maden_toplandi)
	arac.cekirdege_ulasildi.connect(_kazandi)
	arac.yakit_bitti.connect(_yakit_bitti)

	_btn_sat.pressed.connect(_sat)
	_btn_yakit.pressed.connect(_yakit_al)
	for alan in Ayarlar.GELISTIRMELER:
		var dugme: Button = _magaza.get_node("M/V/G_" + alan)
		dugme.pressed.connect(_gelistir.bind(alan))
	$HUD/Magaza/M/V/Kapat.pressed.connect(_magaza_kapat)
	$HUD/Duraklat/M/V/Devam.pressed.connect(_duraklat_kapat)
	$HUD/Duraklat/M/V/Menu.pressed.connect(_menuye)
	$HUD/Bitis/M/V/Menu.pressed.connect(_menuye)
	$HUD/Uyari/M/V/Tamam.pressed.connect(_uyari_kapat)

	_hud_yenile()

func _process(_delta: float) -> void:
	dunya.hazirla(arac.global_position.y)
	_hud_yenile()

func _unhandled_input(olay: InputEvent) -> void:
	if durum.kazandi:
		return
	if olay.is_action_pressed("duraklat"):
		if _magaza.visible:
			_magaza_kapat()
		else:
			_duraklat.visible = not _duraklat.visible
			arac.kilitli = _duraklat.visible
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("etkilesim") and arac.usste_mi() and not _panel_acik():
		_magaza_ac()
		get_viewport().set_input_as_handled()

func _panel_acik() -> bool:
	return _magaza.visible or _duraklat.visible or _bitis.visible or _uyari.visible

# --- HUD ---
func _hud_yenile() -> void:
	var derinlik := maxi(0, floori(arac.global_position.y / Ayarlar.KARO))
	_lbl_derinlik.text = "Derinlik %d m" % derinlik
	_lbl_yakit.text = "Yakıt %d/%d" % [ceili(durum.yakit), int(durum.yakit_kapasitesi())]
	_lbl_yuk.text = "Yük %d/%d" % [durum.yuk_toplam(), durum.yuk_kapasitesi()]
	_lbl_para.text = "Para %d" % durum.para
	_lbl_ipucu.text = _ipucu(derinlik)

func _ipucu(derinlik: int) -> String:
	if _panel_acik():
		return ""
	if arac.usste_mi():
		return "E / X — Üs menüsü (sat, geliştir, yakıt)"
	if durum.yuk_dolu():
		return "Yük dolu! Satmak için üsse dön."
	if durum.yakit < durum.yakit_kapasitesi() * 0.2:
		return "Yakıt azalıyor — üsse dön."
	if absi(derinlik - Ayarlar.CEKIRDEK_DERINLIK) <= 30:
		var fark := dunya.uretici.cekirdek_x * Ayarlar.KARO - arac.global_position.x
		var taraf := "doğuda" if fark > 0.0 else "batıda"
		return "Çekirdek %d m derinlikte, %s" % [Ayarlar.CEKIRDEK_DERINLIK, taraf]
	return ""

# --- olaylar ---
func _maden_toplandi(_tur: int, alindi: bool) -> void:
	if not alindi:
		_lbl_ipucu.text = "Yük dolu, maden alınmadı!"

func _yakit_bitti() -> void:
	var kayip := durum.yuk_degeri() / 2
	durum.kosu_basarisiz()
	arac.usse_don()
	_kaydet()
	_uyari_metin.text = "Yakıt bitti!\nYükün yarısı kayboldu (yaklaşık %d para).\nÜsse çekildin, acil yakıt verildi." % kayip
	_uyari.visible = true
	arac.kilitli = true

func _uyari_kapat() -> void:
	_uyari.visible = false
	arac.kilitli = false

func _kazandi() -> void:
	if durum.kazandi:
		return
	durum.kazandi = true
	arac.kilitli = true
	durum.en_derin = maxi(durum.en_derin, Ayarlar.CEKIRDEK_DERINLIK)
	_kaydet()
	_bitis_metin.text = "ÇEKİRDEĞE ULAŞTIN!\n\nDerinlik: %d m\nSüre: %s\nPara: %d\nTohum: %d" % [
		Ayarlar.CEKIRDEK_DERINLIK, _sure_metni(durum.sure), durum.para, durum.tohum
	]
	_bitis.visible = true

static func _sure_metni(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]

# --- üs menüsü ---
func _magaza_ac() -> void:
	_magaza.visible = true
	arac.kilitli = true
	_magaza_yenile()

func _magaza_kapat() -> void:
	_magaza.visible = false
	arac.kilitli = false
	_kaydet()

func _magaza_yenile() -> void:
	var satirlar := PackedStringArray(["Yükte: %d/%d parça" % [durum.yuk_toplam(), durum.yuk_kapasitesi()]])
	for tur in Ayarlar.MADEN_AD:
		var adet: int = int(durum.yuk.get(tur, 0))
		if adet > 0:
			satirlar.append("  %s x%d = %d" % [Ayarlar.MADEN_AD[tur], adet, adet * int(Ayarlar.MADEN_DEGER[tur])])
	satirlar.append("Para: %d" % durum.para)
	_magaza_bilgi.text = "\n".join(satirlar)

	_btn_sat.text = "Sat (+%d para)" % durum.yuk_degeri()
	_btn_sat.disabled = durum.yuk_toplam() == 0
	var dolum := durum.yakit_dolum_fiyati()
	_btn_yakit.text = "Yakıt doldur (%d para)" % dolum
	_btn_yakit.disabled = dolum <= 0 or durum.para <= 0

	for alan in Ayarlar.GELISTIRMELER:
		var dugme: Button = _magaza.get_node("M/V/G_" + alan)
		var s := durum.seviye(alan)
		var f := durum.fiyat(alan)
		if f < 0:
			dugme.text = "%s — seviye %d (en üst)" % [Ayarlar.GELISTIRME_AD[alan], s]
			dugme.disabled = true
		else:
			dugme.text = "%s %d→%d — %d para" % [Ayarlar.GELISTIRME_AD[alan], s, s + 1, f]
			dugme.disabled = durum.para < f

func _sat() -> void:
	durum.sat()
	_magaza_yenile()

func _yakit_al() -> void:
	durum.yakit_doldur()
	_magaza_yenile()

func _gelistir(alan: String) -> void:
	durum.satin_al(alan)
	_magaza_yenile()

# --- duraklatma / kayıt ---
func _duraklat_kapat() -> void:
	_duraklat.visible = false
	arac.kilitli = false

func _menuye() -> void:
	_kaydet()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _kaydet() -> void:
	Kayit.kaydet(durum.sozluge())
