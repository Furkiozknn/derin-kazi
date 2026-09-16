class_name Simgeler
extends RefCounted
## Godot'nun gömülü yazı tipinde (Open Sans) olmayan simgeler için yedek yazı tipi.
## Masaüstünde sistem yazı tipleri bu eksiği örtüyor; web'de örtmüyor (simge yerine kutu çıkıyor).
## Kapsanan simgeler: ★☆✓✔✗✘←↑→↓↔↕▲▶▼◀△▷▽◁■□●○◆◇⟲⟳₺♥♡⚙
## Kullanım: ilk açılan sahnenin _ready() başında (ya da autoload'da) Simgeler.kur().
## Birden çok çağrı zararsızdır.

const YOL := "res://assets/fonts/simgeler.ttf"


static func kur() -> void:
	var ana := ThemeDB.fallback_font
	if ana == null or not ResourceLoader.exists(YOL):
		return
	var yedek: Font = load(YOL)
	if yedek == null or ana.fallbacks.has(yedek):
		return
	var liste := ana.fallbacks.duplicate()
	liste.append(yedek)
	ana.fallbacks = liste


## Test için: verilen metindeki her karakter yazı tipi zincirinde var mı? Eksikleri döndürür.
static func eksikler(metin: String) -> String:
	var ana := ThemeDB.fallback_font
	var sonuc := ""
	for ch in metin:
		if ch.unicode_at(0) > 32 and not ana.has_char(ch.unicode_at(0)) and not sonuc.contains(ch):
			sonuc += ch
	return sonuc
