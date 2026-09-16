## Oyun sahnesi: HUD, üs, müze, ışınlanma, tehlikeler, oyun hissi, kayıt.
extends Node2D

const SANDIK_ODUL := [
	{"tur": "para", "az": 40, "cok": 120},
	{"tur": "dinamit", "az": 2, "cok": 4},
	{"tur": "yakit", "az": 30, "cok": 70},
]
const HARITA_SIS := 5          ## kazılan hücrenin çevresinde açılan yarıçap
const SARSINTI_SONUM := 9.0
const DUSME_BEKLE := 0.5       ## gevşek kaya kaç saniye titrer

@onready var dunya: Dunya = $Dunya
@onready var arac: Arac = $Arac
@onready var kamera: Camera2D = $Arac/Kamera
@onready var _gorsel: Sprite2D = $Arac/Gorsel
@onready var _etkiler: Node2D = $Etkiler
@onready var _nesneler: Node2D = $Nesneler

@onready var _lbl_derinlik: Label = $HUD/Ust/Derinlik
@onready var _lbl_yakit: Label = $HUD/Ust/Yakit
@onready var _lbl_yuk: Label = $HUD/Ust/Yuk
@onready var _lbl_can: Label = $HUD/Ust/Can
@onready var _lbl_para: Label = $HUD/Ust/Para
@onready var _lbl_katman: Label = $HUD/Katman
@onready var _lbl_zincir: Label = $HUD/Zincir
@onready var _lbl_radar: Label = $HUD/Radar
@onready var _lbl_ipucu: Label = $HUD/Ipucu
@onready var _harita: TextureRect = $HUD/Harita

@onready var _magaza: PanelContainer = $HUD/Magaza
@onready var _muze: PanelContainer = $HUD/Muze
@onready var _isinlanma: PanelContainer = $HUD/Isinlanma
@onready var _ayar_panel: PanelContainer = $HUD/Ayar
@onready var _duraklat: PanelContainer = $HUD/Duraklat
@onready var _bitis: PanelContainer = $HUD/Bitis
@onready var _uyari: PanelContainer = $HUD/Uyari
@onready var _karartma: ColorRect = $Gecis/Karartma

@onready var _fon_gok: TextureRect = $Arkaplan/Gok
@onready var _fon_tepe: TextureRect = $Arkaplan/Tepeler
@onready var _fon_kasaba: TextureRect = $Arkaplan/Kasaba
@onready var _fon_kaya: TextureRect = $Arkaplan/Kaya

var durum: Durum
var _sarsinti := 0.0
var _radar_acik := false
var _titreyen := []     ## {"h": Vector2i, "t": float, "s": Sprite2D}
var _dusenler := []     ## {"s": Sprite2D, "hiz": float}
var _harita_img: Image
var _harita_doku: ImageTexture
var _harita_zaman := 0.0
var _ipucu_sabit := ""
var _ipucu_sure := 0.0
var _derine_indi := false     ## sefer sayacı: dibe inip üsse dönünce bir sefer biter
var _deprem_uyari := 0.0      ## >0 iken deprem uyarısı sürüyor
var _karo_doku: Texture2D
var _cekiliyor := false

func _ready() -> void:
	_karo_doku = load("res://assets/sprites/karolar.png")
	var kayitli := Kayit.yukle()
	durum = Durum.new(int(kayitli.get("tohum", randi())))
	durum.sozlukten(kayitli)

	dunya.kur(durum.tohum, Dunya.diziden_kazilan(kayitli.get("kazilan", null)),
		Dunya.diziden_eklenen(kayitli.get("eklenen", null)))
	arac.durum = durum
	arac.dunya = dunya
	arac.usse_don()
	dunya.hazirla(arac.global_position)

	arac.maden_toplandi.connect(_maden_toplandi)
	arac.karo_kirildi.connect(_karo_kirildi)
	arac.cekirdege_ulasildi.connect(_cekirdege_ulasildi)
	arac.kosu_bitti.connect(_kosu_bitti)
	arac.matkap_yetersiz.connect(_matkap_yetersiz)
	arac.hasar_alindi.connect(_hasar_alindi)
	arac.patlama.connect(_patlama)
	arac.sandik_acildi.connect(_sandik_acildi)

	$HUD/Duraklat/M/V/Devam.pressed.connect(_duraklat_kapat)
	$HUD/Duraklat/M/V/Ayar.pressed.connect(_ayar_ac)
	$HUD/Duraklat/M/V/Menu.pressed.connect(_menuye)
	$HUD/Bitis/M/V/Menu.pressed.connect(_menuye)
	$HUD/Uyari/M/V/Tamam.pressed.connect(_uyari_kapat)

	$Dokunmatik.visible = DisplayServer.is_touchscreen_available()
	if $Dokunmatik.visible:
		_dokunmatik_izler()

	_harita_kur()
	_nesne_yenile()
	_hud_yenile()
	Ses.muzik_cal("muzik")
	_karart(false)

# --- ana döngü ------------------------------------------------------------

func _process(delta: float) -> void:
	dunya.hazirla(arac.global_position)
	_arkaplan_yenile()
	_sarsinti_isle(delta)
	_sefer_isle()
	_deprem_isle(delta)
	_tehlike_isle(delta)
	_sandik_kontrol()
	_kacis_kontrol()
	if _ipucu_sure > 0.0:
		_ipucu_sure -= delta
	_harita_zaman -= delta
	if _harita.visible and _harita_zaman <= 0.0:
		_harita_zaman = 0.25
		_harita_ciz()
	_hud_yenile()
	_muzik_katmani()

func _unhandled_input(olay: InputEvent) -> void:
	if durum.kazandi:
		return
	if olay.is_action_pressed("duraklat"):
		if _panel_acik():
			_panelleri_kapat()
		else:
			_duraklat.visible = true
			arac.kilitli = true
			Ses.cal("menu")
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("etkilesim") and arac.usste_mi() and not _panel_acik():
		_magaza_ac()
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("dinamit") and not _panel_acik():
		if arac.dinamit_at():
			Ses.cal("patlama")
		else:
			_ipucu_goster("Dinamit yok — üsten al.", 1.5)
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("radar") and not _panel_acik():
		if durum.alet_var("radar"):
			_radar_acik = not _radar_acik
			Ses.cal("menu")
		else:
			_ipucu_goster("Maden radarı yok — üsten al.", 1.5)
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("isinlan") and not _panel_acik():
		_isinlanma_ac()
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("harita") and not _panel_acik():
		_harita.visible = not _harita.visible
		_harita_zaman = 0.0
		Ses.cal("menu")
		get_viewport().set_input_as_handled()

func _panel_acik() -> bool:
	return _magaza.visible or _muze.visible or _isinlanma.visible or _ayar_panel.visible \
		or _duraklat.visible or _bitis.visible or _uyari.visible

func _panelleri_kapat() -> void:
	if _bitis.visible:
		return
	for p in [_magaza, _muze, _isinlanma, _ayar_panel, _duraklat, _uyari]:
		p.visible = false
	arac.kilitli = false
	_kaydet()

# --- HUD ------------------------------------------------------------------

func _hud_yenile() -> void:
	# Panel açıkken HUD kapanır: küçük ekranda üst üste binmesin.
	var panel := _panel_acik()
	$HUD/Ust.visible = not panel
	_lbl_katman.visible = not panel
	_lbl_zincir.visible = not panel
	_lbl_radar.visible = not panel
	_harita.visible = _harita.visible and not panel
	if panel:
		_lbl_ipucu.text = ""
		return
	var d := arac.derinlik()
	_lbl_derinlik.text = "%d m" % d
	_lbl_yakit.text = "Yakıt %d/%d" % [ceili(durum.yakit), int(durum.yakit_kapasitesi())]
	_lbl_yuk.text = "Yük %d/%d" % [durum.yuk_toplam(), durum.yuk_kapasitesi()]  ## ağırlık
	_lbl_can.text = "Can %d/%d" % [durum.can, durum.can_kapasitesi()]
	_lbl_para.text = "%d ₺" % durum.para
	var k := Ayarlar.katman(d)
	var ilerleme := clampf(float(d) / float(Ayarlar.CEKIRDEK_DERINLIK), 0.0, 1.0)
	_lbl_katman.text = "%s  •  Çekirdek %d m  [%s]%s" % [
		Ayarlar.KATMANLAR[k]["ad"], Ayarlar.CEKIRDEK_DERINLIK, _cubuk(ilerleme), _mod_etiketi()]
	if durum.zincir_adet >= int(Ayarlar.ZINCIR_ESIK[0]):
		_lbl_zincir.text = "ZİNCİR x%d  ×%.2f" % [durum.zincir_adet, durum.zincir_carpani()]
	else:
		_lbl_zincir.text = ""
	_lbl_radar.text = _radar_metni()
	_lbl_ipucu.text = _ipucu(d)

## Ana oyun dışındaki modun HUD etiketi (günlük dünya / Derin Mod).
func _mod_etiketi() -> String:
	var e := ""
	if Kayit.aktif == Kayit.GUNLUK:
		e += "  •  GÜNLÜK"
	if durum.derin_seviye > 0:
		e += "  •  DERİN MOD x%d" % durum.derin_seviye
	return e

static func _cubuk(oran: float) -> String:
	var dolu := int(round(oran * 12.0))
	return "=".repeat(dolu) + ".".repeat(12 - dolu)

func _radar_metni() -> String:
	if not _radar_acik or not durum.alet_var("radar"):
		return ""
	var bulunan := dunya.en_yakin_maden(arac.hucre())
	if bulunan.is_empty():
		return "Radar: yakında maden yok"
	var h: Vector2i = bulunan[0]
	var fark := h - arac.hucre()
	var ok := ""
	if fark.y > 1:
		ok += "↓"
	elif fark.y < -1:
		ok += "↑"
	if fark.x > 1:
		ok += "→"
	elif fark.x < -1:
		ok += "←"
	if ok == "":
		ok = "•"
	var ad: String = Ayarlar.MADEN_AD.get(dunya.karo_tur(h), "?")
	return "Radar %s %s %d m" % [ok, ad, int(Vector2(fark).length())]

func _ipucu_goster(metin: String, sure := 2.0) -> void:
	_ipucu_sabit = metin
	_ipucu_sure = sure

func _ipucu(d: int) -> String:
	if _panel_acik():
		return ""
	if _ipucu_sure > 0.0:
		return _ipucu_sabit
	if durum.kacis:
		return "KAÇIŞ! Yakıt bitmeden yüzeye çık."
	if arac.usste_mi():
		return "E — Üs (sat, geliştir, yakıt)   •   T — ışınlanma   •   M — harita"
	if durum.yuk_dolu():
		return "Yük dolu! Satmak için üsse dön."
	if durum.can <= 1:
		return "Can azaldı — üsse dön, onarım bedava."
	if durum.yakit < durum.yakit_kapasitesi() * 0.25:
		return "Yakıt azalıyor — üsse dön (T ile ışınlanabilirsin)."
	if d < 3 and durum.en_derin < 8:
		return "S / ↓ ile aşağı kaz. İlk bakır damarı hemen altında."
	if durum.en_derin < 20 and durum.yuk_toplam() > 0:
		return "Madeni sat: W ile yüzeye çık, üste E'ye bas."
	return ""

# --- arka plan ve müzik ---------------------------------------------------

func _arkaplan_yenile() -> void:
	var kam := kamera.get_screen_center_position()
	var d := arac.derinlik()
	# Yüzey katmanları: yatay parallaks, derinde solar.
	var gorunur := clampf(1.0 - float(d) / 18.0, 0.0, 1.0)
	_fon_gok.modulate.a = gorunur
	_fon_tepe.modulate.a = gorunur
	_fon_kasaba.modulate.a = gorunur
	# Ufuk = dünya y=0'ın ekrandaki yeri. Katmanlar buna göre, azalan oranla kayar.
	var ufuk := float(Ayarlar.EKRAN_Y) * 0.5 + (0.0 - kam.y) * kamera.zoom.y
	var orta := float(Ayarlar.EKRAN_Y) * 0.5
	_fon_tepe.position = Vector2(fmod(-kam.x * 0.15, 320.0) - 320.0,
		orta + (ufuk - orta) * 0.30 - 64.0)
	_fon_kasaba.position = Vector2(fmod(-kam.x * 0.32, 320.0) - 320.0,
		orta + (ufuk - orta) * 0.55 - 48.0)
	# Yeraltı: katman rengiyle boyanmış kaya dokusu.
	var yer := clampf((float(d) - 4.0) / 14.0, 0.0, 1.0)
	var renk: Color = Ayarlar.KATMANLAR[Ayarlar.katman(d)]["renk"]
	_fon_kaya.modulate = Color(renk.r, renk.g, renk.b, yer * 0.85)
	_fon_kaya.position = Vector2(fmod(-kam.x * 0.25, 64.0) - 64.0, fmod(-kam.y * 0.25, 64.0) - 64.0)

func _muzik_katmani() -> void:
	Ses.muzik_cal("muzik_derin" if arac.derinlik() >= 90 else "muzik")

# --- oyun hissi -----------------------------------------------------------

func _sarsinti_isle(delta: float) -> void:
	if _sarsinti <= 0.0:
		kamera.offset = Vector2.ZERO
		return
	_sarsinti = maxf(0.0, _sarsinti - delta * SARSINTI_SONUM)
	kamera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _sarsinti

func sars(guc: float) -> void:
	if Ses.sarsinti_acik():
		_sarsinti = maxf(_sarsinti, guc)

## Kısa esneme-sıkışma: kazma ve çarpma anlarında araç "canlı" hissettirir.
func _esnet(x: float, y: float) -> void:
	_gorsel.scale = Vector2(x, y)
	create_tween().tween_property(_gorsel, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _toz(konum: Vector2, renk: Color, adet := 8, hiz := 60.0) -> void:
	var p := CPUParticles2D.new()
	p.texture = load("res://assets/sprites/benek.png")
	p.emitting = true
	p.one_shot = true
	p.amount = adet
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = hiz * 0.4
	p.initial_velocity_max = hiz
	p.gravity = Vector2(0, 240)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.color = renk
	p.global_position = konum
	_etkiler.add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func _ucan_yazi(konum: Vector2, metin: String, renk: Color) -> void:
	var l := Label.new()
	l.text = metin
	l.add_theme_color_override("font_color", renk)
	l.add_theme_font_size_override("font_size", 14)
	l.z_index = 20
	l.global_position = konum + Vector2(-10, -12)
	_etkiler.add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "global_position", l.global_position + Vector2(0, -22), 0.8)
	t.tween_property(l, "modulate:a", 0.0, 0.8)
	t.chain().tween_callback(l.queue_free)

## Karo türünün atlastaki renginden parçacık rengi (palet tek kaynak).
static func _karo_renk(tur: int) -> Color:
	match tur:
		Ayarlar.BAKIR: return Color("be4a2f")
		Ayarlar.DEMIR: return Color("c0cbdc")
		Ayarlar.ALTIN: return Color("feae34")
		Ayarlar.ELMAS: return Color("2ce8f5")
		Ayarlar.PLATIN: return Color("63c74d")
		Ayarlar.GAZ: return Color("63c74d")
		Ayarlar.LAV: return Color("f77622")
		Ayarlar.TOPRAK: return Color("b86f50")
		Ayarlar.TAS: return Color("8b9bb4")
		Ayarlar.SERT: return Color("5a6988")
		Ayarlar.BAZALT: return Color("3a4466")
		Ayarlar.OBSIDYEN: return Color("68386c")
	return Color("8b9bb4")

# --- olaylar --------------------------------------------------------------

func _karo_kirildi(tur: int, konum: Vector2) -> void:
	_toz(konum, _karo_renk(tur))
	_esnet(1.12, 0.88)
	Ses.cal("kaz")
	var h := dunya.hucre(konum)
	_harita_ac(h)
	_gevsek_kontrol(h)

func _maden_toplandi(tur: int, alindi: bool, konum: Vector2) -> void:
	if not alindi:
		_ipucu_goster("Yük dolu, maden alınmadı!", 1.5)
		return
	var carpan := durum.zincir_carpani()
	var deger := int(round(float(durum.maden_degeri(tur)) * carpan))
	_ucan_yazi(konum, "+%d ₺" % deger, Color("fee761") if carpan > 1.0 else Color("c0cbdc"))
	_toz(konum, _karo_renk(tur), 12, 90.0)
	# Zincir uzadıkça ses tizleşir (rakip analizi: "kombo arttıkça perde yükselir").
	Ses.cal("maden", 1.0 + 0.08 * float(mini(durum.zincir_adet - 1, 8)))
	if durum.zincir_adet == int(Ayarlar.ZINCIR_ESIK[0]):
		_ipucu_goster("Kazı zinciri! Aynı madeni sürdür.", 1.5)

func _matkap_yetersiz(gereken: int) -> void:
	_ipucu_goster("Bu kaya için Matkap Sv%d gerekli." % gereken, 1.8)
	Ses.cal("uyari")

func _hasar_alindi(miktar: int, konum: Vector2) -> void:
	sars(5.0)
	_toz(konum, Color("e43b44"), 14, 110.0)
	_ucan_yazi(konum, "-%d" % miktar, Color("e43b44"))
	Ses.cal("hasar")
	_esnet(0.8, 1.2)

func _patlama(konum: Vector2, yaricap: int) -> void:
	sars(6.0)
	_toz(konum, Color("f77622"), 24, 150.0 * float(yaricap))
	Ses.cal("patlama")

func _sandik_acildi(tur: int, konum: Vector2) -> void:
	if tur == Ayarlar.ESER:
		_eser_bul(konum)
		return
	# Ödül hücreden türetiliyor: aynı sandık hep aynı ödülü verir.
	var h := dunya.hucre(konum)
	var r := absi(hash(Vector2i(h.x, h.y + durum.tohum)))
	var odul: Dictionary = SANDIK_ODUL[r % SANDIK_ODUL.size()]
	var miktar := int(odul["az"]) + r % (int(odul["cok"]) - int(odul["az"]) + 1)
	var metin := ""
	match String(odul["tur"]):
		"para":
			durum.para += miktar
			metin = "+%d ₺" % miktar
		"dinamit":
			durum.dinamit += miktar
			metin = "+%d dinamit" % miktar
		"yakit":
			durum.yakit = minf(durum.yakit_kapasitesi(), durum.yakit + float(miktar))
			metin = "+%d yakıt" % miktar
	_ucan_yazi(konum, metin, Color("fee761"))
	_toz(konum, Color("feae34"), 18, 120.0)
	Ses.cal("sandik")
	_ipucu_goster("Sandık: %s" % metin, 2.0)

func _eser_bul(konum: Vector2) -> void:
	var sonraki := -1
	for i in Ayarlar.ESERLER.size():
		if not durum.eserler.has(i):
			sonraki = i
			break
	if sonraki < 0:
		durum.para += 300
		_ucan_yazi(konum, "+300 ₺", Color("fee761"))
		Ses.cal("sandik")
		return
	durum.eserler.append(sonraki)
	var e: Dictionary = Ayarlar.ESERLER[sonraki]
	_toz(konum, Color("feae34"), 26, 140.0)
	Ses.cal("sat")
	sars(3.0)
	_uyari_goster("ESER BULUNDU  (%d/%d)\n\n%s — %s\n\n%s\n\nMüzeye eklendi (üs menüsünden okuyabilirsin)."
		% [durum.eserler.size(), Ayarlar.ESERLER.size(), e["ad"], e["metin"], e["hikaye"]])

func _cekirdege_ulasildi() -> void:
	if durum.kacis or durum.kazandi:
		return
	durum.cekirdek_bulundu = true
	durum.kacis = true
	durum.yakit = durum.yakit_kapasitesi()
	sars(10.0)
	_toz(arac.global_position, Color("b55088"), 40, 200.0)
	Ses.cal("patlama")
	_kaydet()
	_uyari_goster("ÇEKİRDEĞE DOKUNDUN!\n\nKabuk çöküyor — yüzeye kaç!\nDepo dolduruldu, tüm aletler açık.\nSüre yakıtın kadar.")

func _kacis_kontrol() -> void:
	if durum.kacis and not durum.kazandi and arac.usste_mi():
		_kazandi()

func _kosu_bitti() -> void:
	if durum.kazandi or _bitis.visible or _cekiliyor:
		return
	_cekiliyor = true
	var h := arac.hucre()
	var kacisti := durum.kacis
	durum.kacis = false
	var sonuc := durum.kosu_basarisiz(h)
	arac.usse_don()
	durum.onar()
	_kaydet()
	Ses.cal("uyari")
	var satirlar := PackedStringArray()
	satirlar.append("Yüzeye çekildin." if not kacisti else "Kaçış başarısız — yüzeye çekildin.")
	satirlar.append("Çekme ücreti: %d ₺" % int(sonuc["ucret"]))
	if not Dictionary(sonuc["birakilan"]).is_empty():
		satirlar.append("Yükün yarısı %d m'de sandıkta kaldı — geri alabilirsin." % h.y)
	satirlar.append("Yakıt doldurmak için üs menüsünü aç.")
	_uyari_goster("\n".join(satirlar))

func _kazandi() -> void:
	if durum.kazandi:
		return
	durum.kazandi = true
	durum.kacis = false
	arac.kilitli = true
	durum.en_derin = maxi(durum.en_derin, Ayarlar.CEKIRDEK_DERINLIK)
	_kaydet()
	Ses.cal("sat")
	Ses.muzik_cal("bitis")
	var son := "Bütün eserleri topladın — çekirdeğin hikâyesi müzede tamam."
	if durum.eserler.size() < Ayarlar.ESERLER.size():
		son = "Eksik eserler çekirdeğin hikâyesinin kalan parçalarını taşıyor."
	$HUD/Bitis/M/V/Metin.text = "ÇEKİRDEK ÇIKARILDI!\n\nSüre: %s\nEn derin: %d m\nPara: %d ₺\nEser: %d/%d\nTohum kodu: %s\n\n%s\n\nMenüde DERİN MOD açıldı: yeni tohum, daha sert kaya, eser bonusların kalır." % [
		_sure_metni(durum.sure), durum.en_derin, durum.para,
		durum.eserler.size(), Ayarlar.ESERLER.size(), TohumKodu.kodla(durum.tohum), son]
	_bitis.visible = true

static func _sure_metni(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]

# --- sefer sayacı ve deprem (canlı yeraltı) -------------------------------

## Bir "sefer" = dibe inip üsse dönmek. Deprem sayacı bunu kullanıyor.
func _sefer_isle() -> void:
	if durum.kazandi:
		return
	if arac.derinlik() > 12:
		_derine_indi = true
	elif _derine_indi and arac.usste_mi():
		_derine_indi = false
		durum.sefer += 1
		if durum.sefer % Deprem.ARALIK == 0:
			durum.deprem_bekliyor = true

## Deprem, üste dönüldüğünde kurulur ama YERALTINDA patlar: uyarı yeraltında
## anlamlı, üste dönmüş oyuncuya sarsıntı göstermenin gerilimi yok.
func _deprem_isle(delta: float) -> void:
	if durum.kazandi:
		return
	if _deprem_uyari > 0.0:
		_deprem_uyari -= delta
		sars(2.0)
		if _deprem_uyari <= 0.0:
			_deprem_uygula()
		return
	if durum.deprem_bekliyor and not _panel_acik() and arac.derinlik() >= 15:
		durum.deprem_bekliyor = false
		_deprem_uyari = Deprem.UYARI_SURE
		Ses.cal("uyari", 0.45)
		_ipucu_goster("DEPREM YAKLAŞIYOR — kabuk kımıldıyor, yüzeye yakın dur!",
			Deprem.UYARI_SURE)

func _deprem_uygula() -> void:
	durum.deprem += 1
	var korunan := Deprem.korunan_hucreler(durum.istasyonlar, arac.hucre())
	var sonuc := Deprem.hesapla(dunya.kazilan, dunya.karo_tur, korunan,
		durum.tohum, durum.deprem)
	var kapanan: Array = sonuc["kapanan"]
	var yeni: Dictionary = sonuc["yeni"]
	dunya.degistir(kapanan, yeni)
	dunya.hazirla(arac.global_position)
	# Titreyen kayalar artık geçersiz olabilir: sahneden temizle.
	for t in _titreyen:
		t["s"].queue_free()
	_titreyen.clear()
	_harita_guncelle(kapanan)
	_harita_guncelle(yeni.keys())
	sars(12.0)
	Ses.cal("patlama")
	_toz(arac.global_position, _karo_renk(Ayarlar.TOPRAK), 30, 160.0)
	_kaydet()
	_ipucu_goster("DEPREM! %d karo tünel kapandı, %d yeni damar/gaz çıktı."
		% [kapanan.size(), yeni.size() - kapanan.size()], 4.0)

# --- tehlikeler -----------------------------------------------------------

## Kırılan hücrenin üstündeki gevşek kaya varsa titremeye başlar.
func _gevsek_kontrol(h: Vector2i) -> void:
	var ust := h + Vector2i.UP
	if dunya.karo_tur(ust) != Ayarlar.GEVSEK:
		return
	for t in _titreyen:
		if t["h"] == ust:
			return
	var s := Sprite2D.new()
	s.texture = _karo_doku
	s.region_enabled = true
	s.region_rect = Rect2(Ayarlar.GEVSEK * Ayarlar.KARO, 0, Ayarlar.KARO, Ayarlar.KARO)
	s.global_position = dunya.hucre_merkezi(ust)
	_etkiler.add_child(s)
	_titreyen.append({"h": ust, "t": DUSME_BEKLE, "s": s, "k": s.global_position})
	Ses.cal("uyari", 1.6)

func _tehlike_isle(delta: float) -> void:
	for i in range(_titreyen.size() - 1, -1, -1):
		var t: Dictionary = _titreyen[i]
		t["t"] = float(t["t"]) - delta
		var s: Sprite2D = t["s"]
		s.global_position = Vector2(t["k"]) + Vector2(randf_range(-1.5, 1.5), randf_range(-1.0, 1.0))
		if float(t["t"]) > 0.0:
			continue
		_titreyen.remove_at(i)
		if dunya.karo_tur(t["h"]) != Ayarlar.GEVSEK:
			s.queue_free()
			continue
		dunya.karo_kir(t["h"])
		_dusenler.append({"s": s, "hiz": 40.0})
		s.global_position = Vector2(t["k"])

	for i in range(_dusenler.size() - 1, -1, -1):
		var d: Dictionary = _dusenler[i]
		d["hiz"] = minf(float(d["hiz"]) + Ayarlar.YERCEKIMI * delta, Ayarlar.MAX_DUSUS)
		var s: Sprite2D = d["s"]
		s.global_position.y += float(d["hiz"]) * delta
		var carpti := s.global_position.distance_to(arac.global_position) < 13.0
		var h := dunya.hucre(s.global_position + Vector2(0, Ayarlar.KARO * 0.5))
		if carpti:
			arac.hasar(Ayarlar.HASAR_KAYA, s.global_position)
		if carpti or dunya.karo_tur(h) != Ayarlar.BOS or h.y >= Ayarlar.DERINLIK - 1:
			_toz(s.global_position, _karo_renk(Ayarlar.TOPRAK), 12, 80.0)
			sars(2.5)
			s.queue_free()
			_dusenler.remove_at(i)

## Yerde duran düşen sandığın üstünden geçilince yük geri alınır.
func _sandik_kontrol() -> void:
	if durum.dusen_sandiklar.is_empty():
		return
	var m := arac.hucre()
	for i in durum.dusen_sandiklar.size():
		var s: Dictionary = durum.dusen_sandiklar[i]
		if Vector2i(s["h"]).distance_squared_to(m) > 2:
			continue
		var alinan := durum.sandik_al(i)
		if alinan.is_empty():
			return
		var adet := 0
		for tur in alinan:
			adet += int(alinan[tur])
		_ucan_yazi(arac.global_position, "+%d parça" % adet, Color("63c74d"))
		Ses.cal("sandik")
		_ipucu_goster("Düşürdüğün yükü geri aldın (%d parça)." % adet, 2.0)
		_nesne_yenile()
		return

# --- üs menüsü ------------------------------------------------------------

func _dugme(kap: VBoxContainer, metin: String, kapali: bool, geri: Callable) -> void:
	var b := Button.new()
	b.text = metin
	b.disabled = kapali
	b.add_theme_font_size_override("font_size", 11)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		Ses.cal("menu")
		geri.call())
	kap.add_child(b)

static func _temizle(kap: Node) -> void:
	for c in kap.get_children():
		kap.remove_child(c)
		c.queue_free()

func _magaza_ac() -> void:
	durum.onar()   ## üste dönünce onarım bedava
	_magaza.visible = true
	arac.kilitli = true
	Ses.cal("menu")
	_magaza_yenile()

func _magaza_yenile() -> void:
	var satirlar := PackedStringArray(["Yük: %d/%d ağırlık (%d parça)"
		% [durum.yuk_toplam(), durum.yuk_kapasitesi(), durum.yuk_adet()]])
	for tur in Ayarlar.MADEN_AD:
		var adet := int(durum.yuk.get(tur, 0))
		if adet > 0:
			satirlar.append("   %s x%d = %d ₺  (%d ağırlık)" % [Ayarlar.MADEN_AD[tur], adet,
				adet * durum.maden_degeri(tur), adet * int(Ayarlar.MADEN_AGIRLIK[tur])])
	if durum.yuk_bonus > 0:
		satirlar.append("   zincir ikramiyesi +%d ₺" % durum.yuk_bonus)
	satirlar.append("Para: %d ₺   •   Dinamit: %d   •   İstasyon kiti: %d"
		% [durum.para, durum.dinamit, durum.istasyon_kiti])
	$HUD/Magaza/M/V/Bilgi.text = "\n".join(satirlar)

	var liste: VBoxContainer = $HUD/Magaza/M/V/Kaydir/Liste
	_temizle(liste)
	_dugme(liste, "Sat  (+%d ₺)" % durum.yuk_degeri(), durum.yuk_toplam() == 0, _sat)
	var dolum := durum.yakit_dolum_fiyati()
	_dugme(liste, "Yakıt doldur  (%d ₺)" % dolum, dolum <= 0 or durum.para <= 0, _yakit_al)
	for alan in Ayarlar.GELISTIRMELER:
		var s := durum.seviye(alan)
		var f := durum.fiyat(alan)
		if f < 0:
			_dugme(liste, "%s Sv%d — en üst" % [Ayarlar.GELISTIRME_AD[alan], s + 1], true, _bos_islem)
		else:
			_dugme(liste, "%s Sv%d→Sv%d  (%d ₺)" % [Ayarlar.GELISTIRME_AD[alan], s + 1, s + 2, f],
				durum.para < f, _gelistir.bind(alan))
	for ad in Ayarlar.ALET_FIYAT:
		if bool(durum.aletler.get(ad, false)):
			_dugme(liste, "%s ✔ — %s" % [Ayarlar.ALET_AD[ad], Ayarlar.ALET_ACIKLAMA[ad]], true, _bos_islem)
		else:
			var f2 := int(Ayarlar.ALET_FIYAT[ad])
			_dugme(liste, "%s  (%d ₺) — %s" % [Ayarlar.ALET_AD[ad], f2, Ayarlar.ALET_ACIKLAMA[ad]],
				durum.para < f2, _alet_al.bind(ad))
	_dugme(liste, "Dinamit x1  (%d ₺) — F ile 3x3 patlat" % Ayarlar.DINAMIT_FIYAT,
		durum.para < Ayarlar.DINAMIT_FIYAT, _dinamit_al)
	_dugme(liste, "İstasyon kiti  (%d ₺) — T ile kur, anında yolculuk" % Ayarlar.ISTASYON_FIYAT,
		durum.para < Ayarlar.ISTASYON_FIYAT, _istasyon_kiti_al)
	_dugme(liste, "Müze  (%d/%d eser)" % [durum.eserler.size(), Ayarlar.ESERLER.size()], false, _muze_ac)
	_dugme(liste, "Kapat  (Esc)", false, _panelleri_kapat)

func _sat() -> void:
	durum.sat()
	Ses.cal("sat")
	_magaza_yenile()

func _yakit_al() -> void:
	durum.yakit_doldur()
	_magaza_yenile()

func _gelistir(alan: String) -> void:
	if durum.satin_al(alan):
		Ses.cal("gelistir")
	_magaza_yenile()

func _alet_al(ad: String) -> void:
	if durum.alet_al(ad):
		Ses.cal("gelistir")
	_magaza_yenile()

func _dinamit_al() -> void:
	durum.dinamit_al()
	_magaza_yenile()

func _istasyon_kiti_al() -> void:
	durum.istasyon_kiti_al()
	_magaza_yenile()

func _muze_geri() -> void:
	_muze.visible = false
	_magaza_ac()

func _muze_ac() -> void:
	_magaza.visible = false
	_muze.visible = true
	arac.kilitli = true
	$HUD/Muze/M/V/Bilgi.text = "Her eser hem kalıcı bir bonus verir hem de çekirdeğin\nsırrından bir parça anlatır — %d/%d parça toplandı." % [
		durum.eserler.size(), Ayarlar.ESERLER.size()]
	var liste: VBoxContainer = $HUD/Muze/M/V/Kaydir/Liste
	_temizle(liste)
	for i in Ayarlar.ESERLER.size():
		var e: Dictionary = Ayarlar.ESERLER[i]
		var bulundu := durum.eserler.has(i)
		var l := Label.new()
		l.text = ("✔ %d. %s — %s" % [i + 1, e["ad"], e["metin"]]) if bulundu \
			else "%d. %s" % [i + 1, Ayarlar.ESER_KILITLI]
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color("fee761") if bulundu else Color("5a6988"))
		liste.add_child(l)
		if not bulundu:
			continue
		var hk := Label.new()
		hk.text = String(e["hikaye"])
		hk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hk.custom_minimum_size = Vector2(380, 0)
		hk.add_theme_font_size_override("font_size", 11)
		hk.add_theme_color_override("font_color", Color("c0cbdc"))
		liste.add_child(hk)
	_dugme(liste, "Geri", false, _muze_geri)

# --- ışınlanma ve istasyon ------------------------------------------------

func _isinlanma_ac() -> void:
	_isinlanma.visible = true
	arac.kilitli = true
	Ses.cal("menu")
	_isinlanma_yenile()

func _isinlanma_yenile() -> void:
	var h := arac.hucre()
	# Asansör modeli: ışınlanmak için üste ya da bir istasyona basmak gerekir.
	var durak := durum.isinlanma_duragi(h)
	var hub := arac.usste_mi() or durak >= 0
	$HUD/Isinlanma/M/V/Bilgi.text = "Derinlik %d m  •  İstasyon kiti: %d  •  Yolculuk %d yakıt
%s" % [
		h.y, durum.istasyon_kiti, int(Ayarlar.ISINLAMA_YAKIT),
		"Bağlısın." if hub else "Yolculuk için üste ya da bir istasyona gel."]
	var liste: VBoxContainer = $HUD/Isinlanma/M/V/Kaydir/Liste
	_temizle(liste)
	_dugme(liste, "Yüzeye dön (üs)", arac.usste_mi() or not hub,
		_isinla.bind(Vector2(Ayarlar.US_X, -24.0)))
	for i in durum.istasyonlar:
		var hedef: Vector2i = i
		_dugme(liste, "İstasyon — %d m" % hedef.y, not hub or absi(hedef.y - h.y) < 2,
			_isinla.bind(dunya.hucre_merkezi(hedef)))
	if durum.istasyon_kiti <= 0:
		_dugme(liste, "İstasyon kiti yok — üsten al", true, _bos_islem)
	elif durum.istasyon_kurulabilir(h):
		_dugme(liste, "Buraya istasyon kur (%d m)" % h.y, false, _istasyon_kur.bind(h))
	else:
		_dugme(liste, "Buraya kurulamaz — en az %d m, istasyonlar %d m aralıklı"
			% [Ayarlar.ISTASYON_EN_SIG, Ayarlar.ISTASYON_ARALIK], true, _bos_islem)
	_dugme(liste, "Kapat  (Esc)", false, _panelleri_kapat)

func _bos_islem() -> void:
	pass

func _istasyon_kur(h: Vector2i) -> void:
	durum.istasyon_kur(h)
	_nesne_yenile()
	Ses.cal("gelistir")
	_isinlanma_yenile()

func _isinla(hedef: Vector2) -> void:
	_panelleri_kapat()
	Ses.cal("isinlan")
	_karart(true, 0.2)
	await get_tree().create_timer(0.2).timeout
	arac.isinlan(hedef)
	dunya.hazirla(arac.global_position)
	kamera.reset_smoothing()
	_karart(false, 0.2)

## İstasyon ve düşen sandık görsellerini yeniden kurar.
func _nesne_yenile() -> void:
	_temizle(_nesneler)
	var ist := load("res://assets/sprites/istasyon.png")
	for h in durum.istasyonlar:
		var s := Sprite2D.new()
		s.texture = ist
		s.global_position = dunya.hucre_merkezi(h) + Vector2(0, -4)
		_nesneler.add_child(s)
	for sd in durum.dusen_sandiklar:
		var s2 := Sprite2D.new()
		s2.texture = _karo_doku
		s2.region_enabled = true
		s2.region_rect = Rect2(Ayarlar.SANDIK * Ayarlar.KARO, 0, Ayarlar.KARO, Ayarlar.KARO)
		s2.global_position = dunya.hucre_merkezi(Vector2i(sd["h"]))
		_nesneler.add_child(s2)

# --- mini harita ----------------------------------------------------------

func _harita_kur() -> void:
	_harita_img = Image.create(Ayarlar.GENISLIK, Ayarlar.DERINLIK, false, Image.FORMAT_RGBA8)
	_harita_img.fill(Color(0.05, 0.05, 0.08, 0.9))
	for h in dunya.kazilan:
		_harita_ac(h)
	_harita_doku = ImageTexture.create_from_image(_harita_img)
	_harita.texture = _harita_doku

## Kazılan hücrenin çevresini haritada açar (keşfedilmemiş alan kapalı kalır).
func _harita_ac(merkez: Vector2i) -> void:
	if _harita_img == null:
		return
	for dy in range(-HARITA_SIS, HARITA_SIS + 1):
		for dx in range(-HARITA_SIS, HARITA_SIS + 1):
			if dx * dx + dy * dy > HARITA_SIS * HARITA_SIS:
				continue
			_harita_boya(merkez + Vector2i(dx, dy))

## Depremden sonra değişen hücreleri haritada tazeler (zaten keşfedilmiş yerler).
func _harita_guncelle(hucreler: Array) -> void:
	for h in hucreler:
		_harita_boya(Vector2i(h))

func _harita_boya(h: Vector2i) -> void:
	if _harita_img == null:
		return
	if h.x < 0 or h.y < 0 or h.x >= Ayarlar.GENISLIK or h.y >= Ayarlar.DERINLIK:
		return
	var t := dunya.karo_tur(h)
	var renk := Color(0.10, 0.09, 0.13, 1.0)
	if t != Ayarlar.BOS:
		renk = _karo_renk(t).darkened(0.35)
	if Ayarlar.MADEN_DEGER.has(t):
		renk = _karo_renk(t)
	elif t == Ayarlar.SANDIK or t == Ayarlar.ESER:
		renk = Color("fee761")
	elif t == Ayarlar.LAV:
		renk = Color("f77622")
	elif t == Ayarlar.GAZ:
		renk = Color("63c74d")
	_harita_img.set_pixelv(h, renk)

func _harita_ciz() -> void:
	var im := _harita_img.duplicate()
	for h in durum.istasyonlar:
		im.set_pixelv(Vector2i(h), Color("2ce8f5"))
	for sd in durum.dusen_sandiklar:
		im.set_pixelv(Vector2i(sd["h"]), Color("63c74d"))
	var m := arac.hucre()
	for d: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var p := m + d
		if p.x >= 0 and p.y >= 0 and p.x < Ayarlar.GENISLIK and p.y < Ayarlar.DERINLIK:
			im.set_pixelv(p, Color.WHITE)
	_harita_doku.update(im)

# --- paneller, ayarlar, kayıt ---------------------------------------------

func _uyari_goster(metin: String) -> void:
	$HUD/Uyari/M/V/Metin.text = metin
	_uyari.visible = true
	arac.kilitli = true

func _uyari_kapat() -> void:
	_uyari.visible = false
	arac.kilitli = _panel_acik()

func _duraklat_kapat() -> void:
	_duraklat.visible = false
	arac.kilitli = false

func _ayar_ac() -> void:
	_duraklat.visible = false
	_ayar_panel.visible = true
	AyarPanel.kur($HUD/Ayar/M/V/Kaydir/Liste, func():
		_ayar_panel.visible = false
		_duraklat.visible = true)

func _dokunmatik_izler() -> void:
	# Dokunmatik bölgelerin görünür ipuçları (yalnız dokunmatik cihazda).
	var izler: Control = $Dokunmatik/Izler
	# Dokunmatikte klavye yok: E / M / Esc yerine gerçek düğmeler.
	var kutu := HBoxContainer.new()
	kutu.position = Vector2(452, 4)
	kutu.add_theme_constant_override("separation", 4)
	izler.add_child(kutu)
	for veri in [["Üs", _dokun_us], ["Harita", _dokun_harita], ["■", _dokun_duraklat]]:
		var b := Button.new()
		b.text = String(veri[0])
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(0, 22)
		b.pressed.connect(veri[1])
		kutu.add_child(b)
	for veri in [[Vector2(0, 250), Vector2(150, 110), "◀"], [Vector2(490, 250), Vector2(150, 110), "▶"],
			[Vector2(150, 250), Vector2(150, 110), "▼ KAZ"], [Vector2(150, 120), Vector2(150, 110), "▲ UÇ"]]:
		var p := Panel.new()
		p.position = veri[0]
		p.size = veri[1]
		p.modulate = Color(1, 1, 1, 0.16)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		izler.add_child(p)
		var l := Label.new()
		l.text = veri[2]
		l.position = veri[0] + veri[1] * 0.5 - Vector2(20, 10)
		l.modulate = Color(1, 1, 1, 0.55)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		izler.add_child(l)

func _dokun_us() -> void:
	Ses.cal("menu")
	if _panel_acik():
		_panelleri_kapat()
	elif arac.usste_mi():
		_magaza_ac()
	else:
		_isinlanma_ac()

func _dokun_harita() -> void:
	Ses.cal("menu")
	_harita.visible = not _harita.visible
	_harita_zaman = 0.0

func _dokun_duraklat() -> void:
	if _panel_acik():
		_panelleri_kapat()
		return
	Ses.cal("menu")
	_duraklat.visible = true
	arac.kilitli = true

func _karart(kapali: bool, sure := 0.45) -> void:
	create_tween().tween_property(_karartma, "color:a", 1.0 if kapali else 0.0, sure)

func _menuye() -> void:
	_kaydet()
	_karart(true, 0.3)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _kaydet() -> void:
	var d := durum.sozluge()
	d["kazilan"] = dunya.kazilan_dizi()
	d["eklenen"] = dunya.eklenen_dizi()
	Kayit.kaydet(d)
