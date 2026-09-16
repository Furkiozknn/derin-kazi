## Fay hattı garantisi gerçekten bir şey yapıyor mu?
##   godot --headless --path . --script res://tests/test_fay_olcum.gd
##
## Fay kapalıyken dünya v0.2 gibi üretilir. Ölçülen iki şey:
##   1. BFS: yüzeyden çekirdeğe kazılabilir yol var mı?
##   2. Bot: "aşağı kaz, tıkanınca yana git" davranışıyla çekirdeğe varılıyor mu?
## v0.2'deki "bir tohumda 400 turda ulaşılamıyor" sorusunun cevabı bu ikisinin
## farkında: yol VAR ama bot (ve oyuncu) onu bulamıyor.
## v0.4: bu betik artık yalnız ölçmüyor, SINIYOR — fay açıkken botun 12 tohumun
## hepsinde çekirdeğe varması bekleniyor (çıkış kodu 1 = kaldı). v0.3'te tohum 3'te
## kalıyordu; kalan sorun dünyada değil botun yol bulmasındaydı (bkz. Bot._rota).
extends SceneTree

const TOHUMLAR := [11, 4242, 90210, 1337, 7, 555000, 20260916, 1, 2, 3, 999999, 123456]

func _initialize() -> void:
	var acik_bot := 0
	var acik_sisli := 0
	for acik in [false, true]:
		DunyaUretici.fay_acik = acik
		var yol := 0
		var bot := 0
		var kopuk := PackedInt32Array()
		var botsuz := PackedInt32Array()
		for t in TOHUMLAR:
			var u := DunyaUretici.new(t)
			if _ulasilabilir(u).has(Vector2i(u.cekirdek_x, Ayarlar.CEKIRDEK_DERINLIK)):
				yol += 1
			else:
				kopuk.append(t)
			if int(Bot.calistir(t, Bot.MUKEMMEL)["cekirdek_tur"]) > 0:
				bot += 1
			else:
				botsuz.append(t)
		print("fay %s  ->  BFS yol: %d/%d %s  |  bot çekirdeğe vardı: %d/%d %s" % [
			"AÇIK " if acik else "KAPALI", yol, TOHUMLAR.size(), str(kopuk),
			bot, TOHUMLAR.size(), str(botsuz)])
		# v0.5: keşif sisi. Yol bulması yalnız keşfedileni bilen insan botu aynı
		# tohumlarda ne yapıyor? "rota" = kaç kez BFS kuruldu, "kırılma" = karanlıkta
		# sade kaya sandığı hücre kaç kez kaya/lav çıktı (varsayımın bedeli).
		var sisli := _olc(Bot.INSAN_SISLI)
		var sissiz := _olc(Bot.INSAN)
		print("   insan botu   sisli : vardı %d/%d %s  •  rota %d, kırılma %d  •  çekirdek ort. %.0f dk" % [
			int(sisli["vardi"]), TOHUMLAR.size(), str(sisli["kalan"]), int(sisli["rota"]),
			int(sisli["kirilma"]), float(sisli["dk"])])
		print("   insan botu   sissiz: vardı %d/%d %s  •  rota %d  •  çekirdek ort. %.0f dk" % [
			int(sissiz["vardi"]), TOHUMLAR.size(), str(sissiz["kalan"]), int(sissiz["rota"]),
			float(sissiz["dk"])])
		if acik:
			acik_bot = bot
			acik_sisli = int(sisli["vardi"])
	DunyaUretici.fay_acik = true
	# Sınama: fay açıkken kusursuz bot da, yalnız keşfedileni bilen insan botu da
	# her tohumda çekirdeğe varmalı — sis oyunu bitirilemez yapmamalı.
	var gecti := acik_bot == TOHUMLAR.size() and acik_sisli == TOHUMLAR.size()
	print("== fay açıkken kusursuz bot %d/%d, sisli insan botu %d/%d tohumda çekirdeğe vardı — %s ==" % [
		acik_bot, TOHUMLAR.size(), acik_sisli, TOHUMLAR.size(), "TAMAM" if gecti else "KALDI"])
	quit(0 if gecti else 1)

func _olc(ayar: Dictionary) -> Dictionary:
	var vardi := 0
	var rota := 0
	var kirilma := 0
	var dk := 0.0
	var kalan := PackedInt32Array()
	for t in TOHUMLAR:
		var s := Bot.calistir(t, ayar)
		rota += int(s["rota"])
		kirilma += int(s["sis_kirilma"])
		dk += float(s["cekirdek_dk"])
		if int(s["cekirdek_tur"]) > 0:
			vardi += 1
		else:
			kalan.append(t)
	return {"vardi": vardi, "rota": rota, "kirilma": kirilma,
		"dk": dk / float(TOHUMLAR.size()), "kalan": kalan}

func _ulasilabilir(u: DunyaUretici) -> Dictionary:
	var gorulen := {}
	var sira: Array[Vector2i] = [Vector2i(Ayarlar.US_KARO_X, 0)]
	gorulen[sira[0]] = true
	while not sira.is_empty():
		var h: Vector2i = sira.pop_back()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var k := h + d
			if k.x < 1 or k.y < 0 or k.x >= Ayarlar.GENISLIK - 1 or k.y >= Ayarlar.DERINLIK:
				continue
			if gorulen.has(k):
				continue
			var t := u.karo(k.x, k.y)
			if t == Ayarlar.KAYA or t == Ayarlar.LAV:
				continue
			gorulen[k] = true
			sira.append(k)
	return gorulen
