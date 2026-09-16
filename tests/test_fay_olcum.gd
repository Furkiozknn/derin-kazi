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
		if acik:
			acik_bot = bot
	DunyaUretici.fay_acik = true
	var gecti := acik_bot == TOHUMLAR.size()
	print("== fay açıkken bot %d/%d tohumda çekirdeğe vardı — %s ==" % [
		acik_bot, TOHUMLAR.size(), "TAMAM" if gecti else "KALDI"])
	quit(0 if gecti else 1)

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
