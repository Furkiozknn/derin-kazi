## Oynanış entegrasyon testi: gerçek sahneyi kurar, aracı kazdırır, yeni
## özellikleri (chunk boşaltma, kazı kaydı, matkap kapısı, dinamit, istasyon)
## sahne üstünde sınar.
##   godot --headless --path . --script res://tests/test_oynanis.gd   (0 = geçti)
extends SceneTree

var _hata := 0
var _sayac := 0

func dogru(kosul: bool, ad: String) -> void:
	_sayac += 1
	if kosul:
		print("  [OK] ", ad)
	else:
		_hata += 1
		printerr("  [HATA] ", ad)

func _initialize() -> void:
	_calis()

func _kare(n: int) -> void:
	for i in n:
		await physics_frame

func _calis() -> void:
	print("== Oynanış testi ==")
	# Temiz başlangıç + SABİT TOHUM. Kayıt yokken oyun sahnesi randi() ile tohum
	# seçiyor; o zaman bu test her çalıştırmada başka bir dünyada oynuyor ve
	# arada bir kararsız hata veriyordu (derinlik, deprem ve varyant sınamaları
	# dünyaya bağlı). Çok tohumlu kapsama tests/test_calistir.gd işi.
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242})
	var sahne: Node = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(sahne)
	await process_frame
	await _kare(30)

	var arac: Arac = sahne.get_node("Arac")
	var dunya: Dunya = sahne.get_node("Dunya")
	var durum: Durum = sahne.durum
	# Autoload'a --script testinden ADIYLA erişilmez ("Identifier not found: Ses"
	# derleme hatası); düğüm ağacından, dinamik tipte alınır.
	var ses = root.get_node("Ses")

	dogru(arac.is_on_floor(), "araç yüzeyde zemine oturdu")
	dogru(arac.usste_mi(), "başlangıçta üste yakın (menü açılabilir)")
	dogru(dunya.toplam_uretim > 0, "ilk chunk'lar üretildi (%d karo)" % dunya.toplam_uretim)
	dogru(dunya.yuklu_parca_sayisi() <= 9, "yalnız çevredeki chunk'lar yüklü (%d)"
		% dunya.yuklu_parca_sayisi())

	var yakit0 := durum.yakit
	var parca0 := dunya.toplam_uretim

	# --- 25 saniye aşağı kaz --------------------------------------------
	durum.matkap = Ayarlar.EN_YUKSEK_SEVIYE   ## kapı bu aşamada test edilmiyor
	Input.action_press("asagi")
	await _kare(1500)
	Input.action_release("asagi")
	await _kare(10)

	var derinlik := arac.derinlik()
	dogru(derinlik > 15, "aşağı kazarak derinleşti (%d m)" % derinlik)
	dogru(durum.en_derin >= derinlik - 1, "en derin nokta kaydedildi (%d m)" % durum.en_derin)
	dogru(durum.yakit < yakit0, "yakıt tüketildi (%.1f → %.1f)" % [yakit0, durum.yakit])
	dogru(durum.yuk_toplam() > 0, "yol üstündeki maden yüke eklendi (%d ağırlık)" % durum.yuk_toplam())
	dogru(not arac.usste_mi(), "araç üsten uzaklaştı")
	dogru(dunya.toplam_uretim > parca0, "inerken yeni chunk'lar üretildi (%d → %d karo)"
		% [parca0, dunya.toplam_uretim])

	# --- chunk yönetimi: yalnız çevre bellekte --------------------------
	var yuklu := dunya.get_used_cells().size()
	var tum_dunya := Ayarlar.GENISLIK * Ayarlar.DERINLIK
	dogru(dunya.yuklu_parca_sayisi() <= 9, "en fazla 3x3 chunk yüklü (%d)" % dunya.yuklu_parca_sayisi())
	dogru(yuklu < tum_dunya / 4, "chunk'lı üretim: %d / %d karo bellekte (%%%.0f)"
		% [yuklu, tum_dunya, 100.0 * float(yuklu) / float(tum_dunya)])
	dogru(yuklu <= 9 * Ayarlar.PARCA * Ayarlar.PARCA,
		"bellekteki karo sayısı chunk sınırının altında (%d <= %d)"
		% [yuklu, 9 * Ayarlar.PARCA * Ayarlar.PARCA])

	# --- kazı kaydı: tüneller kalıcı ------------------------------------
	dogru(dunya.kazilan.size() > 10, "kazılan hücreler fark olarak kaydedildi (%d)" % dunya.kazilan.size())
	var ornek: Vector2i = dunya.kazilan.keys()[0]
	dogru(dunya.karo_tur(ornek) == Ayarlar.BOS, "kazılan hücre boş görünüyor")
	# Chunk'ı boşaltıp yeniden yükle: tünel kapanmamalı.
	var p := Dunya.parca_no(ornek)
	dunya.hazirla(Vector2(Ayarlar.US_X, -24.0))       ## uzaklaş → chunk boşalır
	dunya.hazirla(dunya.hucre_merkezi(ornek))          ## geri dön → yeniden yüklenir
	dogru(dunya.get_cell_source_id(ornek) < 0, "chunk yeniden yüklenince tünel yerinde kaldı")

	sahne.call("_kaydet")
	var kayit := Kayit.yukle()
	var kazilan_dizi := PackedInt32Array(kayit.get("kazilan", PackedInt32Array()))
	dogru(kazilan_dizi.size() / 2 == dunya.kazilan.size(),
		"kazılan hücreler kayda yazıldı (%d hücre)" % (kazilan_dizi.size() / 2))

	# --- keşif sisi (v0.5) ------------------------------------------------
	# Aracın ışığı indiği yeri kalıcı açar; inilmemiş derinlik karanlık kalır
	# ve mini harita yalnız keşfedileni gösterir (rakip analizi madde 13).
	var karanlik := Vector2i(arac.hucre().x, 200)
	dogru(dunya.kesif_sayisi() > 50, "inilen koridor keşfedildi (%d hücre)"
		% dunya.kesif_sayisi())
	dogru(dunya.kesfedildi_mi(arac.hucre()), "aracın bulunduğu hücre keşfedilmiş")
	dogru(not dunya.kesfedildi_mi(karanlik), "inilmemiş 200 m hâlâ karanlık")
	var harita_img: Image = sahne.get("_harita_img")
	# Dolgu rengi 8 bit'e yuvarlanıyor; karşılaştırma da yuvarlanmış renkle.
	var dolgu_img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	dolgu_img.fill(Color(0.05, 0.05, 0.08, 0.9))
	var dolgu := dolgu_img.get_pixel(0, 0)
	dogru(harita_img.get_pixelv(karanlik).is_equal_approx(dolgu),
		"mini haritada keşfedilmemiş hücre kapalı")
	dogru(not harita_img.get_pixelv(arac.hucre()).is_equal_approx(dolgu),
		"mini haritada keşfedilen hücre boyalı")
	var kesif_kod := String(kayit.get("kesif", ""))
	dogru(kesif_kod != "" and Dunya.diziden_kesif(kesif_kod).size()
		== Ayarlar.GENISLIK * Ayarlar.DERINLIK,
		"keşif sisi kayda yazıldı (%d karakter)" % kesif_kod.length())

	# --- pervane ---------------------------------------------------------
	var y0 := arac.global_position.y
	Input.action_press("yukari")
	await _kare(90)
	Input.action_release("yukari")
	dogru(arac.global_position.y < y0, "pervane ile tünelde yükseldi (%.0f → %.0f px)"
		% [y0, arac.global_position.y])

	var yuk0 := durum.yuk_toplam()
	Input.action_press("yukari")
	await _kare(240)
	Input.action_release("yukari")
	dogru(durum.yuk_toplam() == yuk0, "yukarı doğru kazma yok (yük değişmedi)")

	# --- matkap kapısı ---------------------------------------------------
	var uyari := [0]
	arac.matkap_yetersiz.connect(func(_g: int): uyari[0] += 1)
	# Tünelin dibine in: oranın altı kazılmamış ve 2. katman kapısının ardında.
	var dip := Vector2i(arac.hucre().x, 0)
	for k in dunya.kazilan:
		if int(k.y) > dip.y:
			dip = Vector2i(k)
	arac.isinlan(dunya.hucre_merkezi(dip))
	await _kare(20)
	durum.matkap = 0
	durum.yakit = durum.yakit_kapasitesi()
	var kirilan0 := dunya.kazilan.size()
	dogru(not durum.matkap_yeterli_mi(dip.y + 1),
		"%d m'nin altı Matkap Sv%d istiyor" % [dip.y, Durum.gereken_matkap(dip.y + 1) + 1])
	Input.action_press("asagi")
	await _kare(150)
	Input.action_release("asagi")
	dogru(uyari[0] > 0, "matkap yetersizken uyarı verildi (%d kez)" % uyari[0])
	dogru(dunya.kazilan.size() == kirilan0, "matkap yetersizken karo kırılmadı")
	durum.matkap = Ayarlar.EN_YUKSEK_SEVIYE

	# --- dinamit ---------------------------------------------------------
	durum.dinamit = 1
	await _kare(30)   ## zemine otursun
	var once := dunya.kazilan.size()
	var atildi := arac.dinamit_at()
	dogru(atildi and durum.dinamit == 0, "dinamit kullanıldı")
	dogru(dunya.kazilan.size() > once, "dinamit 3x3 alanı patlattı (%d → %d hücre)"
		% [once, dunya.kazilan.size()])
	dogru(not arac.dinamit_at(), "dinamit bitince atılmıyor")

	# --- istasyon ve ışınlanma -------------------------------------------
	durum.istasyon_kiti = 1
	var h := arac.hucre()
	h.y = maxi(h.y, Ayarlar.ISTASYON_EN_SIG)
	dogru(durum.istasyon_kur(h), "istasyon kuruldu (%d m)" % h.y)
	dogru(durum.isinlanma_duragi(h) == 0, "istasyonun yanında ışınlanma açık")
	dogru(durum.isinlanma_duragi(h + Vector2i(0, 40)) < 0, "istasyondan uzakta ışınlanma kapalı")
	arac.isinlan(Vector2(Ayarlar.US_X, -24.0))
	await _kare(20)
	dogru(arac.usste_mi(), "ışınlanma aracı üsse taşıdı")

	# --- kazı zinciri sahnede --------------------------------------------
	durum.zincir_tur = Ayarlar.BOS
	durum.zincir_adet = 0
	durum.yuk.clear()
	durum.yuk_bonus = 0
	for i in 4:
		durum.maden_ekle(Ayarlar.BAKIR)
	dogru(durum.zincir_adet == 4 and durum.zincir_carpani() > 1.0,
		"art arda aynı maden zinciri çarpan veriyor (×%.2f)" % durum.zincir_carpani())

	# --- mini harita ------------------------------------------------------
	var harita: TextureRect = sahne.get_node("HUD/Harita")
	harita.visible = true
	await _kare(30)
	dogru(harita.texture != null and harita.texture.get_size() == Vector2(Ayarlar.GENISLIK, Ayarlar.DERINLIK),
		"mini harita dokusu dünya boyutunda")

	# --- deprem seferi: bot 5. seferi gerçekten yaşıyor (v0.6) ------------
	# v0.5'e kadar sahne testi depremi elle tetikliyordu (_deprem_uygula): uyarının
	# kendiliğinden başlaması, geri sayımın akması ve kararın üç ucu sahnede hiç
	# sınanmamıştı (tarayıcı testinde de 5. sefere kadar beklenmedi). Burada beş
	# GERÇEK sefer (12 m'den derine in, üsse dön) sayacı doldurur; sonra üç ayrı
	# senaryo: (a) uyarıda pervaneyle yüzeye çık → ikramiye, (b) derinde kal →
	# hasar, (c) istasyondan ışınlan → bedava kaçış.
	var sefer_x := dip.x
	var sefer_h := Vector2i(sefer_x, mini(dip.y, 24))   ## şaftın içinde, 24 m'den sığ
	var saft_ac := func() -> void:
		for yy in range(0, sefer_h.y + 1):
			dunya.karo_kir(Vector2i(sefer_x, yy))
		# Altı dolu: ışınlanınca şaftın dibine düşmesin — (a)'da tırmanış
		# süresi uyarıya sığmalı, (b)'de düşme hasarı ölçümü kirletmesin.
		dunya.degistir([], {sefer_h + Vector2i.DOWN: Ayarlar.TOPRAK})
		dunya.hazirla(dunya.hucre_merkezi(sefer_h))
	saft_ac.call()
	durum.sefer = 0
	durum.deprem = 0
	durum.deprem_bekliyor = false
	sahne.set("_deprem_uyari", 0.0)
	sahne.set("_derine_indi", false)
	for i in durum.deprem_araligi():
		durum.yakit = durum.yakit_kapasitesi()
		arac.isinlan(dunya.hucre_merkezi(sefer_h))
		await _kare(4)
		arac.usse_don()
		await _kare(4)
	dogru(durum.sefer == durum.deprem_araligi() and durum.deprem_bekliyor,
		"%d gerçek sefer tamamlandı, deprem sayacı doldu" % durum.sefer)
	dogru(float(sahne.get("_deprem_uyari")) == 0.0, "üsteyken uyarı başlamıyor (deprem yeraltında patlar)")

	# (a) uyarıda yüzeye çıkan ikramiyeyi alır
	durum.yakit = durum.yakit_kapasitesi()
	durum.onar()
	var para_a := durum.para
	var can_a := durum.can
	arac.isinlan(dunya.hucre_merkezi(sefer_h))
	await _kare(3)
	var uyari_a := float(sahne.get("_deprem_uyari"))
	dogru(uyari_a > 0.0 and not durum.deprem_bekliyor,
		"yeraltına inince uyarı kendiliğinden başladı (%.1f sn)" % uyari_a)
	dogru(absf(uyari_a - Deprem.uyari_suresi(sefer_h.y)) < 0.25
		and int(sahne.get("_deprem_uyari_derinlik")) == sefer_h.y,
		"uyarı süresi ve derinliği %d m'ye göre (%.1f sn)" % [sefer_h.y, Deprem.uyari_suresi(sefer_h.y)])
	await _kare(2)
	var pano_a: VBoxContainer = sahne.get_node("HUD/Deprem")
	dogru(pano_a.visible and String(pano_a.get_node("Kacis").text).contains("%d ₺" % Deprem.odul(sefer_h.y)),
		"pano gerçek uyarıda açıldı ve ikramiyeyi yazıyor (%s)" % pano_a.get_node("Kacis").text)
	Input.action_press("yukari")
	var kare := 0
	while float(sahne.get("_deprem_uyari")) > 0.0 and kare < 1500:
		await physics_frame
		kare += 1
	Input.action_release("yukari")
	await _kare(3)
	dogru(durum.deprem == 1, "5. seferin depremi gerçekten patladı (%d kare sonra)" % kare)
	dogru(arac.derinlik() <= Deprem.GUVENLI_DERINLIK,
		"uyarı bitmeden pervaneyle yüzeye çıkıldı (%d m)" % arac.derinlik())
	dogru(durum.para == para_a + Deprem.odul(sefer_h.y),
		"(a) yüzeye çıkana kabuk nöbeti ikramiyesi geldi (+%d ₺)" % (durum.para - para_a))
	dogru(durum.can == can_a, "(a) yüzeye çıkan hasar almadı (%d/%d)" % [durum.can, can_a])
	dogru(not pano_a.visible, "deprem sonrası pano kapandı")

	# (b) derinde kalan hasar yer — deprem şaftı kapatmış olabilir, yeniden aç
	saft_ac.call()
	durum.sefer = durum.deprem_araligi() * 2 - 1
	sahne.set("_derine_indi", false)
	durum.yakit = durum.yakit_kapasitesi()
	arac.isinlan(dunya.hucre_merkezi(sefer_h))
	await _kare(4)
	arac.usse_don()
	await _kare(4)
	dogru(durum.deprem_bekliyor, "bir sonraki 5. sefer de sayacı doldurdu (sefer %d)" % durum.sefer)
	durum.onar()
	var para_b := durum.para
	arac.isinlan(dunya.hucre_merkezi(sefer_h))
	await _kare(40)   ## zemine otursun; uyarı bu arada sürüyor
	var can_b := durum.can
	dogru(float(sahne.get("_deprem_uyari")) > 0.0, "ikinci uyarı başladı")
	kare = 0
	while float(sahne.get("_deprem_uyari")) > 0.0 and kare < 1500:
		await physics_frame
		kare += 1
	await _kare(3)
	dogru(durum.deprem == 2 and arac.derinlik() > Deprem.GUVENLI_DERINLIK,
		"derinde kalındı, deprem patladı (%d m)" % arac.derinlik())
	dogru(durum.can == can_b - Deprem.hasar(arac.derinlik()),
		"(b) derinde kalan hasar yedi (can %d → %d)" % [can_b, durum.can])
	dogru(durum.para == para_b, "(b) derinde kalana ikramiye yok")

	# (c) istasyondan ışınlanan ikramiyeyi bedavaya alır
	saft_ac.call()
	arac.usse_don()
	durum.onar()
	var ist_h := sefer_h
	durum.istasyonlar = [ist_h]   ## sahne kurulumu; kit ve aralık kuralı yukarıda sınandı
	sahne.call("_nesne_yenile")
	durum.sefer = durum.deprem_araligi() * 3 - 1
	sahne.set("_derine_indi", false)
	durum.yakit = durum.yakit_kapasitesi()
	arac.isinlan(dunya.hucre_merkezi(sefer_h))
	await _kare(4)
	arac.usse_don()
	await _kare(4)
	dogru(durum.deprem_bekliyor, "üçüncü sayaç doldu (sefer %d)" % durum.sefer)
	var para_c := durum.para
	var can_c := durum.can
	arac.isinlan(dunya.hucre_merkezi(ist_h))
	await _kare(5)
	var yakit_c := durum.yakit
	dogru(float(sahne.get("_deprem_uyari")) > 0.0 and durum.isinlanma_duragi(arac.hucre()) == 0,
		"istasyonun üstünde uyarı başladı")
	sahne.call("_isinlanma_ac")
	await _kare(2)
	dogru(sahne.get_node("HUD/Isinlanma").visible, "ışınlanma paneli uyarı sırasında açıldı")
	sahne.call("_isinla", Vector2(Ayarlar.US_X, -24.0))
	await _kare(30)   ## 0,2 sn karartma + ışınlanma
	dogru(arac.usste_mi() and float(sahne.get("_deprem_uyari")) > 0.0,
		"uyarı bitmeden istasyondan üsse ışınlanıldı")
	kare = 0
	while float(sahne.get("_deprem_uyari")) > 0.0 and kare < 1500:
		await physics_frame
		kare += 1
	await _kare(3)
	dogru(durum.deprem == 3, "üçüncü deprem patladı")
	dogru(durum.para == para_c + Deprem.odul(ist_h.y),
		"(c) ışınlanan da ikramiyeyi aldı (+%d ₺)" % (durum.para - para_c))
	dogru(durum.can == can_c, "(c) ışınlanan hasar almadı")
	dogru(yakit_c - durum.yakit < Ayarlar.ISINLAMA_YAKIT + 3.0,
		"(c) kaçış bedava: tırmanış yok, yalnız ışınlanma yakıtı gitti (%.1f)" % (yakit_c - durum.yakit))
	durum.deprem_bekliyor = false
	sahne.set("_deprem_uyari", 0.0)
	durum.onar()

	# --- deprem sahnede ---------------------------------------------------
	# Aracı tünelin dibine götür, depremi elle tetikle: araç sıkışmamalı,
	# tünellerin bir kısmı kapanmalı, dünya yeniden yüklenmeli.
	var dip2 := Vector2i(arac.hucre().x, 0)
	for k2 in dunya.kazilan:
		if int(k2.y) > dip2.y:
			dip2 = Vector2i(k2)
	arac.isinlan(dunya.hucre_merkezi(dip2))
	durum.yakit = durum.yakit_kapasitesi()
	await _kare(20)
	var tunel0 := dunya.kazilan.size()
	durum.deprem_bekliyor = false
	durum.can = durum.can_kapasitesi()
	var derinde := arac.derinlik() > Deprem.GUVENLI_DERINLIK
	var can0 := durum.can
	sahne.set("_deprem_uyari_derinlik", arac.derinlik())
	sahne.call("_deprem_uygula")
	await _kare(30)
	dogru(dunya.kazilan.size() < tunel0, "deprem tünellerin bir kısmını kapattı (%d → %d)"
		% [tunel0, dunya.kazilan.size()])
	dogru(dunya.eklenen.size() > 0, "deprem yeni karolar ekledi (%d)" % dunya.eklenen.size())
	dogru(dunya.get_used_cells().size() > 0, "deprem sonrası chunk'lar yeniden yüklendi")
	# Aracın çevresi korunmuş olmalı: hemen etrafında kaya olmamalı.
	var cevre_dolu := 0
	for dy2 in range(-1, 2):
		for dx2 in range(-1, 2):
			if dunya.karo_tur(arac.hucre() + Vector2i(dx2, dy2)) != Ayarlar.BOS:
				cevre_dolu += 1
	dogru(cevre_dolu < 9, "araç depremden sonra kapalı bir kutuda değil (%d/9 dolu)"
		% cevre_dolu)
	# Kapanan hücreler yeniden kazılabilir olmalı (sıkışma yok).
	var kazilamaz2 := 0
	for h2 in dunya.eklenen:
		if not dunya.kazilabilir_mi(int(dunya.eklenen[h2])):
			kazilamaz2 += 1
	dogru(kazilamaz2 == 0, "deprem karolarının hepsi kazılabilir (%d istisna)" % kazilamaz2)
	# Kararın iki ucu sahnede: derinde kalmak can götürür, yüzeye çıkmak ikramiye verir.
	dogru(not derinde or durum.can < can0,
		"derinde kalınca deprem hasar verdi (can %d → %d, %d m)"
		% [can0, durum.can, arac.derinlik()])
	arac.usse_don()
	durum.onar()
	await _kare(10)
	var para0 := durum.para
	sahne.set("_deprem_uyari_derinlik", 100)
	sahne.call("_deprem_uygula")
	await _kare(10)
	dogru(durum.para == para0 + Deprem.odul(100),
		"yüzeye çıkınca kabuk nöbeti ikramiyesi geldi (+%d ₺)" % (durum.para - para0))
	dogru(durum.can == durum.can_kapasitesi(),
		"yüzeydeyken deprem hasar vermedi (%d/%d can)" % [durum.can, durum.can_kapasitesi()])

	# --- deprem panosu okunur mu (v0.5) ------------------------------------
	# v0.4'te geri sayım 13 px'lik alt ipucu şeridindeydi; artık ekranın
	# ortasında üç satırlık pano var ve kararın iki ucunu birden yazıyor.
	arac.isinlan(dunya.hucre_merkezi(dip2))
	durum.yakit = durum.yakit_kapasitesi()
	await _kare(20)
	sahne.set("_deprem_uyari_derinlik", arac.derinlik())
	sahne.set("_deprem_uyari", 8.0)
	sahne.call("_hud_yenile")
	var pano: VBoxContainer = sahne.get_node("HUD/Deprem")
	dogru(pano.visible, "deprem uyarısında pano açık")
	dogru(String(pano.get_node("Sayac").text).contains("DEPREM"),
		"panoda geri sayım var (%s)" % pano.get_node("Sayac").text)
	dogru(String(pano.get_node("Kacis").text).contains("₺")
		and String(pano.get_node("Kal").text).contains("hasar"),
		"panoda kararın iki ucu birden yazıyor")
	sahne.set("_deprem_uyari", 0.0)
	sahne.call("_hud_yenile")
	dogru(not pano.visible, "uyarı bitince pano kapanıyor")
	arac.usse_don()
	await _kare(10)

	# --- dokunmatik ipucu (sahnede) ---------------------------------------
	sahne.set("_ipucu_sure", 0.0)   ## depremin geçici mesajı kalıcı ipucuyu örtmesin
	sahne.set("_dokunmatik", true)
	var dokun_ipucu := String(sahne.call("_ipucu", 0))
	sahne.set("_dokunmatik", false)
	var masa_ipucu := String(sahne.call("_ipucu", 0))
	dogru(dokun_ipucu != masa_ipucu and not dokun_ipucu.contains("E — Üs"),
		"sahne dokunmatikte başka ipucu veriyor (%s)" % dokun_ipucu)
	dogru(masa_ipucu.contains("E — Üs"), "masaüstü ipucu değişmedi (%s)" % masa_ipucu)

	# --- dokunmatik düzen: tam alet seti, çakışma yok (v0.5) ---------------
	# v0.4'ün bilinen sorunu: telefonda dinamit ve radar kullanılamıyordu.
	# Düğmeler geldi; burada ölçülen şey 640x360'a sığdıkları ve DOKUNMA
	# ALANLARIYLA ÇAKIŞMADIKLARI. Dikdörtgenler sahneden okunuyor (sabit bir
	# listeden değil) ki düzen değişince test de gerçeği ölçsün.
	sahne.set("_dokunmatik", true)
	sahne.get_node("Dokunmatik").visible = true
	sahne.call("dokunmatik_kur")
	await _kare(5)
	var alanlar := []      ## [ad, Rect2]
	for c in sahne.get_node("Dokunmatik").get_children():
		if c is TouchScreenButton:
			alanlar.append([String(c.name), Rect2(c.position, (c.shape as RectangleShape2D).size)])
		elif c is Container:
			for b in c.get_children():
				if b is Button:
					alanlar.append(["%s/%s" % [c.name, b.text], Rect2(b.global_position, b.size)])
	dogru(alanlar.size() == 9, "dokunmatikte 4 kazı alanı + 5 düğme var (%d)" % alanlar.size())
	var tasan := ""
	var ekran := Rect2(0, 0, Ayarlar.EKRAN_G, Ayarlar.EKRAN_Y)
	for a in alanlar:
		if not ekran.encloses(a[1]):
			tasan += "%s %s | " % [a[0], a[1]]
	dogru(tasan == "", "bütün dokunma alanları 640x360'a sığıyor (%s)" % tasan)
	var cakisan := ""
	for i in alanlar.size():
		for j in range(i + 1, alanlar.size()):
			if Rect2(alanlar[i][1]).intersects(Rect2(alanlar[j][1])):
				cakisan += "%s ↔ %s | " % [alanlar[i][0], alanlar[j][0]]
	dogru(cakisan == "", "dokunma alanları çakışmıyor (%s)" % cakisan)

	# Düğmeler gerçekten çalışıyor mu: dinamit sayacı düşsün, radar açılsın.
	var dinamit_dgm: Button = sahne.get("_dgm_dinamit")
	var radar_dgm: Button = sahne.get("_dgm_radar")
	durum.dinamit = 0
	durum.aletler["radar"] = false
	sahne.call("_hud_yenile")
	dogru(dinamit_dgm.disabled and radar_dgm.disabled,
		"alet yokken düğmeler kapalı (%s / %s)" % [dinamit_dgm.text, radar_dgm.text])
	durum.dinamit = 2
	durum.aletler["radar"] = true
	sahne.call("_hud_yenile")
	dogru(dinamit_dgm.text.contains("2") and not dinamit_dgm.disabled,
		"dinamit düğmesi sayacı gösteriyor (%s)" % dinamit_dgm.text)
	# dip2 aradaki depremlerle KAPANMIŞ olabilir (deprem numarası değişince kapanan
	# hücreler de değişiyor; v0.6'da beş gerçek deprem daha var). Bayat hücreye
	# ışınlanınca araç kayanın içinde kalıyor ve dinamit zemin bulamıyordu: o anki
	# en derin AÇIK hücreye git, yere oturana kadar bekle.
	var dip3 := Vector2i(arac.hucre().x, 0)
	for k3 in dunya.kazilan:
		if int(k3.y) > dip3.y:
			dip3 = Vector2i(k3)
	arac.isinlan(dunya.hucre_merkezi(dip3))
	for bekle in 180:
		if arac.is_on_floor():
			break
		await physics_frame
	await _kare(3)
	dinamit_dgm.pressed.emit()
	await _kare(5)
	dogru(durum.dinamit == 1, "dinamit düğmesi dinamit attı (%d kaldı, %d m, zemin %s)"
		% [durum.dinamit, dip3.y, arac.is_on_floor()])
	radar_dgm.pressed.emit()
	dogru(bool(sahne.get("_radar_acik")), "radar düğmesi radarı açtı")
	radar_dgm.pressed.emit()
	dogru(not bool(sahne.get("_radar_acik")), "radar düğmesi radarı kapattı")
	sahne.set("_dokunmatik", false)

	sahne.call("_kaydet")
	var kayit2 := Kayit.yukle()
	dogru(PackedInt32Array(kayit2.get("eklenen", PackedInt32Array())).size() / 3
		== dunya.eklenen.size(), "deprem farkı kayda yazıldı")

	# --- derinlik ambiyansı (v0.6) -----------------------------------------
	# Banda göre parçacık (toz / kıvılcım), arka plan tonu ve müzik; müzik geçişi
	# iki oyuncuyla çaprazlanıyor — geçiş sırasında ikisi birden çalıyor.
	var amb: CPUParticles2D = sahne.get("_ambiyans")
	var fon: ColorRect = sahne.get_node("Arkaplan/Renk")
	arac.usse_don()
	await _kare(5)
	dogru(amb != null and amb.get_parent() == arac and not amb.local_coords,
		"ambiyans parçacığı araca bağlı, dünya koordinatında")
	dogru(not amb.emitting, "yüzeyde ambiyans parçacığı yok")
	dogru(ses.calan_muzik() == "muzik", "yüzeyde toprak bandının müziği (%s)" % ses.calan_muzik())
	var oda_ac := func(merkez: Vector2i) -> void:
		for dy3 in range(-2, 3):
			for dx3 in range(-3, 4):
				dunya.karo_kir(merkez + Vector2i(dx3, dy3))
	var bazalt_h := Vector2i(dunya.uretici.cekirdek_x, 172)
	oda_ac.call(bazalt_h)
	durum.yakit = durum.yakit_kapasitesi()
	arac.isinlan(dunya.hucre_merkezi(bazalt_h))
	await _kare(3)
	dogru(amb.emitting and amb.direction == Vector2.UP and amb.gravity.y < 0.0,
		"bazaltta kıvılcım yukarı süzülüyor")
	dogru(amb.color.r > amb.color.b, "kıvılcım rengi sıcak (%s)" % amb.color)
	dogru(ses.calan_muzik() == "muzik_bazalt", "bazalt bandına geçince müzik değişti (%s)" % ses.calan_muzik())
	dogru(ses.calan_muzik_sayisi() == 2, "geçiş sırasında iki parça birlikte çalıyor (crossfade)")
	await _kare(int(Ayarlar.MUZIK_GECIS * 60.0) + 20)
	dogru(ses.calan_muzik_sayisi() == 1, "geçiş bitince eski parça durdu")
	var fon_b: Color = Ayarlar.AMBIYANS[2]["fon"]
	var fon_t: Color = Ayarlar.AMBIYANS[0]["fon"]
	dogru(_renk_uzaklik(fon.color, fon_b) < _renk_uzaklik(fon.color, fon_t),
		"arka plan tonu bazalt bandına kaydı (%s)" % fon.color)
	var cek_h := Vector2i(dunya.uretici.cekirdek_x, 222)
	oda_ac.call(cek_h)
	arac.isinlan(dunya.hucre_merkezi(cek_h))
	await _kare(3)
	dogru(ses.calan_muzik() == "muzik_cekirdek", "çekirdek kabuğunda dördüncü parça (%s)" % ses.calan_muzik())
	arac.usse_don()
	await _kare(3)
	dogru(ses.calan_muzik() == "muzik" and amb.direction == Vector2.DOWN,
		"yüzeye dönünce toprak müziği ve toz")
	await _kare(int(Ayarlar.MUZIK_GECIS * 60.0) + 20)

	# --- karo varyantları sahnede -----------------------------------------
	var varyant_sayim := {}
	for h3 in dunya.get_used_cells():
		varyant_sayim[dunya.get_cell_atlas_coords(h3).y] = true
	dogru(varyant_sayim.size() > 1, "ekranda birden çok karo varyantı çizili (%d)"
		% varyant_sayim.size())

	# Bellek özeti sahne SERBEST BIRAKILMADAN önce alınır: aşağıda oyun sahnesi
	# kapatılıyor, sonrasında dunya'ya dokunmak serbest bırakılmış nesne hatası
	# verir ve test quit() e hiç gelmez (bir kez öyle asıldı).
	var ozet := "  bellek: %.1f MB statik, %d karo düğümü, %d chunk" % [
		OS.get_static_memory_usage() / 1048576.0, dunya.get_used_cells().size(),
		dunya.yuklu_parca_sayisi()]

	sahne.queue_free()
	await process_frame

	# --- v0.5 kaydı v0.6 sahnesinde açılıyor -------------------------------
	# Gerçek v0.5 dosyası (tests/veri/kayit-v0.5.cfg) ana yuvaya yazılıp sahne
	# kuruluyor: tüneller, keşif ve ilerleme yerinde; Derin Mod alanları varsayılan.
	var cfg5 := ConfigFile.new()
	dogru(cfg5.load("res://tests/veri/kayit-v0.5.cfg") == OK, "v0.5 kayıt fikstürü var")
	var eski5 := {}
	for anahtar in cfg5.get_section_keys(Kayit.ANA):
		eski5[anahtar] = cfg5.get_value(Kayit.ANA, anahtar)
	Kayit.sil()
	Kayit.kaydet(eski5)
	var sahne5: Node = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(sahne5)
	await process_frame
	await _kare(20)
	var durum5: Durum = sahne5.durum
	var dunya5: Dunya = sahne5.get_node("Dunya")
	dogru(durum5.tohum == int(eski5["tohum"]) and durum5.para == int(eski5["para"]),
		"v0.5 kaydı sahnede açıldı (tohum %s, %d ₺)" % [TohumKodu.kodla(durum5.tohum), durum5.para])
	dogru(dunya5.kazilan.size() == PackedInt32Array(eski5["kazilan"]).size() / 2 and dunya5.kazilan.size() > 10,
		"v0.5 tünelleri yerinde (%d hücre)" % dunya5.kazilan.size())
	dogru(dunya5.kesif_sayisi() > 50 and not durum5.derin_mi() and durum5.isik_yaricap() == Ayarlar.ISIK_YARICAP,
		"v0.5 keşfi yerinde (%d hücre), ilk oyun olarak sürüyor" % dunya5.kesif_sayisi())
	dogru(String(sahne5.get_node("HUD/Katman").text).find("DERİN") < 0, "HUD'da Derin Mod etiketi yok")
	dogru(sahne5.get("_ambiyans") != null and ses.calan_muzik() == "muzik",
		"v0.6 ambiyansı eski kayıtla da kuruldu")
	sahne5.call("_kaydet")
	dogru(int(Kayit.yukle().get("tohum", 0)) == int(eski5["tohum"]) and Kayit.yukle().has("kesif"),
		"v0.6 kaydı aynı yuvaya, keşifle birlikte yazıldı")
	sahne5.queue_free()
	await process_frame

	# --- menü sahnesi: paneller gerçekten açılıyor mu -----------------------
	# Tohum / günlük / Derin Mod menüde yaşıyor; düğme bağlantısı ya da düğüm
	# yolu bozulursa oyun değil yalnız menü kırılır ve sessizce fark edilmez.
	Kayit.sil()
	Kayit.sil(Kayit.DERIN)
	Kayit.kaydet({"tohum": 4242, "kazandi": true, "eserler": PackedInt32Array([0, 2])})
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await _kare(5)
	var kod := TohumKodu.kodla(4242)
	dogru(String(menu.get_node("Bilgi").text).contains(kod),
		"menü kayıtlı dünyanın tohum kodunu yazıyor (%s)" % kod)
	dogru(menu.get_node("M/V/Derin").visible, "çekirdek çıkarıldıysa Derin Mod düğmesi açık")
	dogru(not menu.get_node("Rozet").visible, "Derin Mod'a hiç girilmediyse rozet yok")

	# --- Derin Mod yuvası ayrı (v0.6) ----------------------------------------
	# Derin Mod'a girmek ana kaydı (çekirdeği çıkarmış dünya, tünelleri) silmiyor;
	# süren tur kendi yuvasında, biten tur bir üst seviyeyi yeni tohumla kuruyor.
	var d1 := Kayit.derin_mod_hazirla()
	dogru(Kayit.aktif == Kayit.DERIN and int(d1["derin_seviye"]) == 1,
		"Derin Mod x1 kendi yuvasında kuruldu")
	dogru(PackedInt32Array(d1["eserler"]) == PackedInt32Array([0, 2]), "eserler Derin Mod yuvasına taşındı")
	dogru(int(Kayit.yukle(Kayit.ANA).get("tohum", 0)) == 4242 and bool(Kayit.yukle(Kayit.ANA).get("kazandi", false)),
		"ana kayıt yerinde kaldı (tohum, çekirdek bayrağı)")
	Kayit.kaydet({"en_derin": 77, "para": 120}, Kayit.DERIN)
	var d2 := Kayit.derin_mod_hazirla()
	dogru(int(d2.get("en_derin", 0)) == 77 and int(d2["tohum"]) == int(d1["tohum"]),
		"süren Derin Mod turuna aynı yuvadan devam ediliyor")
	menu.call("_bilgi_yenile")
	dogru(menu.get_node("Rozet").visible and String(menu.get_node("Rozet").text).contains("x1"),
		"menüde Derin Mod rozeti (%s)" % menu.get_node("Rozet").text)
	dogru(String(menu.get_node("M/V/Derin").text).contains("devam"),
		"Derin Mod düğmesi süren tura devam diyor (%s)" % menu.get_node("M/V/Derin").text)
	Kayit.kaydet({"kazandi": true, "eserler": PackedInt32Array([0, 2, 6])}, Kayit.DERIN)
	menu.call("_bilgi_yenile")
	dogru(String(menu.get_node("M/V/Derin").text).contains("x2"),
		"Derin Mod bitince x2 sunuluyor (%s)" % menu.get_node("M/V/Derin").text)
	dogru(String(menu.get_node("Rozet").text).contains("bulundu"), "rozet 7. eserin bulunduğunu yazıyor")
	var d3 := Kayit.derin_mod_hazirla()
	dogru(int(d3["derin_seviye"]) == 2 and PackedInt32Array(d3["eserler"]) == PackedInt32Array([0, 2, 6])
		and int(d3["tohum"]) != int(d1["tohum"]),
		"x2 yeni tohumla kuruldu, 7. eser dahil eserler kaldı")
	dogru(int(Kayit.yukle(Kayit.ANA).get("tohum", 0)) == 4242, "x2 kurulurken ana kayıt yine dokunulmadı")
	Kayit.aktif = Kayit.ANA
	menu.call("_tohum_ac")
	await _kare(2)
	dogru(menu.get_node("TohumPanel").visible
		and String(menu.get_node("TohumPanel/M/V/Bilgi").text).contains(kod),
		"tohum paneli açılıyor ve kodu gösteriyor")
	menu.get_node("TohumPanel/M/V/Giris").text = "abc-def!"
	menu.call("_kod_degisti", "abc-def!")
	await _kare(2)
	dogru(menu.get_node("TohumPanel/M/V/Giris").text == "ABCDEF",
		"kod alanı alfabe dışını süzüyor (%s)" % menu.get_node("TohumPanel/M/V/Giris").text)
	menu.call("_tohum_kapat")
	menu.call("_ayar_ac")
	await _kare(2)
	dogru(menu.get_node("Ayar").visible
		and menu.get_node("Ayar/M/V/Kaydir/Liste").get_child_count() > 3,
		"ayar paneli açılıyor ve doluyor")
	menu.call("_ayar_kapat")
	# Günlük yuva ana ilerlemeye dokunmamalı.
	var gunluk := Kayit.gunluk_hazirla()
	dogru(int(gunluk["tohum"]) == Kayit.gunluk_tohum(), "günlük yuva bugünün tohumuyla kuruldu")
	dogru(int(Kayit.yukle(Kayit.ANA).get("tohum", 0)) == 4242,
		"günlük yuva ana kaydı bozmadı")
	menu.queue_free()
	await process_frame

	print(ozet)
	print("== %d sınama, %d hata ==" % [_sayac, _hata])
	Kayit.sil()
	Kayit.sil(Kayit.DERIN)
	quit(1 if _hata > 0 else 0)

static func _renk_uzaklik(a: Color, b: Color) -> float:
	return (a.r - b.r) * (a.r - b.r) + (a.g - b.g) * (a.g - b.g) + (a.b - b.b) * (a.b - b.b)
