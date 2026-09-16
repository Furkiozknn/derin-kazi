## Paylaşılabilir tohum kodu. 32 harflik "karışmayan" alfabe: I, O, 0, 1 yok
## (elle yazılırken l/1/I ve O/0 karışıyor). 7 karakter = 32 bit tohum + 3 bit sağlama,
## yani yanlış yazılan kod sessizce başka bir dünya açmaz, "geçersiz" der.
class_name TohumKodu
extends RefCounted

const ALFABE := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const UZUNLUK := 7
const GECERSIZ := -1

## 3 bitlik sağlama. XOR kullanılmıyor: aynı bitleri üst üste katladığı için
## tek harf hatalarının dörtte birini kaçırıyordu. Konuma duyarlı çarpan
## karıştırıcı her 5 bitlik harfi ayrı ağırlıklıyor. Motorun `hash()`'i de
## bilerek kullanılmıyor: kod sürümler arası aynı kalmalı.
static func _saglama(v: int) -> int:
	var h := 17
	var x := v & 0xFFFFFFFF
	for i in UZUNLUK:
		h = (h * 131 + (x & 31) * 7 + i) & 0x7FFFFFFF
		x >>= 5
	return (h ^ (h >> 5) ^ (h >> 11)) & 0x07

## Tohumdan 7 karakterlik kod.
static func kodla(tohum: int) -> String:
	var v := tohum & 0xFFFFFFFF
	var s := (_saglama(v) << 32) | v
	var kod := ""
	for i in UZUNLUK:
		kod = ALFABE[s & 31] + kod
		s >>= 5
	return kod

## Koddan tohum. Bozuk/eksik kodda GECERSIZ (-1) döner.
static func coz(kod: String) -> int:
	var t := kod.strip_edges().to_upper().replace("-", "").replace(" ", "")
	if t.length() != UZUNLUK:
		return GECERSIZ
	var s := 0
	for ch in t:
		var i := ALFABE.find(ch)
		if i < 0:
			return GECERSIZ
		s = (s << 5) | i
	var v := s & 0xFFFFFFFF
	if (s >> 32) != _saglama(v):
		return GECERSIZ
	return v

## Kullanıcının girdiği metni alfabeye indirger (kod alanı için canlı süzgeç).
static func suz(metin: String) -> String:
	var t := ""
	for ch in metin.to_upper():
		if ALFABE.contains(ch):
			t += ch
	return t.substr(0, UZUNLUK)
