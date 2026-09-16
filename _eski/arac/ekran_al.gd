## Oyundan tek kare ekran görüntüsü alır (görsel doğrulama için).
## godot --path . --script res://arac/ekran_al.gd  → user://ekran.png
## (--headless ile çalışmaz: render gerekiyor.)
extends SceneTree

func _initialize() -> void:
	_calis()

func _calis() -> void:
	var s: Node = load("res://scenes/oyun.tscn").instantiate()
	root.add_child(s)
	for i in 40:
		await physics_frame
	Input.action_press("asagi")
	for i in 900:
		await physics_frame
	Input.action_release("asagi")
	for i in 20:
		await process_frame
	root.get_texture().get_image().save_png("user://ekran.png")
	print("kaydedildi: user://ekran.png")
	quit(0)
