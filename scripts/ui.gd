class_name UI
extends RefCounted
## Arayuz yardimcilari: menu ogelerinin sirayla girisi ve dugme basis hareketi.
## Stil rehberi: giris 180-260 ms ease-out, ogeler 40 ms arayla; dugme basisi 90 ms.

const GIRIS := 0.22
const ARALIK := 0.04
const BASIS := 0.09


## Ogeler sirayla belirir (alfa 0 -> 1, 8 px asagidan yukari). Kutu icindeki
## konteyner duzenini bozmamak icin konum degil, alfa + kayma "position:y" ile
## yerlesim sonrasi gorsel ofsetle degil modulate ile yapilir (konteyner cocugu
## konumunu tekrar hesaplar); bu yuzden yalniz alfa ve olcek.
static func sirayla_gir(ogeler: Array, baslangic: float = 0.0) -> void:
	var i := 0
	for o in ogeler:
		var c := o as Control
		if c == null or not c.visible:
			continue
		c.modulate.a = 0.0
		var t := c.create_tween()
		t.tween_interval(baslangic + i * ARALIK)
		t.tween_property(c, "modulate:a", 1.0, GIRIS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		i += 1


## Bir alt agactaki butun dugmelere basis hareketi verir (90 ms'de %96'ya kucul).
static func dugmeleri_bagla(kok: Node) -> void:
	for d in kok.find_children("*", "BaseButton", true, false):
		var b := d as Control
		if b.has_meta(&"ui_bagli"):
			continue
		b.set_meta(&"ui_bagli", true)
		b.resized.connect(func() -> void: b.pivot_offset = b.size * 0.5)
		b.pivot_offset = b.size * 0.5
		(d as BaseButton).button_down.connect(func() -> void: _olcek(b, 0.96, BASIS))
		(d as BaseButton).button_up.connect(func() -> void: _olcek(b, 1.0, 0.12))


static func _olcek(b: Control, hedef: float, sure: float) -> void:
	if not b.is_inside_tree():
		return
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2(hedef, hedef), sure).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
