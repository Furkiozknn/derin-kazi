## Oynanış entegrasyon testi: gerçek sahneyi kurar, aracı kazdırır.
## godot --headless --script res://tests/test_oynanis.gd   (0 = geçti, 1 = kaldı)
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
	var sahne: Node = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(sahne)
	await process_frame
	await _kare(30)

	var arac: Arac = sahne.get_node("Arac")
	var dunya: Dunya = sahne.get_node("Dunya")
	var durum: Durum = sahne.durum

	dogru(arac.is_on_floor(), "araç yüzeyde zemine oturdu")
	dogru(arac.usste_mi(), "başlangıçta üste yakın (menü açılabilir)")
	dogru(dunya.uretilen_karo > 0, "ilk parçalar üretildi (%d karo)" % dunya.uretilen_karo)

	var yakit0 := durum.yakit
	var parca0 := dunya.uretilen_karo

	# 25 saniye aşağı kaz.
	Input.action_press("asagi")
	await _kare(1500)
	Input.action_release("asagi")
	await _kare(10)

	var derinlik := floori(arac.global_position.y / Ayarlar.KARO)
	dogru(derinlik > 15, "aşağı kazarak derinleşti (%d m)" % derinlik)
	dogru(durum.en_derin >= derinlik - 1, "en derin noktası kaydedildi (%d m)" % durum.en_derin)
	dogru(durum.yakit < yakit0, "yakıt tüketildi (%.1f → %.1f)" % [yakit0, durum.yakit])
	dogru(durum.yuk_toplam() > 0, "yol üstündeki maden yüke eklendi (%d parça)" % durum.yuk_toplam())
	dogru(not arac.usste_mi(), "araç üsten uzaklaştı")
	dogru(dunya.uretilen_karo > parca0, "inerken yeni parçalar üretildi (%d → %d karo)"
		% [parca0, dunya.uretilen_karo])

	# Üretim gerçekten parça parça: tüm dünya (%d karo) bir kerede kurulmadı.
	var tum_dunya := Ayarlar.GENISLIK * Ayarlar.DERINLIK
	dogru(dunya.uretilen_karo < tum_dunya / 2,
		"parça parça üretim: %d / %d karo bellekte" % [dunya.uretilen_karo, tum_dunya])

	# Pervaneyle yukarı çıkabiliyor mu?
	var y0 := arac.global_position.y
	Input.action_press("yukari")
	await _kare(90)
	Input.action_release("yukari")
	dogru(arac.global_position.y < y0, "pervane ile tünelde yükseldi (%.0f → %.0f px)"
		% [y0, arac.global_position.y])

	# Yukarı kazmak yasak: tavan kapalıyken yükselemez.
	var yuk0 := durum.yuk_toplam()
	Input.action_press("yukari")
	await _kare(240)
	Input.action_release("yukari")
	dogru(durum.yuk_toplam() == yuk0, "yukarı doğru kazma yok (yük değişmedi)")

	print("  bellek: %.1f MB statik, %d karo düğümü" % [
		OS.get_static_memory_usage() / 1048576.0, dunya.get_used_cells().size()])
	print("== %d sınama, %d hata ==" % [_sayac, _hata])
	quit(1 if _hata > 0 else 0)
