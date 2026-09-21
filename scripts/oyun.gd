## Oyun sahnesi: HUD, üs, müze, ışınlanma, tehlikeler, oyun hissi, kayıt.
extends Node2D

const SANDIK_ODUL := [
	{"tur": "para", "az": 40, "cok": 120},
	{"tur": "dinamit", "az": 2, "cok": 4},
	{"tur": "yakit", "az": 30, "cok": 70},
]
const SARSINTI_SONUM := 9.0
const DUSME_BEKLE := 0.5       ## gevşek kaya kaç saniye titrer

@onready var dunya: Dunya = $Dunya
@onready var sis: Sis = $Sis
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
@onready var _deprem_pano: VBoxContainer = $HUD/Deprem
@onready var _lbl_deprem: Label = $HUD/Deprem/Sayac
@onready var _lbl_kacis: Label = $HUD/Deprem/Kacis
@onready var _lbl_kal: Label = $HUD/Deprem/Kal
@onready var _isaret: ColorRect = $HUD/Isaret

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
@onready var _fon_renk: ColorRect = $Arkaplan/Renk

var durum: Durum
var _sarsinti := 0.0
var _radar_acik := false
var _titreyen := []     ## {"h": Vector2i, "t": float, "s": Sprite2D}
var _dusenler := []     ## {"s": Sprite2D, "hiz": float}
var _harita_img: Image
var _harita_doku: ImageTexture
var _harita_son: Image        ## son çizilen harita karesi (işaret/istasyon katmanıyla; test okur)
var _harita_zaman := 0.0
var _ipucu_sabit := ""
var _ipucu_sure := 0.0
var _derine_indi := false     ## sefer sayacı: dibe inip üsse dönünce bir sefer biter
var _deprem_uyari := 0.0      ## >0 iken deprem uyarısı sürüyor
var _deprem_uyari_derinlik := 0  ## uyarı başladığında neredeydik (ikramiye buna göre)
var _dokunmatik := false
var _karo_doku: Texture2D
var _cekiliyor := false
var _son_hucre := Vector2i(1 << 30, 1 << 30)   ## keşif sisi bu değişince yenilenir
var _dgm_dinamit: Button                       ## dokunmatik alet düğmeleri (yoksa null)
var _dgm_radar: Button
var _dgm_isaret: Button
var _isaret_ogretildi := false                 ## işaret ipucu oturumda bir kez (30 m'yi ilk geçişte)
var _ambiyans: CPUParticles2D                  ## banda göre toz / kıvılcım (araca bağlı)
var _bant := -1                                ## şu anki ambiyans bandı (Ayarlar.AMBIYANS)

func _ready() -> void:
	_karo_doku = load("res://assets/sprites/karolar.png")
	var kayitli := Kayit.yukle()
	durum = Durum.new(int(kayitli.get("tohum", randi())))
	durum.sozlukten(kayitli)

	dunya.kur(durum.tohum, Dunya.diziden_kazilan(kayitli.get("kazilan", null)),
		Dunya.diziden_eklenen(kayitli.get("eklenen", null)),
		String(kayitli.get("kesif", "")))
	sis.dunya = dunya
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
	arac.kazma_degisti.connect(_kazma_degisti)

	$HUD/Duraklat/M/V/Devam.pressed.connect(_duraklat_kapat)
	$HUD/Duraklat/M/V/Ayar.pressed.connect(_ayar_ac)
	$HUD/Duraklat/M/V/Menu.pressed.connect(_menuye)
	$HUD/Bitis/M/V/Menu.pressed.connect(_menuye)
	$HUD/Uyari/M/V/Tamam.pressed.connect(_uyari_kapat)

	_dokunmatik = DisplayServer.is_touchscreen_available()
	$Dokunmatik.visible = _dokunmatik
	if $Dokunmatik.visible:
		dokunmatik_kur()

	_harita_kur()
	_kesif_yenile()
	_nesne_yenile()
	_hud_yenile()
	_ambiyans_kur()
	_ambiyans_yenile()
	_karart(false)

# --- ana döngü ------------------------------------------------------------

func _process(delta: float) -> void:
	dunya.hazirla(arac.global_position)
	_kesif_yenile()
	_arkaplan_yenile(delta)
	_sarsinti_isle(delta)
	_sefer_isle()
	_deprem_isle(delta)
	_tehlike_isle(delta)
	_sandik_kontrol()
	_kacis_kontrol()
	_isaret_ogret()
	if _ipucu_sure > 0.0:
		_ipucu_sure -= delta
	_harita_zaman -= delta
	if _harita.visible and _harita_zaman <= 0.0:
		_harita_zaman = 0.25
		_harita_ciz()
	_hud_yenile()
	_ambiyans_yenile()

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
		_dinamit_kullan()
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("radar") and not _panel_acik():
		_radar_degistir()
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("isinlan") and not _panel_acik():
		_isinlanma_ac()
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("isaret") and not _panel_acik():
		_isaret_koy()
		get_viewport().set_input_as_handled()
	elif olay.is_action_pressed("harita") and not _panel_acik():
		_harita.visible = not _harita.visible
		_harita_zaman = 0.0
		Ses.cal("menu")
		get_viewport().set_input_as_handled()

# --- aletler (tuş ve dokunmatik düğme aynı yoldan) ------------------------
## v0.4'te bu iki işlem yalnız `_unhandled_input` içindeydi, yani telefonda
## dinamit ve radar KULLANILAMIYORDU. Tek yere taşındı; düğmeler de buraya bağlı.

func _dinamit_kullan() -> void:
	if arac.dinamit_at():
		Ses.cal("patlama")
	elif durum.dinamit <= 0:
		_ipucu_goster("Dinamit yok — üsten al.", 1.5)
	else:
		_ipucu_goster("Dinamit için zemine bas.", 1.5)

func _radar_degistir() -> void:
	if not durum.alet_var("radar"):
		_ipucu_goster("Maden radarı yok — üsten al.", 1.5)
		return
	_radar_acik = not _radar_acik
	Ses.cal("menu")
	_kesif_yenile(true)   ## radar sisi geçici açar / kapatır

# --- ışınlama işareti (v0.7) ----------------------------------------------
## İstasyon dışında tek kullanımlık dönüş noktası: yeraltında R (ya da İŞARET düğmesi)
## işareti aracın hücresine koyar, yenisi eskisini taşır. Işınlanma panelinde
## "İşarete ışınlan" satırı çıkar — asansör kuralı aynı: üsten ya da bir istasyondan
## gidilir, gidince işaret silinir. Bot bunu bilmez; ölçüm değişmez.

func _isaret_koy() -> void:
	if arac.usste_mi():
		_ipucu_goster("İşaret üste konmaz — yeraltında koy.", 1.5)
		return
	durum.isaret = arac.hucre()
	Ses.cal("menu")
	_nesne_yenile()
	_ipucu_goster(Ipucu.isaret_kondu(durum.isaret.y, _dokunmatik), 2.5)

func _isaret_isinla() -> void:
	if not durum.isaret_var():
		return
	var h := durum.isaret
	durum.isaret = Durum.ISARET_YOK
	# Deprem işaretin hücresini doldurmuş olabilir (istasyon gibi korunmuyor; kapanan
	# hücre hep kazılabilir): varışta açılır, araç kayanın içinde kalmaz.
	if dunya.karo_tur(h) != Ayarlar.BOS:
		dunya.karo_kir(h)
	_nesne_yenile()
	_isinla(dunya.hucre_merkezi(h))

func _isaret_ogret() -> void:
	if _isaret_ogretildi or durum.isaret_var() or durum.kazandi or arac.derinlik() < 30:
		return
	_isaret_ogretildi = true
	_ipucu_goster(Ipucu.isaret_ogret(_dokunmatik), 4.0)

## Matkap döngü sesi (v0.7): kazı başlayınca çalar, kesilince kısa kuyrukla söner
## (kuyruk Arac.KAZMA_KUYRUK). Perde matkap seviyesiyle tizleşir — geliştirme kulakla da
## fark edilsin.
func _kazma_degisti(kaziyor: bool) -> void:
	if kaziyor:
		Ses.dongu_baslat("matkap", 0.9 + 0.08 * float(durum.matkap))
	else:
		Ses.dongu_durdur("matkap")

# --- keşif sisi -----------------------------------------------------------

## Araç yeni bir hücreye geçtiyse ışık yarıçapını kalıcı olarak açar, sis
## örtüsünü ve mini haritayı yeniler. Karo başına bir kez çalışır: her karede
## ~80 hücre işaretlemek ve ekranı yeniden çizmek boşuna olurdu.
func _kesif_yenile(zorla := false) -> void:
	var h := arac.hucre()
	if h == _son_hucre and not zorla:
		return
	_son_hucre = h
	# Yarıçap moda bağlı: Derin Mod'da 3, 7. eserle 4 (Durum.isik_yaricap).
	for k in dunya.kesfet(h, durum.isik_yaricap()):
		_harita_boya(k)
	sis.yenile(h, _radar_acik and durum.alet_var("radar"), durum.isik_yaricap())

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
	_deprem_pano.visible = _deprem_uyari > 0.0 and not panel
	if _deprem_pano.visible:
		_deprem_panosu()
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
	_alet_dugmeleri()

## Deprem uyarı panosu: geri sayım + kararın iki ucu. Son 3 saniyede sayaç
## yanıp söner — v0.4'te geri sayım 13 px'lik alt ipucu şeridindeydi ve
## telefonda gözden kaçıyordu.
func _deprem_panosu() -> void:
	var satir := Ipucu.deprem_pano(_deprem_uyari, arac.derinlik(), _dokunmatik)
	_lbl_deprem.text = String(satir[0])
	_lbl_kacis.text = String(satir[1])
	_lbl_kal.text = String(satir[2])
	var hizli := _deprem_uyari <= 3.0
	_lbl_deprem.modulate.a = 1.0 if not hizli else (0.35 + 0.65 * absf(sin(_deprem_uyari * 6.0)))

## Dokunmatik alet düğmelerinin sayacı ve durumu (düğmeler yoksa hiçbir şey).
func _alet_dugmeleri() -> void:
	if _dgm_dinamit == null:
		return
	_dgm_dinamit.text = "DİNAMİT %d" % durum.dinamit
	_dgm_dinamit.disabled = durum.dinamit <= 0
	var radar_var := durum.alet_var("radar")
	if not radar_var:
		_dgm_radar.text = "RADAR yok"
	else:
		_dgm_radar.text = "RADAR KAPA" if _radar_acik else "RADAR AÇ"
	_dgm_radar.disabled = not radar_var
	_dgm_isaret.text = ("İŞARET %d m" % durum.isaret.y) if durum.isaret_var() else "İŞARET KOY"

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

## Metnin kendisi saf sınıfta (scripts/ipucu.gd): dokunmatik/masaüstü ayrımı
## testle sınanabilsin diye. Burada yalnız hangi durumun geçerli olduğu seçiliyor.
## Deprem geri sayımı artık burada DEĞİL — ortadaki $HUD/Deprem panosunda.
func _ipucu(d: int) -> String:
	if _panel_acik():
		return ""
	if _ipucu_sure > 0.0:
		return _ipucu_sabit
	return Ipucu.metin(durum, d, arac.usste_mi(), _dokunmatik)

# --- arka plan ve müzik ---------------------------------------------------

func _arkaplan_yenile(delta: float) -> void:
	var kam := kamera.get_screen_center_position()
	var d := arac.derinlik()
	var kayma := minf(1.0, delta * 2.0)   ## renk geçişleri ~1 sn'de oturur
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
	# Yeraltı: katman rengiyle boyanmış kaya dokusu. Renk katman sınırında yumuşak
	# geçer (v0.5'te sınırda tek karede atlıyordu); düz fon bandın tonunu alır.
	var yer := clampf((float(d) - 4.0) / 14.0, 0.0, 1.0)
	var hedef: Color = Ayarlar.KATMANLAR[Ayarlar.katman(d)]["renk"]
	var renk := Color(_fon_kaya.modulate, 1.0).lerp(hedef, kayma)
	_fon_kaya.modulate = Color(renk.r, renk.g, renk.b, yer * 0.85)
	_fon_kaya.position = Vector2(fmod(-kam.x * 0.25, 64.0) - 64.0, fmod(-kam.y * 0.25, 64.0) - 64.0)
	var fon: Color = Ayarlar.AMBIYANS[Ayarlar.ambiyans(d)]["fon"]
	_fon_renk.color = _fon_renk.color.lerp(fon, kayma)

## Derinlik ambiyansı (v0.6): dört bant (Ayarlar.AMBIYANS). Bant değişince müzik
## öteki parçaya çaprazlanır (Ses.muzik_cal, iki oyuncu), parçacık tozdan
## kıvılcıma döner. Parçacık aracın çocuğu ama dünya koordinatında salınır;
## sisin altında çizilir ki karanlıkta o da sönsün.
func _ambiyans_kur() -> void:
	_ambiyans = CPUParticles2D.new()
	_ambiyans.name = "Ambiyans"
	_ambiyans.texture = load("res://assets/sprites/benek.png")
	_ambiyans.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_ambiyans.emission_rect_extents = Vector2(200, 120)   ## 2x kamerada ekran 320x180
	_ambiyans.local_coords = false
	_ambiyans.z_as_relative = false
	_ambiyans.z_index = 5
	_ambiyans.emitting = false
	arac.add_child(_ambiyans)

func _ambiyans_yenile() -> void:
	var d := arac.derinlik()
	_ambiyans.emitting = d > Ayarlar.GUN_ISIGI
	var b := Ayarlar.ambiyans(d)
	if b == _bant:
		return
	_bant = b
	var a: Dictionary = Ayarlar.AMBIYANS[b]
	Ses.muzik_cal(String(a["muzik"]), Ayarlar.MUZIK_GECIS)
	var renk: Color = a["renk"]
	if String(a["parcacik"]) == "kivilcim":
		# Yükselen kıvılcım: kısa ömür, yukarı, titrek.
		_ambiyans.amount = 18
		_ambiyans.lifetime = 1.6
		_ambiyans.direction = Vector2.UP
		_ambiyans.spread = 35.0
		_ambiyans.initial_velocity_min = 10.0
		_ambiyans.initial_velocity_max = 28.0
		_ambiyans.gravity = Vector2(0, -22)
		_ambiyans.scale_amount_min = 0.3
		_ambiyans.scale_amount_max = 0.7
		_ambiyans.color = Color(renk, 0.9)
	else:
		# Süzülen toz: uzun ömür, ağır, her yöne.
		_ambiyans.amount = 12
		_ambiyans.lifetime = 5.0
		_ambiyans.direction = Vector2.DOWN
		_ambiyans.spread = 180.0
		_ambiyans.initial_velocity_min = 2.0
		_ambiyans.initial_velocity_max = 7.0
		_ambiyans.gravity = Vector2(0, 4)
		_ambiyans.scale_amount_min = 0.5
		_ambiyans.scale_amount_max = 0.9
		_ambiyans.color = Color(renk, 0.5)

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
	# Sıra Durum.sonraki_eser'de: Derin Mod'da 7. eser ilk odada gelir, ilk oyunda hiç.
	var sonraki := durum.sonraki_eser()
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
		% [durum.eser_toplanan(), durum.eser_sayisi(), e["ad"], e["metin"], e["hikaye"]])
	_kesif_yenile(true)   ## 7. eser ışığı büyütüyor

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
	if durum.eser_toplanan() < durum.eser_sayisi():
		son = "Eksik eserler çekirdeğin hikâyesinin kalan parçalarını taşıyor."
	var sonraki_mod := "Menüde DERİN MOD açıldı: yeni tohum, sert kaya, dar ışık, sık deprem ve yalnız orada bulunan 7. eser — eser bonusların kalır."
	if durum.derin_mi():
		sonraki_mod = "Derin Mod x%d tamamlandı. Menüde x%d açıldı — eserlerin seninle gelir." % [
			durum.derin_seviye, durum.derin_seviye + 1]
	$HUD/Bitis/M/V/Metin.text = bitis_metni(durum, Kayit.oyuncu_yukle(), son, sonraki_mod)
	_bitis.visible = true

## Bitiş ekranının dökümü (v0.7): bu dünyanın sayaçları + [oyuncu] toplamı. Saf —
## test sahne kurmadan metni sınıyor. `toplam` _kaydet'ten SONRA okunmalı ki bu koşu
## toplama girmiş olsun. Satırlar 480 px'e sarılır (oyun.tscn autowrap), 640×360'a sığar.
static func bitis_metni(d: Durum, toplam: Dictionary, son: String, sonraki_mod: String) -> String:
	var s := d.istatistik()
	return "ÇEKİRDEK ÇIKARILDI!\n\nSüre %s  •  En derin %d m  •  Para %d ₺  •  Eser %d/%d  •  Tohum %s\n\nBu dünya:  %d karo kazıldı  •  %d deprem  •  %d yüzeye çekilme  •  %d ₺ satış\nToplam (bütün dünyalar):  %d karo  •  %d deprem  •  %d çekilme  •  %d ₺ satış  •  %s oyun\n\n%s\n\n%s" % [
		_sure_metni(d.sure), d.en_derin, d.para, d.eser_toplanan(), d.eser_sayisi(), TohumKodu.kodla(d.tohum),
		int(s["kazilan_karo"]), int(s["deprem"]), int(s["olum"]), int(s["satis_toplam"]),
		int(toplam.get("kazilan_karo", 0)), int(toplam.get("deprem", 0)), int(toplam.get("olum", 0)),
		int(toplam.get("satis_toplam", 0)), _sure_metni(float(toplam.get("sure", 0.0))),
		son, sonraki_mod]

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
		if durum.sefer % durum.deprem_araligi() == 0:   ## Derin Mod'da 4, ilk oyunda 5
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
		_deprem_uyari_derinlik = arac.derinlik()
		# Uyarı derinlikle uzuyor: 100 m'de 10 sn, 250 m'de 19 sn. Karar
		# verilebilsin diye — geri sayım ortadaki panoda ($HUD/Deprem).
		_deprem_uyari = Deprem.uyari_suresi(_deprem_uyari_derinlik)
		_deprem_isareti()

## Uyarının başladığı an: kısa kırmızı ekran işareti + iki katmanlı ses.
## Oyuncu kazmaya bakarken HUD'ın alt şeridini görmüyor; işaret bakışı kaldırıyor.
func _deprem_isareti() -> void:
	Ses.cal("uyari", 0.45)
	Ses.cal("deprem_uyari")   ## v0.7: depremin kendi gürültüsü (tiz, kısık), patlama sesi değil
	sars(4.0)
	_isaret.color.a = 0.32
	create_tween().tween_property(_isaret, "color:a", 0.0, 0.5)

func _deprem_uygula() -> void:
	durum.deprem += 1
	_deprem_pano.visible = false
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
	Ses.cal("deprem")   ## v0.7: düşük frekanslı sarsıntı + çatırtı (tools/ses_uret.gd), patlama değil
	_toz(arac.global_position, _karo_renk(Ayarlar.TOPRAK), 30, 160.0)
	# Oyuncunun kararının karşılığı: yüzeye çıktıysa ikramiye, derinde kaldıysa hasar.
	var k := Deprem.karar(_deprem_uyari_derinlik, arac.derinlik())
	var son := ""
	if bool(k["guvende"]):
		durum.para += int(k["odul"])
		_ucan_yazi(arac.global_position, "+%d ₺" % int(k["odul"]), Color("fee761"))
		Ses.cal("sat")
		son = "  Kabuk nöbeti ikramiyesi +%d ₺." % int(k["odul"])
	elif int(k["hasar"]) > 0:
		arac.hasar(int(k["hasar"]), arac.global_position)
		son = "  Derinde kaldın: -%d can." % int(k["hasar"])
	_kaydet()
	_ipucu_goster("DEPREM! %d karo tünel kapandı, %d yeni damar/gaz çıktı.%s"
		% [kapanan.size(), yeni.size() - kapanan.size(), son], 4.0)

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
	# Alet açıklamaları dokunmatikte tuş değil DÜĞME anlatır (Ipucu.MAGAZA).
	for ad in Ayarlar.ALET_FIYAT:
		var aciklama := Ipucu.magaza(ad, _dokunmatik)
		if bool(durum.aletler.get(ad, false)):
			_dugme(liste, "%s ✔ — %s" % [Ayarlar.ALET_AD[ad], aciklama], true, _bos_islem)
		else:
			var f2 := int(Ayarlar.ALET_FIYAT[ad])
			_dugme(liste, "%s  (%d ₺) — %s" % [Ayarlar.ALET_AD[ad], f2, aciklama],
				durum.para < f2, _alet_al.bind(ad))
	_dugme(liste, "Dinamit x1  (%d ₺) — %s"
		% [Ayarlar.DINAMIT_FIYAT, Ipucu.magaza("dinamit", _dokunmatik)],
		durum.para < Ayarlar.DINAMIT_FIYAT, _dinamit_al)
	_dugme(liste, "İstasyon kiti  (%d ₺) — %s"
		% [Ayarlar.ISTASYON_FIYAT, Ipucu.magaza("istasyon", _dokunmatik)],
		durum.para < Ayarlar.ISTASYON_FIYAT, _istasyon_kiti_al)
	_dugme(liste, "Müze  (%d/%d eser)" % [durum.eser_toplanan(), durum.eser_sayisi()], false, _muze_ac)
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
		durum.eser_toplanan(), durum.eser_sayisi()]
	var liste: VBoxContainer = $HUD/Muze/M/V/Kaydir/Liste
	_temizle(liste)
	for i in Ayarlar.ESERLER.size():
		if Ayarlar.eser_derin_mi(i) and not durum.derin_mi():
			continue   ## 7. eser ilk oyunda müzede bile görünmez (Derin Mod'un sürprizi)
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
	if durum.isaret_var():
		_dugme(liste, "İşarete ışınlan — %d m  (tek kullanımlık, sonra silinir)" % durum.isaret.y,
			not hub or durum.isaret.distance_squared_to(h) <= 2, _isaret_isinla)
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
	if durum.isaret_var():
		var s3 := Sprite2D.new()
		s3.texture = load("res://assets/sprites/isaret.png")
		s3.global_position = dunya.hucre_merkezi(durum.isaret)
		_nesneler.add_child(s3)

# --- mini harita ----------------------------------------------------------

func _harita_kur() -> void:
	_harita_img = Image.create(Ayarlar.GENISLIK, Ayarlar.DERINLIK, false, Image.FORMAT_RGBA8)
	_harita_img.fill(Color(0.05, 0.05, 0.08, 0.9))
	# Kayıttan gelen keşif: yalnız görülmüş hücreler boyanır, gerisi kapalı kalır.
	for y in Ayarlar.DERINLIK:
		for x in Ayarlar.GENISLIK:
			_harita_boya(Vector2i(x, y))
	_harita_doku = ImageTexture.create_from_image(_harita_img)
	_harita.texture = _harita_doku

## Bir merkezin çevresini ışık yarıçapı kadar keşfeder ve haritaya işler.
## (tools/ekran_al.gd yayın görselinde haritayı doldurmak için bunu çağırıyor.)
func _harita_ac(merkez: Vector2i) -> void:
	for k in dunya.kesfet(merkez, durum.isik_yaricap()):
		_harita_boya(k)

## Depremden sonra değişen hücreleri haritada tazeler (zaten keşfedilmiş yerler).
func _harita_guncelle(hucreler: Array) -> void:
	for h in hucreler:
		_harita_boya(Vector2i(h))

## Mini harita YALNIZ keşfedileni gösterir: keşfedilmemiş hücre dokunulmaz,
## yani dolgu rengiyle kapalı kalır (rakip analizi madde 13).
func _harita_boya(h: Vector2i) -> void:
	if _harita_img == null:
		return
	if h.x < 0 or h.y < 0 or h.x >= Ayarlar.GENISLIK or h.y >= Ayarlar.DERINLIK:
		return
	if not dunya.kesfedildi_mi(h):
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
		if dunya.kesfedildi_mi(Vector2i(h)):
			im.set_pixelv(Vector2i(h), Color("2ce8f5"))
	for sd in durum.dusen_sandiklar:
		if dunya.kesfedildi_mi(Vector2i(sd["h"])):
			im.set_pixelv(Vector2i(sd["h"]), Color("63c74d"))
	if durum.isaret_var() and dunya.kesfedildi_mi(durum.isaret):
		im.set_pixelv(durum.isaret, Color("b55088"))   ## işaret: pembe (istasyon camgöbeği)
	var m := arac.hucre()
	for d: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var p := m + d
		if p.x >= 0 and p.y >= 0 and p.x < Ayarlar.GENISLIK and p.y < Ayarlar.DERINLIK:
			im.set_pixelv(p, Color.WHITE)
	_harita_son = im
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

## Dokunmatik düzeni. 640x360'a sığması ve DOKUNMA ALANLARIYLA ÇAKIŞMAMASI
## zorunlu; `tests/test_oynanis.gd` sahnedeki gerçek dikdörtgenleri ölçüp
## çakışma ve taşma arıyor (veri iki yere yazılmasın diye test ölçümü sahneden
## alıyor, sabit listeden değil).
##
## Yerleşim:
##   sağ üst      Üs · Harita · ■                    (y 4..26,  boş şerit)
##   sol orta     DİNAMİT · RADAR · İŞARET (dikey)   (y 100..244, ◀ alanının üstünde,
##                                                    Katman etiketinin (y 21..44) altında)
##   alt/orta     ◀ ▼KAZ ▶ ve ▲UÇ                    (scenes/oyun.tscn, değişmedi)
## v0.4'te alet düğmeleri hiç yoktu: sağ üstteki şeride üç düğme daha 640 px'e
## sığmıyordu, çözüm yatay şeridi büyütmek değil ikinci bir DİKEY şerit açmak.
## v0.7'de üçüncü düğme (İŞARET) için şerit 48 px yukarı alındı: 148'de başlasa
## 250'deki ◀ alanına binerdi.
const ALET_KONUM := Vector2(8, 100)
const ALET_BOYUT := Vector2(92, 44)

func dokunmatik_kur() -> void:
	var izler: Control = $Dokunmatik/Izler
	# Dokunmatikte klavye yok: E / M / Esc yerine gerçek düğmeler.
	var kutu := HBoxContainer.new()
	kutu.name = "Ust"
	kutu.position = Vector2(452, 4)
	kutu.add_theme_constant_override("separation", 4)
	$Dokunmatik.add_child(kutu)
	for veri in [["Üs", _dokun_us], ["Harita", _dokun_harita], ["■", _dokun_duraklat]]:
		var b := Button.new()
		b.text = String(veri[0])
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(0, 22)
		b.pressed.connect(veri[1])
		kutu.add_child(b)
	# Alet şeridi: dikey, sayaçlı. Metni _alet_dugmeleri() her karede yeniliyor.
	var alet := VBoxContainer.new()
	alet.name = "Aletler"
	alet.position = ALET_KONUM
	alet.add_theme_constant_override("separation", 6)
	$Dokunmatik.add_child(alet)
	_dgm_dinamit = _alet_dugme(alet, "DİNAMİT 0", _dinamit_kullan)
	_dgm_radar = _alet_dugme(alet, "RADAR AÇ", _radar_degistir)
	_dgm_isaret = _alet_dugme(alet, "İŞARET KOY", _isaret_koy)
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
	_alet_dugmeleri()

func _alet_dugme(kap: VBoxContainer, metin: String, geri: Callable) -> Button:
	var b := Button.new()
	b.text = metin
	b.custom_minimum_size = ALET_BOYUT
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(geri)
	kap.add_child(b)
	return b

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
	d["kesif"] = dunya.kesif_dizi()   ## keşif sisi kayda giriyor (sıkıştırılmış)
	Kayit.kaydet(d)
	Kayit.oyuncu_biriktir(durum.istatistik_farki())   ## [oyuncu] toplamı (v0.7), yuvadan bağımsız
