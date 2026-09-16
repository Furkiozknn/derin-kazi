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

	# --- dokunmatik ipucu (sahnede) ---------------------------------------
	sahne.set("_ipucu_sure", 0.0)   ## depremin geçici mesajı kalıcı ipucuyu örtmesin
	sahne.set("_dokunmatik", true)
	var dokun_ipucu := String(sahne.call("_ipucu", 0))
	sahne.set("_dokunmatik", false)
	var masa_ipucu := String(sahne.call("_ipucu", 0))
	dogru(dokun_ipucu != masa_ipucu and not dokun_ipucu.contains("E — Üs"),
		"sahne dokunmatikte başka ipucu veriyor (%s)" % dokun_ipucu)
	dogru(masa_ipucu.contains("E — Üs"), "masaüstü ipucu değişmedi (%s)" % masa_ipucu)

	sahne.call("_kaydet")
	var kayit2 := Kayit.yukle()
	dogru(PackedInt32Array(kayit2.get("eklenen", PackedInt32Array())).size() / 3
		== dunya.eklenen.size(), "deprem farkı kayda yazıldı")

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

	# --- menü sahnesi: paneller gerçekten açılıyor mu -----------------------
	# Tohum / günlük / Derin Mod menüde yaşıyor; düğme bağlantısı ya da düğüm
	# yolu bozulursa oyun değil yalnız menü kırılır ve sessizce fark edilmez.
	sahne.queue_free()
	await process_frame
	Kayit.sil()
	Kayit.kaydet({"tohum": 4242, "kazandi": true, "eserler": PackedInt32Array([0, 2])})
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await _kare(5)
	var kod := TohumKodu.kodla(4242)
	dogru(String(menu.get_node("Bilgi").text).contains(kod),
		"menü kayıtlı dünyanın tohum kodunu yazıyor (%s)" % kod)
	dogru(menu.get_node("M/V/Derin").visible, "çekirdek çıkarıldıysa Derin Mod düğmesi açık")
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
	quit(1 if _hata > 0 else 0)
