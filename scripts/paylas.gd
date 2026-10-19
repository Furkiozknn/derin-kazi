## Share text: a short, spoiler-free summary of a world that a player can paste
## into a chat, in the spirit of daily-puzzle share cards. It carries the seed
## code, so whoever reads it can open the same world from the menu's
## "Tohum kodu" screen, even on another day.
##
## Pure class: the scene copies the result to the clipboard
## (DisplayServer.clipboard_set). The text never reaches the game's own fonts,
## so the bar characters do not need to exist in assets/fonts.
class_name Paylas
extends RefCounted

const ADRES := "https://furkiozknn.github.io/derin-kazi/"
const CUBUK := 10            ## depth bar cells: one cell = 25 m of the 250 m
const DOLU := "▰"
const BOS := "▱"
const EN_UZUN := 280         ## must fit a single short post

## Depth bar: how far toward the core this world went ("▰▰▰▱▱▱▱▱▱▱").
static func cubuk(derinlik: int) -> String:
	var oran := clampf(float(derinlik) / float(Ayarlar.CEKIRDEK_DERINLIK), 0.0, 1.0)
	var n := int(floor(oran * CUBUK + 0.0001))
	return DOLU.repeat(n) + BOS.repeat(CUBUK - n)

## Title line: daily world with its date, Derin Mod with its level, or the plain game.
static func baslik(d: Durum, gunluk: bool, gun: String) -> String:
	var b := Ceviri.t("Derin Kazı")
	if gunluk:
		b += " · " + Ceviri.t("Günlük dünya") + " " + gun
	elif d.derin_mi():
		b += " · " + Ceviri.t("DERİN MOD x%d") % d.derin_seviye
	return b

## The full share text. `gunluk` and `gun` come from Kayit (active slot, today).
static func metin(d: Durum, gunluk: bool, gun: String) -> String:
	var satirlar := PackedStringArray()
	satirlar.append(baslik(d, gunluk, gun))
	var derin := mini(d.en_derin, Ayarlar.CEKIRDEK_DERINLIK)
	var durum_satiri := "%d / %d m  %s" % [derin, Ayarlar.CEKIRDEK_DERINLIK, cubuk(derin)]
	if d.kazandi:
		durum_satiri += "  " + Ceviri.t("çekirdek çıkarıldı")
	satirlar.append(durum_satiri)
	satirlar.append(Ceviri.t("Süre %s  ·  eser %d/%d  ·  %d deprem  ·  %d çekilme") % [
		_sure(d.sure), d.eser_toplanan(), d.eser_sayisi(), d.deprem, d.olum])
	satirlar.append(Ceviri.t("Tohum kodu: %s") % TohumKodu.kodla(d.tohum))
	satirlar.append(ADRES)
	return "\n".join(satirlar)

static func _sure(s: float) -> String:
	var t := int(s)
	return "%d:%02d" % [t / 60, t % 60]
