## Depth splits: the run clock at the moment each stratum boundary is first
## reached (40 / 90 / 150 / 210 m) and the core (250 m), compared with the player's
## best split at that depth, the way speedrun timers show splits.
##
## Pure class: no scene, no save file. Durum keeps this run's splits, the
## [rekor] save section keeps the best ones; the scene only calls isle() and
## shows the text. The bot never calls it, so balance measurements do not change.
##
## A split array always has esikler().size() entries; YOK means "not reached yet".
class_name AraSure
extends RefCounted

const YOK := -1.0

## Split depths in metres: every stratum boundary below the surface, then the core.
static func esikler() -> PackedInt32Array:
	var e := PackedInt32Array()
	for i in range(1, Ayarlar.KATMANLAR.size()):
		e.append(int(Ayarlar.KATMANLAR[i]["y0"]))
	e.append(Ayarlar.CEKIRDEK_DERINLIK)
	return e

## An empty split array (nothing reached).
static func bos() -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(esikler().size())
	a.fill(YOK)
	return a

## Returns a well-formed split array: anything of the wrong size or type (old or
## hand-edited save) becomes bos(); negative or non-finite entries become YOK.
static func gecerli(v: Variant) -> PackedFloat32Array:
	if not (v is PackedFloat32Array or v is Array):
		return bos()
	var a := PackedFloat32Array(v)
	if a.size() != esikler().size():
		return bos()
	for i in a.size():
		if is_nan(a[i]) or is_inf(a[i]) or a[i] < 0.0:
			a[i] = YOK
	return a

## Records every split that `derinlik` has passed and that is still empty, at time
## `sure`. Returns the index of the deepest newly recorded split, or -1 if none.
## Falling straight through two boundaries records both with the same time.
static func isle(ara: PackedFloat32Array, derinlik: int, sure: float) -> int:
	var e := esikler()
	var yeni := -1
	for i in e.size():
		if derinlik >= e[i] and ara[i] < 0.0:
			ara[i] = sure
			yeni = i
	return yeni

## Per-split best of `rekor` and `ara` (an empty entry never wins).
static func birlestir(rekor: PackedFloat32Array, ara: PackedFloat32Array) -> PackedFloat32Array:
	var r := gecerli(rekor)
	var a := gecerli(ara)
	for i in r.size():
		if a[i] >= 0.0 and (r[i] < 0.0 or a[i] < r[i]):
			r[i] = a[i]
	return r

## How many splits of `ara` beat (or set) the record in `rekor`.
static func yeni_rekor_sayisi(rekor: PackedFloat32Array, ara: PackedFloat32Array) -> int:
	var r := gecerli(rekor)
	var a := gecerli(ara)
	var n := 0
	for i in a.size():
		if a[i] >= 0.0 and (r[i] < 0.0 or a[i] < r[i]):
			n += 1
	return n

## "m:ss".
static func sure_metni(s: float) -> String:
	var t := int(round(s))
	return "%d:%02d" % [t / 60, t % 60]

## Difference to the record: "-0:05" (ahead), "+0:12" (behind), "0:00" (tied),
## "" when there is no record to compare with. ASCII signs: the web build's
## fallback icon font is not guaranteed to carry U+2212.
static func fark_metni(sure: float, rekor: float) -> String:
	if rekor < 0.0 or sure < 0.0:
		return ""
	var f := int(round(sure)) - int(round(rekor))
	if f == 0:
		return "0:00"
	return ("-" if f < 0 else "+") + sure_metni(absf(float(f)))

## One split for the HUD toast: "90 m  5:40  (-0:21)".
static func tek_metin(i: int, ara: PackedFloat32Array, rekor: PackedFloat32Array) -> String:
	var e := esikler()
	var r := gecerli(rekor)
	var s := "%d m  %s" % [e[i], sure_metni(ara[i])]
	var f := fark_metni(ara[i], r[i])
	if f != "":
		s += "  (%s)" % f
	elif ara[i] >= 0.0:
		s += "  (" + Ceviri.t("ilk") + ")"
	return s

## The end-panel line: every split with its difference; "—" for depths not reached
## in this run (an old save loaded mid-run, or a run that ended above 250 m).
static func satir(ara: PackedFloat32Array, rekor: PackedFloat32Array) -> String:
	var a := gecerli(ara)
	var parca := PackedStringArray()
	for i in a.size():
		if a[i] < 0.0:
			parca.append("%d m —" % esikler()[i])
		else:
			parca.append(tek_metin(i, a, rekor).replace("  ", " "))
	return Ceviri.t("ARA SÜRELER") + "  " + "  ·  ".join(parca)
